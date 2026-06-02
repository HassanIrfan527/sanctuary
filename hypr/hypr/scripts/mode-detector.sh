#!/usr/bin/env bash
# mode-detector.sh — emit JSON for waybar custom/mode (bottom bar).
# Maps the focused window's class (and descendants for terminals)
# to a mode label + CSS class.

set -euo pipefail

class=""
pid=""
title=""

json="$(hyprctl activewindow -j 2>/dev/null || echo '{}')"
class="$(printf '%s' "$json" | jq -r '.class // empty' 2>/dev/null)" || true
pid="$(printf '%s' "$json" | jq -r '.pid // empty' 2>/dev/null)" || true
title="$(printf '%s' "$json" | jq -r '.title // empty' 2>/dev/null)" || true

class="${class:-}"
pid="${pid:-}"
title="${title:-}"
[ "$class" = "null" ] && class=""
[ "$pid" = "null" ] && pid=""

wsname="$(printf '%s' "$json" | jq -r '.workspace.name // empty' 2>/dev/null)" || true
[ "$wsname" = "null" ] && wsname=""

# walk process tree for nvim if the window is a terminal; fall back to the
# window title if the pid isn't available.
has_nvim() {
    if [[ -n "$pid" && "$pid" != "null" ]]; then
        pstree -p "$pid" 2>/dev/null | grep -qE '\bnvim\(' && return 0
        ps --ppid "$pid" -o comm= 2>/dev/null | grep -q '^nvim$' && return 0
    fi
    [[ "$title" == *nvim* || "$title" == *NVIM* ]] && return 0
    return 1
}

if [[ "$wsname" == special:* ]]; then
    label="SPECIAL"
    cls="special"
else
case "$class" in
kitty | foot | Alacritty | alacritty)
    if has_nvim; then
        label="THINKING"
        cls="thinking"
    else
        label="TERMINAL"
        cls="terminal"
    fi
    ;;
brave-browser | firefox | zen | app.zen_browser.zen | Brave-browser | org.qutebrowser.qutebrowser)
    label="BROWSE"
    cls="browse"
    ;;
code | Code | code-url-handler | nvim | NVIM)
    label="CODING"
    cls="coding"
    ;;
org.gnome.Nautilus | nautilus | yazi)
    label="FILES"
    cls="files"
    ;;
discord | TelegramDesktop | Slack | VESKTOP | vesktop)
    label="CHAT"
    cls="chat"
    ;;
spotify | Spotify | mpv | mpris | com.spotify.Client)
    label="LISTENING"
    cls="listening"
    ;;
mpv | vlc | VLC)
    label="WATCHING"
    cls="watching"
    ;;
steam | steam_app_* | gamescope | Lutris | lutris)
    label="PLAY"
    cls="play"
    ;;
"")
    label="IDLE"
    cls="idle"
    ;;
*)
    label="$(echo "$class" | tr '[:lower:]' '[:upper:]' | cut -c1-10)"
    cls="idle"
    ;;
esac
fi

printf '{"text":"  %s","class":"%s","alt":"%s"}\n' "$label" "$cls" "$class"
