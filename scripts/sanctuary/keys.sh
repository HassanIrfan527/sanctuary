#!/usr/bin/env bash
# Mod+/ — KEYS, the keybind cheat sheet.
#
#   Quickshell up    → its card (quickshell/sanctuary/KeySheet.qml), drawn in the
#                      current style; the words live in Keymap.qml
#   fallback         → niri's own hotkey overlay (unstyled, but always there)
set -uo pipefail

QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"

if "$QS" running; then
  "$QS" call keys toggle >/dev/null
else
  niri msg action show-hotkey-overlay
fi
