#!/usr/bin/env bash
# Modes — one keypress changes the whole desk: space, shape, bar, quiet.
#
#   mode.sh pick            the picker: fzf in a floating kitty  (Mod+Shift+Z)
#   mode.sh set <name>      switch to modes/<name>.conf
#   mode.sh status          print the current mode name
#   mode.sh reapply         re-assert the saved mode (called at startup)
#
# A mode is a file: scripts/sanctuary/modes/<name>.conf. Adding one is adding a
# file — the picker lists whatever is in that directory, sorted by ORDER.
#
# ── How a switch works, and why it works this way ─────────────────────────
# niri allows exactly ONE top-level `layout {}` block (a second one fails with
# `duplicate node 'layout', single node expected`), so a mode cannot be a small
# override include stacked on the base config — it has to BE the layout block.
# So: render niri/templates/mode.kdl.in with this mode's numbers, install it as
# niri/mode.kdl, and make niri re-read it. Shape is the opposite case —
# `window-rule` blocks are additive and the last wins — so the rendered file can
# override the 2px radius floor in window-rules.kdl purely by being included
# after it.
#
# The install is validated and reversible: the old mode.kdl is kept and put back
# if the composed config fails `niri validate`, so a bad mode file can never
# leave the desktop with a broken config.
set -uo pipefail

NIRI="$HOME/.dotfiles/niri/niri"
TEMPLATE="$NIRI/templates/mode.kdl.in"
TARGET="$NIRI/mode.kdl"
MODES="$HOME/.dotfiles/scripts/sanctuary/modes"
BAR_SH="$HOME/.dotfiles/scripts/sanctuary/bar.sh"

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
SAVED="$STATE/mode"
mkdir -p "$STATE"

current() { if [ -s "$SAVED" ]; then cat "$SAVED"; else echo default; fi; }

# Sorted by ORDER, so the picker's row order is a property of the mode files and
# not of whatever order the filesystem hands them back in.
list() {
  local f name order
  for f in "$MODES"/*.conf; do
    [ -r "$f" ] || continue
    name=$(basename "$f" .conf)
    order=$(. "$f"; printf '%s' "${ORDER:-99}")
    printf '%s\t%s\n' "$order" "$name"
  done | sort -n | cut -f2
}

render() {                       # $1 = mode name  ->  rendered KDL on stdout
  local conf="$MODES/$1.conf"
  [ -r "$conf" ] || { printf 'mode.sh: no such mode: %s\n' "$1" >&2; return 1; }
  (
    . "$conf"
    local center="// always-center-single-column   (off in this mode)"
    [ "${CENTER_SINGLE:-no}" = yes ] && center="always-center-single-column"
    sed -e "s|@NAME@|${1}|g" \
        -e "s|@GAPS@|${GAPS}|g" \
        -e "s|@STRUT_SIDE@|${STRUT_SIDE}|g" \
        -e "s|@STRUT_TOP@|${STRUT_TOP}|g" \
        -e "s|@STRUT_BOTTOM@|${STRUT_BOTTOM}|g" \
        -e "s|@DEFAULT_WIDTH@|${DEFAULT_WIDTH}|g" \
        -e "s|@BORDER@|${BORDER}|g" \
        -e "s|@RADIUS@|${RADIUS}|g" \
        -e "s|@WINDOW_OPACITY@|${WINDOW_OPACITY:-1.0}|g" \
        -e "s|@CENTER_SINGLE@|${center}|g" \
        "$TEMPLATE"
    # Blur behind the bar, per mode. Two things to know:
    #
    #  1. It is emitted here rather than living in effects.kdl because a
    #     layer-rule matching `waybar` blurs the FULL bar too — and that bar is a
    #     row of opaque islands with transparent air between them, so it shows up
    #     as a smeared strip across the top of the screen in Default.
    #  2. niri blurs the layer's whole RECTANGLE, not the painted pixels, and a
    #     layer-rule's geometry-corner-radius does not round that rectangle. So
    #     the zen bar's surface is sized to the pill exactly (`width` in its
    #     config.jsonc, min-width/min-height in its CSS); anything left over
    #     blurs as a halo around it.
    if [ "${BAR_BLUR:-no}" = yes ]; then
      cat <<'RULE'

layer-rule {
    match namespace="^waybar$"
    // No geometry-corner-radius here: on a LAYER rule it does not shape the blur.
    // Tested 2026-09-25 at 0 and 17 on niri 26.04 — pixel-identical. niri blurs
    // the surface RECTANGLE, so the only way to stop a halo is for the bar's
    // surface to be exactly the size of what is painted on it (see the zen bar's
    // width setting and the pill's min-width/min-height), and to keep the pill's radius
    // small enough that the square corners of the blur stay invisible.
    background-effect {
        blur true
        xray false
    }
}
RULE
    fi
    printf '\n// Rendered for mode `%s` by mode.sh on %s. Do not edit.\n' \
      "$1" "$(date +%Y-%m-%d\ %H:%M)"
  )
}

# swaync toggles DND blind (`-d` flips it), so read the state first and only act
# if it disagrees — otherwise a re-apply of the same mode inverts it.
dnd_set() {
  local want=$1 now i
  # The loop is for startup only: `mode.sh reapply` can run before swaync has
  # claimed org.freedesktop.Notifications, and a query that early answers with
  # nothing — which would silently drop the quiet half of the mode. Bounded at
  # ~3s, and it never spins when swaync is already up.
  for i in 1 2 3 4 5 6; do
    now=$(swaync-client -D 2>/dev/null)
    [ -n "$now" ] && break
    sleep 0.5
  done
  case "$want:$now" in
    on:false|off:true) swaync-client -d >/dev/null 2>&1 ;;
  esac
}

# The bar has no mode module, so the toast IS the readout — same reasoning as
# nightlight.sh. A fixed replaces-id means repeated switches update one toast.
announce() {
  local label=$1 desc=$2
  notify-send -a sanctuary -r 9412 -t 1600 "[ mode ▸ $label ]" "$desc" 2>/dev/null
}

apply() {
  local name=$1 prev
  prev=$(current)
  [ -r "$MODES/$name.conf" ] || { printf 'mode.sh: no such mode: %s\n' "$name" >&2; return 1; }

  local label desc bar dnd
  label=$(. "$MODES/$name.conf"; printf '%s' "${LABEL:-$name}")
  desc=$(. "$MODES/$name.conf";  printf '%s' "${DESC:-}")
  bar=$(. "$MODES/$name.conf";   printf '%s' "${BAR:-full}")
  dnd=$(. "$MODES/$name.conf";   printf '%s' "${DND:-off}")

  # 1. Shape + space. Keep the outgoing file so a failed validate is reversible.
  local backup=""
  if [ -f "$TARGET" ]; then backup="$TARGET.prev"; cp -f "$TARGET" "$backup"; fi
  render "$name" > "$TARGET" || return 1
  if ! niri validate -c "$NIRI/config.kdl" >/dev/null 2>&1; then
    [ -n "$backup" ] && mv -f "$backup" "$TARGET"
    notify-send -a sanctuary -u critical -r 9412 \
      "[ mode ✗ $label ]" "config failed validation — kept $prev" 2>/dev/null
    printf 'mode.sh: %s produced an invalid config; rolled back\n' "$name" >&2
    return 1
  fi
  niri msg action load-config-file >/dev/null 2>&1

  # 2. Remember it BEFORE touching the bar: bar.sh reads this file to decide
  #    which config to launch, so the order here is load-bearing.
  printf '%s\n' "$name" > "$SAVED"

  # 3. Bar.
  case "$bar" in
    none) "$BAR_SH" stop ;;
    *)    "$BAR_SH" restart ;;
  esac

  # 4. Quiet, and say so. Leaving a DND mode: clear DND first, then announce, or
  #    the toast is swallowed by the mode you are leaving. Entering one: announce
  #    first, then go quiet.
  if [ "$dnd" = on ]; then
    announce "$label" "$desc"
    sleep 0.2
    dnd_set on
  else
    dnd_set off
    announce "$label" "$desc"
  fi
}

# The picker. Same fzf dressing as clipboard.sh — sharp border, mocha colours,
# ctrl-j/k — and the same gutter glyphs the launcher uses: `█` is where you are,
# `░` is everything else.
pick() {
  local cur rows name label desc glyph pad n
  cur=$(current)
  rows=""
  while read -r name; do
    label=$(. "$MODES/$name.conf"; printf '%s' "${LABEL:-$name}")
    desc=$(. "$MODES/$name.conf";  printf '%s' "${DESC:-}")
    if [ "$name" = "$cur" ]; then glyph="█"; else glyph="░"; fi
    # Pad by CHARACTERS, not bytes. printf '%-14s' counts bytes, and a label with
    # an em dash in it ("Zen — no bar") is three bytes wider than it looks — which
    # knocks the description column out of line by exactly that much.
    local pad="" n=$(( 14 - ${#label} ))
    while [ "$n" -gt 0 ]; do pad+=" "; n=$((n - 1)); done
    rows+=$(printf '%s\t%s %s%s  %s' "$name" "$glyph" "$label" "$pad" "$desc")$'\n'
  done < <(list)

  local sel
  sel=$(printf '%s' "$rows" | fzf \
    --no-sort --reverse --border=sharp \
    --delimiter='\t' --with-nth=2.. \
    --border-label=' mode ' --border-label-pos=2 \
    --prompt='[ switch ] ' --pointer='▸' --info=inline-right \
    --color='bg+:#1e1e2e,fg:#a6adc8,fg+:#cdd6f4,hl:#cba6f7,hl+:#cba6f7' \
    --color='border:#797faa,label:#b4befe,info:#45475a' \
    --color='prompt:#b4befe,pointer:#b4befe,spinner:#585b70' \
    --bind 'ctrl-j:down,ctrl-k:up' \
    | cut -f1)

  [ -n "$sel" ] || exit 0
  # setsid: this runs inside a kitty that exits the instant fzf returns, and
  # everything apply() starts would go down with it (the fsel SIGHUP trap,
  # DESIGN-BRIEF §5). bar.sh setsids waybar for the same reason.
  setsid "$0" set "$sel" >/dev/null 2>&1 &
}

case "${1:-pick}" in
  pick)    pick ;;
  set)     apply "${2:?mode.sh set <name>}" ;;
  reapply) apply "$(current)" ;;
  status)  current ;;
  list)    list ;;
  *)       printf 'usage: mode.sh pick|set <name>|reapply|status|list\n' >&2; exit 2 ;;
esac
