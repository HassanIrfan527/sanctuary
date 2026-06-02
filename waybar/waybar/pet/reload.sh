#!/usr/bin/env bash
# Apply the desk-pet changes live: restart the TOP waybar + swaync.
# Leaves the optional bottom bar (bottom.jsonc) alone.
# Also kills any stray pet-watch.sh — that old signal-based watcher would
# SIGRTMIN-kill the bar, so it must not be running.

pkill -f 'pet/pet-watch.sh' 2>/dev/null
for pid in $(pgrep -x waybar); do
    grep -qa 'bottom.jsonc' "/proc/$pid/cmdline" 2>/dev/null || kill "$pid" 2>/dev/null
done
pkill -x swaync 2>/dev/null

sleep 1
setsid -f swaync   >/dev/null 2>&1
sleep 0.6
setsid -f waybar   >/dev/null 2>&1

sleep 1
if pgrep -x waybar | while read -r p; do grep -qa bottom.jsonc "/proc/$p/cmdline" 2>/dev/null || echo hit; done | grep -q hit; then
    echo "top waybar is up. send a test notification:"
    echo "  notify-send 'Spotify' 'Now playing · Bonobo — Kerala'"
else
    echo "top waybar did NOT stay up — run 'waybar' in a terminal to see the error."
fi
