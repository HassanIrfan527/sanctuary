#!/bin/bash
# Switch between Quickshell (default) and Waybar+Wofi+Swaync (cozy) UI stacks
# Usage: switch-ui.sh <default|cozy-night|cozy-day>

MODE="$1"
COZY_DIR="$HOME/.dotfiles/cozy"

[ -z "$MODE" ] && echo "Usage: switch-ui.sh <default|cozy-night|cozy-day>" && exit 1

case "$MODE" in
    default)
        # Kill waybar stack
        killall waybar swaync 2>/dev/null
        sleep 0.3

        # Restore Quickshell keybinds
        cp "$COZY_DIR/keybinds-quickshell.conf" "$HOME/.config/hypr/ui-keybinds.conf"
        hyprctl reload 2>/dev/null

        # Start Quickshell
        qs -c ii &

        # Restore dark mode
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

        notify-send "UI: Default" "Quickshell active"
        ;;

    cozy-night)
        # Kill Quickshell
        killall qs quickshell 2>/dev/null
        sleep 0.3

        # Copy cozy keybinds
        cp "$COZY_DIR/keybinds-cozy.conf" "$HOME/.config/hypr/ui-keybinds.conf"

        # Copy waybar night config
        mkdir -p ~/.config/waybar/colors
        cp "$COZY_DIR/waybar-cozy/config-night.jsonc" "$HOME/.config/waybar/config.jsonc"
        cp "$COZY_DIR/waybar-cozy/style-night.css" "$HOME/.config/waybar/style.css"
        cp "$COZY_DIR/waybar-cozy/colors/everforest.css" "$HOME/.config/waybar/colors/"

        # Copy wofi config
        mkdir -p ~/.config/wofi/themes ~/.config/wofi/colors
        cp "$COZY_DIR/wofi-cozy/themes/everforest.css" "$HOME/.config/wofi/themes/"
        cp "$COZY_DIR/wofi-cozy/colors/everforest.css" "$HOME/.config/wofi/colors/"

        # Copy swaync config
        cp "$COZY_DIR/swaync-cozy/style-night.css" "$HOME/.config/swaync/style.css"
        cp "$COZY_DIR/swaync-cozy/config.json" "$HOME/.config/swaync/config.json"

        # Reload hyprland keybinds
        hyprctl reload 2>/dev/null

        # Start services
        waybar &
        swaync &

        # Set wallpaper
        swww img "$COZY_DIR/wallpapers/summer-night.png" \
            --transition-type grow --transition-duration 2 --transition-fps 60

        # GTK theme
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

        # Hyprland border colors (Everforest dark)
        hyprctl keyword general:col.active_border "rgba(7fbbb3ee)" 2>/dev/null
        hyprctl keyword general:col.inactive_border "rgba(2d353baa)" 2>/dev/null

        notify-send "UI: Cozy Night" "Waybar + Everforest Dark"
        ;;

    cozy-day)
        # Kill Quickshell
        killall qs quickshell 2>/dev/null
        sleep 0.3

        # Copy cozy keybinds
        cp "$COZY_DIR/keybinds-cozy.conf" "$HOME/.config/hypr/ui-keybinds.conf"

        # Copy waybar day config
        mkdir -p ~/.config/waybar/colors
        cp "$COZY_DIR/waybar-cozy/config-day.jsonc" "$HOME/.config/waybar/config.jsonc"
        cp "$COZY_DIR/waybar-cozy/style-day.css" "$HOME/.config/waybar/style.css"
        cp "$COZY_DIR/waybar-cozy/colors/everforest-light.css" "$HOME/.config/waybar/colors/"

        # Copy wofi config
        mkdir -p ~/.config/wofi/themes ~/.config/wofi/colors
        cp "$COZY_DIR/wofi-cozy/themes/everforest-light.css" "$HOME/.config/wofi/themes/"
        cp "$COZY_DIR/wofi-cozy/colors/everforest-light.css" "$HOME/.config/wofi/colors/"

        # Copy swaync config
        cp "$COZY_DIR/swaync-cozy/style-day.css" "$HOME/.config/swaync/style.css"
        cp "$COZY_DIR/swaync-cozy/config.json" "$HOME/.config/swaync/config.json"

        # Reload hyprland keybinds
        hyprctl reload 2>/dev/null

        # Start services
        waybar &
        swaync &

        # Set wallpaper
        swww img "$COZY_DIR/wallpapers/summer-day.png" \
            --transition-type grow --transition-duration 2 --transition-fps 60

        # GTK theme
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

        # Hyprland border colors (Everforest light)
        hyprctl keyword general:col.active_border "rgba(3a94c5ee)" 2>/dev/null
        hyprctl keyword general:col.inactive_border "rgba(e6e2ccaa)" 2>/dev/null

        notify-send "UI: Cozy Day" "Waybar + Everforest Light"
        ;;

    *)
        echo "Unknown mode: $MODE"
        echo "Options: default, cozy-night, cozy-day"
        exit 1
        ;;
esac

# Save current UI mode
echo "$MODE" > "$HOME/.config/themes/current-ui"
