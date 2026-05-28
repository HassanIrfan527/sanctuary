#!/usr/bin/env bash
# Run a Pomodoro session: 4 cycles of 25min study + 5min break.
# Study mode is forced ON during study, OFF (force-off, no friction) during break.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="$SCRIPT_DIR/study-mode.sh"
STATE_DIR="$HOME/.cache/study-mode"
PIDFILE="$STATE_DIR/pomodoro.pid"

mkdir -p "$STATE_DIR"

CYCLES=${POMODORO_CYCLES:-4}
STUDY_MIN=${POMODORO_STUDY:-25}
BREAK_MIN=${POMODORO_BREAK:-5}

notify() { command -v notify-send >/dev/null && notify-send -a "pomodoro" "$1" "${2:-}" || true; }

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    notify "Pomodoro" "A session is already running (PID $(cat "$PIDFILE")). Cancel it first: kill $(cat "$PIDFILE")"
    exit 1
fi

echo $$ > "$PIDFILE"
trap '"$MODE" force-off >/dev/null 2>&1; rm -f "$PIDFILE"' EXIT INT TERM

for i in $(seq 1 "$CYCLES"); do
    notify "Pomodoro $i/$CYCLES" "Study block: ${STUDY_MIN} min. Begin."
    "$MODE" on >/dev/null 2>&1 || true
    sleep $((STUDY_MIN * 60))

    if [[ $i -lt $CYCLES ]]; then
        notify "Pomodoro $i/$CYCLES done" "Break: ${BREAK_MIN} min. Stand up. Water."
        "$MODE" force-off >/dev/null 2>&1 || true
        sleep $((BREAK_MIN * 60))
    fi
done

"$MODE" force-off >/dev/null 2>&1 || true
notify "Pomodoro complete" "$CYCLES cycles done. Today's 2 hours: in the bank."
rm -f "$PIDFILE"
