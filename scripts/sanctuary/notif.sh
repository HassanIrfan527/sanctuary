#!/usr/bin/env bash
# Notification keybinds, routed to whichever daemon the current mode runs:
# swaync in Default / Zen, Quickshell in the QS modes. The binds in binds.kdl
# call this instead of swaync-client, so they work in every mode.
#
#   notif.sh centre   open / close the notification centre   (Mod+Shift+D)
#   notif.sh clear    dismiss everything                     (Mod+Ctrl+D)
#   notif.sh dnd      toggle do-not-disturb                  (Mod+Alt+D)
set -uo pipefail

QS="$HOME/.dotfiles/scripts/sanctuary/qs.sh"

if "$QS" running; then
  case "${1:-}" in
    centre) "$QS" call notifs toggle ;;
    clear)  "$QS" call notifs clear ;;
    dnd)    "$QS" call notifs dnd ;;
    *)      printf 'usage: notif.sh centre|clear|dnd\n' >&2; exit 2 ;;
  esac
else
  case "${1:-}" in
    centre) timeout 2 swaync-client -t ;;
    clear)  timeout 2 swaync-client -C ;;
    dnd)    timeout 2 swaync-client -d ;;
    *)      printf 'usage: notif.sh centre|clear|dnd\n' >&2; exit 2 ;;
  esac
fi >/dev/null 2>&1
