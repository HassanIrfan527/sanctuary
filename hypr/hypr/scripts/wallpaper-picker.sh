#!/usr/bin/env bash
# Unified wallpaper picker (walker dmenu):
#   🖼 static images → swww      🎬 videos → mpvpaper (live)
# Picking a static image stops live mode; "Stop live" restores the last static.

set -euo pipefail

IMG_DIRS=("$HOME/Pictures/Wallpapers" "$HOME/Pictures")
VID_DIRS=("$HOME/Videos")
STATE="${XDG_RUNTIME_DIR:-/tmp}/live-wallpaper.last"
SEP=" │ "

build_list() {
    printf '■%sStop live wallpaper\n' "$SEP"
    { for d in "${IMG_DIRS[@]}"; do
        [[ -d "$d" ]] && find "$d" -maxdepth 2 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null
      done; } | sort -u | sed "s|^|🖼${SEP}|; s|$HOME|~|"
    { for d in "${VID_DIRS[@]}"; do
        [[ -d "$d" ]] && find -L "$d" -maxdepth 3 -type f \
            \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) 2>/dev/null
      done; } | sort -u | sed "s|^|🎬${SEP}|; s|$HOME|~|"
}

ensure_swww() { pgrep -x swww-daemon >/dev/null || { swww-daemon & sleep 0.4; }; }
set_static()  { ensure_swww; swww img "$1" --transition-type grow --transition-pos 0.5,0.5 \
                    --transition-duration 0.8 --transition-fps 60; }

choice=$(build_list | walker --dmenu -p "wallpaper") || exit 0
[[ -z "$choice" ]] && exit 0

tag="${choice%%"$SEP"*}"
rest="${choice#*"$SEP"}"
path="${rest/#\~/$HOME}"

if [[ "$tag" == "■" ]]; then
    pkill -x mpvpaper 2>/dev/null || true; sleep 0.2
    ensure_swww
    if [[ -f "$STATE" ]]; then wp=$(cat "$STATE"); [[ -f "$wp" ]] && set_static "$wp"; fi
    notify-send "Wallpaper" "Live stopped" 2>/dev/null || true
    exit 0
fi

[[ -f "$path" ]] || exit 1

case "${path,,}" in
    *.mp4|*.webm|*.mkv|*.mov)
        if pgrep -x swww-daemon >/dev/null; then
            swww query 2>/dev/null | awk -F'image: ' 'NF>1 {print $2; exit}' > "$STATE" || true
        fi
        pkill -x swww-daemon 2>/dev/null || true; sleep 0.2
        setsid -f mpvpaper -o "no-audio loop-file=inf hwdec=auto" '*' "$path" >/dev/null 2>&1
        notify-send "Wallpaper" "Live · $(basename "$path")" 2>/dev/null || true
        ;;
    *)
        pkill -x mpvpaper 2>/dev/null || true
        set_static "$path"
        echo "$path" > "$STATE"
        notify-send "Wallpaper" "$(basename "$path")" 2>/dev/null || true
        ;;
esac
