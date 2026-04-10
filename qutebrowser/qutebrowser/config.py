config.load_autoconfig(False)

# -- Catppuccin Mocha Palette --
palette = {
    'rosewater': '#f5e0dc',
    'flamingo':  '#f2cdcd',
    'pink':      '#f5c2e7',
    'mauve':     '#cba6f7',
    'red':       '#f38ba8',
    'maroon':    '#eba0ac',
    'peach':     '#fab387',
    'yellow':    '#f9e2af',
    'green':     '#a6e3a1',
    'teal':      '#94e2d5',
    'sky':       '#89dceb',
    'sapphire':  '#74c7ec',
    'blue':      '#89b4fa',
    'lavender':  '#b4befe',
    'text':      '#cdd6f4',
    'subtext1':  '#bac2de',
    'subtext0':  '#a6adc8',
    'overlay2':  '#9399b2',
    'overlay1':  '#7f849c',
    'overlay0':  '#6c7086',
    'surface2':  '#585b70',
    'surface1':  '#45475a',
    'surface0':  '#313244',
    'base':      '#1e1e2e',
    'mantle':    '#181825',
    'crust':     '#11111b',
}

# -- Completion --
c.colors.completion.fg = palette['text']
c.colors.completion.odd.bg = palette['mantle']
c.colors.completion.even.bg = palette['mantle']
c.colors.completion.category.bg = palette['crust']
c.colors.completion.category.fg = palette['mauve']
c.colors.completion.category.border.top = palette['crust']
c.colors.completion.category.border.bottom = palette['crust']
c.colors.completion.item.selected.bg = palette['surface1']
c.colors.completion.item.selected.fg = palette['text']
c.colors.completion.item.selected.border.top = palette['surface1']
c.colors.completion.item.selected.border.bottom = palette['surface1']
c.colors.completion.item.selected.match.fg = palette['peach']
c.colors.completion.match.fg = palette['peach']
c.colors.completion.scrollbar.bg = palette['mantle']
c.colors.completion.scrollbar.fg = palette['mauve']

# -- Context Menu --
c.colors.contextmenu.menu.bg = palette['base']
c.colors.contextmenu.menu.fg = palette['text']
c.colors.contextmenu.selected.bg = palette['surface1']
c.colors.contextmenu.selected.fg = palette['text']
c.colors.contextmenu.disabled.bg = palette['base']
c.colors.contextmenu.disabled.fg = palette['overlay0']

# -- Downloads --
c.colors.downloads.bar.bg = palette['base']
c.colors.downloads.start.bg = palette['blue']
c.colors.downloads.start.fg = palette['crust']
c.colors.downloads.stop.bg = palette['green']
c.colors.downloads.stop.fg = palette['crust']
c.colors.downloads.error.bg = palette['red']
c.colors.downloads.error.fg = palette['crust']

# -- Hints --
c.colors.hints.bg = palette['peach']
c.colors.hints.fg = palette['crust']
c.colors.hints.match.fg = palette['surface0']

# -- Keyhint --
c.colors.keyhint.bg = palette['base']
c.colors.keyhint.fg = palette['text']
c.colors.keyhint.suffix.fg = palette['peach']

# -- Messages --
c.colors.messages.error.bg = palette['red']
c.colors.messages.error.fg = palette['crust']
c.colors.messages.error.border = palette['red']
c.colors.messages.info.bg = palette['base']
c.colors.messages.info.fg = palette['text']
c.colors.messages.info.border = palette['base']
c.colors.messages.warning.bg = palette['yellow']
c.colors.messages.warning.fg = palette['crust']
c.colors.messages.warning.border = palette['yellow']

# -- Prompts --
c.colors.prompts.bg = palette['mantle']
c.colors.prompts.fg = palette['text']
c.colors.prompts.border = palette['mauve']
c.colors.prompts.selected.bg = palette['surface1']
c.colors.prompts.selected.fg = palette['text']

# -- Statusbar (lualine-inspired: mode colors match your nvim bubbles) --
# Normal mode: violet/mauve accent (matches your lualine normal = violet)
c.colors.statusbar.normal.bg = palette['base']
c.colors.statusbar.normal.fg = palette['text']
# Insert mode: blue accent (matches your lualine insert = blue)
c.colors.statusbar.insert.bg = palette['blue']
c.colors.statusbar.insert.fg = palette['crust']
# Command mode: surface for subtle distinction
c.colors.statusbar.command.bg = palette['surface0']
c.colors.statusbar.command.fg = palette['text']
# Caret mode: mauve/violet (matches your lualine normal = violet)
c.colors.statusbar.caret.bg = palette['mauve']
c.colors.statusbar.caret.fg = palette['crust']
c.colors.statusbar.caret.selection.bg = palette['mauve']
c.colors.statusbar.caret.selection.fg = palette['crust']
# Passthrough mode: teal for a distinct visual cue
c.colors.statusbar.passthrough.bg = palette['teal']
c.colors.statusbar.passthrough.fg = palette['crust']
# Private browsing
c.colors.statusbar.private.bg = palette['surface1']
c.colors.statusbar.private.fg = palette['text']
# Progress bar
c.colors.statusbar.progress.bg = palette['mauve']
# URL colors
c.colors.statusbar.url.fg = palette['text']
c.colors.statusbar.url.hover.fg = palette['sky']
c.colors.statusbar.url.success.http.fg = palette['subtext0']
c.colors.statusbar.url.success.https.fg = palette['green']
c.colors.statusbar.url.error.fg = palette['red']
c.colors.statusbar.url.warn.fg = palette['yellow']

# -- Tabs (matching kitty active tab style: accent bg, dark fg) --
c.colors.tabs.bar.bg = palette['crust']
c.colors.tabs.odd.bg = palette['base']
c.colors.tabs.odd.fg = palette['overlay1']
c.colors.tabs.even.bg = palette['base']
c.colors.tabs.even.fg = palette['overlay1']
c.colors.tabs.selected.odd.bg = palette['mauve']
c.colors.tabs.selected.odd.fg = palette['crust']
c.colors.tabs.selected.even.bg = palette['mauve']
c.colors.tabs.selected.even.fg = palette['crust']
c.colors.tabs.pinned.odd.bg = palette['base']
c.colors.tabs.pinned.odd.fg = palette['overlay1']
c.colors.tabs.pinned.even.bg = palette['base']
c.colors.tabs.pinned.even.fg = palette['overlay1']
c.colors.tabs.pinned.selected.odd.bg = palette['mauve']
c.colors.tabs.pinned.selected.odd.fg = palette['crust']
c.colors.tabs.pinned.selected.even.bg = palette['mauve']
c.colors.tabs.pinned.selected.even.fg = palette['crust']
c.colors.tabs.indicator.start = palette['blue']
c.colors.tabs.indicator.stop = palette['mauve']
c.colors.tabs.indicator.error = palette['red']

# -- Webpage (force dark mode) --
c.colors.webpage.bg = palette['base']
c.colors.webpage.preferred_color_scheme = 'dark'
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = 'never'

# -- Fonts --
c.fonts.default_family = 'JetBrainsMono Nerd Font'
c.fonts.default_size = '11pt'

# -- UI --
c.tabs.position = 'top'
c.tabs.padding = {'bottom': 5, 'left': 8, 'right': 8, 'top': 5}
c.tabs.indicator.width = 3
c.tabs.favicons.scale = 1.0
c.completion.shrink = True
c.scrolling.smooth = True
c.statusbar.padding = {'bottom': 5, 'left': 6, 'right': 6, 'top': 5}
c.statusbar.widgets = ['keypress', 'search_match', 'url', 'scroll', 'history', 'tabs', 'progress']
c.hints.border = f'1px solid {palette["peach"]}'
c.hints.radius = 4

# -- Keybinds --

# J/K swapped: J=prev tab (left), K=next tab (right)
config.bind('J', 'tab-prev')
config.bind('K', 'tab-next')

# Space leader binds (mirroring nvim)
config.bind('<Space>x', 'tab-close')
config.bind('<Space>n', 'tab-next')
config.bind('<Space>p', 'tab-prev')
config.bind('<Space>b', 'bookmark-list')
config.bind('<Space>ff', 'cmd-set-text -s :open')
config.bind('<Space>fg', 'cmd-set-text /')
config.bind('<Space>fb', 'cmd-set-text -s :tab-select')
config.bind('<Space>fr', 'cmd-set-text -s :open -t {url:history}')

# H/L for back/forward (like browser vim extensions)
config.bind('H', 'back')
config.bind('L', 'forward')

# Space+sv for opening in new window
config.bind('<Space>sv', 'open -w')
