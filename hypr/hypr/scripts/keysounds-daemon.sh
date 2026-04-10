#!/bin/bash

CONFIG="$HOME/.config/keysounds/config"
BUCKLE="$HOME/.local/bin/buckle"
BUCKLE_SOUNDS="$HOME/.local/share/bucklespring-sounds"
MECHSIM_SOUNDS="/usr/share/mechsim/audio"

source "$CONFIG" 2>/dev/null || {
    ENGINE="bucklespring"
    BUCKLESPRING_THEME="ibm-model-m"
    MECHSIM_THEME="eg-oreo"
}

# Kill any running engines
pkill -x buckle 2>/dev/null
pkill -f keyboard_sound_player 2>/dev/null
sudo -n pkill -f get_key_presses 2>/dev/null
sleep 0.3

case "$ENGINE" in
    bucklespring)
        if [ -x "$BUCKLE" ] && [ -d "${BUCKLE_SOUNDS}/${BUCKLESPRING_THEME}" ]; then
            setsid "$BUCKLE" -f -p "${BUCKLE_SOUNDS}/${BUCKLESPRING_THEME}" &>/dev/null &
        fi
        ;;
    mechsim)
        THEME_DIR="${MECHSIM_SOUNDS}/${MECHSIM_THEME}"
        if [ -d "$THEME_DIR" ]; then
            setsid bash -c "cd '$THEME_DIR' && sudo -n /usr/bin/get_key_presses | /usr/bin/keyboard_sound_player config.json 100" &>/dev/null &
        fi
        ;;
esac
