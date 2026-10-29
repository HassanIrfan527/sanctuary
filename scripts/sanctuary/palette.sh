#!/usr/bin/env bash
# Signal's colour palette — Mod+Shift+C. Colours only: shape, font and layout
# stay Signal. Live: nothing restarts.
#
#   palette.sh set <word>    save it and re-point everything (the picker calls this)
#   palette.sh pick          Mod+Shift+C: Quickshell's palette picker
#   palette.sh point         re-point for the saved style + palette (shell.sh calls this on every style switch)
#   palette.sh current       print the saved palette
#
# palettes/signal.json is the one source. Quickshell reads it and the state
# file itself (Theme.qml watches both), so the bar, toasts, launcher and lock
# restyle the moment the file changes. The apps get links to files that
# palette.py build wrote — like the style links in shell.sh, nothing is written
# here but symlinks:
#   kitty     kitty/kitty/palette.conf → palettes/<word>.conf  (style-signal.conf includes it; SIGUSR1 reloads)
#   starship  ~/.config/starship.toml  → themes/signal/<word>.toml  (next prompt)
#   niri      niri/niri/palette.kdl    → palettes/<word>.kdl, or none.kdl outside Signal (validated, then reloaded)
# Only Signal wears a palette. Under Flare / Lantern / Harvest the choice is
# kept and comes back with Signal.
set -uo pipefail

DIR="$HOME/.dotfiles/scripts/sanctuary"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
PALETTE_FILE="$STATE/palette"
STYLE_FILE="$STATE/style"
KITTY_DIR="$HOME/.dotfiles/kitty/kitty"
NIRI_DIR="$HOME/.dotfiles/niri/niri"
STAR_DIR="$HOME/.dotfiles/starship/themes/signal"
mkdir -p "$STATE"

has() { [ -n "$1" ] && [ -r "$KITTY_DIR/palettes/$1.conf" ]; }

saved() {
  local p=default
  [ -s "$PALETTE_FILE" ] && p=$(cat "$PALETTE_FILE")
  has "$p" || p=default                     # a stale / hand-edited file can't strand the desk
  printf '%s' "$p"
}

style() {
  local s=signal
  [ -s "$STYLE_FILE" ] && s=$(cat "$STYLE_FILE")
  printf '%s' "$s"
}

# Re-point $2 at $1 only if it isn't already; exit 0 when it changed.
relink() {
  [ "$(readlink "$2" 2>/dev/null)" = "$1" ] && return 1
  ln -sfn "$1" "$2"
}

point_niri() {                              # $1 = palette file name (word.kdl / none.kdl)
  local link="$NIRI_DIR/palette.kdl" prev
  prev=$(readlink "$link" 2>/dev/null)
  relink "palettes/$1" "$link" || return 0
  if ! niri validate -c "$NIRI_DIR/config.kdl" >/dev/null 2>&1; then
    ln -sfn "${prev:-palettes/none.kdl}" "$link"
    notify-send -a sanctuary -u critical "[ palette ✗ niri ]" \
      "niri/niri/palettes/$1 failed niri validate — kept ${prev:-none}" 2>/dev/null
    return 1
  fi
  niri msg action load-config-file >/dev/null 2>&1
}

point() {
  local p s
  p=$(saved)
  s=$(style)
  # kitty: only style-signal.conf includes palette.conf, so this link is harmless elsewhere
  relink "palettes/$p.conf" "$KITTY_DIR/palette.conf" && [ "$s" = signal ] && pkill -USR1 -x kitty 2>/dev/null
  if [ "$s" = signal ]; then
    relink "$STAR_DIR/$p.toml" "$HOME/.config/starship.toml"
    point_niri "$p.kdl"
  else
    point_niri none.kdl                     # the style's own layout colours (shell.sh points starship)
  fi
  return 0
}

set_palette() {
  if ! has "$1"; then
    notify-send -a sanctuary -u critical "[ palette ✗ $1 ]" \
      "no such palette — have: $(python3 "$DIR/palette.py" words | paste -sd' ')" 2>/dev/null
    return 1
  fi
  printf '%s\n' "$1" > "$PALETTE_FILE"      # Quickshell is watching this file
  point
}

case "${1:-}" in
  set)     set_palette "${2:?palette.sh set <word>}" ;;
  pick)    "$DIR/qs.sh" call palettes toggle >/dev/null 2>&1 ;;
  point)   point ;;
  current) saved; printf '\n' ;;
  *)       printf 'usage: palette.sh set <word>|pick|point|current\n' >&2; exit 2 ;;
esac
