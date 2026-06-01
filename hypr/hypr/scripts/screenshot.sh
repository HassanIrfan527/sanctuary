#!/usr/bin/env bash
# screenshot.sh — grim + slurp + (satty) pipeline
#
# usage:
#   screenshot.sh area     # select region, copy straight to clipboard
#   screenshot.sh screen   # full active output, copy straight to clipboard
#   screenshot.sh edit      # select region, open satty to annotate + save
#
# area / screen are the fast path: capture lands on the clipboard, no UI.
# edit opens satty. From there:
#   - Ctrl+S to save     (also auto-copies via --copy-command)
#   - Ctrl+C to copy only
#   - Esc / close to discard

set -euo pipefail

mode=${1:-area}
ts=$(date +%Y%m%d_%H%M%S)
out_dir="$HOME/Pictures/screenshots"
mkdir -p "$out_dir"
out_file="$out_dir/${ts}.png"

capture() {
    case "$1" in
        area|edit)
            geom=$(slurp) || exit 0
            grim -g "$geom" -
            ;;
        screen)
            active=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
            grim -o "$active" -
            ;;
    esac
}

case "$mode" in
    area|screen)
        capture "$mode" | wl-copy
        notify-send "screenshot" "copied to clipboard"
        ;;
    edit)
        capture edit \
            | satty \
                --filename - \
                --output-filename "$out_file" \
                --early-exit \
                --copy-command wl-copy \
                --initial-tool brush
        notify-send "screenshot" "saved → $out_file"
        ;;
    *)
        notify-send "screenshot" "unknown mode: $mode"
        exit 1
        ;;
esac
