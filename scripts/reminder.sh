#!/bin/bash

# Send notification. If clicked, runs the journal.py python script
ACTION=$(
    notify-send "🌱 Journal" "Anything good happened?" \
        --action="open=Write Now"
)

if [ "$ACTION" == "open" ]; then
    python3 ~/.dotfiles/scripts/journal.py
fi
