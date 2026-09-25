#!/usr/bin/env bash
# Waiting notifications as a rising block.
#   [ ░ ] nothing waiting · [ ▁ ▃ ▅ ▇ ] 1-4 · [ █ ] 5+
#
# Unlike the other modules this one does NOT render nothing when empty: it is
# the click target for the centre, and an affordance you cannot see is an
# affordance you cannot press. Empty just goes dim.
#
# Driven by `swaync-client -swb`, which streams a JSON line on every add/close —
# event-driven, no polling interval.
#
# Every swaync-client call is wrapped in `timeout`. Without it, a client run
# while swaync is down blocks FOREVER on "Could not connect to CC service. Will
# wait for connection..." — which hangs this script before it emits anything and
# the module silently never appears.
command -v swaync-client >/dev/null 2>&1 || exit 0

emit() {
  local count="${1:-0}" dnd="${2:-false}" glyph cls
  case "$count" in
    0) glyph="░"; cls="empty" ;;
    1) glyph="▁"; cls="waiting" ;;
    2) glyph="▃"; cls="waiting" ;;
    3) glyph="▅"; cls="waiting" ;;
    4) glyph="▇"; cls="waiting" ;;
    *) glyph="█"; cls="waiting" ;;
  esac
  [ "$dnd" = "true" ] && cls="dnd"
  # Brackets are punctuation, not content — dimmed to the frame colour so the
  # block is what the eye lands on. Same rule as the clock and the mic.
  local d="<span color='#45475a'>" e="</span>"
  printf '{"text":"%s","class":"%s","tooltip":false}\n' "${d}[${e} ${glyph} ${d}]${e}" "$cls"
}

prime() {
  local c d
  c=$(timeout 2 swaync-client -c 2>/dev/null) || c=0
  case "$c" in ''|*[!0-9]*) c=0 ;; esac
  d=$(timeout 2 swaync-client -D 2>/dev/null) || d=false
  [ "$d" = "true" ] || d=false
  emit "$c" "$d"
}

# Draw something immediately, before waiting on any event.
prime

# -swb emits {"text":"<count>","alt":"...","tooltip":"...","class":"..."} —
# the count rides in `text`, and dnd shows up as a "dnd-" prefix on `class`.
swaync-client -swb 2>/dev/null | while read -r line; do
  count=$(jq -r '.text // "0"' <<<"$line" 2>/dev/null)
  case "$count" in ''|*[!0-9]*) count=0 ;; esac
  cls=$(jq -r '.class // ""' <<<"$line" 2>/dev/null)
  case "$cls" in dnd*) dnd=true ;; *) dnd=false ;; esac
  emit "$count" "$dnd"
done
