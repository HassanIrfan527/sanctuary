#!/usr/bin/env bash
# The locker. Reached via `loginctl lock-session`, which swayidle's `lock`
# handler runs — that is the correct chain, so screen-lock also fires on suspend
# and on idle without a second code path.
#
#   lock.sh            Quickshell's lock (Lock.qml, Signal face) if Quickshell is
#                      up; swaylock otherwise. Returns once the session IS locked
#                      (swayidle's before-sleep waits on that).
#   lock.sh swaylock   swaylock, no questions
#   lock.sh rescue     Mod+Alt+Escape, works ON the lock screen: the Quickshell
#                      lock is broken or the screen is red → stop Quickshell,
#                      swaylock takes the lock over
#   lock.sh takeover   shell.sh's watcher, when Quickshell dies while locked
#
# ── Why this is safe ──────────────────────────────────────────────────
# Both lockers use ext-session-lock: niri keeps the session locked until the
# locker that holds it says the password was right. A locker that dies leaves
# niri's red "locked" screen — never an open desktop — and niri lets a new
# locker take over (niri FAQ, "dead screen locker"). So rescue/takeover only
# ever swap one locker for another; neither can unlock anything.
#
# $XDG_RUNTIME_DIR/sanctuary-lock exists while a Quickshell lock is up (removed
# by Lock.qml on unlock): it is how the watcher knows a dead Quickshell means a
# dead LOCK, not just a dead bar.
set -uo pipefail

DIR="$HOME/.dotfiles/scripts/sanctuary"
QS="$DIR/qs.sh"
FLAG="${XDG_RUNTIME_DIR:-/tmp}/sanctuary-lock"

# The old look, kept for the fallback: square, monospace, Mocha, one field.
SWAYLOCK=(swaylock
  --ignore-empty-password
  --show-failed-attempts
  --indicator-radius 52
  --indicator-thickness 2
  --ring-color 45475a
  --ring-ver-color b4befe
  --ring-wrong-color f38ba8
  --ring-clear-color fab387
  --inside-color 11111b
  --inside-ver-color 11111b
  --inside-wrong-color 11111b
  --inside-clear-color 11111b
  --key-hl-color cba6f7
  --bs-hl-color f38ba8
  --separator-color 00000000
  --text-color cdd6f4
  --text-ver-color b4befe
  --text-wrong-color f38ba8
  --text-clear-color fab387
  --line-color 00000000
  --line-ver-color 00000000
  --line-wrong-color 00000000
  --line-clear-color 00000000
  --font "JetBrainsMono Nerd Font"
  --font-size 12
  --color 11111b)

# A normal lock: blurred screenshot, fade in, returns once locked.
swaylock_daemon() {
  rm -f "$FLAG"
  exec "${SWAYLOCK[@]}" --daemonize --screenshots --effect-blur 7x3 \
       --effect-vignette 0.4:0.4 --fade-in 0.16
}

# Taking over a dead lock: foreground, so the flag is cleared only after the
# unlock — a later Quickshell crash is then not mistaken for a dead lock.
swaylock_takeover() {
  pgrep -x swaylock >/dev/null 2>&1 && exit 0
  "${SWAYLOCK[@]}"
  rm -f "$FLAG"
}

qs_lock() {
  "$QS" running || return 1
  touch "$FLAG"
  "$QS" call lock lock >/dev/null 2>&1 || return 1
  local _
  for _ in $(seq 30); do                   # up to 3s for niri to confirm
    [ "$("$QS" call lock secure 2>/dev/null)" = true ] && return 0
    sleep 0.1
  done
  return 1
}

case "${1:-}" in
  swaylock)
    swaylock_daemon ;;
  rescue)
    touch "$FLAG"
    "$QS" stop                             # shell.sh's watcher brings waybar up
    swaylock_takeover ;;
  takeover)
    swaylock_takeover ;;
  *)
    qs_lock && exit 0
    # Quickshell down, or its lock did not take: swaylock. Should Quickshell's
    # lock come up late anyway, swaylock just fails to lock — the session is
    # locked either way, and Mod+Alt+Escape is the way out of a broken one.
    swaylock_daemon ;;
esac
