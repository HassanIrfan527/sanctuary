#!/usr/bin/env bash
# mode-detector.sh — emit JSON for waybar custom/mode (bottom bar).
# Maps the focused window's class/app-id (and descendants for terminals)
# to a mode label + CSS class. Works on both Hyprland and niri.

set -euo pipefail

class=""; pid=""; title=""

if [ -n "${NIRI_SOCKET:-}" ] || { [ "${XDG_CURRENT_DESKTOP:-}" = "niri" ] && command -v niri >/dev/null 2>&1; }; then
    json="$(niri msg --json focused-window 2>/dev/null || echo '{}')"
    class="$(printf '%s' "$json" | jq -r '.app_id // empty' 2>/dev/null)" || true
    pid="$(printf '%s' "$json" | jq -r '.pid // empty' 2>/dev/null)" || true
    title="$(printf '%s' "$json" | jq -r '.title // empty' 2>/dev/null)" || true
else
    json="$(hyprctl activewindow -j 2>/dev/null || echo '{}')"
    class="$(printf '%s' "$json" | jq -r '.class // empty' 2>/dev/null)" || true
    pid="$(printf '%s' "$json" | jq -r '.pid // empty' 2>/dev/null)" || true
    title="$(printf '%s' "$json" | jq -r '.title // empty' 2>/dev/null)" || true
fi

class="${class:-}"; pid="${pid:-}"; title="${title:-}"
[ "$class" = "null" ] && class=""
[ "$pid" = "null" ] && pid=""

# walk process tree for nvim if the window is a terminal; fall back to the
# window title since niri's focused-window may not expose a pid.
has_nvim() {
    if [[ -n "$pid" && "$pid" != "null" ]]; then
        pstree -p "$pid" 2>/dev/null | grep -qE '\bnvim\(' && return 0
        ps --ppid "$pid" -o comm= 2>/dev/null | grep -q '^nvim$' && return 0
    fi
    [[ "$title" == *nvim* || "$title" == *NVIM* ]] && return 0
    return 1
}

case "$class" in
    kitty|foot|Alacritty|alacritty)
        if has_nvim; then
            label="THINKING"; cls="thinking"
        else
            label="TERMINAL"; cls="terminal"
        fi ;;
    brave-browser|firefox|zen|app.zen_browser.zen|Brave-browser)
        label="BROWSE"; cls="browse" ;;
    code|Code|code-url-handler|VSCodium|cursor)
        label="CODING"; cls="coding" ;;
    org.gnome.Nautilus|nautilus|yazi)
        label="FILES"; cls="files" ;;
    discord|TelegramDesktop|Slack)
        label="CHAT"; cls="chat" ;;
    spotify|Spotify|mpv|mpris|com.spotify.Client)
        label="LISTENING"; cls="listening" ;;
    steam|steam_app_*|gamescope|Lutris|lutris)
        label="PLAY"; cls="play" ;;
    "")
        label="IDLE"; cls="idle" ;;
    *)
        label="$(echo "$class" | tr '[:lower:]' '[:upper:]' | cut -c1-10)"
        cls="idle" ;;
esac

printf '{"text":"  %s","class":"%s","alt":"%s"}\n' "$label" "$cls" "$class"
