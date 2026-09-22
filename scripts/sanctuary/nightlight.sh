#!/usr/bin/env bash
# Night light — manual, always on, adjusted by keybind.
#
# wl-gammarelay-rs, not wlsunset. wlsunset is a *scheduler*: it interpolates
# between two temperatures across sunrise and sunset and exposes no way to say
# "make it warmer now". wl-gammarelay-rs is the opposite — a daemon that just
# holds a temperature, with a DBus property you can set at any moment. That is
# exactly "manual all the time".
#
#   nightlight.sh start          daemon up, last temperature restored
#   nightlight.sh warmer [step]  lower the temperature (more filter)
#   nightlight.sh cooler [step]  raise it (less filter)
#   nightlight.sh set <kelvin>
#   nightlight.sh reset          back to 6500K — no filter
#   nightlight.sh get            print the current value
set -uo pipefail

DEST=rs.wl-gammarelay
PATH_=/
IFACE=rs.wl.gammarelay

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
SAVED="$STATE/nightlight"
mkdir -p "$STATE"

STEP_DEFAULT=300
# 6500K is neutral daylight — anything higher is blue-shifted, which is the
# opposite of a night light. 1500K is about as orange as a screen gets.
MIN=1500
MAX=6500
DEFAULT=4500

running() { pgrep -x wl-gammarelay-rs >/dev/null 2>&1; }

get() {
  busctl --user get-property "$DEST" "$PATH_" "$IFACE" Temperature 2>/dev/null \
    | awk '{print $2}'
}

set_temp() {
  local t=$1
  [ "$t" -lt "$MIN" ] && t=$MIN
  [ "$t" -gt "$MAX" ] && t=$MAX
  busctl --user set-property "$DEST" "$PATH_" "$IFACE" Temperature q "$t" 2>/dev/null || return 1
  printf '%s\n' "$t" > "$SAVED"
  printf '%s' "$t"
}

# The bar has no night-light module, so the notification IS the readout.
# A fixed replaces-id means repeated presses update one toast instead of
# stacking a column of them.
announce() {
  local t=$1 cells=7 filled
  filled=$(( ((t - MIN) * cells + (MAX - MIN) / 2) / (MAX - MIN) ))
  [ "$filled" -lt 0 ] && filled=0
  [ "$filled" -gt "$cells" ] && filled=$cells
  local meter="" i
  for ((i = 0; i < cells; i++)); do
    if [ "$i" -lt "$filled" ]; then meter+="░"; else meter+="█"; fi
  done
  notify-send -a nightlight -r 9411 -t 1200 \
    "[ night $meter ]" "${t}K" 2>/dev/null
}

case "${1:-start}" in
  start)
    running || { wl-gammarelay-rs run >/dev/null 2>&1 & sleep 0.6; }
    t=$DEFAULT
    [ -s "$SAVED" ] && t=$(cat "$SAVED")
    set_temp "$t" >/dev/null
    ;;
  warmer)
    cur=$(get) || exit 1
    [ -z "$cur" ] && exit 1
    announce "$(set_temp $(( cur - ${2:-$STEP_DEFAULT} )))"
    ;;
  cooler)
    cur=$(get) || exit 1
    [ -z "$cur" ] && exit 1
    announce "$(set_temp $(( cur + ${2:-$STEP_DEFAULT} )))"
    ;;
  set)   announce "$(set_temp "${2:-$DEFAULT}")" ;;
  reset) announce "$(set_temp "$MAX")" ;;
  get)   get ;;
esac
