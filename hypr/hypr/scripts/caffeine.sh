#!/usr/bin/env bash
# caffeine.sh — keep-awake toggle (Super+M). Stops/starts hypridle so the
# screen won't dim, DPMS-off, or auto-lock while it's on. The daemon's
# presence is the single source of truth, so it never drifts out of sync.
# A toast confirms each flip (no bar indicator by choice).
set -uo pipefail

if pgrep -x hypridle >/dev/null; then
    # idle daemon up → caffeinate by stopping it
    pkill -x hypridle
    notify-send -t 2000 -a caffeine "Caffeine on" "Screen will stay awake  "
else
    # already caffeinated → restore idle (lock 30m · display off 1h)
    hyprctl dispatch exec hypridle >/dev/null 2>&1
    notify-send -t 2000 -a caffeine "Caffeine off" "Idle lock & dim restored  "
fi
