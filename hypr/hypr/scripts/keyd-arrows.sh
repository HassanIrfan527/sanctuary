#!/usr/bin/env bash
# keyd-arrows.sh — reflect keyd's ARROWS layer (ijkl → arrow keys) in the bottom
# waybar. keyd toggles the layer internally and emits a phantom F23 key that the
# compositor binds to this script. We run as the user, so signaling waybar is
# trivial. Mirrors keyd-mode.sh (the NAVIGATION layer).

STATE=/tmp/keyd-mode-arrows

case "${1:-toggle}" in
    on)     : > "$STATE" ;;
    off)    rm -f "$STATE" ;;
    toggle) [ -e "$STATE" ] && rm -f "$STATE" || : > "$STATE" ;;
esac

# instant refresh; the pill also polls every 1s as a fallback
pkill -RTMIN+9 waybar 2>/dev/null || true
