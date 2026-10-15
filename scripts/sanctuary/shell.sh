#!/usr/bin/env bash
# The desk's shell: Quickshell drawing the saved style (Signal unless you picked
# another), with the old waybar + swaync stack as the AUTOMATIC fallback.
#
#   shell.sh start          startup (niri spawns this): Quickshell, or fallback if it won't come up
#   shell.sh set <style>    switch style — the Mod+Shift+T picker calls this; survives reboots
#   shell.sh pick           Mod+Shift+T: the Quickshell picker — or, while in fallback, retry Quickshell
#   shell.sh fallback       stop Quickshell, bring up waybar + swaync
#   shell.sh status         "quickshell <style>" or "fallback"
#
# ── The rule ──────────────────────────────────────────────────────────
# Nothing here writes niri config or keybinds (2026-10-03). Window styling lives
# in three HAND-KEPT files, niri/niri/layout-{signal,ink,paper,flare}.kdl; config.kdl
# includes `layout.kdl`, a symlink to the active one. A style switch re-points
# that symlink (validated first) and restarts Quickshell — it never writes a
# byte of config. The old per-mode renderer is in archive/mode-system/.
#
# ── When the fallback happens ─────────────────────────────────────────
#   1. Quickshell is missing, or does not answer within ~4s of starting.
#   2. Quickshell dies later (a crash). `watch` — started after every good start
#      — notices within ~4s and brings the fallback up, so the desk is never
#      left with no bar and nothing to receive notifications.
# A style switch kills Quickshell on purpose; the `switching` flag tells the
# watcher that this one is expected.
set -uo pipefail

DIR="$HOME/.dotfiles/scripts/sanctuary"
QS="$DIR/qs.sh"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/sanctuary"
STYLE_FILE="$STATE/style"
SWITCHING="$STATE/qs.switching"
mkdir -p "$STATE"

# The fallback: the classic configs, exactly as they were.
WAYBAR_CFG="$HOME/.dotfiles/waybar/config.jsonc"
WAYBAR_CSS="$HOME/.dotfiles/waybar/style.css"
SWAYNC_THEME="$HOME/.dotfiles/swaync/swaync/themes/ascii"

# The password prompt (polkit agent). Quickshell is the agent while it runs
# (Polkit.qml); in the fallback, mate-polkit is. Only ONE agent may hold the
# session, so the swap happens with the rest of the stack: classic_down kills
# mate before Quickshell starts, classic_up starts it once Quickshell is gone.
POLKIT_MATE=/usr/libexec/polkit-mate-authentication-agent-1

saved_style() {
  local s=signal
  [ -s "$STYLE_FILE" ] && s=$(cat "$STYLE_FILE")
  "$QS" has "$s" || s=signal     # a stale / hand-edited file can't strand the desk
  printf '%s' "$s"
}

# ── window styling: point layout.kdl at the style's hand-kept file ────
NIRI_DIR="$HOME/.dotfiles/niri/niri"
point_layout() {                             # $1 = style
  local want="layout-$1.kdl" link="$NIRI_DIR/layout.kdl" prev
  [ -r "$NIRI_DIR/$want" ] || want="layout-signal.kdl"   # a style without its own file looks like Signal
  prev=$(readlink "$link" 2>/dev/null)
  [ "$prev" = "$want" ] && return 0
  ln -sfn "$want" "$link"
  # Validate the COMPOSED config before niri sees it; on failure put the old
  # link back (or Signal's, if there was none) and say so.
  if ! niri validate -c "$NIRI_DIR/config.kdl" >/dev/null 2>&1; then
    ln -sfn "${prev:-layout-signal.kdl}" "$link"
    notify-send -a sanctuary -u critical "[ layout ✗ $1 ]" \
      "niri/niri/$want failed niri validate — kept ${prev:-layout-signal.kdl}" 2>/dev/null
    return 1
  fi
  niri msg action load-config-file >/dev/null 2>&1
}

# ── Mango: the same, for its look.conf → look-<style>.conf ───────────
# Mango re-reads its config on its own when a sourced file changes; the
# explicit reload is for when the symlink flips but the target file didn't.
MANGO_DIR="$HOME/.dotfiles/mango/mango"
point_look() {                               # $1 = style
  local want="look-$1.conf" link="$MANGO_DIR/look.conf"
  [ -r "$MANGO_DIR/$want" ] || want="look-signal.conf"   # only Signal exists so far
  [ "$(readlink "$link" 2>/dev/null)" = "$want" ] && return 0
  ln -sfn "$want" "$link"
  [ "$("$HOME/.dotfiles/scripts/sanctuary/wm.sh" name)" = mango ] &&
    "$HOME/.dotfiles/scripts/sanctuary/wm.sh" reload
  return 0
}

# ── terminal styling: same idea for kitty + starship ──────────────────
# kitty.conf ends with `include style.conf` (git-ignored symlink → style-<word>.conf);
# ~/.config/starship.toml → starship/themes/<word>.toml. A style without its own
# file looks like Signal, as with layout.kdl. kitty reloads its config on
# SIGUSR1 (open windows restyle at once); starship re-reads on the next prompt.
KITTY_DIR="$HOME/.dotfiles/kitty/kitty"
STARSHIP_DIR="$HOME/.dotfiles/starship/themes"
point_term() {                               # $1 = style
  local kit="style-$1.conf" star="$STARSHIP_DIR/$1.toml"
  [ -r "$KITTY_DIR/$kit" ] || kit="style-signal.conf"
  [ -r "$star" ] || star="$STARSHIP_DIR/signal.toml"
  [ "$(readlink "$HOME/.config/starship.toml" 2>/dev/null)" = "$star" ] \
    || ln -sfn "$star" "$HOME/.config/starship.toml"
  [ "$(readlink "$KITTY_DIR/style.conf" 2>/dev/null)" = "$kit" ] && return 0
  ln -sfn "$kit" "$KITTY_DIR/style.conf"
  pkill -USR1 -x kitty 2>/dev/null
  return 0
}

# ── browser: qutebrowser reads the style itself ───────────────────────
# qutebrowser/theme.py reads $STYLE_FILE (Signal palette, or Flare's for
# `flare`); a running browser only needs to re-run its config. Started only if
# it is already open — `qutebrowser :cmd` with none running would launch one.
point_browser() {
  pgrep -u "$USER" -f '/qutebrowser( |$)' >/dev/null 2>&1 || return 0
  ( setsid qutebrowser ':config-source' >/dev/null 2>&1 </dev/null & )
}

# ── system light/dark: the one setting the rest of the desktop follows ─
# org.gnome.desktop.interface color-scheme reaches apps through the portal and
# they restyle live: Brave (profiles on "Device"), Vesktop (signal24's
# @media prefers-color-scheme block), libadwaita/GTK4, qutebrowser pages under
# Signal ("auto"). GTK3 can't follow it, so its theme name is switched with it:
# adw-gtk3 / adw-gtk3-dark (Adwaita's look for GTK3). NOT "Adwaita-dark" — GTK3
# has no theme by that name and silently draws light Adwaita (probed 2026-10-12).
# Dracula was retired the same day (archive/gtk-dracula/).
# Only Flare is light, as with the wallpaper.
point_scheme() {                             # $1 = style
  local scheme=prefer-dark gtk=adw-gtk3-dark
  [ "$1" = flare ] && scheme=prefer-light gtk=adw-gtk3
  gsettings set org.gnome.desktop.interface color-scheme "$scheme" 2>/dev/null
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk" 2>/dev/null
  return 0
}

# ── wallpaper: light styles get a light wallpaper, and give yours back ─
# Each side remembers its own: leaving the dark side saves the current
# wallpaper as wallpaper.dark, leaving the light side saves wallpaper.light, and
# arriving restores what that side had (first time on the light side: the first
# image in $LIGHT_WALLS). "Which side is it on" = is the file inside
# $LIGHT_WALLS, so a wallpaper picked by hand (Mod+Shift+W) is respected. Only
# Flare is light here — Paper keeps its wallpaper, as before (2026-10-12).
LIGHT_WALLS="${SANCTUARY_WALLPAPERS:-$HOME/Pictures/Wallpapers}/light"
point_wall() {                               # $1 = style
  local want=dark cur side=dark target
  [ "$1" = flare ] && want=light
  cur=$(cat "$STATE/wallpaper" 2>/dev/null)
  case "$cur" in "$LIGHT_WALLS"/*) side=light ;; esac
  [ "$want" = "$side" ] && return 0
  [ -n "$cur" ] && printf '%s\n' "$cur" > "$STATE/wallpaper.$side"
  target=$(cat "$STATE/wallpaper.$want" 2>/dev/null)
  if [ "$want" = light ] && [ ! -f "$target" ]; then
    target=$(find "$LIGHT_WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \
      -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)
  fi
  [ -f "$target" ] || return 0               # nothing to go back to: leave it be
  ( trap '' HUP; setsid "$DIR/wallpaper.sh" set "$target" >/dev/null 2>&1 </dev/null & )
}

# ── the classic stack ─────────────────────────────────────────────────
classic_down() {
  pkill -f "^$POLKIT_MATE" 2>/dev/null
  pkill -x waybar
  pkill -f '^swaync-client -swb$'           # waybar's notification module, orphaned
  pgrep -x swaync >/dev/null 2>&1 || return 0
  pkill -x swaync
  local _
  for _ in $(seq 1 30); do                  # the bus name is free only once it has exited
    pgrep -x swaync >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  pkill -9 -x swaync
}

classic_up() {
  trap '' HUP
  pgrep -x swaync >/dev/null 2>&1 \
    || setsid swaync -c "$SWAYNC_THEME/config.json" -s "$SWAYNC_THEME/style.css" \
         >/dev/null 2>&1 </dev/null &
  pgrep -x waybar >/dev/null 2>&1 \
    || setsid waybar -c "$WAYBAR_CFG" -s "$WAYBAR_CSS" >/dev/null 2>&1 </dev/null &
  if [ -x "$POLKIT_MATE" ] && ! pgrep -f "^$POLKIT_MATE" >/dev/null 2>&1; then
    setsid "$POLKIT_MATE" >/dev/null 2>&1 </dev/null &
  fi
}

fallback() {
  local why=${1:-"switched by hand"}
  rm -f "$SWITCHING"
  "$QS" stop
  classic_up
  sleep 0.6                                  # let swaync claim the bus before we toast
  notify-send -a sanctuary -u critical -r 9414 "[ fallback ▸ waybar ]" \
    "$why — Mod+Shift+T retries Quickshell. Log: ~/.local/state/sanctuary/qs.log" 2>/dev/null
}

# ── Quickshell ────────────────────────────────────────────────────────
watch() {
  # One watcher at a time, whoever started it.
  exec 9>"$STATE/watch.lock"
  flock -n 9 || exit 0
  local misses=0
  while :; do
    sleep 2
    if "$QS" running; then misses=0; continue; fi
    # Down WHILE LOCKED (Lock.qml's flag is up): niri is showing its red locked
    # screen. Hand the lock to swaylock at once — don't wait for a second miss.
    if [ -e "${XDG_RUNTIME_DIR:-/tmp}/sanctuary-lock" ] && ! pgrep -x swaylock >/dev/null 2>&1; then
      ( trap '' HUP; setsid "$DIR/lock.sh" takeover >/dev/null 2>&1 </dev/null & )
    fi
    # Down. Expected if a switch is mid-restart (flag younger than 15s).
    if [ -e "$SWITCHING" ] && [ $(( $(date +%s) - $(stat -c %Y "$SWITCHING") )) -lt 15 ]; then
      continue
    fi
    misses=$((misses + 1))
    if [ "$misses" -ge 2 ]; then              # down on two checks in a row: not a blip
      pgrep -x waybar >/dev/null 2>&1 || fallback "Quickshell exited"
      exit 0
    fi
  done
}

start_watch() {
  trap '' HUP
  setsid "$0" watch >/dev/null 2>&1 </dev/null &
}

up() {                                       # $1 = style
  point_layout "$1"                          # windows first: instant, and independent of Quickshell
  point_look "$1"                            # …on Mango too
  point_term "$1"                            # kitty + starship follow the desk
  point_scheme "$1"                          # system light/dark + GTK3 theme — before the browser re-reads
  point_browser                              # qutebrowser re-reads the style file
  point_wall "$1"                            # light style ⇄ light wallpaper
  touch "$SWITCHING"
  classic_down                               # no-op unless we are leaving the fallback
  if "$QS" start "$1"; then
    rm -f "$SWITCHING"
    start_watch
    return 0
  fi
  fallback "Quickshell ($1) did not start"
  return 1
}

set_style() {
  local s=$1
  if ! "$QS" has "$s"; then
    notify-send -a sanctuary -u critical "[ style ✗ $s ]" \
      "no such style — have: $("$QS" styles | paste -sd' ')" 2>/dev/null
    return 1
  fi
  printf '%s\n' "$s" > "$STYLE_FILE"
  up "$s"
}

pick() {
  if "$QS" running; then
    "$QS" call picker toggle >/dev/null
  else
    up "$(saved_style)"                      # in fallback: Mod+Shift+T = try again
  fi
}

status() {
  if "$QS" running; then printf 'quickshell %s\n' "$(saved_style)"; else printf 'fallback\n'; fi
}

case "${1:-}" in
  start)    up "$(saved_style)" ;;
  set)      set_style "${2:?shell.sh set <style>}" ;;
  pick)     pick ;;
  fallback) fallback ;;
  watch)    watch ;;
  status)   status ;;
  *)        printf 'usage: shell.sh start|set <style>|pick|fallback|status\n' >&2; exit 2 ;;
esac
