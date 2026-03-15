#!/bin/bash
THEME="$1"
THEME_DIR="$HOME/.config/themes/$THEME"

[ -z "$THEME" ] && echo "Usage: switch-theme.sh <stardew|cozy|cyberpunk>" && exit 1
[ ! -d "$THEME_DIR" ] && echo "Unknown theme: $THEME" && exit 1

# Source color definitions
source "$THEME_DIR/colors.sh"

# 1. Wallpaper (animated transition via swww)
for ext in png jpg gif; do
    if [ -f "$THEME_DIR/wallpaper.$ext" ]; then
        swww img "$THEME_DIR/wallpaper.$ext" \
            --transition-type grow --transition-duration 2 --transition-fps 60
        break
    fi
done

# 2. Kitty colors (live reload)
cp "$THEME_DIR/kitty.conf" "$HOME/.config/kitty/current-theme.conf"
kitty @ set-colors --all "$THEME_DIR/kitty.conf" 2>/dev/null

# 3. Waybar (copy theme CSS override, reload)
cp "$THEME_DIR/waybar.css" "$HOME/.config/waybar/theme-override.css"
killall -SIGUSR2 waybar

# 4. Notifications (copy override + full restart for reliable CSS reload)
cp "$THEME_DIR/swaync.css" "$HOME/.config/swaync/theme-override.css"
killall swaync 2>/dev/null
sleep 0.3
swaync &

# 5. Hyprland colors (border, gaps, rounding)
hyprctl keyword source "$THEME_DIR/hypr.conf" 2>/dev/null

# 6. GTK theme
[ -n "$GTK_THEME" ] && gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

# 7. Rofi colors (copy theme palette, rofi reads on next open)
[ -f "$THEME_DIR/rofi-colors.rasi" ] && cp "$THEME_DIR/rofi-colors.rasi" "$HOME/.config/rofi/theme-colors.rasi"

# 8. Cursor theme
if [ -n "$CURSOR_THEME" ]; then
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    hyprctl setcursor "$CURSOR_THEME" 24 2>/dev/null
fi

# 9. Icon theme
[ -n "$ICON_THEME" ] && gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"

# 10. System font
[ -n "$SYSTEM_FONT" ] && gsettings set org.gnome.desktop.interface font-name "$SYSTEM_FONT"

# 11. Save current theme
echo "$THEME" > "$HOME/.config/themes/current"

notify-send "Theme: $THEME" "Switched successfully" -t 3000
