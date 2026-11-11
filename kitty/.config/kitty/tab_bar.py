# Equal-width tab bar with switchable separators.
# Wired from kitty.conf via: tab_bar_style custom, tab_title_template "{custom}"
#
# Separator styles (change SEPARATOR_STYLE below, then reload Cmd+Ctrl+,):
#   slanted — powerline  / ╱ (same glyphs as tab_powerline_style slanted)
#   hard    — ▌ on a colour change, │ between same-bg tabs

from __future__ import annotations

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, wcswidth
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title as kitty_draw_title

SEPARATOR_STYLE = "slanted"

# Preferred floor from the old fixed tab_title_max_length. Equal share wins when
# larger; when n * MIN would not fit, tabs still shrink equally (titles truncate).
MIN_TAB_WIDTH = 28

REMOTE_MARKER = "🖥️ "

# (hard, soft) — hard bleeds when neighbouring tab backgrounds differ.
SEPARATORS: dict[str, tuple[str, str]] = {
    "slanted": ("", "╱"),
    "hard": ("▌", "│"),
}


def _is_remote(data: dict) -> bool:
    """True when the tab's active pane is plain ssh or kitten ssh."""
    try:
        tab = get_boss().tab_for_id(data["tab"].tab_id)
        win = tab.active_window if tab else None
        if win is None:
            return False
        return win.child_is_remote or bool(win.ssh_kitten_cmdline())
    except Exception:
        # Never break the tab bar if process inspection fails.
        return False


def _fit(text: str, width: int) -> str:
    if width <= 0:
        return ""
    if wcswidth(text) <= width:
        return text
    if width == 1:
        return "…"
    budget = width - 1  # room for …
    out = ""
    for ch in text:
        if wcswidth(out + ch) > budget:
            break
        out += ch
    return out + "…"


def _center(text: str, width: int) -> str:
    text = _fit(text, width)
    pad = max(0, width - wcswidth(text))
    left = pad // 2
    return (" " * left) + text + (" " * (pad - left))


def draw_title(data: dict) -> str:
    """Title for tab_title_template "{custom}": "N: [🖥️ ]title", centred."""
    marker = REMOTE_MARKER if _is_remote(data) else ""
    width = int(data.get("max_title_length") or MIN_TAB_WIDTH)
    label = f"{data['index']}: {marker}{data['title']}"
    return _center(label, width)


def _sep_pair() -> tuple[str, str]:
    return SEPARATORS.get(SEPARATOR_STYLE, SEPARATORS["slanted"])


def _tab_title_width(screen: Screen, index: int, sep_cells: int) -> int:
    """Equal share of the bar for this tab's title region (1-based index)."""
    tm = get_boss().active_tab_manager
    ntabs = len(tm.tabs) if tm else 1
    ntabs = max(1, ntabs)
    ncols = max(0, screen.columns - sep_cells)
    width = ncols // ntabs
    # Hand leftover columns to the leftmost tabs.
    if index <= ncols % ntabs:
        width += 1
    return max(1, width)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Full-width bar; every tab gets ~columns/n cells."""
    del max_tab_length  # equal-width layout owns sizing
    hard, soft = _sep_pair()
    sep_width = max(wcswidth(hard), wcswidth(soft), 1)
    tm = get_boss().active_tab_manager
    ntabs = max(1, len(tm.tabs) if tm else 1)
    # Separator after every tab (last bleeds into the bar background).
    title_width = _tab_title_width(screen, index, ntabs * sep_width)
    tab_width = title_width + sep_width

    if extra_data.for_layout:
        screen.cursor.x = before + tab_width
        return screen.cursor.x

    tab_bg = screen.cursor.bg
    tab_fg = screen.cursor.fg
    default_bg = as_rgb(int(draw_data.default_bg))

    screen.cursor.x = before
    if title_width <= 3:
        screen.draw(_center("…", title_width))
    else:
        kitty_draw_title(draw_data, screen, tab, index, title_width)
        used = screen.cursor.x - before
        if used < title_width:
            screen.draw(" " * (title_width - used))
        elif used > title_width:
            screen.cursor.x = before + title_width - 1
            screen.draw("…")

    next_tab = extra_data.next_tab
    next_tab_bg = as_rgb(draw_data.tab_bg(next_tab)) if next_tab else default_bg
    if next_tab_bg != tab_bg:
        screen.cursor.fg = tab_bg
        screen.cursor.bg = next_tab_bg
        screen.draw(hard)
    else:
        prev_fg = screen.cursor.fg
        screen.cursor.bg = tab_bg
        if tab_bg == tab_fg:
            screen.cursor.fg = default_bg
        screen.draw(soft)
        screen.cursor.fg = prev_fg

    if is_last and (extra := screen.columns - screen.cursor.x) > 0:
        screen.cursor.bg = default_bg
        screen.draw(" " * extra)

    screen.cursor.fg = tab_fg
    screen.cursor.bg = tab_bg
    return screen.cursor.x
