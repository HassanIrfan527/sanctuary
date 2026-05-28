#!/usr/bin/env bash
set -euo pipefail

sink=$(pactl get-default-sink)

mapfile -t entries < <(
  pactl -f json list sinks 2>/dev/null \
    | jq -r --arg s "$sink" '
        .[] | select(.name == $s) as $cur
        | $cur.ports[]
        | "\(.name)\t\(.description)\t\(.availability)\t\($cur.active_port)"
      '
)

[[ ${#entries[@]} -eq 0 ]] && { notify-send "Audio" "No ports on sink $sink"; exit 1; }

menu=""
for e in "${entries[@]}"; do
  IFS=$'\t' read -r pname pdesc avail active <<<"$e"
  marker="  "
  [[ "$pname" == "$active" ]] && marker="* "
  tag=""
  [[ "$avail" == "not available" ]] && tag="  (unavailable)"
  menu+="${marker}${pdesc}${tag}"$'\t'"${pname}"$'\n'
done

choice=$(printf '%s' "$menu" | cut -f1 | fuzzel --dmenu --prompt "Output port: ")
[[ -z "$choice" ]] && exit 0

port=$(printf '%s' "$menu" | awk -F'\t' -v c="$choice" '$1==c {print $2; exit}')
[[ -z "$port" ]] && exit 1

pactl set-sink-port "$sink" "$port"
notify-send "Audio output" "${choice# * }"
