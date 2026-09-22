#!/usr/bin/env bash
# Output volume as a two-tone block meter: [ vol ████░░░ ]
#
# Seven cells. Filled cells inherit the module's accent from CSS; empty cells are
# overridden to @surface1 via pango markup, because a meter drawn in one colour
# reads as a solid bar and you lose the "how full" at a glance. Pango uses single
# quotes so the markup survives JSON without escaping.
command -v wpctl >/dev/null 2>&1 || exit 0

DIM="#45475a"   # @surface1 — keep in sync with waybar/style.css

raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || exit 0
# raw looks like: "Volume: 0.45" or "Volume: 0.45 [MUTED]"
vol=${raw#Volume: }
vol=${vol%% *}
pct=$(awk -v v="$vol" 'BEGIN{printf "%d", (v*100)+0.5}')

cells=7
filled=$(( (pct * cells + 50) / 100 ))
[ "$filled" -gt "$cells" ] && filled=$cells
[ "$filled" -lt 0 ] && filled=0
empty=$(( cells - filled ))

on=""; for ((i=0; i<filled; i++)); do on+="█"; done
off=""; for ((i=0; i<empty; i++)); do off+="░"; done
[ -n "$off" ] && off="<span color='$DIM'>$off</span>"

case "$raw" in
  *MUTED*) class="muted" ;;
  *)       class="live"  ;;
esac

printf '{"text":"[ vol %s%s ]","class":"%s","percentage":%d}\n' "$on" "$off" "$class" "$pct"
