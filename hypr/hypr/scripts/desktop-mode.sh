#!/usr/bin/env bash
set -euo pipefail

PRESETS_DIR="$HOME/.config/hypr/presets"
ACTIVE_FILE="$PRESETS_DIR/active.conf"
AGS_DIR="$HOME/.config/ags"
LOG=/tmp/desktop-mode.log

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >> "$LOG"; }

read_active() {
    [[ -f "$ACTIVE_FILE" ]] || { echo grid; return; }
    awk -F'=' '/\$DESKTOP_PRESET/ {gsub(/[[:space:]]/,"",$2); print $2; exit}' "$ACTIVE_FILE"
}

write_active() {
    local preset=$1
    printf '$DESKTOP_PRESET = %s\n' "$preset" > "$ACTIVE_FILE"
    log "active = $preset"
}

kill_shells() {
    pkill -x ags 2>/dev/null || true
    pkill -f 'gjs -m .*ags' 2>/dev/null || true
    pkill -x qs 2>/dev/null || true
    pkill -x quickshell 2>/dev/null || true
    sleep 0.3
}

start_shell() {
    local preset=$1
    export GI_TYPELIB_PATH="/usr/local/lib64/girepository-1.0:${GI_TYPELIB_PATH:-}"
    case "$preset" in
        sys24)
            log "starting ags app.sys24.ts"
            ( cd "$AGS_DIR" && setsid /usr/local/bin/ags run app.sys24.ts >> /tmp/ags-sys24.log 2>&1 & )
            ;;
        grid)
            log "starting ags app.grid.ts"
            ( cd "$AGS_DIR" && setsid /usr/local/bin/ags run app.grid.ts >> /tmp/ags-grid.log 2>&1 & )
            ;;
        qs)
            log "starting quickshell ii"
            setsid qs -c ii >> /tmp/qs.log 2>&1 &
            ;;
        *)
            log "unknown preset: $preset"
            return 1
            ;;
    esac
}

switch_to() {
    local preset=$1
    case "$preset" in sys24|grid|qs) ;; *) echo "usage: desktop-mode.sh {sys24|grid|qs|autostart|current}" >&2; exit 2;; esac
    write_active "$preset"
    kill_shells
    hyprctl reload >/dev/null
    sleep 0.3
    start_shell "$preset"
    echo "switched to $preset"
}

cmd=${1:-current}
case "$cmd" in
    sys24|grid|qs)
        switch_to "$cmd"
        ;;
    autostart)
        preset=$(read_active)
        log "autostart with preset=$preset"
        start_shell "$preset"
        ;;
    current)
        read_active
        ;;
    *)
        echo "usage: desktop-mode.sh {sys24|grid|qs|autostart|current}" >&2
        exit 2
        ;;
esac
