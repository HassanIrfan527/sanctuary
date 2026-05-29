#!/usr/bin/env bash
# Zen mode toggle: hide bars + DND + bigger gaps/rounding + hard dim.
# Reversible — exit restores everything via `hyprctl reload`.

set -euo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/zen-mode.on"

enter_zen() {
    # remember if the bottom bar was up so we can bring it back
    if pgrep -f 'waybar.*bottom\.jsonc' >/dev/null; then
        echo "bottom" > "$STATE"
    else
        echo "" > "$STATE"
    fi

    pkill -x waybar || true
    swaync-client --dnd-on >/dev/null 2>&1 || true

    hyprctl --batch "\
        keyword general:gaps_out 60;\
        keyword general:gaps_in 14;\
        keyword decoration:rounding 20;\
        keyword decoration:dim_strength 0.55" >/dev/null

    # faint center kanji watermark (click-through overlay)
    setsid -f waybar -c ~/.config/waybar/zen-kanji.jsonc -s ~/.config/waybar/zen-kanji.css >/dev/null 2>&1

    # cozy terminal — only if this workspace is empty, so we never split an existing window
    if [[ "$(hyprctl activeworkspace -j | grep -o '"windows": *[0-9]*' | grep -o '[0-9]*')" == "0" ]]; then
        setsid -f kitty --class=cozy \
            -o font_size=16 -o window_padding_width=24 -o background_opacity=0.88 \
            >/dev/null 2>&1
    fi

    notify-send "Zen" "On — breathe." 2>/dev/null || true
}

exit_zen() {
    # drop the kanji watermark
    pkill -f 'zen-kanji\.jsonc' || true

    # restore gaps/rounding/dim/etc from the config file
    hyprctl reload >/dev/null

    # bars back
    setsid -f waybar >/dev/null 2>&1
    if [[ "$(cat "$STATE" 2>/dev/null)" == "bottom" ]]; then
        setsid -f waybar -c ~/.config/waybar/bottom.jsonc -s ~/.config/waybar/bottom.css >/dev/null 2>&1
    fi

    swaync-client --dnd-off >/dev/null 2>&1 || true
    rm -f "$STATE"
    notify-send "Zen" "Off — welcome back." 2>/dev/null || true
}

if [[ -f "$STATE" ]]; then
    exit_zen
else
    enter_zen
fi
