#!/usr/bin/env bash
# Left-edge affirmation + quick-note drawer, built on gum (no nvim, no tmux).
#   top : a calm Japanese affirmation in a lavender box (affirmation.toml only)
#   below: an editable scratch note — Ctrl+D saves to ~/notes/scratch.md, Esc discards
# Same key dismisses it; a fresh affirmation each time you open.

set -euo pipefail

CLASS="affirm-drawer"
NOTE="$HOME/notes/scratch.md"
TOML="$HOME/.config/kotofetch/quotes/affirmation.toml"

LAV=183      # catppuccin lavender (256-color)
MUTE=244     # muted grey

# ── inner: runs inside the kitty terminal ──
if [[ "${1:-}" == "--inner" ]]; then
    mkdir -p "$(dirname "$NOTE")"
    [[ -f "$NOTE" ]] || : > "$NOTE"

    mapfile -t JP < <(grep -E '^japanese'    "$TOML" | sed -E 's/^japanese = "(.*)"$/\1/')
    mapfile -t EN < <(grep -E '^translation' "$TOML" | sed -E 's/^translation = "(.*)"$/\1/')
    n=${#JP[@]}; [[ "$n" -eq 0 ]] && n=1
    idx=$(( RANDOM % n ))
    jp="${JP[idx]:-}"; en="${EN[idx]:-}"

    clear; printf '\033[3J'
    gum style --align center --width 40 --padding "1 2" --margin "1 0 0 0" \
        --border rounded --border-foreground "$LAV" --foreground "$LAV" \
        "$jp"
    gum style --align center --width 43 --margin "0 0 1 0" \
        --foreground "$MUTE" "$en"

    if new=$(gum write --width 43 --height 14 --char-limit 0 \
                --header "scratch · ctrl+d saves · esc discards" \
                --header.foreground "$MUTE" \
                --placeholder "jot something…" \
                --value "$(cat "$NOTE")"); then
        printf '%s\n' "$new" > "$NOTE"
    fi
    exit 0
fi

# ── outer: toggle the kitty drawer ──
if pgrep -f "class=$CLASS" >/dev/null 2>&1; then
    pkill -f "class=$CLASS" 2>/dev/null || true
    exit 0
fi

setsid -f kitty --class="$CLASS" \
    -o background_opacity=0.92 \
    -o font_size=14 \
    -o window_padding_width=24 \
    -o cursor_blink_interval=0 \
    "$HOME/.config/hypr/scripts/affirmation.sh" --inner >/dev/null 2>&1
