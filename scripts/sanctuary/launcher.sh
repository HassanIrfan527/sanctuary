#!/usr/bin/env bash
# Mod+Space — the app launcher.
#
#   Quickshell up    → its launcher (quickshell/sanctuary/Launcher.qml), drawn
#                      in the current style; opens instantly, it is already running
#   fallback         → fsel in a floating kitty, exactly as before — the backup.
#                      `-d` detaches what it launches, or apps die with the kitty.
set -uo pipefail

QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"

if "$QS" running; then
  "$QS" call launcher toggle >/dev/null
else
  setsid kitty --class sanctuary-run -e fsel -d >/dev/null 2>&1 </dev/null &
fi
