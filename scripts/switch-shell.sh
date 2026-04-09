#!/bin/bash
# Switch between quickshell and AGS (epik-shell)
# Usage: switch-shell.sh [qs|ags]

HYPR_DIR="$HOME/.dotfiles/hypr/hypr"
KEYBINDS_FILE="$HYPR_DIR/ui-keybinds.conf"

write_qs_keybinds() {
    cat > "$KEYBINDS_FILE" << 'EOF'
# UI-specific keybinds — Quickshell mode
$mod = SUPER
bind = $mod, SPACE, global, quickshell:searchToggle
bind = $mod, A, global, quickshell:sidebarLeftToggle
bind = $mod, PERIOD, global, quickshell:sidebarRightToggle
bind = $mod, O, global, quickshell:overlayToggle
bind = $mod, SLASH, global, quickshell:cheatsheetToggle
bind = $mod CTRL, M, global, quickshell:mediaControlsToggle
bind = $mod SHIFT, V, global, quickshell:overviewClipboardToggle
bind = $mod SHIFT, W, global, quickshell:wallpaperSelectorToggle
bind = $mod SHIFT, S, global, quickshell:regionScreenshot
bindd = Ctrl+Alt, Delete, Toggle session menu, global, quickshell:sessionToggle
bind = Ctrl+$mod, R, exec, killall qs quickshell; qs -c ii &
EOF
}

write_ags_keybinds() {
    cat > "$KEYBINDS_FILE" << 'EOF'
# UI-specific keybinds — AGS (epik-shell) mode
$mod = SUPER
bind = $mod, SPACE, exec, ags toggle applauncher
bind = $mod SHIFT, W, exec, ags toggle wallpaperpicker
bind = $mod SHIFT, S, exec, ags toggle quicksettings
bind = $mod, N, exec, ags toggle notifications
bindd = Ctrl+Alt, Delete, Toggle session menu, exec, ags toggle powermenu
bind = Ctrl+$mod, R, exec, ags quit; ags run &
EOF
}

kill_shells() {
    pkill -9 -f "qs -c" 2>/dev/null
    pkill -f "^ags" 2>/dev/null
    pkill -f "gjs.*ags" 2>/dev/null
    sleep 0.5
}

case "$1" in
    qs|quickshell)
        kill_shells
        write_qs_keybinds
        python3 ~/.dotfiles/scripts/fix-config-corruption.py
        nohup qs -c ii > /tmp/qs.log 2>&1 &
        echo "Switched to Quickshell"
        ;;
    ags|epik)
        kill_shells
        pkill mako 2>/dev/null
        write_ags_keybinds
        nohup ags run > /tmp/ags.log 2>&1 &
        echo "Switched to AGS (epik-shell)"
        ;;
    *)
        echo "Usage: switch-shell.sh [qs|ags]"
        exit 1
        ;;
esac

# Reload Hyprland config to pick up new keybinds
hyprctl reload
