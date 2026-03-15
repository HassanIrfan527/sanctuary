#!/bin/bash
# Switch wallpaper — matugen auto-generates all colors
WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
    echo "Usage: switch-theme.sh <wallpaper_path>"
    echo "Colors are auto-generated from the wallpaper via matugen."
    exit 1
fi

[ ! -f "$WALLPAPER" ] && echo "File not found: $WALLPAPER" && exit 1

# Use Quickshell's switchwall script if available
if [ -f ~/.config/quickshell/ii/scripts/colors/switchwall.sh ]; then
    ~/.config/quickshell/ii/scripts/colors/switchwall.sh --image "$WALLPAPER" --mode dark
else
    # Fallback: manual swww + matugen
    swww img "$WALLPAPER" --transition-type grow --transition-duration 2 --transition-fps 60
    matugen image "$WALLPAPER" --mode dark 2>/dev/null
    notify-send "Wallpaper" "$(basename "$WALLPAPER")"
fi
