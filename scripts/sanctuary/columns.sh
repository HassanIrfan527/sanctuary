#!/usr/bin/env bash
# Mod+Grave — the column strip (quickshell/sanctuary/Columns.qml): what
# Mod+1..9 points at on this workspace, held open to pick from.
#
# Fallback (Quickshell down): niri's overview.
set -uo pipefail

QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"

if "$QS" running; then
  "$QS" call columns toggle >/dev/null
else
  niri msg action toggle-overview
fi
