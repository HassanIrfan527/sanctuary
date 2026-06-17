#!/usr/bin/env bash
# mode-detector.sh — emit JSON for waybar custom/mode (bottom bar).
# Maps the focused window's class (and descendants for terminals)
# to a mode label + CSS class.

set -euo pipefail

class=""
pid=""
title=""

# Focused-window info, compositor-aware. niri's `app_id` == Hyprland's `class`.
if [[ "${XDG_CURRENT_DESKTOP:-}" == niri || -n "${NIRI_SOCKET:-}" ]]; then
    json="$(niri msg -j focused-window 2>/dev/null || echo '{}')"
    [ -z "$json" ] && json='{}'
    class="$(printf '%s' "$json" | jq -r '.app_id // empty' 2>/dev/null)" || true
    pid="$(printf '%s' "$json" | jq -r '.pid // empty' 2>/dev/null)" || true
    title="$(printf '%s' "$json" | jq -r '.title // empty' 2>/dev/null)" || true
    wsname=""   # no special workspaces in this niri setup
else
    json="$(hyprctl activewindow -j 2>/dev/null || echo '{}')"
    class="$(printf '%s' "$json" | jq -r '.class // empty' 2>/dev/null)" || true
    pid="$(printf '%s' "$json" | jq -r '.pid // empty' 2>/dev/null)" || true
    title="$(printf '%s' "$json" | jq -r '.title // empty' 2>/dev/null)" || true
    wsname="$(printf '%s' "$json" | jq -r '.workspace.name // empty' 2>/dev/null)" || true
fi

class="${class:-}"
pid="${pid:-}"
title="${title:-}"
[ "$class" = "null" ] && class=""
[ "$pid" = "null" ] && pid=""
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
            label="TINKERING"
            cls="terminal"
        fi
        ;;
    brave-browser | firefox | zen | app.zen_browser.zen | Brave-browser | org.qutebrowser.qutebrowser)
        case "${title,,}" in
        *"youtube music"* | *"music.youtube"*)
            label="VIBING"
            cls="listening"
            ;;
        *youtube* | *twitch* | *netflix* | *"prime video"*)
            label="WATCHING"
            cls="watching"
            ;;
        *gmail* | *"proton mail"* | *outlook*)
            label="INBOX-ING"
            cls="reading"
            ;;
        *github* | *gitlab* | *"stack overflow"*)
            label="BUILDING"
            cls="coding"
            ;;
        *chatgpt* | *claude* | *perplexity* | *gemini*)
            label="PROMPTING"
            cls="thinking"
            ;;
        *figma* | *excalidraw* | *canva*)
            label="DESIGNING"
            cls="creating"
            ;;
        *"google docs"* | *notion* | *overleaf*)
            label="WRITING"
            cls="notes"
            ;;
        *reddit* | *twitter* | *instagram* | *"/ x"*)
            label="DOOMSCROLL"
            cls="chat"
            ;;
        *)
            label="SURFING"
            cls="browse"
            ;;
        esac
        ;;
    code | Code | code-url-handler | dev.zed.Zed | zed | nvim | NVIM)
        label="BUILDING"
        cls="coding"
        ;;
    org.gnome.Nautilus | nautilus | yazi)
        label="DIGGING"
        cls="files"
        ;;
    discord | VESKTOP | vesktop)
        label="YAPPING"
        cls="chat"
        ;;
    spotify | Spotify | com.spotify.Client | mpris)
        label="VIBING"
        cls="listening"
        ;;
    mpv | vlc | VLC | io.github.celluloid_player.Celluloid)
        label="WATCHING"
        cls="watching"
        ;;
    steam | steam_app_* | gamescope | Lutris | lutris | heroic)
        label="GAMING"
        cls="play"
        ;;
    obsidian | Obsidian | logseq | Logseq)
        label="SCRIBBLING"
        cls="notes"
        ;;
    org.pwmt.zathura | zathura | org.gnome.Evince | evince | com.github.johnfactotum.Foliate)
        label="READING"
        cls="reading"
        ;;
    gimp | GIMP | org.gimp.GIMP | krita | org.kde.krita | Inkscape | org.inkscape.Inkscape | blender | Blender)
        label="CREATING"
        cls="creating"
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

printf '{"text":"%s","class":"%s","alt":"%s"}\n' "$label" "$cls" "$class"
