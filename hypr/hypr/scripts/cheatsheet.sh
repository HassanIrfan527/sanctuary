#!/usr/bin/env bash
set -euo pipefail

SHEET="$HOME/.dotfiles/docs/cheatsheet.txt"
[[ -f "$SHEET" ]] || SHEET=/dev/null

(
    if [[ -s "$SHEET" ]]; then
        cat "$SHEET"
    else
        printf '%s\n' \
            "super + enter         | terminal" \
            "super + q             | close window" \
            "super + space         | app picker (fuzzel)" \
            "super + 1..9          | switch workspace" \
            "super + shift + v     | clipboard history" \
            "super + shift + w     | wallpaper picker" \
            "print                 | region screenshot → clipboard" \
            "shift + print         | region screenshot → satty (edit)" \
            "super + print         | fullscreen screenshot → clipboard" \
            "super + slash         | this cheatsheet" \
            "super + i             | bug capture" \
            "ctrl + alt + delete   | session menu"
    fi
) | fuzzel --dmenu --prompt "cheat > " --width 70 --lines 22 >/dev/null || true
