#!/usr/bin/env bash
# screenshot.sh — grim + slurp + satty pipeline
#
# usage:
#   screenshot.sh area     # select region, annotate, copy + save
#   screenshot.sh screen   # full active output, annotate, copy + save
#
# satty opens an annotation UI. From there:
#   - Ctrl+S to save     (also auto-copies via --copy-command)
#   - Ctrl+C to copy only
#   - Esc / close to discard

set -euo pipefail

mode=${1:-area}
ts=$(date +%Y%m%d_%H%M%S)
out_dir="$HOME/Pictures/screenshots"
mkdir -p "$out_dir"
out_file="$out_dir/${ts}.png"

case "$mode" in
    area)
        geom=$(slurp) || exit 0
        grim -g "$geom" -
        ;;
    screen)
        # active monitor only
        active=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
        grim -o "$active" -
        ;;
    *)
        notify-send "screenshot" "unknown mode: $mode"
        exit 1
        ;;
esac \
    | satty \
        --filename - \
        --output-filename "$out_file" \
        --early-exit \
        --copy-command wl-copy \
        --initial-tool brush

notify-send "screenshot" "saved → $out_file"
