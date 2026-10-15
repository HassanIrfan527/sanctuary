#!/usr/bin/env bash
# Mod+C — COMMS, Discord voice (Quickshell card, quickshell/sanctuary/CommsCard.qml).
#
#   Quickshell up    → the card: M mute · D deafen · X leave · F Vesktop
#   fallback         → just focus Vesktop's window (or start it)
set -uo pipefail

QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"

if "$QS" running; then
  "$QS" call comms toggle >/dev/null
else
  "$HOME/.dotfiles/scripts/sanctuary/wm.sh" focus-app vesktop ||
    setsid vesktop >/dev/null 2>&1 </dev/null &
fi
