#!/usr/bin/env bash
# screenrec.sh — the screen recorder behind RIG (Mod+U) and Ctrl+Print.
#
#   screenrec.sh key                 Ctrl+Print: recording → stop; idle → open the overlay
#   screenrec.sh open                the Quickshell overlay (drag a region, MIC/SYS, REC);
#                                    Quickshell down → slurp a region and record straight away
#   screenrec.sh start [--geom "X,Y WxH" | --full] [--mic 0|1] [--sys 0|1]
#   screenrec.sh pause | resume | pause-toggle
#   screenrec.sh mic on|off|toggle   what goes into the RECORDING — never your real mic
#   screenrec.sh sys on|off|toggle
#   screenrec.sh stop                save to ~/Videos/Recordings
#   screenrec.sh discard             throw it away
#   screenrec.sh status              exit 0 = recording or paused
#
# ── How it records ────────────────────────────────────────────────────
# Three plain processes per SEGMENT, nothing else touched:
#   v.mkv    wf-recorder, H.264 on the Intel GPU (VAAPI) — video only
#   mic.wav  pw-record from the default source
#   sys.wav  pw-record from the default sink's monitor (what you hear)
# Both audio tracks are ALWAYS captured; MIC/SYS only log the moment you flipped
# them. The mute happens afterwards, in the finalize step, as silence over the
# "off" stretches. So a toggle never touches PipeWire: no virtual sinks, no
# default-device changes, your call hears exactly what it heard before.
# A track that was off for the whole recording is left out entirely.
#
# Pause = end the segment; resume = start a new one. Stop joins the segments.
# Segments are .mkv on purpose: a killed mkv is still readable, a killed mp4
# is not. The final file is an mp4 (video copied, not re-encoded).
#
# Sync: wf-recorder takes ~0.1s longer than pw-record to start, and all three
# are stopped together — so each segment's audio is aligned to the video at
# the END and the surplus is trimmed off its start.
#
# State for the bar lives in $XDG_RUNTIME_DIR/screenrec/state.json (read by
# Rec.qml once a second). No state dir = not recording.
set -uo pipefail

RUN="${XDG_RUNTIME_DIR:-/tmp}/screenrec"
STATEF="$RUN/state.json"
OUT_DIR="${SCREENREC_DIR:-$HOME/Videos/Recordings}"
QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"
SELF=$(realpath "$0")
RENDER=/dev/dri/renderD128

notify() { notify-send -a screenrec "$@" 2>/dev/null; }
die()    { echo "screenrec: $*" >&2; notify -u critical "Screen recording failed" "$*"; exit 1; }
now_ms() { date +%s%3N; }
alive()  { [[ -n "${1:-}" ]] && kill -0 "$1" 2>/dev/null; }
get()    { cat "$RUN/$1" 2>/dev/null; }
put()    { printf '%s' "$2" > "$RUN/$1"; }
node_name() { wpctl inspect "$1" 2>/dev/null | sed -n 's/.*node\.name = "\(.*\)".*/\1/p' | head -1; }

recording() { [[ -d "$RUN" && -f "$RUN/state" ]]; }
# While the pieces are being joined, every command but `status` waits it out.
saving()    { [[ $(get state) == saving ]]; }

# The one file Quickshell reads. Written whole, then renamed: never half a file.
write_state() {
  jq -n --arg state "$(get state)" --arg mode "$(get mode)" --arg geom "$(get geom)" \
        --argjson mic "$(get mic)" --argjson sys "$(get sys)" \
        --argjson acc "$(get acc)" --argjson seg "$(get seg_started)" \
        '{state:$state, mode:$mode, geom:$geom, mic:($mic==1), sys:($sys==1),
          acc_ms:$acc, seg_started_ms:$seg}' > "$STATEF.tmp" && mv "$STATEF.tmp" "$STATEF"
}

# ── one segment ───────────────────────────────────────────────────────
seg_start() {
  local n dir geom
  n=$(( $(get nseg) + 1 )); put nseg "$n"
  dir="$RUN/seg-$(printf '%03d' "$n")"; mkdir -p "$dir"
  geom=$(get geom)

  local wf=(wf-recorder -c h264_vaapi -d "$RENDER" -f "$dir/v.mkv")
  [[ -n "$geom" ]] && wf+=(-g "$geom")
  # setsid: the recorder must outlive whoever called us (a keybind, a QML Process).
  setsid "${wf[@]}" >"$dir/wf.log" 2>&1 </dev/null &
  echo $! > "$dir/v.pid"

  now_ms > "$dir/a0"
  local mic sink
  mic=$(node_name @DEFAULT_AUDIO_SOURCE@)
  sink=$(node_name @DEFAULT_AUDIO_SINK@)
  if [[ -n "$mic" ]]; then
    setsid pw-record --rate 48000 --channels 1 --format s16 --target "$mic" \
      "$dir/mic.wav" >"$dir/mic.log" 2>&1 </dev/null &
    echo $! > "$dir/mic.pid"
  fi
  if [[ -n "$sink" ]]; then
    setsid pw-record --rate 48000 --channels 2 --format s16 --target "$sink" \
      -P '{ stream.capture.sink=true }' "$dir/sys.wav" >"$dir/sys.log" 2>&1 </dev/null &
    echo $! > "$dir/sys.pid"
  fi

  sleep 0.4                                  # let a bad start fail loudly
  if ! alive "$(cat "$dir/v.pid")"; then
    seg_stop
    return 1
  fi
  put seg_started "$(now_ms)"
  put state recording
}

# SIGINT for wf-recorder (it finishes the file), SIGTERM for pw-record (it
# rewrites the WAV header). Killed together so the END lines up (see top).
seg_stop() {
  local dir; dir=$(ls -d "$RUN"/seg-* 2>/dev/null | tail -1)
  [[ -n "$dir" ]] || return 0
  local v m s
  v=$(cat "$dir/v.pid" 2>/dev/null); m=$(cat "$dir/mic.pid" 2>/dev/null); s=$(cat "$dir/sys.pid" 2>/dev/null)
  alive "$v" && kill -INT "$v"
  alive "$m" && kill -TERM "$m"
  alive "$s" && kill -TERM "$s"
  now_ms > "$dir/a1"
  local p _
  for p in "$v" "$m" "$s"; do
    for _ in $(seq 50); do alive "$p" || break; sleep 0.1; done
    alive "$p" && kill -KILL "$p" 2>/dev/null
  done
  rm -f "$dir"/*.pid
  local seg; seg=$(get seg_started)
  [[ "$seg" != 0 ]] && put acc $(( $(get acc) + $(now_ms) - seg ))
  put seg_started 0
}

# ── commands ──────────────────────────────────────────────────────────
cmd_start() {
  local geom="" full=0 mic=1 sys=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --geom) geom="${2:-}"; shift 2 ;;
      --full) full=1; shift ;;
      --mic)  mic="${2:-1}"; shift 2 ;;
      --sys)  sys="${2:-0}"; shift 2 ;;
      *) shift ;;
    esac
  done
  recording && die "already recording — Ctrl+Print stops it"
  command -v wf-recorder >/dev/null || die "wf-recorder is not installed (sudo dnf install wf-recorder)"
  command -v pw-record   >/dev/null || die "pw-record is missing (sudo dnf install pipewire-utils)"
  command -v jq          >/dev/null || die "jq is missing"
  (( full )) && geom=""
  [[ -z "$geom" ]] && full=1

  mkdir -p "$RUN" "$OUT_DIR" || die "cannot create $RUN"
  put mode "$( (( full )) && echo full || echo region)"
  put geom "$geom"
  put mic "$mic"; put sys "$sys"
  put acc 0; put seg_started 0; put nseg 0
  put started_human "$(date '+%Y-%m-%d %H-%M-%S')"
  : > "$RUN/events"
  printf '%s mic %s\n%s sys %s\n' "$(now_ms)" "$mic" "$(now_ms)" "$sys" >> "$RUN/events"

  if ! seg_start; then
    local err; err=$(grep -v '^\s*$' "$RUN"/seg-001/wf.log 2>/dev/null | tail -2)
    rm -rf "$RUN"
    die "wf-recorder stopped at once: ${err:-no log}"
  fi
  write_state
}

cmd_pause() {
  recording || exit 1
  [[ $(get state) == recording ]] || return 0
  seg_stop
  put state paused
  write_state
}

cmd_resume() {
  recording || exit 1
  [[ $(get state) == paused ]] || return 0
  seg_start || die "could not resume — the recording so far is kept; Ctrl+Print saves it"
  write_state
}

cmd_track() {                                # $1 = mic|sys, $2 = on|off|toggle
  recording || exit 1
  local t=$1 v
  case "${2:-toggle}" in
    on) v=1 ;; off) v=0 ;; *) v=$(( 1 - $(get "$t") )) ;;
  esac
  put "$t" "$v"
  printf '%s %s %s\n' "$(now_ms)" "$t" "$v" >> "$RUN/events"
  write_state
}

cmd_discard() {
  recording || exit 1
  seg_stop
  rm -rf "$RUN"
  notify -u low "Recording discarded" ""
}

cmd_stop() {
  recording || { echo "screenrec: not recording" >&2; exit 1; }
  [[ $(get state) == recording ]] && seg_stop
  put state saving
  write_state

  local out="$OUT_DIR/Recording $(get started_human).mp4"
  local err
  if ! err=$(finalize "$RUN" "$out" 2>&1); then
    # Keep the raw segments rather than lose the recording.
    local keep="$OUT_DIR/.raw-$(get started_human)"
    rm -f "$STATEF"; mv "$RUN" "$keep" 2>/dev/null
    die "joining failed — raw pieces kept in $keep (${err##*$'\n'})"
  fi
  rm -rf "$RUN"

  local size; size=$(du -h "$out" 2>/dev/null | cut -f1)
  # Wait for the click in the background, so the caller returns now.
  ( trap '' HUP
    act=$(notify-send -a screenrec -A open=Open -A folder="Show folder" \
            "Recording saved" "${size:-?} · $(basename "$out")" 2>/dev/null)
    case "$act" in
      open)   xdg-open "$out" ;;
      folder) xdg-open "$OUT_DIR" ;;
    esac ) >/dev/null 2>&1 </dev/null &
  disown
  echo "$out"
}

# Mute the "off" stretches, mix, align, join. Python because the timeline maths
# (events × segments) is miserable in bash.
finalize() {
  python3 - "$1" "$2" <<'PY'
import glob, json, os, subprocess, sys
run, out = sys.argv[1], sys.argv[2]

def probe(path):
    try:
        r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                            "-of", "csv=p=0", path], capture_output=True, text=True)
        return float(r.stdout.strip())
    except Exception:
        return 0.0

events = []
for line in open(os.path.join(run, "events")):
    p = line.split()
    if len(p) == 3:
        events.append((int(p[0]), p[1], p[2] == "1"))

def off_spans(track, a0, a1):
    """Stretches (in seconds from a0) where `track` was off."""
    spans, state, since = [], True, a0
    for t, name, on in events:
        if name != track:
            continue
        if t <= a0:
            state = on
            continue
        if t >= a1:
            break
        if state and not on:
            since = t
        elif not state and on:
            spans.append(((since - a0) / 1000, (t - a0) / 1000))
        state = on
    if not state:
        spans.append(((max(since, a0) - a0) / 1000, (a1 - a0) / 1000))
    return spans

def ever_on(track):
    return any(on for _, name, on in events if name == track)

want_audio = ever_on("mic") or ever_on("sys")
segs = sorted(glob.glob(os.path.join(run, "seg-*")))
parts = []
for seg in segs:
    v = os.path.join(seg, "v.mkv")
    if not os.path.exists(v) or probe(v) <= 0:
        continue
    vdur = probe(v)
    a0 = int(open(os.path.join(seg, "a0")).read())
    a1 = int(open(os.path.join(seg, "a1")).read()) if os.path.exists(os.path.join(seg, "a1")) else a0 + int(vdur * 1000)
    cmd = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-i", v]
    chains, labels, n = [], [], 1
    for track in ("mic", "sys"):
        wav = os.path.join(seg, track + ".wav")
        if not ever_on(track) or not os.path.exists(wav) or os.path.getsize(wav) < 1024:
            continue
        adur = probe(wav)
        cmd += ["-i", wav]
        f = f"[{n}:a]aformat=sample_rates=48000:channel_layouts=stereo"
        spans = off_spans(track, a0, a1)
        if spans:
            expr = "+".join(f"between(t,{a:.3f},{b:.3f})" for a, b in spans)
            f += f",volume=0:enable='{expr}'"
        lead = max(0.0, adur - vdur)          # align at the end, see screenrec.sh
        f += f",atrim=start={lead:.3f},asetpts=PTS-STARTPTS[a{n}]"
        chains.append(f)
        labels.append(f"[a{n}]")
        n += 1
    part = os.path.join(seg, "part.mkv")
    if want_audio and not labels:
        # This piece has no usable audio but others do: silence, so the
        # pieces still share one layout and join cleanly.
        cmd += ["-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo"]
        chains.append(f"[{n}:a]anull[a{n}]")
        labels.append(f"[a{n}]")
    if labels:
        head = "".join(labels)
        if len(labels) > 1:
            head += f"amix=inputs={len(labels)}:normalize=0:duration=longest,"
        mix = head + f"apad,atrim=end={vdur:.3f}[aout]"
        cmd += ["-filter_complex", ";".join(chains + [mix]),
                "-map", "0:v", "-map", "[aout]", "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", part]
    else:
        cmd += ["-map", "0:v", "-c:v", "copy", part]
    subprocess.run(cmd, check=True)
    parts.append(part)

if not parts:
    sys.exit("no video was recorded")
lst = os.path.join(run, "parts.txt")
with open(lst, "w") as fh:
    for p in parts:
        fh.write("file '%s'\n" % p.replace("'", "'\\''"))
subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy",
                "-movflags", "+faststart", out], check=True)
PY
}

cmd_open() {
  if "$QS" running; then
    "$QS" call rec select >/dev/null
  else
    # Fallback: no overlay, no dimming — pick a region and go.
    local g; g=$(slurp -d 2>/dev/null) || exit 0
    cmd_start --geom "$g" --mic 1 --sys 0
    notify "Recording" "Ctrl+Print stops — Quickshell is down, so no controls on screen"
  fi
}

if [[ "${1:-}" != status ]] && recording && saving; then
  notify -u low "Still saving" "the last recording is being joined"; exit 1
fi

case "${1:-}" in
  key)          if recording; then cmd_stop; else cmd_open; fi ;;
  open)         cmd_open ;;
  start)        shift; cmd_start "$@" ;;
  pause)        cmd_pause ;;
  resume)       cmd_resume ;;
  pause-toggle) recording || exit 1; [[ $(get state) == paused ]] && cmd_resume || cmd_pause ;;
  mic|sys)      cmd_track "$1" "${2:-toggle}" ;;
  stop)         cmd_stop ;;
  discard)      cmd_discard ;;
  status)       recording && { cat "$STATEF"; echo; exit 0; }; echo idle; exit 1 ;;
  *)            sed -n '2,15p' "$SELF" | sed 's/^# \?//'; exit 2 ;;
esac
