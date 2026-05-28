#!/usr/bin/env bash
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

hyprctl hyprpaper unload all >/dev/null 2>&1 || true
hyprctl hyprpaper preload "$full" >/dev/null
for m in $(hyprctl monitors -j | jq -r '.[].name'); do
    hyprctl hyprpaper wallpaper "$m,$full" >/dev/null
done
