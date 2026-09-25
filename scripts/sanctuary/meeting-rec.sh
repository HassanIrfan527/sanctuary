#!/usr/bin/env bash
# meeting-rec.sh — keybind-driven two-channel meeting recorder for PipeWire.
#
# Records two SEPARATE mono files instead of one stereo mix:
#   me.wav    ← default audio SOURCE  (your microphone)
#   them.wav  ← monitor of the default audio SINK (everything you hear)
#
# Separate files mean speaker separation is free — no diarization model, ever.
#
# Everything is captured at 16 kHz / mono / s16, which is exactly what Whisper
# consumes. That is not a quality compromise: Whisper resamples to 16 kHz mono
# internally regardless. Recording there directly means ffmpeg is never needed
# on this machine, and an hour of meeting costs ~115 MB per channel.
#
# Usage:
#   meeting-rec.sh toggle [--solo] [--label TEXT]   start if idle, stop if running
#   meeting-rec.sh start  [--solo] [--label TEXT]
#   meeting-rec.sh stop
#   meeting-rec.sh status                            exit 0 = recording, 1 = idle
#
#   --solo   mic only; skips them.wav. For the practice-ground mode, where
#            there is no other party and a monitor capture would only record
#            your own playback back at you.
#   --label  free text folded into the session directory name.

set -uo pipefail

REC_ROOT="${MEETING_REC_ROOT:-$HOME/Recordings/meetings}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/meeting-rec"
RATE=16000

notify() { command -v notify-send >/dev/null && notify-send -a "meeting-rec" -i audio-input-microphone "$@"; }
die()    { echo "meeting-rec: $*" >&2; notify -u critical "Recording failed" "$*"; exit 1; }

# Resolve the *current* default devices at start time rather than hardcoding a
# card. Plugging in a headset between meetings then needs no config edit.
node_name() { wpctl inspect "$1" 2>/dev/null | sed -n 's/.*node\.name = "\(.*\)".*/\1/p' | head -1; }
node_desc() { wpctl inspect "$1" 2>/dev/null | sed -n 's/.*node\.description = "\(.*\)".*/\1/p' | head -1; }

alive() { [[ -n "${1:-}" ]] && kill -0 "$1" 2>/dev/null; }

is_recording() {
    [[ -f "$STATE_DIR/me.pid" ]] || return 1
    alive "$(cat "$STATE_DIR/me.pid" 2>/dev/null)" && return 0
    # PID file outlived its process (crash, unplugged device, reboot mid-session).
    # Treat as idle but keep whatever audio landed on disk.
    rm -rf "$STATE_DIR"
    return 1
}

cmd_start() {
    local solo=0 label=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --solo)  solo=1; shift ;;
            --label) label="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done

    is_recording && die "already recording (started $(cat "$STATE_DIR/started_human" 2>/dev/null))"

    command -v pw-record >/dev/null || die "pw-record not found (pipewire not installed?)"

    local src sink
    src=$(node_name @DEFAULT_AUDIO_SOURCE@)
    [[ -n "$src" ]] || die "no default audio source — is a microphone connected?"
    if (( ! solo )); then
        sink=$(node_name @DEFAULT_AUDIO_SINK@)
        [[ -n "$sink" ]] || die "no default audio sink to capture"
    fi

    local slug stamp dir
    stamp=$(date +%Y-%m-%d_%H%M%S)
    slug="$stamp"
    (( solo )) && slug="${slug}_practice"
    if [[ -n "$label" ]]; then
        # fold label to a safe path component
        slug="${slug}_$(printf '%s' "$label" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//' | cut -c1-40)"
    fi
    dir="$REC_ROOT/$slug"
    mkdir -p "$dir" "$STATE_DIR" || die "cannot create $dir"

    # --target + stream.capture.sink=true attaches the capture to the sink's
    # monitor ports, which is how you record playback under PipeWire.
    pw-record --rate "$RATE" --channels 1 --format s16 \
              --target "$src" "$dir/me.wav" >"$STATE_DIR/me.log" 2>&1 &
    echo $! > "$STATE_DIR/me.pid"

    if (( ! solo )); then
        pw-record --rate "$RATE" --channels 1 --format s16 \
                  --target "$sink" -P '{ stream.capture.sink=true }' \
                  "$dir/them.wav" >"$STATE_DIR/them.log" 2>&1 &
        echo $! > "$STATE_DIR/them.pid"
    fi

    # Give PipeWire a beat to fail loudly (bad target, device busy) rather than
    # reporting a successful start for a process that is already dead.
    sleep 0.4
    if ! alive "$(cat "$STATE_DIR/me.pid")"; then
        local err; err=$(tail -2 "$STATE_DIR/me.log" 2>/dev/null)
        rm -rf "$STATE_DIR"
        die "mic capture died immediately: ${err:-unknown error}"
    fi

    printf '%s' "$dir"    > "$STATE_DIR/dir"
    date +%s              > "$STATE_DIR/started"
    date '+%H:%M:%S'      > "$STATE_DIR/started_human"
    printf '%s' "$solo"   > "$STATE_DIR/solo"

    jq -n --arg dir "$dir" --arg started "$(date -Is)" --arg label "$label" \
          --arg src "$(node_desc @DEFAULT_AUDIO_SOURCE@)" \
          --arg sink "$(node_desc @DEFAULT_AUDIO_SINK@)" \
          --argjson solo "$solo" --argjson rate "$RATE" \
        '{started:$started, label:$label, solo:($solo==1), rate:$rate,
          source:$src, sink:(if $solo==1 then null else $sink end)}' \
        > "$dir/meta.json" 2>/dev/null

    if (( solo )); then
        notify "Practice recording" "mic only · $slug"
    else
        notify "Meeting recording" "you + system audio · $slug"
    fi
    echo "$dir"
}

cmd_stop() {
    is_recording || { notify -u low "Not recording" "nothing to stop"; echo "meeting-rec: not recording" >&2; exit 1; }

    local dir started elapsed
    dir=$(cat "$STATE_DIR/dir")
    started=$(cat "$STATE_DIR/started")

    # SIGTERM, not SIGKILL: pw-record rewrites the RIFF/data chunk sizes on
    # clean shutdown. A killed process leaves a WAV header claiming zero frames.
    for p in me them; do
        local pid; pid=$(cat "$STATE_DIR/$p.pid" 2>/dev/null) || continue
        alive "$pid" && kill -TERM "$pid" 2>/dev/null
    done
    for p in me them; do
        local pid; pid=$(cat "$STATE_DIR/$p.pid" 2>/dev/null) || continue
        for _ in $(seq 20); do alive "$pid" || break; sleep 0.1; done
        alive "$pid" && kill -KILL "$pid" 2>/dev/null
    done

    elapsed=$(( $(date +%s) - started ))
    if command -v jq >/dev/null && [[ -f "$dir/meta.json" ]]; then
        jq --arg ended "$(date -Is)" --argjson dur "$elapsed" \
           '. + {ended:$ended, duration_sec:$dur}' "$dir/meta.json" \
           > "$dir/meta.json.tmp" && mv "$dir/meta.json.tmp" "$dir/meta.json"
    fi
    rm -rf "$STATE_DIR"

    local mins=$(( elapsed / 60 )) secs=$(( elapsed % 60 ))
    local size; size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    notify "Recording saved" "$(printf '%dm %02ds' "$mins" "$secs") · ${size:-?} · $(basename "$dir")"
    printf 'saved %s (%dm %02ds)\n' "$dir" "$mins" "$secs"
}

cmd_status() {
    if is_recording; then
        local started elapsed
        started=$(cat "$STATE_DIR/started")
        elapsed=$(( $(date +%s) - started ))
        printf 'recording %dm %02ds → %s\n' $(( elapsed / 60 )) $(( elapsed % 60 )) "$(cat "$STATE_DIR/dir")"
        exit 0
    fi
    echo "idle"
    exit 1
}

case "${1:-toggle}" in
    start)  shift; cmd_start "$@" ;;
    stop)   cmd_stop ;;
    status) cmd_status ;;
    toggle) shift; if is_recording; then cmd_stop; else cmd_start "$@"; fi ;;
    *)      sed -n '2,30p' "$0" | sed 's/^# \?//'; exit 2 ;;
esac
