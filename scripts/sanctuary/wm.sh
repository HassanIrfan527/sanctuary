#!/usr/bin/env bash
# One door to "the compositor", so scripts don't talk to niri directly.
# niri sets $NIRI_SOCKET for everything it starts.
#
#   wm.sh name            niri | none
#   wm.sh monitors-off    power every screen down (idle.sh)
#   wm.sh monitors-on
#   wm.sh quit            leave the session (power.sh)
#   wm.sh focused-output  name of the screen with focus, e.g. DP-3
#   wm.sh focus-app ID    focus the first window with that app id; exit 1 if none
#   wm.sh focus-column N  focus the Nth column on this workspace (SUPER+N)
#   wm.sh overview        toggle the compositor's own overview
#   wm.sh reload          re-read the compositor config
set -uo pipefail

case "${1:-}" in
  name) if [ -n "${NIRI_SOCKET:-}" ]; then echo niri; else echo none; fi ;;

  monitors-off|monitors-on)
    niri msg action "power-${1#monitors-}-monitors" ;;

  quit)
    niri msg action quit --skip-confirmation ;;

  focused-output)
    niri msg -j focused-output 2>/dev/null | sed -n 's/.*"name":"\([^"]*\)".*/\1/p' ;;

  focus-app)
    app="${2:?app id}"
    id=$(niri msg -j windows | python3 -c 'import json,sys; print(next((str(w["id"]) for w in json.load(sys.stdin) if w["app_id"] == sys.argv[1]), ""))' "$app")
    [ -n "$id" ] || exit 1
    niri msg action focus-window --id "$id" ;;

  focus-column)
    niri msg action focus-column "${2:?column number}" ;;

  overview)
    niri msg action toggle-overview ;;

  reload)
    niri msg action load-config-file >/dev/null 2>&1 ;;

  *) sed -n '2,13p' "$0" >&2; exit 2 ;;
esac
