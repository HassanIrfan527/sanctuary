#!/usr/bin/env bash
# toggle-bottom-bar.sh — start/stop the bottom lualine-style waybar instance.
set -euo pipefail

if pgrep -f 'waybar.*bottom\.jsonc' >/dev/null; then
    pkill -f 'waybar.*bottom\.jsonc'
else
    setsid waybar \
        -c "$HOME/.config/waybar/bottom.jsonc" \
        -s "$HOME/.config/waybar/bottom.css" \
        </dev/null >/dev/null 2>&1 &
    disown
fi
