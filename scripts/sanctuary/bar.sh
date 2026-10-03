#!/usr/bin/env bash
# Mod+Shift+A — hide / show the bar, whichever bar is up.
#
#   Quickshell running  → its bar, over IPC (the shell keeps running)
#   fallback (waybar)   → waybar itself, started / stopped
#
# Starting and stopping the stacks is shell.sh's job; this only toggles.
#
# Two things the waybar half still has to get right:
#  1. Match waybar by exact process name. On NixOS the binary was wrapped (comm
#     `.waybar-wrapped`); on Fedora it is plain `waybar`. Wrong name = stacked bars.
#  2. SIGHUP: setsid, so a waybar started from a short-lived parent survives it.
set -uo pipefail

QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"
CFG="$HOME/.dotfiles/waybar/config.jsonc"
CSS="$HOME/.dotfiles/waybar/style.css"

if "$QS" running; then
  "$QS" call bar toggle >/dev/null
  exit 0
fi

if pgrep -x waybar >/dev/null 2>&1; then
  pkill -x waybar
  pkill -f '^swaync-client -swb$'   # the notification module's stream, orphaned by the kill
else
  setsid waybar -c "$CFG" -s "$CSS" >/dev/null 2>&1 </dev/null &
fi
