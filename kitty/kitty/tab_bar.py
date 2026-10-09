# Signal tab strip — kitty's tab bar drawn as the top rule of an instrument panel.
#
#   ┌ 01 PIXIECODE   02 NVIM •                                    GRID 110×39 ┐
#
# ┌ ┐  registration marks, trace green — the frame (DESIGN-BRIEF §2, SignalTicks.qml)
# 01   index: green when active, red when the tab rang its bell (Master Caution)
# NAME caps, value colour when active, label colour when not
# •    output arrived in a tab you are not looking at
# GRID the focused window's size in cells — a live readout where a clock would be
#
# Loaded by `tab_bar_style custom` (style-signal.conf). kitty only reads this file
# at startup and on config reload; an exception here falls back to the fade style.
from kitty.fast_data_types import Screen, get_boss
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

# Mocha, same names as Theme.qml's sig* tokens
VALUE = 0xCDD6F4   # text
LABEL = 0x6C7086   # overlay0
DIM = 0x585B70     # surface2
RULE = 0x313244    # surface0
HOT = 0xA6E3A1     # green
ALARM = 0xF38BA8   # red


def _pen(screen: Screen, fg: int, bold: bool = False) -> None:
    screen.cursor.fg = as_rgb(fg)
    screen.cursor.bg = 0          # 0 = the strip's own (glass) background
    screen.cursor.bold = bold
    screen.cursor.italic = False


def _name(title: str) -> str:
    # The shell titles tabs with the cwd; a path reads as its last folder.
    t = title.strip()
    if t.startswith(('~', '/')):
        t = t.rstrip('/').rsplit('/', 1)[-1] or t
    return t.upper()


def _grid() -> str:
    try:
        w = get_boss().active_window
        return f'{w.screen.columns}×{w.screen.lines}' if w else ''
    except Exception:
        return ''


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData,
    before: int, max_tab_length: int, index: int, is_last: bool,
    extra_data: ExtraData,
) -> int:
    if index == 1:
        _pen(screen, HOT)
        screen.draw('┌ ')

    mark = ALARM if tab.needs_attention else HOT if tab.is_active else DIM
    _pen(screen, mark)
    screen.draw(f'{index:02d} ')

    name = _name(tab.title)
    room = max(3, max_tab_length - 5)
    if len(name) > room:
        name = name[:room - 1] + '…'
    _pen(screen, VALUE if tab.is_active else LABEL)
    screen.draw(name)

    if tab.has_activity_since_last_focus and not tab.is_active:
        _pen(screen, HOT)
        screen.draw(' •')

    end = screen.cursor.x

    if not is_last:
        _pen(screen, RULE)
        screen.draw('   ')
        return end

    # Last tab: push the readout and the closing mark to the right edge.
    grid = _grid()
    tail = (f'GRID {grid} ┐' if grid else '┐')
    gap = screen.columns - screen.cursor.x - len(tail)
    if gap > 1:
        screen.draw(' ' * gap)
        if grid:
            _pen(screen, LABEL)
            screen.draw('GRID ')
            _pen(screen, VALUE)
            screen.draw(f'{grid} ')
        _pen(screen, HOT)
        screen.draw('┐')
    return end
