#!/usr/bin/env bash
# Window jump (walker dmenu): list open windows, focus the chosen one.
#   Random-access counterpart to directional Super+hjkl focus.
set -euo pipefail

SEP=" │ "

mapfile -t rows < <(hyprctl clients -j | jq -r '
    [ .[] | select(.mapped == true) ]
    | sort_by(.workspace.id, .class)
    | .[]
    | "\(.address)\t\(.workspace.name)\t\(.class)\t\(.title)"
')

[[ ${#rows[@]} -eq 0 ]] && exit 0

addrs=()
labels=()
for r in "${rows[@]}"; do
    IFS=$'\t' read -r addr ws cls title <<<"$r"
    [[ ${#title} -gt 60 ]] && title="${title:0:57}…"
    [[ -z "$title" ]] && title="$cls"
    addrs+=("$addr")
    labels+=("🪟${SEP}${ws}${SEP}${cls}${SEP}${title}")
done

idx=$(printf '%s\n' "${labels[@]}" | walker --dmenu -i -p "jump") || exit 0
[[ -z "$idx" ]] && exit 0

addr="${addrs[$idx]:-}"
[[ -z "$addr" ]] && exit 0

hyprctl dispatch focuswindow "address:$addr" >/dev/null
