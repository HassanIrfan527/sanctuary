#!/usr/bin/env bash
# Wallpaper: pick visually, apply through awww, remember the choice.
#
#   wallpaper.sh open      Mod+Shift+W. Quickshell up → its picker
#                          (quickshell/sanctuary/WallPicker.qml: thumbnails, stills
#                          and live videos, drawn in the current style).
#                          Fallback → `pick`.
#   wallpaper.sh pick      floating kitty + yazi over the wallpaper dir
#   wallpaper.sh set PATH  apply and remember (stops a live wallpaper first)
#   wallpaper.sh restore   re-apply what was last set (used at startup)
#   wallpaper.sh list      what the Quickshell picker reads, tab-separated:
#                            current <still|live> PATH      (first line)
#                            <still|live> PATH THUMB        (one per file)
#   wallpaper.sh thumbs    make any missing thumbnails; prints how many it made
#
# yazi runs in --chooser-file mode: Enter writes the selection and exits, so
# this script keeps control and does the applying. kitty's graphics protocol
# gives yazi real image previews, which is the whole reason the fallback is a
# terminal at all.
set -uo pipefail

DIR="${SANCTUARY_WALLPAPERS:-$HOME/Pictures/Wallpapers}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
CURRENT="$STATE/wallpaper"
LIVEDIR="${SANCTUARY_LIVEWALLS:-$HOME/Videos/Wallpapers}"
LIVEWALL="$HOME/.dotfiles/scripts/sanctuary/livewall.sh"
# Thumbnails are named by the md5 of the full path, so a renamed or moved file
# simply gets a new one. 480x270 = 16:9, twice the size the picker draws them.
THUMBS="${XDG_CACHE_HOME:-$HOME/.cache}/sanctuary/wallthumbs"
mkdir -p "$STATE" "$THUMBS"

# 160ms everywhere else; the wallpaper is the one place a longer fade reads as
# calm rather than sluggish, because nothing is waiting on it.
# Upstream renamed swww -> awww at 0.12. Prefer the new name, accept the old
# one, so this keeps working on a machine that has either.
WW=$(command -v awww || command -v swww) || true
WWD=$(command -v awww-daemon || command -v swww-daemon) || true

# The daemon has to be up before anything can be drawn. Owning that here rather
# than in startup.kdl keeps the KDL to one readable line and means `restore`
# works from a shell too.
# Liveness is checked by ASKING the daemon, never by process name. NixOS wraps
# these binaries, so the daemon's comm is ".awww-daemon-wr", and `pgrep -x
# awww-daemon` cheerfully reports "not running" while it is running — which then
# starts a second one that aborts. Same trap as waybar, swaync and noctalia.
ensure_daemon() {
  [ -n "${WWD:-}" ] || return 1
  "$WW" query >/dev/null 2>&1 && return 0
  "$WWD" >/dev/null 2>&1 &
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    "$WW" query >/dev/null 2>&1 && return 0
    sleep 0.3
  done
  return 1
}

stills() {
  find "$DIR" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \
    -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) 2>/dev/null | sort -f
}
lives() {
  find "$LIVEDIR" -maxdepth 2 -type f \( -iname '*.mp4' -o -iname '*.mkv' \
    -o -iname '*.webm' -o -iname '*.mov' \) 2>/dev/null | sort -f
}
thumb_of() { printf '%s/%s.jpg' "$THUMBS" "$(printf '%s' "$1" | md5sum | cut -c1-32)"; }

# One thumbnail. Written to a temp name and moved into place, so the picker
# never loads a half-written file. Videos: a frame 3s in (intros are often
# black), or the first frame if the clip is shorter than that.
make_thumb() {
  local f=$1 t tmp
  t=$(thumb_of "$f")
  [ -s "$t" ] && return 0
  tmp="$t.part.jpg"
  case "${f,,}" in
    *.mp4|*.mkv|*.webm|*.mov)
      local vf="scale=480:270:force_original_aspect_ratio=increase,crop=480:270"
      ffmpeg -v error -ss 3 -i "$f" -frames:v 1 -vf "$vf" -y "$tmp" </dev/null 2>/dev/null
      [ -s "$tmp" ] || ffmpeg -v error -i "$f" -frames:v 1 -vf "$vf" -y "$tmp" </dev/null 2>/dev/null
      ;;
    *)
      magick "${f}[0]" -auto-orient -thumbnail '480x270^' -gravity center \
        -extent 480x270 -quality 82 "$tmp" 2>/dev/null
      ;;
  esac
  if [ -s "$tmp" ]; then mv -f "$tmp" "$t" && echo made; else rm -f "$tmp"; fi
}
export -f make_thumb thumb_of
export THUMBS

apply() {
  [ -n "${WW:-}" ] || { echo "awww/swww not installed" >&2; return 1; }
  ensure_daemon || { echo "wallpaper daemon would not start" >&2; return 1; }
  "$WW" img "$1" \
    --transition-type random \
    --transition-duration 1.2 \
    --transition-fps 60 >/dev/null 2>&1
}

case "${1:-pick}" in
  open)
    if "$HOME/.dotfiles/scripts/sanctuary/qs.sh" running; then
      "$HOME/.dotfiles/scripts/sanctuary/qs.sh" call wallpaper toggle >/dev/null
    else
      "$0" pick
    fi
    ;;
  set)
    [ -f "${2:-}" ] || exit 1
    # A live wallpaper is a layer ABOVE awww — leave it running and the new
    # still would change underneath where nobody can see it.
    pgrep -u "$USER" -x mpvpaper >/dev/null && "$LIVEWALL" stop
    apply "$2" && printf '%s\n' "$2" > "$CURRENT"
    ;;
  restore)
    # Startup is also when to catch up on thumbnails for anything added since
    # last time, so the picker opens with pictures, not names. Background, niced.
    setsid "$0" thumbs >/dev/null 2>&1 </dev/null &
    if [ -s "$CURRENT" ] && [ -f "$(cat "$CURRENT")" ]; then
      apply "$(cat "$CURRENT")"
    else
      # First run after the noctalia cutover: take anything rather than a
      # black screen, and record it so the next boot is stable.
      pick=$(find "$DIR" -maxdepth 2 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | head -1)
      [ -n "$pick" ] && apply "$pick" && printf '%s\n' "$pick" > "$CURRENT"
    fi
    ;;
  list)
    if pgrep -u "$USER" -x mpvpaper >/dev/null; then
      printf 'current\tlive\t%s\n' "$(cat "$STATE/livewall" 2>/dev/null)"
    else
      printf 'current\tstill\t%s\n' "$(cat "$CURRENT" 2>/dev/null)"
    fi
    # Hashed in one python pass, not an md5sum fork per file: ~400 files took
    # 2s that way, and the picker waits on this. Same name as thumb_of.
    { stills | sed 's/^/still\t/'; lives | sed 's/^/live\t/'; } | python3 -c '
import sys, hashlib, os
T = os.environ["THUMBS"]
for line in sys.stdin.buffer:
    kind, path = line.rstrip(b"\n").split(b"\t", 1)
    h = hashlib.md5(path).hexdigest()
    sys.stdout.buffer.write(b"%s\t%s\t%s/%s.jpg\n" % (kind, path, T.encode(), h.encode()))
'
    ;;
  thumbs)
    # nice + one job per core: the first run over a big folder takes a minute,
    # every run after only touches what is new.
    { stills; lives; } | tr '\n' '\0' \
      | nice -n 19 xargs -0 -r -P "$(nproc)" -I{} bash -c 'make_thumb "$1"' _ {} \
      | wc -l
    ;;
  pick)
    tmp=$(mktemp)
    kitty --class sanctuary-wallpaper \
      -e yazi --chooser-file="$tmp" "$DIR" >/dev/null 2>&1
    sel=$(head -1 "$tmp" 2>/dev/null); rm -f "$tmp"
    [ -n "$sel" ] && [ -f "$sel" ] && apply "$sel" && printf '%s\n' "$sel" > "$CURRENT"
    ;;
esac
