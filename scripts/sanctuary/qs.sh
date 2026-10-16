#!/usr/bin/env bash
# Quickshell — the bar + toasts + notification centre for the QS modes, as one
# process. shell.sh is the only thing that should start or stop it.
#
#   qs.sh start <style>   (re)start Quickshell drawing <style>; waits until it answers
#   qs.sh stop            stop it, and wait until it is really gone
#   qs.sh running         exit 0 if it is up
#   qs.sh call <target> <function> [args…]    IPC, e.g. `qs.sh call notifs toggle`
#   qs.sh styles          list the styles this config can draw
#   qs.sh has <style>     exit 0 if <style> is one of them
#   qs.sh kit <style>     point quickshell/sanctuary/kit at that style's kit (start does this)
#   qs.sh log             follow the running instance's log
#
# ── Why the waiting matters ───────────────────────────────────────────
# Quickshell is also the notification daemon in these modes, and only ONE
# process may own org.freedesktop.Notifications. So:
#   start: swaync must be gone first (shell.sh does that), and we wait for the
#          shell to answer IPC before returning, so anything sent right after
#          lands in Quickshell and not in the void.
#   stop:  wait until the process has exited, so the swaync started right after
#          can claim the name.
#
# ── Adding a style ────────────────────────────────────────────────────
# A style is a kit: quickshell/sanctuary/kits/<word>/ (DESIGN-SYSTEM.md §4),
# plus its palette in Theme.qml. `styles` lists every kit, plus the VARIANTS
# below (a base style's kit, a different palette in Theme.qml).
set -uo pipefail

QS_DIR="$HOME/.dotfiles/quickshell/sanctuary"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
LOG="$STATE/qs.log"
mkdir -p "$STATE"

QS_BIN=$(command -v qs || command -v quickshell || true)

# The daemon's command line is exactly `<qs> -p <dir>` — nothing after it. IPC
# calls are `<qs> ipc -p <dir> …`, so anchoring the pattern at both ends matches
# the daemon and never a client that happens to be running at the same moment.
PATTERN="^[^ ]*(qs|quickshell) -p $QS_DIR\$"

running() { pgrep -f "$PATTERN" >/dev/null 2>&1; }

need_qs() {
  [ -n "$QS_BIN" ] && return 0
  printf 'qs.sh: quickshell is not installed\n' >&2
  notify-send -a sanctuary -u critical "[ quickshell missing ]" \
    "install it first — see quickshell/README.md" 2>/dev/null
  return 1
}

# Variants: a second printing of an existing style, palette chosen inside
# Theme.qml. `word:base` — the word is valid only if kits/<base>/ exists.
VARIANTS=(flare:signal)

# The kit: quickshell/sanctuary/kit is a (git-ignored) symlink to kits/<style>/,
# the drawing parts every module imports (DESIGN-SYSTEM.md §4). A variant draws
# with its base's kit (flare → signal); a style with no kit draws with Signal's.
kit_of() {                                   # $1 = style word → kit name
  local v
  for v in "${VARIANTS[@]}"; do
    [ "${v%%:*}" = "$1" ] && { printf '%s\n' "${v#*:}"; return; }
  done
  printf '%s\n' "$1"
}
point_kit() {                                # $1 = style word
  local k
  k=$(kit_of "$1")
  [ -d "$QS_DIR/kits/$k" ] || k=signal
  [ "$(readlink "$QS_DIR/kit" 2>/dev/null)" = "kits/$k" ] || ln -sfn "kits/$k" "$QS_DIR/kit"
}

styles() {
  local d v
  for d in "$QS_DIR"/kits/*/; do
    [ -d "$d" ] || continue
    basename "$d"
  done
  for v in "${VARIANTS[@]}"; do
    [ -d "$QS_DIR/kits/${v#*:}" ] && printf '%s\n' "${v%%:*}"
  done
}

# Is $1 a style? Compared against the whole list in a variable, NOT with
# `styles | grep -q`: grep -q exits on the first match, the still-writing
# `styles` takes a SIGPIPE, and under pipefail the pipeline fails (141) — so
# the check failed precisely when the style WAS there.
has_style() {
  local all
  all=" $(styles | tr '\n' ' ') "
  [[ "$all" == *" $1 "* ]]
}

call() {
  [ -n "$QS_BIN" ] || return 1
  timeout 2 "$QS_BIN" ipc -p "$QS_DIR" call "$@" 2>/dev/null
}

stop() {
  running || return 0
  pkill -f "$PATTERN"
  local i
  for i in $(seq 1 30); do          # ≤3s for a clean exit
    running || return 0
    sleep 0.1
  done
  pkill -9 -f "$PATTERN"
  sleep 0.1
}

start() {
  local style=$1
  need_qs || return 1
  if ! has_style "$style"; then
    printf 'qs.sh: no such style: %s (have: %s)\n' "$style" "$(styles | paste -sd' ')" >&2
    return 1
  fi
  stop
  point_kit "$style"
  # setsid + ignored HUP: whatever started us (niri, the picker's detached
  # process) may be gone a moment later; Quickshell must not go with it.
  trap '' HUP
  SANCTUARY_QS="$style" setsid env -u QT_QPA_PLATFORMTHEME "$QS_BIN" -p "$QS_DIR" >"$LOG" 2>&1 </dev/null &
  local i
  for i in $(seq 1 40); do          # ≤4s for the shell to come up and answer
    case "$(call notifs ping)" in pong*) return 0 ;; esac
    running || break                # died during startup: stop waiting
    sleep 0.1
  done
  printf 'qs.sh: quickshell did not come up — see %s\n' "$LOG" >&2
  return 1
}

case "${1:-}" in
  start)   start "${2:?qs.sh start <style>}" ;;
  stop)    stop ;;
  running) running ;;
  call)    shift; call "$@" ;;
  styles)  styles ;;
  has)     has_style "${2:?qs.sh has <style>}" ;;
  kit)     point_kit "${2:?qs.sh kit <style>}"; readlink "$QS_DIR/kit" ;;
  log)     need_qs && exec "$QS_BIN" log -p "$QS_DIR" -f ;;
  *)       printf 'usage: qs.sh start <style>|stop|running|call <target> <fn> [args]|styles|log\n' >&2
           exit 2 ;;
esac
