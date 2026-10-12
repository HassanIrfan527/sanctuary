# Status bar, command line, completion — one strip, Signal style.
# Colour is spent on state: everyday modes stay quiet, passthrough is loud.

from theme import palette

# -- Status bar: shape + readouts --
c.statusbar.position = "bottom"
c.statusbar.padding = {"top": 6, "bottom": 6, "left": 10, "right": 10}
c.statusbar.widgets = ["keypress", "search_match", "url", "scroll", "tabs", "progress"]

# -- Modes --
# (bg, fg) per mode. The bar stays crust; only the text says which mode.
modes = {
    "normal": ("crust", "text"),
    "command": ("crust", "text"),
    "insert": ("crust", "green"),          # live
    "caret": ("crust", "lavender"),        # touching text
    "caret.selection": ("crust", "lavender"),
    "passthrough": ("yellow", "crust"),    # loud on purpose: your binds are off
    "private": ("mantle", "mauve"),
    "command.private": ("mantle", "mauve"),
}
for mode, (bg, fg) in modes.items():
    config.set(f"colors.statusbar.{mode}.bg", palette[bg])
    config.set(f"colors.statusbar.{mode}.fg", palette[fg])

c.colors.statusbar.progress.bg = palette["green"]

# -- URL: https is normal, so it gets no colour --
c.colors.statusbar.url.fg = palette["text"]
c.colors.statusbar.url.success.https.fg = palette["subtext0"]
c.colors.statusbar.url.success.http.fg = palette["yellow"]
c.colors.statusbar.url.warn.fg = palette["yellow"]
c.colors.statusbar.url.error.fg = palette["red"]
c.colors.statusbar.url.hover.fg = palette["lavender"]

# -- Completion (the list above the command line) --
c.completion.shrink = True  # only as tall as its results
c.completion.scrollbar.width = 2
c.completion.scrollbar.padding = 0

c.colors.completion.fg = palette["text"]
c.colors.completion.odd.bg = palette["mantle"]
c.colors.completion.even.bg = palette["mantle"]  # no stripes
c.colors.completion.match.fg = palette["lavender"]

# category headers: labels dimmer than values, no grey gradient
c.colors.completion.category.bg = palette["crust"]
c.colors.completion.category.fg = palette["overlay0"]
c.colors.completion.category.border.top = palette["crust"]
c.colors.completion.category.border.bottom = palette["crust"]

# selected row: borders match the fill, so there's no boxed outline
c.colors.completion.item.selected.bg = palette["surface0"]
c.colors.completion.item.selected.fg = palette["text"]
c.colors.completion.item.selected.border.top = palette["surface0"]
c.colors.completion.item.selected.border.bottom = palette["surface0"]
c.colors.completion.item.selected.match.fg = palette["lavender"]

c.colors.completion.scrollbar.bg = palette["mantle"]
c.colors.completion.scrollbar.fg = palette["surface1"]
