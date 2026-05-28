#!/usr/bin/env bash
# wallpaper-picker.sh — fuzzel + swww
set -euo pipefail

DIRS=(
    "$HOME/Pictures/Wallpapers"
    "$HOME/Pictures"
)

list_walls() {
    for d in "${DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        find "$d" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
    done
}

pick=$(list_walls | sed "s|$HOME/||" | sort -u | fuzzel --dmenu --prompt "wallpaper > " --width 60 --lines 12) || exit 0
[[ -z "$pick" ]] && exit 0
full="$HOME/$pick"
[[ -f "$full" ]] || exit 1

# make sure swww-daemon is up
pgrep -x swww-daemon >/dev/null || { swww-daemon & disown; sleep 0.5; }

swww img "$full" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-duration 0.8 \
    --transition-fps 60
