#!/usr/bin/env bash
# Toggle study mode: hosts blocking, app close, wallpaper, border color.
# Usage:
#   study-mode.sh on | off | toggle | status
#   default action: toggle

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCKLIST="$SCRIPT_DIR/blocklist.txt"
STATE_DIR="$HOME/.cache/study-mode"
STATE="$STATE_DIR/state"
HOSTS_BACKUP="$STATE_DIR/hosts.backup"
HOSTS="/etc/hosts"
MARKER_START="# >>> STUDY MODE START >>>"
MARKER_END="# <<< STUDY MODE END <<<"

WALLPAPER_STUDY="$HOME/Pictures/calm.jpg"
WALLPAPER_NORMAL="$HOME/Pictures/daredevil-2.jpg"
BORDER_STUDY="rgba(7fbfaeff)"
BORDER_NORMAL=""  # restore via reload

KILL_APPS=(steam lutris)

mkdir -p "$STATE_DIR"

notify() { command -v notify-send >/dev/null && notify-send -a "study-mode" "$1" "${2:-}" || true; }

is_on() { [[ -f "$STATE" && "$(cat "$STATE")" == "on" ]]; }

write_hosts_block() {
    local tmp; tmp="$(mktemp)"
    awk -v s="$MARKER_START" -v e="$MARKER_END" '
        $0==s {skip=1; next}
        $0==e {skip=0; next}
        !skip
    ' "$HOSTS" > "$tmp"
    {
        echo "$MARKER_START"
        while IFS= read -r d; do
            [[ -z "$d" || "$d" =~ ^# ]] && continue
            echo "0.0.0.0 $d"
        done < "$BLOCKLIST"
        echo "$MARKER_END"
    } >> "$tmp"
    sudo install -m 644 "$tmp" "$HOSTS"
    rm -f "$tmp"
}

remove_hosts_block() {
    local tmp; tmp="$(mktemp)"
    awk -v s="$MARKER_START" -v e="$MARKER_END" '
        $0==s {skip=1; next}
        $0==e {skip=0; next}
        !skip
    ' "$HOSTS" > "$tmp"
    sudo install -m 644 "$tmp" "$HOSTS"
    rm -f "$tmp"
}

apply_visuals_on() {
    [[ -f "$WALLPAPER_STUDY" ]] && swww img "$WALLPAPER_STUDY" --transition-type fade --transition-duration 1 >/dev/null 2>&1 || true
    hyprctl --batch "keyword general:col.active_border $BORDER_STUDY ; keyword general:col.inactive_border rgba(2c3a37aa)" >/dev/null
}

apply_visuals_off() {
    [[ -f "$WALLPAPER_NORMAL" ]] && swww img "$WALLPAPER_NORMAL" --transition-type fade --transition-duration 1 >/dev/null 2>&1 || true
    hyprctl reload >/dev/null
}

kill_distractions() {
    for app in "${KILL_APPS[@]}"; do
        pkill -x "$app" 2>/dev/null || true
    done
}

inject_window_kill_rules() {
    for app in "${KILL_APPS[@]}"; do
        hyprctl keyword windowrulev2 "close, class:^(?i)(${app}).*" >/dev/null 2>&1 || true
    done
}

mode_on() {
    if is_on; then notify "Study mode" "Already on."; exit 0; fi
    write_hosts_block
    kill_distractions
    inject_window_kill_rules
    apply_visuals_on
    echo on > "$STATE"
    date +%s > "$STATE_DIR/started_at"
    notify "Study mode: ON" "Distractions blocked. You've got this."
}

mode_off_now() {
    remove_hosts_block
    apply_visuals_off
    echo off > "$STATE"
    rm -f "$STATE_DIR/started_at"
    notify "Study mode: OFF" "Welcome back. Did you finish your Pomodoros?"
}

mode_off_friction() {
    if ! is_on; then notify "Study mode" "Already off."; exit 0; fi
    local typed
    typed="$(printf '' | fuzzel --dmenu --prompt='type DISABLE to turn off study mode > ' || true)"
    if [[ "$typed" != "DISABLE" ]]; then
        notify "Study mode" "Disable cancelled. Stay strong."
        exit 0
    fi
    notify "Study mode" "Disabling in 60s..."
    sleep 30
    notify "Study mode" "Disabling in 30s..."
    sleep 20
    notify "Study mode" "Disabling in 10s..."
    sleep 10
    mode_off_now
}

case "${1:-toggle}" in
    on)     mode_on ;;
    off)    mode_off_friction ;;
    force-off) mode_off_now ;;
    toggle) if is_on; then mode_off_friction; else mode_on; fi ;;
    status) is_on && echo on || echo off ;;
    *) echo "usage: $0 {on|off|toggle|force-off|status}"; exit 2 ;;
esac
