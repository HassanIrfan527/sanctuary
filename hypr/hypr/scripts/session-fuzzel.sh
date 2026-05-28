#!/usr/bin/env bash
set -euo pipefail

pick=$(printf '%s\n' \
    "lock     | hyprlock" \
    "logout   | hyprctl dispatch exit" \
    "reboot   | systemctl reboot" \
    "shutdown | systemctl poweroff" \
    | fuzzel --dmenu --prompt "session > " --width 30 --lines 4) || exit 0
[[ -z "$pick" ]] && exit 0

cmd=${pick#*|}
cmd=${cmd# }
eval "$cmd"
