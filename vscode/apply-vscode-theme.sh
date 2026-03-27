#!/usr/bin/env bash
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
VSCODE_COLORS="$XDG_STATE_HOME/quickshell/user/generated/vscode-colors.json"

settings_paths=(
    "$XDG_CONFIG_HOME/Code/User/settings.json"
    "$XDG_CONFIG_HOME/VSCodium/User/settings.json"
    "$XDG_CONFIG_HOME/Code - OSS/User/settings.json"
    "$XDG_CONFIG_HOME/Code - Insiders/User/settings.json"
    "$XDG_CONFIG_HOME/Cursor/User/settings.json"
)

if [[ ! -f "$VSCODE_COLORS" ]]; then
    echo "No generated colors at $VSCODE_COLORS"
    exit 1
fi

bg=$(jq -r '.background' "$VSCODE_COLORS")
surface=$(jq -r '.surface' "$VSCODE_COLORS")
surface_container=$(jq -r '.surface_container' "$VSCODE_COLORS")
surface_container_low=$(jq -r '.surface_container_low' "$VSCODE_COLORS")
surface_container_lowest=$(jq -r '.surface_container_lowest' "$VSCODE_COLORS")
surface_container_high=$(jq -r '.surface_container_high' "$VSCODE_COLORS")
surface_container_highest=$(jq -r '.surface_container_highest' "$VSCODE_COLORS")
surface_bright=$(jq -r '.surface_bright' "$VSCODE_COLORS")
surface_variant=$(jq -r '.surface_variant' "$VSCODE_COLORS")
on_bg=$(jq -r '.on_background' "$VSCODE_COLORS")
on_surface=$(jq -r '.on_surface' "$VSCODE_COLORS")
on_surface_variant=$(jq -r '.on_surface_variant' "$VSCODE_COLORS")
primary=$(jq -r '.primary' "$VSCODE_COLORS")
on_primary=$(jq -r '.on_primary' "$VSCODE_COLORS")
primary_container=$(jq -r '.primary_container' "$VSCODE_COLORS")
on_primary_container=$(jq -r '.on_primary_container' "$VSCODE_COLORS")
secondary=$(jq -r '.secondary' "$VSCODE_COLORS")
secondary_container=$(jq -r '.secondary_container' "$VSCODE_COLORS")
on_secondary_container=$(jq -r '.on_secondary_container' "$VSCODE_COLORS")
tertiary=$(jq -r '.tertiary' "$VSCODE_COLORS")
tertiary_container=$(jq -r '.tertiary_container' "$VSCODE_COLORS")
error=$(jq -r '.error' "$VSCODE_COLORS")
error_container=$(jq -r '.error_container' "$VSCODE_COLORS")
outline=$(jq -r '.outline' "$VSCODE_COLORS")
outline_variant=$(jq -r '.outline_variant' "$VSCODE_COLORS")
inverse_surface=$(jq -r '.inverse_surface' "$VSCODE_COLORS")
inverse_on_surface=$(jq -r '.inverse_on_surface' "$VSCODE_COLORS")
inverse_primary=$(jq -r '.inverse_primary' "$VSCODE_COLORS")

color_customizations=$(cat <<ENDJSON
{
    "editor.background": "${surface_container_lowest}",
    "editor.foreground": "${on_surface}",
    "editor.lineHighlightBackground": "${surface_container_low}",
    "editor.selectionBackground": "${primary_container}",
    "editor.selectionForeground": "${on_primary_container}",
    "editor.wordHighlightBackground": "${surface_container}",
    "editor.findMatchBackground": "${tertiary_container}",
    "editor.findMatchHighlightBackground": "${secondary_container}",
    "editorCursor.foreground": "${primary}",
    "editorLineNumber.foreground": "${outline}",
    "editorLineNumber.activeForeground": "${on_surface}",
    "editorIndentGuide.background1": "${outline_variant}",
    "editorIndentGuide.activeBackground1": "${outline}",
    "editorBracketMatch.background": "${surface_container}",
    "editorBracketMatch.border": "${outline}",
    "editorGroupHeader.tabsBackground": "${surface_container_lowest}",
    "editorGutter.addedBackground": "${tertiary}",
    "editorGutter.deletedBackground": "${error}",
    "editorGutter.modifiedBackground": "${primary}",
    "tab.activeBackground": "${surface_container}",
    "tab.activeForeground": "${on_surface}",
    "tab.inactiveBackground": "${surface_container_lowest}",
    "tab.inactiveForeground": "${on_surface_variant}",
    "tab.activeBorderTop": "${primary}",
    "tab.border": "${surface_container_lowest}",
    "activityBar.background": "${surface_container_low}",
    "activityBar.foreground": "${on_surface}",
    "activityBar.activeBorder": "${primary}",
    "activityBar.inactiveForeground": "${on_surface_variant}",
    "activityBarBadge.background": "${primary}",
    "activityBarBadge.foreground": "${on_primary}",
    "sideBar.background": "${surface_container_low}",
    "sideBar.foreground": "${on_surface}",
    "sideBar.border": "${outline_variant}",
    "sideBarTitle.foreground": "${on_surface}",
    "sideBarSectionHeader.background": "${surface_container}",
    "sideBarSectionHeader.foreground": "${on_surface}",
    "list.activeSelectionBackground": "${primary_container}",
    "list.activeSelectionForeground": "${on_primary_container}",
    "list.hoverBackground": "${surface_container}",
    "list.inactiveSelectionBackground": "${surface_container_high}",
    "list.inactiveSelectionForeground": "${on_surface}",
    "list.highlightForeground": "${primary}",
    "statusBar.background": "${surface_container_low}",
    "statusBar.foreground": "${on_surface_variant}",
    "statusBar.debuggingBackground": "${error_container}",
    "statusBar.noFolderBackground": "${surface_container_lowest}",
    "statusBarItem.hoverBackground": "${surface_container_high}",
    "statusBarItem.remoteBackground": "${primary}",
    "statusBarItem.remoteForeground": "${on_primary}",
    "titleBar.activeBackground": "${surface_container_low}",
    "titleBar.activeForeground": "${on_surface}",
    "titleBar.inactiveBackground": "${surface_container_lowest}",
    "titleBar.inactiveForeground": "${on_surface_variant}",
    "panel.background": "${surface_container_lowest}",
    "panel.border": "${outline_variant}",
    "panelTitle.activeBorder": "${primary}",
    "panelTitle.activeForeground": "${on_surface}",
    "panelTitle.inactiveForeground": "${on_surface_variant}",
    "terminal.background": "${surface_container_lowest}",
    "terminal.foreground": "${on_surface}",
    "terminal.ansiBlack": "${surface_container_lowest}",
    "terminal.ansiBrightBlack": "${outline}",
    "terminal.ansiWhite": "${on_surface}",
    "terminal.ansiBrightWhite": "${on_bg}",
    "terminal.ansiBlue": "${primary}",
    "terminal.ansiBrightBlue": "${primary}",
    "terminal.ansiCyan": "${tertiary}",
    "terminal.ansiBrightCyan": "${tertiary}",
    "terminal.ansiRed": "${error}",
    "terminal.ansiBrightRed": "${error}",
    "terminal.ansiGreen": "${tertiary}",
    "terminal.ansiBrightGreen": "${tertiary}",
    "terminal.ansiYellow": "${secondary}",
    "terminal.ansiBrightYellow": "${secondary}",
    "terminal.ansiMagenta": "${tertiary_container}",
    "terminal.ansiBrightMagenta": "${tertiary_container}",
    "input.background": "${surface_container}",
    "input.foreground": "${on_surface}",
    "input.border": "${outline}",
    "input.placeholderForeground": "${on_surface_variant}",
    "focusBorder": "${primary}",
    "dropdown.background": "${surface_container}",
    "dropdown.foreground": "${on_surface}",
    "dropdown.border": "${outline}",
    "button.background": "${primary}",
    "button.foreground": "${on_primary}",
    "button.hoverBackground": "${inverse_primary}",
    "button.secondaryBackground": "${secondary_container}",
    "button.secondaryForeground": "${on_secondary_container}",
    "badge.background": "${primary}",
    "badge.foreground": "${on_primary}",
    "scrollbarSlider.background": "${outline_variant}44",
    "scrollbarSlider.hoverBackground": "${outline_variant}88",
    "scrollbarSlider.activeBackground": "${outline_variant}aa",
    "breadcrumb.foreground": "${on_surface_variant}",
    "breadcrumb.focusForeground": "${on_surface}",
    "breadcrumb.activeSelectionForeground": "${primary}",
    "widget.shadow": "#00000033",
    "notifications.background": "${surface_container_high}",
    "notifications.foreground": "${on_surface}",
    "notificationCenterHeader.background": "${surface_container}",
    "gitDecoration.addedResourceForeground": "${tertiary}",
    "gitDecoration.conflictingResourceForeground": "${error}",
    "gitDecoration.deletedResourceForeground": "${error}",
    "gitDecoration.modifiedResourceForeground": "${primary}",
    "gitDecoration.untrackedResourceForeground": "${tertiary}",
    "editorWidget.background": "${surface_container_high}",
    "editorWidget.foreground": "${on_surface}",
    "editorSuggestWidget.background": "${surface_container_high}",
    "editorSuggestWidget.selectedBackground": "${primary_container}",
    "editorSuggestWidget.highlightForeground": "${primary}",
    "peekView.border": "${primary}",
    "peekViewEditor.background": "${surface_container}",
    "peekViewResult.background": "${surface_container_low}",
    "peekViewTitle.background": "${surface_container_high}",
    "peekViewResult.matchHighlightBackground": "${primary_container}",
    "peekViewEditor.matchHighlightBackground": "${primary_container}",
    "diffEditor.insertedTextBackground": "${tertiary_container}33",
    "diffEditor.removedTextBackground": "${error_container}33",
    "settings.modifiedItemIndicator": "${primary}",
    "settings.headerForeground": "${on_surface}",
    "welcomePage.tileBackground": "${surface_container}",
    "textLink.foreground": "${primary}",
    "textLink.activeForeground": "${inverse_primary}",
    "icon.foreground": "${on_surface_variant}",
    "progressBar.background": "${primary}",
    "charts.foreground": "${on_surface}",
    "charts.lines": "${outline}",
    "minimap.selectionHighlight": "${primary_container}",
    "editorOverviewRuler.addedForeground": "${tertiary}",
    "editorOverviewRuler.deletedForeground": "${error}",
    "editorOverviewRuler.modifiedForeground": "${primary}"
}
ENDJSON
)

for CODE_SETTINGS_PATH in "${settings_paths[@]}"; do
    if [[ -f "$CODE_SETTINGS_PATH" ]]; then
        tmp=$(mktemp)
        jq --argjson colors "$color_customizations" '."workbench.colorCustomizations" = $colors' \
            "$CODE_SETTINGS_PATH" > "$tmp" && mv "$tmp" "$CODE_SETTINGS_PATH" && chmod 644 "$CODE_SETTINGS_PATH"
    fi
done
