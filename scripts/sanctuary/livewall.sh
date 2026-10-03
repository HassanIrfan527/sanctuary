#!/usr/bin/env bash
# Live wallpaper: a looping video behind everything, via mpvpaper.
#
#   livewall start [VIDEO]  play VIDEO (or the last one used) on every output
#   livewall sound [VIDEO]  same, but with audio (volume: LIVEWALL_VOLUME, default 100)
#   livewall stop           kill it; the awww still underneath shows again
#   livewall toggle         start if stopped, stop if running
#   livewall pick           yazi chooser over the video dir, then start
#
# Deliberately NOT in startup.kdl — this is on-demand only. awww keeps owning
# the static wallpaper; mpvpaper just draws a layer surface above it, so
# stopping this drops you straight back to the still image with no restore.
set -uo pipefail

DIR="${SANCTUARY_LIVEWALLS:-$HOME/Videos/Wallpapers}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
CURRENT="$STATE/livewall"
mkdir -p "$STATE" "$DIR"

# Muted unless asked for via `sound`.
# panscan=1.0: crop to fill instead of letterboxing on odd aspect ratios.
# hwdec=auto: decode on the GPU, otherwise this costs real CPU all day.
MPV_OPTS="loop panscan=1.0 hwdec=auto"

running() { pgrep -u "$USER" -x mpvpaper >/dev/null; }

start() {
  command -v mpvpaper >/dev/null || { echo "mpvpaper not installed" >&2; return 1; }
  local vid="${1:-}"
  if [ -z "$vid" ] && [ -s "$CURRENT" ]; then vid=$(cat "$CURRENT"); fi
  if [ -z "$vid" ]; then
    vid=$(find "$DIR" -maxdepth 2 -type f \
      \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.gif' \) | head -1)
  fi
  [ -n "$vid" ] && [ -f "$vid" ] || { echo "no video given and none found in $DIR" >&2; return 1; }
  vid=$(realpath "$vid")

  running && stop
  if [ "${SOUND:-0}" = 1 ]; then
    # No -p here: auto-pause would cut the audio every time a window covers
    # the wallpaper. One output only, or every monitor plays its own copy.
    local out
    out=$(niri msg -j focused-output 2>/dev/null | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
    setsid -f mpvpaper -o "$MPV_OPTS volume=${LIVEWALL_VOLUME:-100}" "${out:-*}" "$vid" >/dev/null 2>&1
  else
    # -p: pause when the wallpaper is fully covered, so it costs nothing then.
    setsid -f mpvpaper -p -o "$MPV_OPTS no-audio" '*' "$vid" >/dev/null 2>&1
  fi
  printf '%s\n' "$vid" > "$CURRENT"
}

stop() { pkill -u "$USER" -x mpvpaper; }

case "${1:-toggle}" in
  start)  start "${2:-}" ;;
  sound)  SOUND=1 start "${2:-}" ;;
  stop)   stop ;;
  toggle) if running; then stop; else start; fi ;;
  pick)
    tmp=$(mktemp)
    kitty --class sanctuary-wallpaper \
      -e yazi --chooser-file="$tmp" "$DIR" >/dev/null 2>&1
    sel=$(head -1 "$tmp" 2>/dev/null); rm -f "$tmp"
    [ -n "$sel" ] && start "$sel"
    ;;
  *) sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
