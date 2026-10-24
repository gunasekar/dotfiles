# Prefix SSH/remote tab titles with a server emoji.
# Wired from kitty.conf via: tab_title_template "{custom}"

from kitty.boss import get_boss

REMOTE_MARKER = "🖥️ "
# Fallback when max_title_length is unset; keep in sync with tab_title_max_length.
TITLE_WIDTH = 28


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


def draw_title(data: dict) -> str:
    marker = REMOTE_MARKER if _is_remote(data) else ""
    width = data.get("max_title_length") or TITLE_WIDTH
    label = f"{data['index']}: {marker}{data['title']}"
    return f"{label:^{width}}"
