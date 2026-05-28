#!/usr/bin/env bash
set -euo pipefail

# ── notification center via fuzzel ──
# triggered by the bell capsule in waybar (and Super+N-style binds)

count=$(makoctl list 2>/dev/null | grep -c '^Notification ' || true)
mode=$(makoctl mode 2>/dev/null | head -1)

dnd_label="dnd: off"
[[ "$mode" == "do-not-disturb" ]] && dnd_label="dnd: on"

pick=$(printf '%s\n' \
    "  dismiss all          | makoctl dismiss --all" \
    "  restore last         | makoctl restore" \
    " 󰀝 toggle $dnd_label   | makoctl mode -t do-not-disturb" \
    "  unread: $count       | true" \
    "  session…             | ~/.config/hypr/scripts/session-fuzzel.sh" \
    | fuzzel --dmenu --prompt "  > " --width 32 --lines 5) || exit 0

[[ -z "$pick" ]] && exit 0

cmd=${pick#*|}
cmd=${cmd# }
eval "$cmd"
