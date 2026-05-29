#!/usr/bin/env bash
# Toggle between swww (static) and mpvpaper (video).

set -euo pipefail

VIDEO_DIR="${HOME}/Videos"
STATE="${XDG_RUNTIME_DIR:-/tmp}/live-wallpaper.last"

if pgrep -x mpvpaper >/dev/null; then
    pkill -x mpvpaper || true
    sleep 0.2
    swww-daemon >/dev/null 2>&1 &
    sleep 0.4
    if [[ -f "$STATE" ]]; then
        wp=$(cat "$STATE")
        [[ -f "$wp" ]] && swww img "$wp" --transition-type grow --transition-pos 0.5,0.5
    fi
    notify-send "Wallpaper" "Live mode off"
    exit 0
fi

mapfile -t videos < <(find -L "$VIDEO_DIR" -maxdepth 3 -type f \
    \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) 2>/dev/null)

if [[ ${#videos[@]} -eq 0 ]]; then
    notify-send "Live wallpaper" "No videos found in $VIDEO_DIR"
    exit 1
fi

choice=$(printf '%s\n' "${videos[@]}" \
    | sed "s|$HOME|~|" \
    | fuzzel --dmenu --prompt='video > ' --width=60 --lines=12)
[[ -z "$choice" ]] && exit 0
choice="${choice/#\~/$HOME}"

# remember current static wallpaper so we can restore it on toggle-off
if pgrep -x swww-daemon >/dev/null; then
    swww query 2>/dev/null | awk -F'image: ' 'NF>1 {print $2; exit}' > "$STATE" || true
fi

pkill -x swww-daemon || true
sleep 0.2

setsid -f mpvpaper -o "no-audio loop-file=inf hwdec=auto" '*' "$choice" \
    >/dev/null 2>&1
notify-send "Wallpaper" "Live mode on · $(basename "$choice")"
