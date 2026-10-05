#!/usr/bin/env bash
# The desk's shell: Quickshell drawing the saved style (Signal unless you picked
# another), with the old waybar + swaync stack as the AUTOMATIC fallback.
#
#   shell.sh start          startup (niri spawns this): Quickshell, or fallback if it won't come up
#   shell.sh set <style>    switch style — the Mod+Shift+T picker calls this; survives reboots
#   shell.sh pick           Mod+Shift+T: the Quickshell picker — or, while in fallback, retry Quickshell
#   shell.sh fallback       stop Quickshell, bring up waybar + swaync
#   shell.sh status         "quickshell <style>" or "fallback"
#
# ── The rule ──────────────────────────────────────────────────────────
# Nothing here writes niri config or keybinds (2026-10-03). Window styling lives
# in three HAND-KEPT files, niri/niri/layout-{signal,ink,paper}.kdl; config.kdl
# includes `layout.kdl`, a symlink to the active one. A style switch re-points
# that symlink (validated first) and restarts Quickshell — it never writes a
# byte of config. The old per-mode renderer is in archive/mode-system/.
#
# ── When the fallback happens ─────────────────────────────────────────
#   1. Quickshell is missing, or does not answer within ~4s of starting.
#   2. Quickshell dies later (a crash). `watch` — started after every good start
#      — notices within ~4s and brings the fallback up, so the desk is never
#      left with no bar and nothing to receive notifications.
# A style switch kills Quickshell on purpose; the `switching` flag tells the
# watcher that this one is expected.
set -uo pipefail

DIR="$HOME/.dotfiles/scripts/sanctuary"
QS="$DIR/qs.sh"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
STYLE_FILE="$STATE/style"
SWITCHING="$STATE/qs.switching"
mkdir -p "$STATE"

# The fallback: the classic configs, exactly as they were.
WAYBAR_CFG="$HOME/.dotfiles/waybar/config.jsonc"
WAYBAR_CSS="$HOME/.dotfiles/waybar/style.css"
SWAYNC_THEME="$HOME/.dotfiles/swaync/swaync/themes/ascii"

# The password prompt (polkit agent). Quickshell is the agent while it runs
# (Polkit.qml); in the fallback, mate-polkit is. Only ONE agent may hold the
# session, so the swap happens with the rest of the stack: classic_down kills
# mate before Quickshell starts, classic_up starts it once Quickshell is gone.
POLKIT_MATE=/usr/libexec/polkit-mate-authentication-agent-1

saved_style() {
  local s=signal
  [ -s "$STYLE_FILE" ] && s=$(cat "$STYLE_FILE")
  "$QS" has "$s" || s=signal     # a stale / hand-edited file can't strand the desk
  printf '%s' "$s"
}

# ── window styling: point layout.kdl at the style's hand-kept file ────
NIRI_DIR="$HOME/.dotfiles/niri/niri"
point_layout() {                             # $1 = style
  local want="layout-$1.kdl" link="$NIRI_DIR/layout.kdl" prev
  [ -r "$NIRI_DIR/$want" ] || want="layout-signal.kdl"   # a style without its own file looks like Signal
  prev=$(readlink "$link" 2>/dev/null)
  [ "$prev" = "$want" ] && return 0
  ln -sfn "$want" "$link"
  # Validate the COMPOSED config before niri sees it; on failure put the old
  # link back (or Signal's, if there was none) and say so.
  if ! niri validate -c "$NIRI_DIR/config.kdl" >/dev/null 2>&1; then
    ln -sfn "${prev:-layout-signal.kdl}" "$link"
    notify-send -a sanctuary -u critical "[ layout ✗ $1 ]" \
      "niri/niri/$want failed niri validate — kept ${prev:-layout-signal.kdl}" 2>/dev/null
    return 1
  fi
  niri msg action load-config-file >/dev/null 2>&1
}

# ── the classic stack ─────────────────────────────────────────────────
classic_down() {
  pkill -f "^$POLKIT_MATE" 2>/dev/null
  pkill -x waybar
  pkill -f '^swaync-client -swb$'           # waybar's notification module, orphaned
  pgrep -x swaync >/dev/null 2>&1 || return 0
  pkill -x swaync
  local _
  for _ in $(seq 1 30); do                  # the bus name is free only once it has exited
    pgrep -x swaync >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  pkill -9 -x swaync
}

classic_up() {
  trap '' HUP
  pgrep -x swaync >/dev/null 2>&1 \
    || setsid swaync -c "$SWAYNC_THEME/config.json" -s "$SWAYNC_THEME/style.css" \
         >/dev/null 2>&1 </dev/null &
  pgrep -x waybar >/dev/null 2>&1 \
    || setsid waybar -c "$WAYBAR_CFG" -s "$WAYBAR_CSS" >/dev/null 2>&1 </dev/null &
  if [ -x "$POLKIT_MATE" ] && ! pgrep -f "^$POLKIT_MATE" >/dev/null 2>&1; then
    setsid "$POLKIT_MATE" >/dev/null 2>&1 </dev/null &
  fi
}

fallback() {
  local why=${1:-"switched by hand"}
  rm -f "$SWITCHING"
  "$QS" stop
  classic_up
  sleep 0.6                                  # let swaync claim the bus before we toast
  notify-send -a sanctuary -u critical -r 9414 "[ fallback ▸ waybar ]" \
    "$why — Mod+Shift+T retries Quickshell. Log: ~/.local/state/sanctuary/qs.log" 2>/dev/null
}

# ── Quickshell ────────────────────────────────────────────────────────
watch() {
  # One watcher at a time, whoever started it.
  exec 9>"$STATE/watch.lock"
  flock -n 9 || exit 0
  local misses=0
  while :; do
    sleep 2
    if "$QS" running; then misses=0; continue; fi
    # Down WHILE LOCKED (Lock.qml's flag is up): niri is showing its red locked
    # screen. Hand the lock to swaylock at once — don't wait for a second miss.
    if [ -e "${XDG_RUNTIME_DIR:-/tmp}/sanctuary-lock" ] && ! pgrep -x swaylock >/dev/null 2>&1; then
      ( trap '' HUP; setsid "$DIR/lock.sh" takeover >/dev/null 2>&1 </dev/null & )
    fi
    # Down. Expected if a switch is mid-restart (flag younger than 15s).
    if [ -e "$SWITCHING" ] && [ $(( $(date +%s) - $(stat -c %Y "$SWITCHING") )) -lt 15 ]; then
      continue
    fi
    misses=$((misses + 1))
    if [ "$misses" -ge 2 ]; then              # down on two checks in a row: not a blip
      pgrep -x waybar >/dev/null 2>&1 || fallback "Quickshell exited"
      exit 0
    fi
  done
}

start_watch() {
  trap '' HUP
  setsid "$0" watch >/dev/null 2>&1 </dev/null &
}

up() {                                       # $1 = style
  point_layout "$1"                          # windows first: instant, and independent of Quickshell
  touch "$SWITCHING"
  classic_down                               # no-op unless we are leaving the fallback
  if "$QS" start "$1"; then
    rm -f "$SWITCHING"
    start_watch
    return 0
  fi
  fallback "Quickshell ($1) did not start"
  return 1
}

set_style() {
  local s=$1
  if ! "$QS" has "$s"; then
    notify-send -a sanctuary -u critical "[ style ✗ $s ]" \
      "no such style — have: $("$QS" styles | paste -sd' ')" 2>/dev/null
    return 1
  fi
  printf '%s\n' "$s" > "$STYLE_FILE"
  up "$s"
}

pick() {
  if "$QS" running; then
    "$QS" call picker toggle >/dev/null
  else
    up "$(saved_style)"                      # in fallback: Mod+Shift+T = try again
  fi
}

status() {
  if "$QS" running; then printf 'quickshell %s\n' "$(saved_style)"; else printf 'fallback\n'; fi
}

case "${1:-}" in
  start)    up "$(saved_style)" ;;
  set)      set_style "${2:?shell.sh set <style>}" ;;
  pick)     pick ;;
  fallback) fallback ;;
  watch)    watch ;;
  status)   status ;;
  *)        printf 'usage: shell.sh start|set <style>|pick|fallback|status\n' >&2; exit 2 ;;
esac
