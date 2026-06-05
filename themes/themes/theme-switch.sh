#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# theme-switch.sh — flip the whole ecosystem between the dark
# default (Catppuccin Mocha / rose-pine) and cozy-white
# (Gruvbox Light). Mocha stays the default.
#
#   theme-switch.sh              → toggle
#   theme-switch.sh cozy-white   → warm cream
#   theme-switch.sh dark         → back to dark
#   theme-switch.sh current      → print active variant
# ─────────────────────────────────────────────────────────────

ROOT="$HOME/.dotfiles"
THEMES="$ROOT/themes/themes"
CFG="$HOME/.config"
CURRENT_FILE="$THEMES/current"

cur="$(cat "$CURRENT_FILE" 2>/dev/null || echo dark)"
[ "$cur" = "cozy" ] && cur="dark"   # legacy value

target="${1:-toggle}"
case "$target" in
  toggle)            [ "$cur" = "cozy-white" ] && target=dark || target=cozy-white ;;
  dark|mocha)        target=dark ;;
  cozy-white|light)  target=cozy-white ;;
  current)           echo "$cur"; exit 0 ;;
  *) echo "usage: theme-switch.sh [dark|cozy-white|toggle|current]"; exit 1 ;;
esac

if [ "$target" = dark ]; then SRC="$THEMES/mocha"; else SRC="$THEMES/cozy-white"; fi

echo "→ switching to: $target"

put() { # copy if both source and dest-dir exist; never abort the whole switch
  [ -f "$1" ] || { echo "  ✗ missing source $(basename "$1")"; return; }
  if cp -f "$1" "$2" 2>/dev/null; then echo "  ✓ $(basename "$2")"
  else echo "  ✗ $2 (skipped)"; fi
}

# ── swap colour files (live paths; dir-symlinks write through to the repo) ──
put "$SRC/palette.css"          "$CFG/waybar/colors.css"
put "$SRC/palette.css"          "$CFG/walker/themes/cozy/colors.css"
put "$SRC/palette.css"          "$CFG/swaync/colors.css"
put "$SRC/palette.css"          "$CFG/swayosd/colors.css"
put "$SRC/kitty.conf"           "$CFG/kitty/current-theme.conf"
put "$SRC/fuzzel.ini"           "$CFG/fuzzel/fuzzel_theme.ini"
put "$SRC/mako.conf"            "$CFG/mako/config"
put "$SRC/hypr-colors.conf"     "$CFG/hypr/colors.conf"
put "$SRC/hyprlock-colors.conf" "$CFG/hypr/hyprlock-colors.conf"
put "$SRC/tmux.conf"            "$ROOT/tmux/theme-current.conf"
put "$SRC/yazi.toml"            "$CFG/yazi/theme.toml"
put "$SRC/nvim-theme.lua"       "$CFG/nvim/lua/theme_active.lua"
put "$SRC/qute-theme.py"        "$CFG/qutebrowser/theme-current.py"

# television: swap the builtin theme name (default ⇄ gruvbox-light)
TV_THEME=default; [ "$target" = cozy-white ] && TV_THEME="gruvbox-light"
if sed -i -E "s/^theme = \".*\"/theme = \"$TV_THEME\"/" "$CFG/television/config.toml" 2>/dev/null; then
  echo "  ✓ television ($TV_THEME)"
fi

# system color-scheme (xdg-desktop-portal) — drives Brave "System" theme + other portal-aware apps
if command -v gsettings >/dev/null 2>&1; then
  if [ "$target" = cozy-white ]; then SCHEME="prefer-light"; else SCHEME="prefer-dark"; fi
  gsettings set org.gnome.desktop.interface color-scheme "$SCHEME" 2>/dev/null && echo "  ✓ color-scheme ($SCHEME)"
fi

# cursor (theme-aware): warm amber on cream, purple on dark
if [ "$target" = cozy-white ]; then CURSOR="Bibata-Modern-Amber"; else CURSOR="Drop-Purple"; fi
hyprctl setcursor "$CURSOR" 24 >/dev/null 2>&1 && echo "  ✓ cursor ($CURSOR)"
command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR" 2>/dev/null
put "$SRC/rofi.rasi"            "$ROOT/rofi/rofi/theme-colors.rasi"
[ -e "$CFG/rofi/theme-colors.rasi" ] && put "$SRC/rofi.rasi" "$CFG/rofi/theme-colors.rasi"

# ── starship: repoint the active-theme symlink ──
if [ "$target" = cozy-white ]; then
  ln -sf "$ROOT/starship/themes/gruvbox.toml"        "$CFG/starship.toml"
else
  ln -sf "$ROOT/starship/themes/rose-pine-moon.toml" "$CFG/starship.toml"
fi
echo "  ✓ starship.toml"

# ── reloads ──
echo "→ reloading apps…"
hyprctl reload                >/dev/null 2>&1 && echo "  ✓ hyprland" || true
makoctl reload                 2>/dev/null && echo "  ✓ mako" || true
swaync-client --reload-config  2>/dev/null; swaync-client --reload-css 2>/dev/null && echo "  ✓ swaync" || true
kill -SIGUSR1 "$(pgrep -x kitty 2>/dev/null)" 2>/dev/null && echo "  ✓ kitty" || true
tmux source-file "$ROOT/tmux/theme-current.conf" 2>/dev/null && echo "  ✓ tmux" || true

# waybar: clean restart (not SIGUSR2 — see project_waybar_frosted)
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -x waybar 2>/dev/null; sleep 0.3
  (setsid waybar >/dev/null 2>&1 &) && echo "  ✓ waybar (restarted)"
fi
# swayosd reads css at start → restart only if running
if pgrep -x swayosd-server >/dev/null 2>&1; then
  pkill -x swayosd-server 2>/dev/null; sleep 0.2
  (setsid swayosd-server >/dev/null 2>&1 &) && echo "  ✓ swayosd (restarted)"
fi

# ── wallpaper ──
WALL=""
if   [ -f "$SRC/wallpaper.jpg" ]; then WALL="$SRC/wallpaper.jpg"
elif [ -f "$SRC/wallpaper.txt" ]; then WALL="$(cat "$SRC/wallpaper.txt")"; fi
if [ -n "$WALL" ] && [ -f "$WALL" ]; then
  swww img "$WALL" --transition-type grow --transition-pos 0.85,0.2 \
    --transition-duration 1.6 --transition-fps 60 2>/dev/null && echo "  ✓ wallpaper"
fi

echo "$target" > "$CURRENT_FILE"
command -v notify-send >/dev/null && notify-send -t 3000 "Theme" "Switched to $target"
echo "✓ done — $target"
echo "  (nvim picks up the new colours on next launch)"
