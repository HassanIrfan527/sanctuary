#!/bin/bash

CONFIG="$HOME/.config/keysounds/config"
source "$CONFIG" 2>/dev/null || ENGINE="bucklespring"

if pgrep -x buckle > /dev/null || pgrep -f keyboard_sound_player > /dev/null; then
    pkill -x buckle 2>/dev/null
    pkill -f keyboard_sound_player 2>/dev/null
    sudo -n pkill -f get_key_presses 2>/dev/null
    notify-send "Key Sounds" "Turned off"
else
    ~/.config/hypr/scripts/keysounds-daemon.sh
    THEME="$BUCKLESPRING_THEME"
    [ "$ENGINE" = "mechsim" ] && THEME="$MECHSIM_THEME"
    notify-send "Key Sounds" "Turned on (${ENGINE}: ${THEME})"
fi
