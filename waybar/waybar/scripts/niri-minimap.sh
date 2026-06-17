#!/usr/bin/env bash
# ── waybar custom module: niri column minimap ──────────────────────────
# Shows where you are in niri's infinite scrolling column strip:
#     · · ● · ·     (● = focused column, dots = open columns in this workspace)
# Continuous module: prints a fresh line on every niri focus/layout event.
# Under anything other than a running niri it prints nothing → module hides.

command -v niri >/dev/null 2>&1 || exit 0
niri msg version >/dev/null 2>&1 || exit 0   # niri not running → bail quietly

# single instance — waybar restarts can otherwise leave orphan event-stream tailers
for p in $(pgrep -f "niri-minimap\.sh" 2>/dev/null); do
    [ "$p" != "$$" ] && kill "$p" 2>/dev/null
done

ON=$(printf '●')   # ●  focused column
OFF=$(printf '·')  # ·  other column

render() {
    local active
    active=$(niri msg -j workspaces 2>/dev/null | jq -r '[.[] | select(.is_active)][0].id // empty')
    [ -z "$active" ] && { echo ""; return; }

    niri msg -j windows 2>/dev/null | jq -r \
        --argjson ws "$active" --arg on "$ON" --arg off "$OFF" '
        [ .[]
          | select(.workspace_id == $ws)
          | select(.is_floating | not)
          | select(.layout.pos_in_scrolling_layout != null)
        ] as $w
        | ( [ $w[].layout.pos_in_scrolling_layout[0] ] | unique ) as $cols
        | ( [ $w[] | select(.is_focused) | .layout.pos_in_scrolling_layout[0] ][0] ) as $cur
        | if ($cols | length) == 0 then ""
          else ( [ $cols[] | if . == $cur then $on else $off end ] | join(" ") )
          end
    '
}

render
niri msg -j event-stream 2>/dev/null | while read -r line; do
    case "$line" in
        *Window*|*Workspace*) render ;;
    esac
done
