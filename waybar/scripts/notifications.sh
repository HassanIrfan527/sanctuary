#!/usr/bin/env bash
# Waiting notifications as a rising block, not a dot.
# ▁ ▃ ▅ ▇ █  — one glyph wide, so "how much is waiting" reads without counting.
# Renders nothing when the queue is empty (DESIGN-BRIEF §2: empty states render nothing).
#
# Driven by `swaync-client -swb`, which streams a JSON line on every add/close.
# That is event-driven — no polling interval — which matters on an i5-6500 where
# DESKTOP-PLAN.md §1 says every process has to earn its RAM.
command -v swaync-client >/dev/null 2>&1 || exit 0

emit() {
  local count="${1:-0}" dnd="${2:-false}" glyph cls
  case "$count" in
    0)       printf '{"text":"","class":"empty"}\n'; return ;;
    1)       glyph="▁" ;;
    2)       glyph="▃" ;;
    3)       glyph="▅" ;;
    4)       glyph="▇" ;;
    *)       glyph="█" ;;
  esac
  cls="waiting"
  [ "$dnd" = "true" ] && cls="dnd"
  printf '{"text":"[ %s ]","class":"%s","tooltip":false}\n' "$glyph" "$cls"
}

# -swb emits {"text":"<count>","alt":"...","tooltip":"...","class":"..."} —
# the count rides in `text`, and dnd shows up as a "dnd-" prefix on `class`.
# Prime immediately so the module is correct before the first event arrives.
emit "$(swaync-client -c 2>/dev/null || echo 0)" \
     "$([ "$(swaync-client -D 2>/dev/null)" = "true" ] && echo true || echo false)"

swaync-client -swb 2>/dev/null | while read -r line; do
  count=$(jq -r '.text // "0"' <<<"$line" 2>/dev/null)
  cls=$(jq -r '.class // ""' <<<"$line" 2>/dev/null)
  case "$cls" in dnd*) dnd=true ;; *) dnd=false ;; esac
  emit "${count:-0}" "$dnd"
done
