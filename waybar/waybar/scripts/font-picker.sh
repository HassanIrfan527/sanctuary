#!/bin/bash
# Font picker — browse installed fonts and apply to system/terminal/waybar

# Step 1: Pick what to change
target=$(echo -e "System (GTK apps)\nTerminal (Kitty)\nWaybar (top bar)" | rofi -dmenu -p "Change font for" -i)

[ -z "$target" ] && exit 0

# Step 2: List all installed font families, deduplicated
font=$(fc-list --format="%{family[0]}\n" | sort -u | rofi -dmenu -p "Font" -i -theme-str 'listview { lines: 14; }')

[ -z "$font" ] && exit 0

case "$target" in
    "System (GTK apps)")
        gsettings set org.gnome.desktop.interface font-name "$font 11"
        gsettings set org.gnome.desktop.interface document-font-name "$font 11"
        notify-send "Font Changed" "System → $font"
        ;;
    "Terminal (Kitty)")
        kitty @ set-fonts --all "font_family=$font" 2>/dev/null
        sed -i "s/^font_family .*/font_family      $font/" ~/.config/kitty/kitty.conf
        sed -i "s/^bold_font .*/bold_font        $font Bold/" ~/.config/kitty/kitty.conf
        sed -i "s/^italic_font .*/italic_font      $font Italic/" ~/.config/kitty/kitty.conf
        sed -i "s/^bold_italic_font .*/bold_italic_font $font Bold Italic/" ~/.config/kitty/kitty.conf
        notify-send "Font Changed" "Kitty → $font"
        ;;
    "Waybar (top bar)")
        CURRENT_THEME=$(cat ~/.config/themes/current 2>/dev/null || echo "cozy")
        CSS_FILE="$HOME/.config/themes/$CURRENT_THEME/waybar.css"
        if grep -q "font-family" "$CSS_FILE" 2>/dev/null; then
            sed -i "s/font-family:.*/font-family: \"$font\", monospace;/" "$CSS_FILE"
        fi
        # Also update the active waybar override
        OVERRIDE="$HOME/.config/waybar/theme-override.css"
        if grep -q "font-family" "$OVERRIDE" 2>/dev/null; then
            sed -i "s/font-family:.*/font-family: \"$font\", monospace;/" "$OVERRIDE"
        fi
        killall -SIGUSR2 waybar
        notify-send "Font Changed" "Waybar → $font"
        ;;
esac
