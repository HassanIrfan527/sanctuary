# qutebrowser — Signal
# Entry point. qutebrowser only runs this file; everything else is
# config.source()'d from here, in order (a later file wins on conflicts).

from theme import font

# config.py is the only source of truth — :set changes don't survive a restart.
config.load_autoconfig(False)

# -- Fonts --
# Every UI font setting (tabs, statusbar, completion, hints, prompts,
# messages, downloads, keyhint, contextmenu, debug console) defaults to
# "default_size default_family", so these two lines reach all of them.
c.fonts.default_family = font["family"]
c.fonts.default_size = font["size"]

# -- Categories --
config.source("tabs.py")
config.source("statusbar.py")
