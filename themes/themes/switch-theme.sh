#!/bin/bash
THEME="$1"
THEME_DIR="$HOME/.config/themes/$THEME"

[ -z "$THEME" ] && echo "Usage: switch-theme.sh <stardew|cozy|cyberpunk>" && exit 1
[ ! -d "$THEME_DIR" ] && echo "Unknown theme: $THEME" && exit 1

# Source color definitions
source "$THEME_DIR/colors.sh"

# 1. Wallpaper (animated transition via swww)
if [ -f "$THEME_DIR/wallpaper.png" ]; then
    swww img "$THEME_DIR/wallpaper.png" \
        --transition-type grow --transition-duration 2 --transition-fps 60
elif [ -f "$THEME_DIR/wallpaper.gif" ]; then
    swww img "$THEME_DIR/wallpaper.gif" \
        --transition-type grow --transition-duration 2 --transition-fps 60
elif [ -f "$THEME_DIR/wallpaper.jpg" ]; then
    swww img "$THEME_DIR/wallpaper.jpg" \
        --transition-type grow --transition-duration 2 --transition-fps 60
fi

# 2. Kitty colors (live reload)
cp "$THEME_DIR/kitty.conf" "$HOME/.config/kitty/current-theme.conf"
kitty @ set-colors --all "$THEME_DIR/kitty.conf" 2>/dev/null

# 3. Waybar (copy theme CSS override, reload)
cp "$THEME_DIR/waybar.css" "$HOME/.config/waybar/theme-override.css"
killall -SIGUSR2 waybar

# 4. Notifications (reload swaync style)
cp "$THEME_DIR/swaync.css" "$HOME/.config/swaync/theme-override.css"
swaync-client -rs 2>/dev/null

# 5. Hyprland colors (border, gaps, etc.)
hyprctl keyword source "$THEME_DIR/hypr.conf" 2>/dev/null

# 6. GTK theme
if [ -n "$GTK_THEME" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
fi

# 7. Save current theme
echo "$THEME" > "$HOME/.config/themes/current"

notify-send "Theme: $THEME" "Switched successfully" -t 3000
