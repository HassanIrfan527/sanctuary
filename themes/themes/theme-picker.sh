#!/bin/bash
# Theme picker — launches a themed menu to switch between UI modes
# Adapts its appearance to the currently active theme

THEMES_DIR="$HOME/.dotfiles/themes/themes"
COZY_DIR="$HOME/.dotfiles/cozy"
CURRENT_UI=$(cat "$HOME/.config/themes/current-ui" 2>/dev/null || echo "default")

# Menu entries
ENTRIES="  Default (Quickshell)\n  Cozy Night\n  Cozy Day"

pick_theme() {
    local selection="$1"
    case "$selection" in
        *"Default"*)   "$THEMES_DIR/switch-ui.sh" default ;;
        *"Cozy Night"*) "$THEMES_DIR/switch-ui.sh" cozy-night ;;
        *"Cozy Day"*)  "$THEMES_DIR/switch-ui.sh" cozy-day ;;
    esac
}

case "$CURRENT_UI" in
    default)
        # Quickshell/Material theme — read generated colors if available
        COLORS_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"
        if [ -f "$COLORS_JSON" ]; then
            BG=$(python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d.get('surface_container','131313'))" 2>/dev/null)
            FG=$(python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d.get('on_surface','e2e2e2'))" 2>/dev/null)
            SEL=$(python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d.get('primary_container','474747'))" 2>/dev/null)
            SEL_TEXT=$(python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d.get('on_primary_container','c6c6c6'))" 2>/dev/null)
            BORDER=$(python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d.get('outline','474747'))" 2>/dev/null)
            MATCH=$(python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d.get('primary','c0c1ff'))" 2>/dev/null)
        else
            BG="131313"
            FG="e2e2e2"
            SEL="474747"
            SEL_TEXT="c6c6c6"
            BORDER="474747"
            MATCH="c0c1ff"
        fi
        # Strip any leading # from hex values
        BG="${BG#\#}"; FG="${FG#\#}"; SEL="${SEL#\#}"
        SEL_TEXT="${SEL_TEXT#\#}"; BORDER="${BORDER#\#}"; MATCH="${MATCH#\#}"

        CHOICE=$(echo -e "$ENTRIES" | fuzzel --dmenu \
            --prompt="Theme  " \
            --width=28 --lines=3 \
            --background="${BG}ff" \
            --text-color="${FG}ff" \
            --selection-color="${SEL}ff" \
            --selection-text-color="${SEL_TEXT}ff" \
            --border-color="${BORDER}dd" \
            --match-color="${MATCH}ff" \
        )
        ;;

    cozy-night)
        # Everforest dark palette
        CHOICE=$(echo -e "$ENTRIES" | fuzzel --dmenu \
            --prompt="Theme  " \
            --width=28 --lines=3 \
            --background="2d353bff" \
            --text-color="d3c6aaff" \
            --selection-color="3d484dff" \
            --selection-text-color="a7c080ff" \
            --border-color="475258dd" \
            --match-color="7fbbb3ff" \
        )
        ;;

    cozy-day)
        # Everforest light palette
        CHOICE=$(echo -e "$ENTRIES" | fuzzel --dmenu \
            --prompt="Theme  " \
            --width=28 --lines=3 \
            --background="fdf6e3ff" \
            --text-color="5c6a72ff" \
            --selection-color="efebd4ff" \
            --selection-text-color="8da101ff" \
            --border-color="e6e2ccdd" \
            --match-color="3a94c5ff" \
        )
        ;;

    *)
        CHOICE=$(echo -e "$ENTRIES" | fuzzel --dmenu \
            --prompt="Theme  " \
            --width=28 --lines=3 \
        )
        ;;
esac

[ -n "$CHOICE" ] && pick_theme "$CHOICE"
