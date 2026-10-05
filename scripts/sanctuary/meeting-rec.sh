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
# internally regardless. An hour of meeting costs ~115 MB per channel.
#
# Capture backend: pw-record (Fedora package `pipewire-utils`) when present,
# otherwise ffmpeg through pipewire-pulse. Both write identical WAVs; Fedora
# ships ffmpeg-free by default but not pipewire-utils.
#
# Usage:
#   meeting-rec.sh toggle [--solo] [--label TEXT]   start if idle, stop if running
#   meeting-rec.sh start  [--solo] [--label TEXT]
#   meeting-rec.sh stop
#   meeting-rec.sh pause | resume | pause-toggle
#   meeting-rec.sh status                            exit 0 = recording or paused, 1 = idle
#
# Pause stops the recorders and parks what they wrote as me.p001.wav, … ; resume
# starts fresh ones. Stop joins the parts back into ONE me.wav / them.wav, so
# whatever reads a session folder never sees a pause.
#
# Quickshell (Rec.qml) reads $STATE_DIR/state.json once a second for the bar's
# AUD cell; it is rewritten on every change of state.
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

# capture <node.name> <out.wav> <log> [sink]
# Backgrounds one mono 16 kHz recorder; the caller reads $! for the PID.
# With "sink", records that sink's monitor (i.e. what you hear) instead.
capture() {
    local node="$1" out="$2" log="$3" sink="${4:-}"
    if command -v pw-record >/dev/null; then
        # --target + stream.capture.sink=true attaches the capture to the
        # sink's monitor ports, which is how you record playback under PipeWire.
        local props=()
        [[ -n "$sink" ]] && props=(-P '{ stream.capture.sink=true }')
        pw-record --rate "$RATE" --channels 1 --format s16 --target "$node" \
                  "${props[@]}" "$out" >"$log" 2>&1 &
    else
        # pipewire-pulse exposes every sink's monitor as "<sink>.monitor".
        # ffmpeg finalizes the WAV header on SIGTERM, same as pw-record.
        ffmpeg -nostdin -hide_banner -loglevel error -f pulse \
               -i "$node${sink:+.monitor}" -ac 1 -ar "$RATE" -c:a pcm_s16le \
               -y "$out" >"$log" 2>&1 &
    fi
}

# For the bar: {state, solo, acc_ms, seg_started_ms}. Elapsed = acc + (now - seg).
write_state() {
    local st=recording; [[ -f "$STATE_DIR/paused" ]] && st=paused
    printf '{"state":"%s","solo":%s,"acc_ms":%s,"seg_started_ms":%s}\n' \
        "$st" "$( [[ $(cat "$STATE_DIR/solo" 2>/dev/null) == 1 ]] && echo true || echo false)" \
        "$(cat "$STATE_DIR/acc" 2>/dev/null || echo 0)" "$(cat "$STATE_DIR/seg" 2>/dev/null || echo 0)" \
        > "$STATE_DIR/state.json.tmp" && mv "$STATE_DIR/state.json.tmp" "$STATE_DIR/state.json"
}
now_ms() { date +%s%3N; }

# Stop the running recorders. SIGTERM, not SIGKILL: pw-record rewrites the
# RIFF/data chunk sizes on clean shutdown. A killed process leaves a WAV header
# claiming zero frames.
stop_captures() {
    for p in me them; do
        local pid; pid=$(cat "$STATE_DIR/$p.pid" 2>/dev/null) || continue
        alive "$pid" && kill -TERM "$pid" 2>/dev/null
    done
    for p in me them; do
        local pid; pid=$(cat "$STATE_DIR/$p.pid" 2>/dev/null) || continue
        for _ in $(seq 20); do alive "$pid" || break; sleep 0.1; done
        alive "$pid" && kill -KILL "$pid" 2>/dev/null
        rm -f "$STATE_DIR/$p.pid"
    done
    local seg; seg=$(cat "$STATE_DIR/seg" 2>/dev/null || echo 0)
    if [[ "$seg" != 0 ]]; then
        echo $(( $(cat "$STATE_DIR/acc" 2>/dev/null || echo 0) + $(now_ms) - seg )) > "$STATE_DIR/acc"
        echo 0 > "$STATE_DIR/seg"
    fi
}

# (Re)start the recorders into $dir/me.wav (+ them.wav). Node names were
# resolved once, at start, so a resume records the same devices.
start_captures() {
    local dir; dir=$(cat "$STATE_DIR/dir")
    capture "$(cat "$STATE_DIR/src")" "$dir/me.wav" "$STATE_DIR/me.log"
    echo $! > "$STATE_DIR/me.pid"
    if [[ -s "$STATE_DIR/sink" ]]; then
        capture "$(cat "$STATE_DIR/sink")" "$dir/them.wav" "$STATE_DIR/them.log" sink
        echo $! > "$STATE_DIR/them.pid"
    fi
    now_ms > "$STATE_DIR/seg"
}

is_recording() {
    [[ -f "$STATE_DIR/paused" ]] && return 0
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

    command -v pw-record >/dev/null || command -v ffmpeg >/dev/null \
        || die "need pw-record (dnf install pipewire-utils) or ffmpeg"

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

    printf '%s' "$dir"  > "$STATE_DIR/dir"
    printf '%s' "$src"  > "$STATE_DIR/src"
    printf '%s' "${sink:-}" > "$STATE_DIR/sink"
    echo 0 > "$STATE_DIR/acc"
    start_captures

    # Give PipeWire a beat to fail loudly (bad target, device busy) rather than
    # reporting a successful start for a process that is already dead.
    sleep 0.4
    if ! alive "$(cat "$STATE_DIR/me.pid")"; then
        local err; err=$(tail -2 "$STATE_DIR/me.log" 2>/dev/null)
        rm -rf "$STATE_DIR"
        die "mic capture died immediately: ${err:-unknown error}"
    fi

    date +%s              > "$STATE_DIR/started"
    date '+%H:%M:%S'      > "$STATE_DIR/started_human"
    printf '%s' "$solo"   > "$STATE_DIR/solo"
    write_state

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

    local dir elapsed
    dir=$(cat "$STATE_DIR/dir")

    [[ -f "$STATE_DIR/paused" ]] || stop_captures
    join_parts "$dir"

    # Recorded time, pauses excluded.
    elapsed=$(( $(cat "$STATE_DIR/acc" 2>/dev/null || echo 0) / 1000 ))
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

# Park the just-finished me.wav / them.wav as the next numbered part.
park_parts() {
    local dir=$1 n
    n=$(( $(ls "$dir"/me.p*.wav 2>/dev/null | wc -l) + 1 ))
    for p in me them; do
        [[ -f "$dir/$p.wav" ]] && mv "$dir/$p.wav" "$dir/$p.p$(printf '%03d' "$n").wav"
    done
}

# Parts (and a final me.wav, if the stop came while recording) → one me.wav.
join_parts() {
    local dir=$1
    compgen -G "$dir/me.p*.wav" >/dev/null || return 0
    park_parts "$dir"
    for p in me them; do
        local parts=("$dir/$p".p*.wav)
        [[ -f "${parts[0]}" ]] || continue
        if command -v ffmpeg >/dev/null; then
            local list="$dir/.$p.list"
            printf "file '%s'\n" "${parts[@]}" > "$list"
            ffmpeg -nostdin -hide_banner -loglevel error -y -f concat -safe 0 -i "$list" \
                   -c copy "$dir/$p.wav" && rm -f "${parts[@]}" "$list"
        else
            notify -u critical "Recording kept in parts" "no ffmpeg to join $p.p*.wav"
        fi
    done
}

cmd_pause() {
    is_recording || exit 1
    [[ -f "$STATE_DIR/paused" ]] && return 0
    stop_captures
    park_parts "$(cat "$STATE_DIR/dir")"
    touch "$STATE_DIR/paused"
    write_state
}

cmd_resume() {
    [[ -f "$STATE_DIR/paused" ]] || return 0
    start_captures
    sleep 0.4
    if ! alive "$(cat "$STATE_DIR/me.pid")"; then
        stop_captures
        notify -u critical "Could not resume" "$(tail -1 "$STATE_DIR/me.log" 2>/dev/null) — still paused; stop saves what you have"
        exit 1
    fi
    rm -f "$STATE_DIR/paused"
    write_state
}

cmd_status() {
    if is_recording; then
        local seg elapsed word=recording
        [[ -f "$STATE_DIR/paused" ]] && word=paused
        seg=$(cat "$STATE_DIR/seg" 2>/dev/null || echo 0)
        elapsed=$(cat "$STATE_DIR/acc" 2>/dev/null || echo 0)
        [[ "$seg" != 0 ]] && elapsed=$(( elapsed + $(now_ms) - seg ))
        elapsed=$(( elapsed / 1000 ))
        printf '%s %dm %02ds → %s\n' "$word" $(( elapsed / 60 )) $(( elapsed % 60 )) "$(cat "$STATE_DIR/dir")"
        exit 0
    fi
    echo "idle"
    exit 1
}

case "${1:-toggle}" in
    start)  shift; cmd_start "$@" ;;
    stop)   cmd_stop ;;
    pause)  cmd_pause ;;
    resume) cmd_resume ;;
    pause-toggle) if [[ -f "$STATE_DIR/paused" ]]; then cmd_resume; else cmd_pause; fi ;;
    status) cmd_status ;;
    toggle) shift; if is_recording; then cmd_stop; else cmd_start "$@"; fi ;;
    *)      sed -n '2,30p' "$0" | sed 's/^# \?//'; exit 2 ;;
esac
