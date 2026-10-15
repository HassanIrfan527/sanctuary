#!/usr/bin/env bash
# Idle chain: lock at 30 min, screens off at 45, and honour logind's Lock
# signal so Mod+Escape and suspend land in the same locker.
#
# awake.py runs alongside: it holds the idle timer off while a controller is
# in use or media is playing — niri can't see gamepads, so without it a long
# controller session (or a film) gets locked at 30 min.
#
# Lives in a script rather than inline in startup.kdl because KDL strings take
# no backslash line-continuations — the whole thing would be one unreadable line.
set -uo pipefail
LOCK="$HOME/.dotfiles/scripts/sanctuary/lock.sh"
WM="$HOME/.dotfiles/scripts/sanctuary/wm.sh"   # niri or Mango, whichever is running
pkill -x swayidle 2>/dev/null
pkill -f "^python3 $HOME/.dotfiles/scripts/sanctuary/awake.py" 2>/dev/null

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
mkdir -p "$STATE"
"$HOME/.dotfiles/scripts/sanctuary/awake.py" >"$STATE/awake.log" 2>&1 &

exec swayidle -w \
  timeout 1800 "$LOCK" \
  timeout 2700 "$WM monitors-off" \
  resume       "$WM monitors-on" \
  before-sleep "$LOCK" \
  lock         "$LOCK"
