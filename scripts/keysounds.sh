#!/usr/bin/env bash

STATEFILE="${XDG_STATE_HOME:-$HOME/.local/state}/keysound_current"
mkdir -p "$(dirname "$STATEFILE")"

ACTION=$1

case "$ACTION" in
    toggle)
        if pgrep -x mechsim >/dev/null; then
            pkill -f "mechsim" 2>/dev/null

            # noctalia's toast IPC is gone; this is the standard notification
            # path, so it works with swaync (or anything else that owns the bus).
            notify-send -a keysounds "Keysounds off" "Typing is quiet again" 2>/dev/null
        else
            KEYSOUND=$(<"$STATEFILE")
            nohup mechsim -s "$KEYSOUND" -V 100 >/dev/null 2>&1 &

            notify-send -a keysounds "Keysounds on" "$KEYSOUND" 2>/dev/null
        fi
        ;;
    choose)

        OFF_OPTION="🛑 Turn OFF"

        # 1. Fetch available sound list
        list=$(mechsim -l 2>/dev/null | sed '1,2d' | sed 's/^[[:space:]]*//')

        # 2. Always display fzf menu (with Turn OFF option at top)
        SELECTED=$(printf '%s\n%s' "$OFF_OPTION" "$list" | fzf --layout=reverse --border=sharp --height=100% --prompt="Select Keysound > ")

        # 3. Handle selection
        if [ "$SELECTED" = "$OFF_OPTION" ]; then

            # Kill running process
            pkill -f "mechsim" 2>/dev/null

            notify-send -a keysounds "Keysounds off" "Typing is quiet again" 2>/dev/null

        elif [ -n "$SELECTED" ]; then

            echo "$SELECTED" >"$STATEFILE"
            # Kill old instance if running, then start new selected sound
            pkill -f "mechsim" 2>/dev/null

            nohup mechsim -s "$SELECTED" -V 100 >/tmp/mechsim.log 2>&1 &

            notify-send -a keysounds "Keysound changed" "$SELECTED" 2>/dev/null

        fi
        ;;
    *)
        exit 1
        ;;
esac
