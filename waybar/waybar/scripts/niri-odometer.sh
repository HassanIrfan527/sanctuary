#!/usr/bin/env bash
# ── waybar custom module: niri scroll odometer ─────────────────────────
# Measures how far you've "walked" across niri's infinite column strip,
# in your own Japanese distance units. Distance = sum of column hops
# (jumping column 1 → 5 counts as 4). Resets daily.
#     󰖾 1,284 歩   →   󰖾 2.4 里
# Tune the scale below — these are YOUR rules.
# Continuous module: prints on every focus change. Hides outside niri.

command -v niri >/dev/null 2>&1 || exit 0
niri msg version >/dev/null 2>&1 || exit 0

# single instance — waybar restarts/reloads (incl. theme-switch) can leave orphan
# tailers, and multiple writers would double-count the shared odometer state file
for p in $(pgrep -f "niri-odometer\.sh" 2>/dev/null); do
    [ "$p" != "$$" ] && kill "$p" 2>/dev/null
done

STEPS_PER_RI=360                       # 360 column-hops = 1 里  (change freely)

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/niri-odometer"
STATE="$STATE_DIR/state"
mkdir -p "$STATE_DIR"

ICON=$(printf '\U000F0583')   # nf-md-walk (verified present in Maple Mono NF)
RI=$(printf '里')         # 里
HO=$(printf '歩')         # 歩

today=$(date +%Y-%m-%d)
steps=0; lastcol=""
if [ -f "$STATE" ]; then
    read -r sdate steps lastcol < "$STATE"
    [ "$sdate" != "$today" ] && { steps=0; lastcol=""; }   # new day → reset
    [[ "$steps" =~ ^[0-9]+$ ]] || steps=0
fi

save() { printf '%s %s %s\n' "$today" "$steps" "$lastcol" > "$STATE"; }

render() {
    if [ "$steps" -ge "$STEPS_PER_RI" ]; then
        awk -v i="$ICON" -v s="$steps" -v r="$STEPS_PER_RI" -v u="$RI" \
            'BEGIN{ printf "%s %.1f %s\n", i, s/r, u }'
    else
        printf '%s %s %s\n' "$ICON" "$steps" "$HO"
    fi
}

curcol() { niri msg -j focused-window 2>/dev/null | jq -r '.layout.pos_in_scrolling_layout[0] // empty'; }

[ -z "$lastcol" ] && lastcol=$(curcol)
render

niri msg -j event-stream 2>/dev/null | while read -r line; do
    case "$line" in
        *WindowFocusChanged*|*WindowOpenedOrChanged*|*WorkspaceActivated*) ;;
        *) continue ;;
    esac
    t=$(date +%Y-%m-%d)
    [ "$t" != "$today" ] && { today=$t; steps=0; }          # midnight rollover
    col=$(curcol)
    [ -z "$col" ] && continue
    if [ -n "$lastcol" ] && [ "$col" != "$lastcol" ]; then
        if [ "$col" -gt "$lastcol" ]; then delta=$(( col - lastcol )); else delta=$(( lastcol - col )); fi
        steps=$(( steps + delta ))
    fi
    lastcol="$col"
    save
    render
done
