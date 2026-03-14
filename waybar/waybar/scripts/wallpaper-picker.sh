#!/bin/bash
# Wallpaper picker — GUI with image previews
# Uses waypaper for browsing, saves selection to current theme

CURRENT_THEME=$(cat "$HOME/.config/themes/current" 2>/dev/null || echo "cozy")
THEME_DIR="$HOME/.config/themes/$CURRENT_THEME"

# Launch waypaper with swww backend and wallpapers folder
GTK_THEME=Adwaita:dark waypaper --backend swww --folder "$HOME/Pictures/wallpapers"

# After waypaper closes, grab the last wallpaper it set and save to theme
LAST_WALL=$(swww query | head -1 | grep -oP 'image: \K.*')
[ -n "$LAST_WALL" ] && ln -sf "$LAST_WALL" "$THEME_DIR/wallpaper.png"
