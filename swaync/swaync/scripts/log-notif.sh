#!/usr/bin/env bash
# log-notif.sh — append every notification to a JSONL scrollback that the
# walker "*" inbox reads. Run by swaync's `scripts` hook on receive.
set -euo pipefail

hist="${XDG_STATE_HOME:-$HOME/.local/state}/swaync/history.jsonl"
mkdir -p "$(dirname "$hist")"

jq -nc \
    --arg id "$(date +%s%N)" \
    --argjson ts "$(date +%s)" \
    --arg app "${SWAYNC_APP_NAME:-}" \
    --arg summary "${SWAYNC_SUMMARY:-}" \
    --arg body "${SWAYNC_BODY:-}" \
    --arg urgency "${SWAYNC_URGENCY:-}" \
    --arg desktop "${SWAYNC_DESKTOP_ENTRY:-}" \
    '{id:$id, ts:$ts, app:$app, summary:$summary, body:$body, urgency:$urgency, desktop:$desktop}' \
    >> "$hist"

# keep the last 200 only
tmp="$(mktemp)"
tail -n 200 "$hist" > "$tmp" && mv "$tmp" "$hist"

# cozy chime — skip while do-not-disturb is on. Drop any file named
# notif.* (mp3/ogg/wav/flac) into ~/.config/swaync/sounds/ to change it.
sound="$(ls "$HOME/.config/swaync/sounds/"notif.* 2>/dev/null | head -n1)"
if [ -n "$sound" ] && [ "$(swaync-client -D 2>/dev/null)" != "true" ]; then
    setsid -f pw-play --volume=0.55 "$sound" >/dev/null 2>&1 || true
fi
