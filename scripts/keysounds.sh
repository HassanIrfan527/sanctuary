#!/usr/bin/env bash

OFF_OPTION="🛑 Turn OFF"

# 1. Fetch available sound list
list=$(mechsim -l 2>/dev/null | sed '1,2d'| sed 's/^[[:space:]]*//')

# 2. Always display fzf menu (with Turn OFF option at top)
selected=$(printf '%s\n%s' "$OFF_OPTION" "$list" | fzf --layout=reverse --border=rounded --height=100% --prompt="Select Keysound > ")

# 3. Handle selection
if [ "$selected" = "$OFF_OPTION" ]; then

    # Kill running process
   pkill -f "mechsim" 2>/dev/null

    toast_json=$(jq -n \
      --arg title "Keysounds" \
      --arg body "Disabled" \
      '{title: $title, body: $body}')

    noctalia-shell ipc call toast send "$toast_json" 2>/dev/null

elif [ -n "$selected" ]; then

    # Kill old instance if running, then start new selected sound
    pkill -f "mechsim" 2>/dev/null

    nohup mechsim -s "$selected" -V 100 > /tmp/mechsim.log 2>&1 &

    toast_json=$(jq -n \
      --arg title "Keysound Changed" \
      --arg body "Sound Selected: $selected" \
      '{title: $title, body: $body}')

    noctalia-shell ipc call toast send "$toast_json" 2>/dev/null

fi
