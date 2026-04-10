#!/bin/bash

CONFIG="$HOME/.config/keysounds/config"
BUCKLE_SOUNDS="$HOME/.local/share/bucklespring-sounds"
MECHSIM_SOUNDS="/usr/share/mechsim/audio"

source "$CONFIG" 2>/dev/null || {
    ENGINE="bucklespring"
    BUCKLESPRING_THEME="ibm-model-m"
    MECHSIM_THEME="eg-oreo"
}

# Build list: engine/theme, mark current with *
ITEMS=""
for theme in $(ls -1 "$BUCKLE_SOUNDS" 2>/dev/null); do
    marker=""
    [ "$ENGINE" = "bucklespring" ] && [ "$BUCKLESPRING_THEME" = "$theme" ] && marker=" *"
    ITEMS+="bucklespring/${theme}${marker}\n"
done
for theme in $(ls -1 "$MECHSIM_SOUNDS" 2>/dev/null); do
    marker=""
    [ "$ENGINE" = "mechsim" ] && [ "$MECHSIM_THEME" = "$theme" ] && marker=" *"
    ITEMS+="mechsim/${theme}${marker}\n"
done

CHOSEN=$(echo -e "$ITEMS" | sed '/^$/d' | fuzzel --dmenu --prompt "Key sound: " --width 35)

[ -z "$CHOSEN" ] && exit 0

# Strip the * marker
CHOSEN=$(echo "$CHOSEN" | sed 's/ \*$//')

NEW_ENGINE=$(echo "$CHOSEN" | cut -d/ -f1)
NEW_THEME=$(echo "$CHOSEN" | cut -d/ -f2)

sed -i "s/^ENGINE=.*/ENGINE=$NEW_ENGINE/" "$CONFIG"

case "$NEW_ENGINE" in
    bucklespring)
        sed -i "s/^BUCKLESPRING_THEME=.*/BUCKLESPRING_THEME=$NEW_THEME/" "$CONFIG"
        ;;
    mechsim)
        sed -i "s/^MECHSIM_THEME=.*/MECHSIM_THEME=$NEW_THEME/" "$CONFIG"
        ;;
esac

# Restart if running
if pgrep -x buckle > /dev/null || pgrep -f keyboard_sound_player > /dev/null; then
    ~/.config/hypr/scripts/keysounds-daemon.sh
fi

notify-send "Key Sounds" "Switched to ${NEW_ENGINE}: ${NEW_THEME}"
