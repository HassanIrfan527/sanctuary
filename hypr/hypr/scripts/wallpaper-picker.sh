#!/usr/bin/env bash
# Cozy wallpaper picker — fzf grid in a floating kitty, real thumbnails via icat.
#    static images → swww      live videos → mpvpaper
# Modes:  (default) launch floating kitty · __inner run the fzf UI · __preview render one
# Picking a static image stops live mode; "Stop live" restores the last static.

set -euo pipefail

SELF="$(realpath "${BASH_SOURCE[0]}")"
IMG_DIRS=("$HOME/Pictures/Wallpapers" "$HOME/Pictures")
VID_DIRS=("$HOME/Videos")
STATE="${XDG_RUNTIME_DIR:-/tmp}/live-wallpaper.last"
TAB=$'\t'

# Thumbnail cache — 5K wallpapers decode slowly, so preview a small cached copy.
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
mkdir -p "$CACHE"

# thumb <image> → prints path to a cached 640px thumbnail, generating on miss.
# Keyed by path+mtime so edited images regenerate. Atomic write avoids races
# between the live preview and the background pre-warm.
thumb() {
    local f="$1" mt key cache tmp
    mt="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
    key="$(printf '%s:%s' "$f" "$mt" | sha1sum | cut -d' ' -f1)"
    cache="$CACHE/$key.jpg"
    if [[ ! -f "$cache" ]]; then
        tmp="$CACHE/$key.$$.tmp.jpg"
        if vipsthumbnail "$f" --size 640x360 -o "${tmp}[Q=80]" 2>/dev/null \
           || magick "$f" -auto-orient -strip -thumbnail 640x360 -quality 80 "jpg:$tmp" 2>/dev/null; then
            mv -f "$tmp" "$cache"
        else
            rm -f "$tmp"; printf '%s\n' "$f"; return
        fi
    fi
    printf '%s\n' "$cache"
}

# warm mode: pre-generate every image thumbnail (run nice'd in background).
if [[ "${1:-}" == "__warm" ]]; then
    { for d in "${IMG_DIRS[@]}"; do
        [[ -d "$d" ]] && find "$d" -maxdepth 2 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null
      done; } | sort -u | while IFS= read -r p; do thumb "$p" >/dev/null 2>&1; done
    exit 0
fi

# Nerd Font glyphs (no emojis):  image   film   stop
G_IMG=$''
G_VID=$''
G_STOP=$''

# ── preview mode: fzf calls this per highlighted row ────────────────────────
if [[ "${1:-}" == "__preview" ]]; then
    f="${2:-}"
    if [[ "$f" == "__STOP__" ]]; then
        printf '\n\n   %s  stop live wallpaper\n\n   return to the last static image.\n' "$G_STOP"
        exit 0
    fi
    case "${f,,}" in
        *.mp4|*.webm|*.mkv|*.mov)
            if command -v ffmpegthumbnailer >/dev/null 2>&1; then
                tmp="$(mktemp --suffix=.png)"
                if ffmpegthumbnailer -i "$f" -o "$tmp" -s 0 >/dev/null 2>&1; then
                    kitten icat --clear --transfer-mode=memory --stdin=no \
                        --place="${FZF_PREVIEW_COLUMNS:-40}x${FZF_PREVIEW_LINES:-20}@0x0" "$tmp"
                fi
                rm -f "$tmp"
            else
                printf '\n\n   %s  live video\n\n   %s\n' "$G_VID" "$(basename "$f")"
            fi
            ;;
        *)
            img="$(thumb "$f")"
            kitten icat --clear --transfer-mode=memory --stdin=no \
                --place="${FZF_PREVIEW_COLUMNS:-40}x${FZF_PREVIEW_LINES:-20}@0x0" "$img"
            ;;
    esac
    exit 0
fi

# ── inner mode: the fzf UI (runs inside the floating kitty) ──────────────────
if [[ "${1:-}" == "__inner" ]]; then
    setsid -f nice -n 19 "$SELF" __warm >/dev/null 2>&1 || true

    build_list() {
        printf '%s  Stop live wallpaper%s__STOP__%sstop\n' "$G_STOP" "$TAB" "$TAB"
        { for d in "${IMG_DIRS[@]}"; do
            [[ -d "$d" ]] && find "$d" -maxdepth 2 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null
          done; } | sort -u | while IFS= read -r p; do
            printf '%s  %s%s%s%simg\n' "$G_IMG" "$(basename "$p")" "$TAB" "$p" "$TAB"
          done
        { for d in "${VID_DIRS[@]}"; do
            [[ -d "$d" ]] && find -L "$d" -maxdepth 3 -type f \
                \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) 2>/dev/null
          done; } | sort -u | while IFS= read -r p; do
            printf '%s  %s%s%s%svid\n' "$G_VID" "$(basename "$p")" "$TAB" "$p" "$TAB"
          done
    }

    choice="$(build_list | fzf \
        --delimiter="$TAB" --with-nth=1 \
        --layout=reverse --border=rounded --margin=1 --padding=1 \
        --prompt="$G_IMG  " --pointer="" --info=inline \
        --header="static · live  ·  enter to set" \
        --preview="$SELF __preview {2}" \
        --preview-window="right:55%:border-left")" || exit 0

    [[ -z "$choice" ]] && exit 0
    path="$(cut -f2 <<<"$choice")"
    type="$(cut -f3 <<<"$choice")"

    ensure_swww() { pgrep -x swww-daemon >/dev/null || { swww-daemon & sleep 0.4; }; }
    set_static()  { ensure_swww; swww img "$1" --transition-type grow --transition-pos 0.5,0.5 \
                        --transition-duration 0.8 --transition-fps 60; }

    case "$type" in
        stop)
            pkill -x mpvpaper 2>/dev/null || true; sleep 0.2
            ensure_swww
            if [[ -f "$STATE" ]]; then wp="$(cat "$STATE")"; [[ -f "$wp" ]] && set_static "$wp"; fi
            notify-send "Wallpaper" "Live stopped" 2>/dev/null || true
            ;;
        vid)
            [[ -f "$path" ]] || exit 1
            if pgrep -x swww-daemon >/dev/null; then
                swww query 2>/dev/null | awk -F'image: ' 'NF>1 {print $2; exit}' > "$STATE" || true
            fi
            pkill -x swww-daemon 2>/dev/null || true; sleep 0.2
            setsid -f mpvpaper -o "no-audio loop-file=inf hwdec=auto" '*' "$path" >/dev/null 2>&1
            notify-send "Wallpaper" "Live · $(basename "$path")" 2>/dev/null || true
            ;;
        img)
            [[ -f "$path" ]] || exit 1
            pkill -x mpvpaper 2>/dev/null || true
            set_static "$path"
            echo "$path" > "$STATE"
            notify-send "Wallpaper" "$(basename "$path")" 2>/dev/null || true
            ;;
    esac
    exit 0
fi

# ── default mode: open the floating kitty running the UI ─────────────────────
exec kitty --class wallpaper-picker --title wallpaper-picker -e "$SELF" __inner
