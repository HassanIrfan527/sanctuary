# qutebrowser — Signal (or Flare, its light printing)
# Entry point. qutebrowser only runs this file; everything else is
# config.source()'d from here, in order (a later file wins on conflicts).

import importlib

import theme

# :config-source re-runs this file but Python keeps `theme` cached — reload it
# so a style switch (shell.sh → Signal/Flare) is actually read.
importlib.reload(theme)
from theme import font, light  # noqa: E402

# config.py is the only source of truth — :set changes don't survive a restart.
config.load_autoconfig(False)

# -- Fonts --
# Every UI font setting (tabs, statusbar, completion, hints, prompts,
# messages, downloads, keyhint, contextmenu, debug console) defaults to
# "default_size default_family", so these two lines reach all of them.
c.fonts.default_family = font["family"]
c.fonts.default_size = font["size"]

# -- Web pages: Flare asks sites for their light look; Signal keeps the default --
c.colors.webpage.preferred_color_scheme = "light" if light else "auto"

# -- Categories --
config.source("tabs.py")
config.source("statusbar.py")
