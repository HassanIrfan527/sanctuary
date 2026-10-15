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
  # niri has a built-in overlay; Mango doesn't, so say where the list lives
  if [ "$("$HOME/.dotfiles/scripts/sanctuary/wm.sh" name)" = niri ]; then
    niri msg action show-hotkey-overlay
  else
    notify-send -a sanctuary "[ keys ]" "Quickshell is down — binds are in ~/.config/mango/binds.conf"
  fi
fi
