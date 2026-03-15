#!/bin/bash
# Font picker — browse installed fonts and apply to system/terminal/waybar/widgets
# Shows currently active font at top with ✓ marker

# ── Detect current fonts ──
sys_font=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'" | sed 's/ [0-9]*$//')
kitty_font=$(grep "^font_family" ~/.config/kitty/kitty.conf 2>/dev/null | sed 's/font_family *//')
waybar_font=$(grep -oP 'font-family:\s*"\K[^"]+' ~/.config/waybar/theme-override.css 2>/dev/null | head -1)
rofi_font=$(grep -oP 'font:\s*"\K[^"]+' ~/.config/rofi/config.rasi 2>/dev/null | sed 's/ [0-9]*$//')
swaync_font=$(grep -oP 'font-family:\s*"\K[^"]+' ~/.config/swaync/style.css 2>/dev/null | head -1)
lock_font=$(grep -oP 'font_family = \K.*' ~/.config/hyprlock/hyprlock.conf 2>/dev/null | sed 's/ Bold$//')

# Step 1: Pick what to change (show current font for each)
target=$(cat <<EOF | rofi -dmenu -p "Change font for" -i
System (GTK apps) — ✓ $sys_font
Terminal (Kitty) — ✓ $kitty_font
Waybar (top bar) — ✓ $waybar_font
Rofi (app launcher) — ✓ $rofi_font
Notifications (swaync) — ✓ $swaync_font
Lock Screen (hyprlock) — ✓ $lock_font
EOF
)

[ -z "$target" ] && exit 0

# Extract target name (before the —)
target_name=$(echo "$target" | sed 's/ —.*//')

# Determine current font for this target
case "$target_name" in
    "System (GTK apps)") current="$sys_font" ;;
    "Terminal (Kitty)") current="$kitty_font" ;;
    "Waybar (top bar)") current="$waybar_font" ;;
    "Rofi (app launcher)") current="$rofi_font" ;;
    "Notifications (swaync)") current="$swaync_font" ;;
    "Lock Screen (hyprlock)") current="$lock_font" ;;
esac

# Step 2: List fonts with current one at top marked with ✓
all_fonts=$(fc-list --format="%{family[0]}\n" | sort -u)
font=$(echo -e "✓ $current (current)\n$all_fonts" | rofi -dmenu -p "Font" -i -theme-str 'listview { lines: 14; }')

[ -z "$font" ] && exit 0

# Strip the ✓ marker if they selected the current font
font=$(echo "$font" | sed 's/^✓ //' | sed 's/ (current)$//')

case "$target_name" in
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
        OVERRIDE="$HOME/.config/waybar/theme-override.css"
        if grep -q "font-family" "$OVERRIDE" 2>/dev/null; then
            sed -i "s/font-family:.*/font-family: \"$font\", monospace;/" "$OVERRIDE"
        fi
        killall -SIGUSR2 waybar
        notify-send "Font Changed" "Waybar → $font"
        ;;
    "Rofi (app launcher)")
        sed -i "s/font: .*/font: \"$font 13\";/" ~/.config/rofi/config.rasi
        notify-send "Font Changed" "Rofi → $font"
        ;;
    "Notifications (swaync)")
        sed -i "s/font-family:.*/font-family: \"$font\", sans-serif;/" ~/.config/swaync/style.css
        CURRENT_THEME=$(cat ~/.config/themes/current 2>/dev/null || echo "cozy")
        CSS_FILE="$HOME/.config/themes/$CURRENT_THEME/swaync.css"
        if grep -q "font-family" "$CSS_FILE" 2>/dev/null; then
            sed -i "s/font-family:.*/font-family: \"$font\", sans-serif;/" "$CSS_FILE"
        fi
        swaync-client -rs
        notify-send "Font Changed" "Notifications → $font"
        ;;
    "Lock Screen (hyprlock)")
        sed -i "s/font_family = .*/font_family = $font Bold/" ~/.config/hyprlock/hyprlock.conf
        notify-send "Font Changed" "Lock Screen → $font"
        ;;
esac
