#!/bin/bash

SOUNDS_DIR="/home/anonymous/.local/share/bucklespring-sounds"
THEME_FILE="/home/anonymous/.config/bucklespring/theme"
BUCKLE="/home/anonymous/.local/bin/buckle"

THEMES=$(ls -1 "$SOUNDS_DIR")
CURRENT=$(cat "$THEME_FILE" 2>/dev/null || echo "ibm-model-m")

CHOSEN=$(echo "$THEMES" | fuzzel --dmenu --prompt "Sound theme: " --width 30)

if [ -n "$CHOSEN" ]; then
    echo "$CHOSEN" > "$THEME_FILE"

    if pgrep -x buckle > /dev/null; then
        pkill -x buckle
        sleep 0.3
        setsid "$BUCKLE" -f -p "${SOUNDS_DIR}/${CHOSEN}" &>/dev/null &
    fi

    notify-send "Key Sounds" "Theme: ${CHOSEN}"
fi
