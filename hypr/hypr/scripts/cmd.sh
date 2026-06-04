#!/usr/bin/env bash
# Command dispatcher for the walker "/" command palette (menus:commands).
# One keyword per action; keeps the elephant menu file declarative.
set -euo pipefail

case "${1:-}" in
    wifi)     kitty --class=impala-wifi --title=wifi -e impala ;;
    dismiss)  swaync-client --close-all ;;
    dnd)      swaync-client --toggle-dnd ;;
    panel)    swaync-client --toggle-panel ;;
    lock)     hyprlock ;;
    logout)   hyprctl dispatch exit ;;
    suspend)  systemctl suspend ;;
    reboot)   systemctl reboot ;;
    shutdown) systemctl poweroff ;;
    *)        exit 1 ;;
esac
