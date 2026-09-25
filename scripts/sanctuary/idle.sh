#!/usr/bin/env bash
# Idle chain: lock at 30 min, screens off at 45, and honour logind's Lock
# signal so Mod+Escape and suspend land in the same locker.
#
# Lives in a script rather than inline in startup.kdl because KDL strings take
# no backslash line-continuations — the whole thing would be one unreadable line.
set -uo pipefail
LOCK="$HOME/.dotfiles/scripts/sanctuary/lock.sh"
pkill -x swayidle 2>/dev/null

exec swayidle -w \
  timeout 1800 "$LOCK" \
  timeout 2700 'niri msg action power-off-monitors' \
  resume       'niri msg action power-on-monitors' \
  before-sleep "$LOCK" \
  lock         "$LOCK"
