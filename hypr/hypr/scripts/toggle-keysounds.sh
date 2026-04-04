#!/bin/bash

BUCKLE="/home/anonymous/.local/bin/buckle"
SOUNDS_DIR="/home/anonymous/.local/share/bucklespring-sounds"
THEME_FILE="/home/anonymous/.config/bucklespring/theme"
THEME=$(cat "$THEME_FILE" 2>/dev/null || echo "ibm-model-m")

if pgrep -x buckle > /dev/null; then
    pkill -x buckle
    notify-send "Key Sounds" "Turned off"
else
    setsid "$BUCKLE" -f -p "${SOUNDS_DIR}/${THEME}" &>/dev/null &
    notify-send "Key Sounds" "Turned on (${THEME})"
fi
