#!/usr/bin/env bash
# Prints the path to the blob pet's current face for the waybar image#pet module.
#   dnd on                  -> melts, eyes closed, zzz
#   notification just landed -> perks up for PERK_WINDOW seconds, then settles
#   otherwise                -> idle, drowsing
#
# "Just landed" = the newest entry in swaync's history log is younger than
# PERK_WINDOW. We deliberately do NOT use `swaync-client -c`: that counts the
# whole notification-center backlog, so the pet would look perky forever.

base="$HOME/.config/waybar/pet/blob"
hist="${XDG_STATE_HOME:-$HOME/.local/state}/swaync/history.jsonl"
PERK_WINDOW=6

if [ "$(swaync-client -D 2>/dev/null)" = "true" ]; then
    printf '%s\n' "$base/blob-dnd.svg"
    exit 0
fi

last_ts=$(tail -n1 "$hist" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null)
now=$(date +%s)

if [ -n "$last_ts" ] && [ "$((now - last_ts))" -lt "$PERK_WINDOW" ]; then
    printf '%s\n' "$base/blob-unread.svg"
else
    printf '%s\n' "$base/blob-idle.svg"
fi
