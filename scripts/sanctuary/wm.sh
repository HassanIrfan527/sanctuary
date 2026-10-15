#!/usr/bin/env bash
# One door to "the compositor", so scripts don't care which one is running.
# niri sets $NIRI_SOCKET for everything it starts; Mango sets
# $MANGO_INSTANCE_SIGNATURE. Each verb below does the same thing on both.
#
#   wm.sh name            niri | mango | none
#   wm.sh monitors-off    power every screen down (idle.sh)
#   wm.sh monitors-on
#   wm.sh quit            leave the session (power.sh)
#   wm.sh focused-output  name of the screen with focus, e.g. DP-3
#   wm.sh focus-app ID    focus the first window with that app id; exit 1 if none
#   wm.sh focus-column N  focus the Nth column on this workspace / tag (SUPER+N)
#   wm.sh overview        toggle the compositor's own overview
#   wm.sh reload          re-read the compositor config
set -uo pipefail

name() {
  if [ -n "${MANGO_INSTANCE_SIGNATURE:-}" ]; then echo mango
  elif [ -n "${NIRI_SOCKET:-}" ]; then echo niri
  else echo none
  fi
}

# Mango: names of all monitors, one per line.
mango_monitors() {
  mmsg get all-monitors | python3 -c 'import json,sys; [print(m["name"]) for m in json.load(sys.stdin)["monitors"]]'
}

wm=$(name)
case "${1:-}" in
  name) echo "$wm" ;;

  monitors-off|monitors-on)
    if [ "$wm" = mango ]; then
      act=sleep_monitor; [ "$1" = monitors-on ] && act=wakeup_monitor
      for m in $(mango_monitors); do mmsg dispatch "$act,$m" >/dev/null; done
    else
      niri msg action "power-${1#monitors-}-monitors"
    fi ;;

  quit)
    if [ "$wm" = mango ]; then
      "$HOME/.dotfiles/scripts/sanctuary/mango-session.sh" stop
      mmsg dispatch quit
    else
      niri msg action quit --skip-confirmation
    fi ;;

  focused-output)
    if [ "$wm" = mango ]; then
      mmsg get focusing-client | python3 -c 'import json,sys; print(json.load(sys.stdin).get("monitor") or "")'
    else
      niri msg -j focused-output 2>/dev/null | sed -n 's/.*"name":"\([^"]*\)".*/\1/p'
    fi ;;

  focus-app)
    app="${2:?app id}"
    if [ "$wm" = mango ]; then
      id=$(mmsg get all-clients | python3 -c 'import json,sys; print(next((str(c["id"]) for c in json.load(sys.stdin)["clients"] if c["appid"] == sys.argv[1]), ""))' "$app")
      [ -n "$id" ] || exit 1
      # the window may sit on another tag: show that tag first, then focus it
      tag=$(mmsg get client "$id" | python3 -c 'import json,sys; t=json.load(sys.stdin).get("tags") or []; print(t[0] if t else "")')
      [ -n "$tag" ] && mmsg dispatch "view,$tag" >/dev/null
      mmsg dispatch focusid "client,$id" >/dev/null
    else
      id=$(niri msg -j windows | python3 -c 'import json,sys; print(next((str(w["id"]) for w in json.load(sys.stdin) if w["app_id"] == sys.argv[1]), ""))' "$app")
      [ -n "$id" ] || exit 1
      niri msg action focus-window --id "$id"
    fi ;;

  focus-column)
    n="${2:?column number}"
    if [ "$wm" = mango ]; then
      # Mango has no "Nth column": count them here. Visible tiled windows on
      # the focused monitor, grouped by x (a stack shares one x), left to
      # right; the top window of column N gets focus. Same counting as
      # Mango.qml's columnsOf, so the column strip shows the same numbers.
      mon=$(mmsg get focusing-client | python3 -c 'import json,sys; print(json.load(sys.stdin).get("monitor") or "")')
      id=$(mmsg get all-clients | python3 -c '
import json, sys
n, mon = int(sys.argv[1]), sys.argv[2]
cols = {}
for c in json.load(sys.stdin)["clients"]:
    if c["is_visible"] and not c["is_floating"] and not c["is_minimized"] and (not mon or c["monitor"] == mon):
        cols.setdefault(c["x"], []).append(c)
xs = sorted(cols)
if 1 <= n <= len(xs):
    print(min(cols[xs[n - 1]], key=lambda c: c["y"])["id"])
' "$n" "$mon")
      [ -n "$id" ] || exit 1
      mmsg dispatch focusid "client,$id" >/dev/null
    else
      niri msg action focus-column "$n"
    fi ;;

  overview)
    if [ "$wm" = mango ]; then mmsg dispatch toggleoverview >/dev/null
    else niri msg action toggle-overview
    fi ;;

  reload)
    if [ "$wm" = mango ]; then mmsg dispatch reload_config >/dev/null
    else niri msg action load-config-file >/dev/null 2>&1
    fi ;;

  *) sed -n '2,16p' "$0" >&2; exit 2 ;;
esac
