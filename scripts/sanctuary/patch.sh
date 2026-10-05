#!/usr/bin/env bash
# Mod+O — PATCH, the audio input/output switcher.
#
#   Quickshell up    → its card (quickshell/sanctuary/Patch.qml), drawn in the
#                      current style: pick the default output / input, volume, mute
#   fallback         → wiremix in a floating kitty (the Mod+Alt+M mixer), which
#                      can set defaults too
set -uo pipefail

QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"

if "$QS" running; then
  "$QS" call patch toggle >/dev/null
else
  setsid kitty --class sanctuary-mixer -e wiremix >/dev/null 2>&1 </dev/null &
fi
