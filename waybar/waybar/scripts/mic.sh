#!/usr/bin/env bash
# Waybar mic pill — default source level, scroll to adjust, click to mute.
# Glyphs are FontAwesome mic / mic-slash (verified present in Maple Mono NF).

set -euo pipefail

raw=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null) || { printf '{"text":""}\n'; exit 0; }

vol=$(printf '%s\n' "$raw" | awk '{print $2}')
pct=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 + 0.5 }')

mic=$(printf '')
mic_off=$(printf '')

if printf '%s' "$raw" | grep -q MUTED; then
    printf '{"text":"%s","tooltip":"Mic muted","class":"muted","percentage":%d}\n' "$mic_off" "$pct"
else
    printf '{"text":"%s %d%%","tooltip":"Mic %d%%","class":"active","percentage":%d}\n' "$mic" "$pct" "$pct" "$pct"
fi
