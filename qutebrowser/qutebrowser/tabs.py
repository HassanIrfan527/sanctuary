# Tab bar — thick, square, green = selected (Signal's selection colour).

from theme import palette

# -- Shape --
# Height = font (11pt, from theme.py) + vertical padding.
c.tabs.padding = {"top": 5, "bottom": 5, "left": 8, "right": 8}
c.tabs.indicator.width = 3
c.tabs.favicons.show = "always"

# -- Content --
c.tabs.title.format = "{audio}{index} {current_title}"
c.tabs.title.format_pinned = "{audio}{index}"

# -- Colour --
c.colors.tabs.bar.bg = palette["crust"]

# Odd and even tabs look the same, so set both from one loop.
# config.set() takes the setting name as a string, which lets us build it.
for parity in ("odd", "even"):
    for prefix in ("", "pinned."):
        # unselected: quiet fill, dim text
        config.set(f"colors.tabs.{prefix}{parity}.bg", palette["base"])
        config.set(f"colors.tabs.{prefix}{parity}.fg", palette["overlay1"])
        # selected: solid green, dark text
        config.set(f"colors.tabs.{prefix}selected.{parity}.bg", palette["green"])
        config.set(f"colors.tabs.{prefix}selected.{parity}.fg", palette["crust"])

# Loading strip: blue while loading -> green when done -> red on failure
c.colors.tabs.indicator.start = palette["blue"]
c.colors.tabs.indicator.stop = palette["green"]
c.colors.tabs.indicator.error = palette["red"]
c.colors.tabs.indicator.system = "none"  # flat colours, no gradient between start/stop
