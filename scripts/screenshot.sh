#!/usr/bin/env bash

set -o pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILENAME="Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png"
FILEPATH="$DIR/$FILENAME"

# Take the screenshot, save it, and copy it to the clipboard
if grim -g "$(slurp)" - | tee "$FILEPATH" | wl-copy; then
    # Standard notification path — works with swaync, or anything else that
    # owns org.freedesktop.Notifications. noctalia's toast IPC is gone.
    notify-send -a screenshot "Screenshot" "$FILENAME" 2>/dev/null
else
    # If grim fails (e.g. pressed Esc during slurp), clean up the empty file
    rm -f "$FILEPATH"
fi
