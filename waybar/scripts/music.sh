#!/usr/bin/env bash
# Ambient now-playing. Renders nothing when there is nothing to say.
# waybar's built-in mpris module defaults to tracking `playerctld`, which
# isn't running here — polling playerctl directly is more robust and gives
# us control over the empty-artist case (browsers often send title only).
command -v playerctl >/dev/null 2>&1 || exit 0

status=$(playerctl status 2>/dev/null) || exit 0
case "$status" in Playing) glyph="▶" ;; Paused) glyph="‖" ;; *) exit 0 ;; esac

artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
[ -z "$title" ] && exit 0

if [ -n "$artist" ]; then label="$title — $artist"; else label="$title"; fi

# Truncate on grapheme count, not bytes. Title leads, so when a long entry is
# cut it is the artist that gets clipped and the track name that survives.
max=42
if [ "${#label}" -gt "$max" ]; then label="${label:0:$((max-1))}…"; fi

# Pango markup safety.
label=${label//&/&amp;}; label=${label//</&lt;}; label=${label//>/&gt;}

printf '{"text":"%s  %s","class":"%s"}\n' "$glyph" "$label" "${status,,}"
