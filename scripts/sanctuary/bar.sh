#!/usr/bin/env bash
# Start / stop / restart waybar — in whichever mode is current.
#
# NixOS wraps the binary, so `pkill -x waybar` matches NOTHING and you end up
# stacking invisible instances. The real process name is `.waybar-wrapped`.
# This cost a long debug detour once already (DESIGN-BRIEF.md §5).
#
# Two more things this has to get right:
#
#  1. The mode. `modes/<name>.conf` sets BAR=full|zen|none, so the same
#     `bar.sh start` brings up the full bar in Default and the clock-only bar in
#     Zen. BAR=none means "don't autostart", NOT "refuse to run": Mod+Shift+A
#     still peeks the zen bar back in, so the clock is never a mode switch away.
#
#  2. SIGHUP. mode.sh's picker runs inside a kitty that exits the moment you
#     choose, and a waybar started as its descendant dies with it — the same trap
#     that made the fsel launcher look broken (DESIGN-BRIEF.md §5). `setsid` puts
#     waybar in its own session so it survives whatever launched it.
set -uo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
MODES="$HOME/.dotfiles/scripts/sanctuary/modes"

mode=default
[ -s "$STATE/mode" ] && mode=$(cat "$STATE/mode")
want=full
[ -r "$MODES/$mode.conf" ] && want=$(. "$MODES/$mode.conf"; printf '%s' "${BAR:-full}")

autostart=yes
case "$want" in
  zen)  CFG="$HOME/.dotfiles/waybar/zen/config.jsonc"; CSS="$HOME/.dotfiles/waybar/zen/style.css" ;;
  none) CFG="$HOME/.dotfiles/waybar/zen/config.jsonc"; CSS="$HOME/.dotfiles/waybar/zen/style.css"
        autostart=no ;;
  *)    CFG="$HOME/.dotfiles/waybar/config.jsonc";     CSS="$HOME/.dotfiles/waybar/style.css" ;;
esac

running() { pgrep -x .waybar-wrapped >/dev/null 2>&1; }
launch()  { setsid waybar -c "$CFG" -s "$CSS" >/dev/null 2>&1 & }
stop()    { pkill -x .waybar-wrapped; }

case "${1:-toggle}" in
  start)   [ "$autostart" = yes ] && { running || launch; } ;;
  stop)    stop ;;
  restart) stop; sleep 0.2; [ "$autostart" = yes ] && launch ;;
  toggle)  if running; then stop; else launch; fi ;;   # deliberately ignores autostart
esac
