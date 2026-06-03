#!/usr/bin/env bash
# keyd-mode.sh — reflect keyd's NAVIGATION layer state in the bottom waybar.
# keyd toggles its own layer internally and emits a phantom key (F24=enter,
# F23=exit) that Hyprland binds to this script. We run as the user (not root),
# so signaling waybar is trivial.

STATE=/tmp/keyd-mode-nav

case "${1:-toggle}" in
    on)     : > "$STATE" ;;
    off)    rm -f "$STATE" ;;
    toggle) [ -e "$STATE" ] && rm -f "$STATE" || : > "$STATE" ;;
esac

# instant refresh; the pill also polls every 1s as a fallback
pkill -RTMIN+9 waybar 2>/dev/null || true
