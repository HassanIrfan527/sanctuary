# Signal / Flare / Lantern / Harvest tokens — values only, no settings.
# Every other file reads from here: `from theme import palette, font`.
# Signal is Catppuccin Mocha, same as DESIGN-BRIEF.md §4. Flare (2026-10-12)
# is the same names on Theme.qml's parchment palette. Lantern / Harvest
# (2026-10-16) are the same names on Theme.qml's lan* values.
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
light = style in ("flare", "harvest")

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

# Lantern / Harvest: same keys again, the pixel style's colour rules
# (docs/styles/lantern-harvest.md). `green` is what Signal spends on the
# selected tab, insert mode and progress — in Lantern that is YOU, so pink.
# Amber (light) takes lavender's hover / caret; red, yellow stay the machine's
# alarm and warn (orange); blue is the cyan of links and sound.
_lantern = {
    # fills: the night's ink
    "crust": "#0f0c1e",
    "mantle": "#1a1630",
    "base": "#1a1630",
    # structure
    "surface0": "#2c2650",
    "surface1": "#3a3366",
    "surface2": "#6e6288",
    # text
    "overlay0": "#9d8cb0",
    "overlay1": "#aa9cbb",
    "overlay2": "#b8abc4",
    "subtext0": "#d8c6a6",
    "subtext1": "#e8d6b4",
    "text": "#f2dcb0",
    # accents
    "rosewater": "#ffc2dc",
    "flamingo": "#ffc2dc",
    "pink": "#ff5c9d",
    "mauve": "#c79bd8",
    "red": "#e8423f",
    "maroon": "#ff8a7a",
    "peach": "#ffb347",
    "yellow": "#f08a3c",
    "green": "#ff5c9d",      # you: selected tab, insert mode, progress
    "teal": "#5fd3e0",
    "sky": "#5fd3e0",
    "sapphire": "#5fd3e0",
    "blue": "#5fd3e0",
    "lavender": "#ffb347",   # amber: hover, caret
}

_harvest = {
    # fills: paper
    "crust": "#d9b77c",
    "mantle": "#f6e2b3",
    "base": "#fff0cc",
    # structure
    "surface0": "#e8cc94",
    "surface1": "#d9b77c",
    "surface2": "#b0906a",
    # text
    "overlay0": "#8a5a3a",
    "overlay1": "#7a4e32",
    "overlay2": "#6a442c",
    "subtext0": "#5a3a26",
    "subtext1": "#4f3222",
    "text": "#4a2a1e",
    # accents
    "rosewater": "#a0405e",
    "flamingo": "#a0405e",
    "pink": "#b8286c",
    "mauve": "#7a4a8a",
    "red": "#a82418",
    "maroon": "#8a2a1e",
    "peach": "#a8561a",
    "yellow": "#c56a1a",
    "green": "#b8286c",      # you
    "teal": "#2f6fa0",
    "sky": "#2f6fa0",
    "sapphire": "#2f6fa0",
    "blue": "#2f6fa0",
    "lavender": "#a8561a",   # amber
}

palette = {"flare": _flare, "lantern": _lantern, "harvest": _harvest}.get(style, _signal)

font = {
    "family": "DM Mono",
    "size": "11pt",
}
