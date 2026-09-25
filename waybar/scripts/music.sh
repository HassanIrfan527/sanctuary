#!/usr/bin/env bash
# Ambient now-playing. Renders nothing when there is nothing to say.
# waybar's built-in mpris module defaults to tracking `playerctld`, which
# isn't running here — polling playerctl directly is more robust and gives
# us control over the empty-artist case (browsers often send title only).
#
# Layout:  ▶ ▓▓▓░░░░░ │ Title — Artist
#          ^ transport  ^ position     ^ label, title first
command -v playerctl >/dev/null 2>&1 || exit 0

status=$(playerctl status 2>/dev/null) || exit 0
case "$status" in Playing) glyph="▶" ;; Paused) glyph="‖" ;; *) exit 0 ;; esac

artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
[ -z "$title" ] && exit 0

if [ -n "$artist" ]; then label="$title — $artist"; else label="$title"; fi

# Truncate on grapheme count, not bytes. Title leads, so when a long entry is
# cut it is the artist that gets clipped and the track name that survives.
# 34, down from 42, to pay for the meter without the island growing.
max=34
if [ "${#label}" -gt "$max" ]; then label="${label:0:$((max-1))}…"; fi

# Pango markup safety — must happen before any markup is added.
label=${label//&/&amp;}; label=${label//</&lt;}; label=${label//>/&gt;}

# Eight-cell position meter, same block language as the workspace indicator.
# Pulled down to subtext/frame colours: the track title is what gets read, the
# meter is something you glance at. Silent when the player reports no length —
# radio streams and some browsers don't, and a meter stuck at 0 is a lie.
meter=""
len=$(playerctl metadata mpris:length 2>/dev/null)   # microseconds
pos=$(playerctl position 2>/dev/null)                # seconds, float
if [ -n "$len" ] && [ -n "$pos" ] && [ "$len" -gt 0 ] 2>/dev/null; then
  cells=8
  filled=$(awk -v p="$pos" -v l="$len" -v c="$cells" \
    'BEGIN { s = l / 1000000; if (s <= 0) { print 0; exit }
             f = int((p / s) * c + 0.5); if (f < 0) f = 0; if (f > c) f = c; print f }')
  fill=""; empty=""
  for ((i = 0; i < filled; i++)); do fill+="▓"; done
  for ((i = filled; i < cells; i++)); do empty+="░"; done
  meter="<span color='#a6adc8'>${fill}</span><span color='#45475a'>${empty}</span> <span color='#45475a'>│</span> "
fi

printf '{"text":"%s %s%s","class":"%s"}\n' "$glyph" "$meter" "$label" "${status,,}"
