#!/usr/bin/env bash
# Pick a screen color with hyprpicker → copy hex to clipboard, notify with swatch.
set -euo pipefail

col=$(hyprpicker -f hex -r 2>/dev/null) || exit 0
[[ -z "$col" ]] && exit 0

printf '%s' "$col" | wl-copy
notify-send "Color picked" "$col · copied to clipboard" 2>/dev/null || true
