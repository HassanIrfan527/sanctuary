# Signal / Flare tokens — values only, no settings.
# Every other file reads from here: `from theme import palette, font`.
# Signal is Catppuccin Mocha, same as DESIGN-BRIEF.md §4. Flare (2026-10-12)
# is the same names on Theme.qml's parchment palette.
#
# The desk style picks which: shell.sh writes the word to
# ~/.local/state/sanctuary/style and runs :config-source, and config.py reloads
# this module so the new word is read.

import os

_state = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
try:
    with open(os.path.join(_state, "sanctuary", "style")) as f:
        style = f.read().strip()
except OSError:
    style = "signal"
light = style == "flare"

_signal = {
    # fills
    "crust": "#11111b",
    "mantle": "#181825",
    "base": "#1e1e2e",
    # structure
    "surface0": "#313244",
    "surface1": "#45475a",
    "surface2": "#585b70",
    # text
    "overlay0": "#6c7086",
    "overlay1": "#7f849c",
    "overlay2": "#9399b2",
    "subtext0": "#a6adc8",
    "subtext1": "#bac2de",
    "text": "#cdd6f4",
    # accents — Signal spends colour on state only
    "rosewater": "#f5e0dc",
    "flamingo": "#f2cdcd",
    "pink": "#f5c2e7",
    "mauve": "#cba6f7",
    "red": "#f38ba8",
    "maroon": "#eba0ac",
    "peach": "#fab387",
    "yellow": "#f9e2af",
    "green": "#a6e3a1",
    "teal": "#94e2d5",
    "sky": "#89dceb",
    "sapphire": "#74c7ec",
    "blue": "#89b4fa",
    "lavender": "#b4befe",
}

# Flare: same keys, so no other file changes. Where a hue fails on paper the
# role moves, as in Theme.qml: `green` is the TRACE (selected tab, insert mode,
# progress), so it becomes ember; the rest are darkened to >= 4:1 on mantle.
_flare = {
    # fills
    "crust": "#e2d4ad",
    "mantle": "#eadfc0",
    "base": "#f1e8cf",
    # structure
    "surface0": "#d6c69c",
    "surface1": "#c6b48a",
    "surface2": "#a8986f",
    # text
    "overlay0": "#857a62",
    "overlay1": "#766c56",
    "overlay2": "#695f4c",
    "subtext0": "#5c5445",
    "subtext1": "#4a4439",
    "text": "#2b2838",
    # accents
    "rosewater": "#a05a4e",
    "flamingo": "#a5505a",
    "pink": "#a03f78",
    "mauve": "#74489a",
    "red": "#b0283c",
    "maroon": "#9c3346",
    "peach": "#17706a",      # Signal's warm second voice turns cool (the trace took warm)
    "yellow": "#8a6400",
    "green": "#b04a06",      # the trace: ember
    "teal": "#17706a",
    "sky": "#1f6f8a",
    "sapphire": "#245f94",
    "blue": "#3f56a6",
    "lavender": "#3f56a6",
}

palette = _flare if light else _signal

font = {
    "family": "DM Mono",
    "size": "11pt",
}
