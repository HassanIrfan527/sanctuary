#!/usr/bin/env bash
# Ambient soundscapes via mpv — a walker picker for cozy/hard moments.
# Drop your own loops in ~/Music/ambient/ named <scene>.<ext> (e.g. rain.mp3)
# and they take priority over the streamed fallback below. Edit URLs freely.
# Pick the currently-playing scene again — or "■ Stop" — to silence it.

set -euo pipefail

DIR="$HOME/Music/ambient"
SOCK="${XDG_RUNTIME_DIR:-/tmp}/ambient.sock"
NOWF="${XDG_RUNTIME_DIR:-/tmp}/ambient.now"

declare -A URL=(
    [Rain]="https://www.youtube.com/watch?v=mPZkdNFkNps"
    [Café]="https://www.youtube.com/watch?v=h2zkV-l_TbY"
    [Fireplace]="https://www.youtube.com/watch?v=L_LUpnjgPso"
    [Forest]="https://www.youtube.com/watch?v=OdIJ2x3nxzQ"
    [Ocean]="https://www.youtube.com/watch?v=bn9F19Hi1Lk"
    [Lofi]="https://ice1.somafm.com/fluid-128-mp3"
)
declare -A ICON=( [Rain]="🌧" [Café]="☕" [Fireplace]="🔥" [Forest]="🌲" [Ocean]="🌊" [Lofi]="🎐" )
ORDER=(Rain Café Fireplace Forest Ocean Lofi)

playing() { pgrep -f "$SOCK" >/dev/null 2>&1; }
current() { [[ -f "$NOWF" ]] && cat "$NOWF" 2>/dev/null || true; }

stop() { pkill -f "$SOCK" 2>/dev/null || true; rm -f "$NOWF"; }

start() {
    local scene="$1" src
    src=$(find "$DIR" -maxdepth 1 -type f -iname "${scene}.*" 2>/dev/null | head -1 || true)
    [[ -z "$src" ]] && src="${URL[$scene]:-}"
    [[ -z "$src" ]] && { notify-send "Ambient" "no source for $scene" 2>/dev/null || true; exit 1; }
    setsid -f mpv --no-video --no-terminal --really-quiet --loop-file=inf \
        --volume=70 --ytdl-format="bestaudio/best" \
        --input-ipc-server="$SOCK" "$src" >/dev/null 2>&1
    echo "$scene" > "$NOWF"
    notify-send "Ambient" "${ICON[$scene]:-}  $scene" 2>/dev/null || true
}

cur="$(current)"
menu=""
if playing; then menu+="■  Stop"$'\n'; fi
for s in "${ORDER[@]}"; do
    mark="    "
    if playing && [[ "$s" == "$cur" ]]; then mark="●  "; fi
    menu+="${mark}${ICON[$s]}  ${s}"$'\n'
done

choice=$(printf '%s' "$menu" | walker --dmenu -p "ambient") || exit 0
[[ -z "$choice" ]] && exit 0

if [[ "$choice" == *"Stop"* ]]; then
    stop; notify-send "Ambient" "stopped" 2>/dev/null || true; exit 0
fi

scene=$(awk '{print $NF}' <<<"$choice")

if playing && [[ "$scene" == "$cur" ]]; then
    stop; notify-send "Ambient" "stopped" 2>/dev/null || true; exit 0
fi

start "$scene"
