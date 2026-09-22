#!/usr/bin/env bash
# Wallpaper: pick visually, apply through swww, remember the choice.
#
#   wallpaper.sh pick      floating kitty + yazi over the wallpaper dir
#   wallpaper.sh set PATH  apply and remember
#   wallpaper.sh restore   re-apply what was last set (used at startup)
#
# yazi runs in --chooser-file mode: Enter writes the selection and exits, so
# this script keeps control and does the applying. kitty's graphics protocol
# gives yazi real image previews, which is the whole reason the picker is a
# terminal (DESIGN-BRIEF.md §5) — hjkl and Enter, no filenames typed.
set -uo pipefail

DIR="${SANCTUARY_WALLPAPERS:-$HOME/Pictures/Wallpapers}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
CURRENT="$STATE/wallpaper"
mkdir -p "$STATE"

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

apply() {
  [ -n "${WW:-}" ] || { echo "awww/swww not installed" >&2; return 1; }
  ensure_daemon || { echo "wallpaper daemon would not start" >&2; return 1; }
  "$WW" img "$1" \
    --transition-type fade \
    --transition-duration 0.4 \
    --transition-fps 60 >/dev/null 2>&1
}

case "${1:-pick}" in
  set)
    [ -f "${2:-}" ] || exit 1
    apply "$2" && printf '%s\n' "$2" > "$CURRENT"
    ;;
  restore)
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
  pick)
    tmp=$(mktemp)
    kitty --class sanctuary-wallpaper \
      -e yazi --chooser-file="$tmp" "$DIR" >/dev/null 2>&1
    sel=$(head -1 "$tmp" 2>/dev/null); rm -f "$tmp"
    [ -n "$sel" ] && [ -f "$sel" ] && apply "$sel" && printf '%s\n' "$sel" > "$CURRENT"
    ;;
esac
