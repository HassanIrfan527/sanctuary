#!/usr/bin/env bash
# toggle-bottom-bar.sh — start/stop the bottom lualine-style waybar instance.
# Picks the niri-specific config when running under niri, else the hypr one.
set -euo pipefail

if pgrep -f 'waybar.*bottom\.jsonc' >/dev/null; then
    pkill -f 'waybar.*bottom\.jsonc'
else
    cfg="$HOME/.config/waybar/bottom.jsonc"
    if [ -n "${NIRI_SOCKET:-}" ] || [ "${XDG_CURRENT_DESKTOP:-}" = "niri" ]; then
        cfg="$HOME/.config/waybar/niri-bottom.jsonc"
    fi
    setsid waybar \
        -c "$cfg" \
        -s "$HOME/.config/waybar/bottom.css" \
        </dev/null >/dev/null 2>&1 &
    disown
fi
