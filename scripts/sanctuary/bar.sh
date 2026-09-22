#!/usr/bin/env bash
# Start / stop / restart waybar.
#
# NixOS wraps the binary, so `pkill -x waybar` matches NOTHING and you end up
# stacking invisible instances. The real process name is `.waybar-wrapped`.
# This cost a long debug detour once already (DESIGN-BRIEF.md §5).
set -uo pipefail
CFG="$HOME/.dotfiles/waybar/config.jsonc"
CSS="$HOME/.dotfiles/waybar/style.css"

running() { pgrep -x .waybar-wrapped >/dev/null 2>&1; }

case "${1:-toggle}" in
  start)   running || waybar -c "$CFG" -s "$CSS" >/dev/null 2>&1 & ;;
  stop)    pkill -x .waybar-wrapped ;;
  restart) pkill -x .waybar-wrapped; sleep 0.2; waybar -c "$CFG" -s "$CSS" >/dev/null 2>&1 & ;;
  toggle)  if running; then pkill -x .waybar-wrapped; else waybar -c "$CFG" -s "$CSS" >/dev/null 2>&1 & fi ;;
esac
