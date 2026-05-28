#!/usr/bin/env bash
set -euo pipefail

choice=$(cliphist list | fuzzel --dmenu --prompt "clip > " --width 60 --lines 12) || exit 0
[[ -z "$choice" ]] && exit 0
printf '%s' "$choice" | cliphist decode | wl-copy
