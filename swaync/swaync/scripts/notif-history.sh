#!/usr/bin/env bash
# notif-history.sh — mutate the walker notification scrollback.
#   remove <id>   delete one entry by id; the id "__ALL__" clears everything
set -euo pipefail

hist="${XDG_STATE_HOME:-$HOME/.local/state}/swaync/history.jsonl"
[ -f "$hist" ] || exit 0

case "${1:-}" in
    remove)
        id="${2:-}"
        [ -n "$id" ] || exit 0
        if [ "$id" = "__ALL__" ]; then
            : > "$hist"
        else
            tmp="$(mktemp)"
            jq -c --arg id "$id" 'select(.id != $id)' "$hist" > "$tmp" && mv "$tmp" "$hist"
        fi
        ;;
esac
