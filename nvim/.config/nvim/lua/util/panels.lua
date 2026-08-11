-- Window helpers shared by the panel definitions (bottom shell, right agent).
--
-- Snacks' `position` values map to full-screen splits: "bottom" is `botright
-- split` and "right" is `vertical botright split`. Both re-lay-out the *entire*
-- screen, so opening either panel resizes every other one — and a resize is a
-- real SIGWINCH to whatever is running in the other panels. Handing snacks
-- `relative = "win"` plus a specific window confines the split to that window
-- instead, leaving the other panels' dimensions untouched.
local M = {}

-- The window a panel should split: prefer the focused one when it's an editor
-- window (so the panel opens where you already are), else the first editor
-- window in the tab. Returns nil when the layout is all panels and there is
-- nothing to split — callers fall back to `relative = "editor"`.
function M.editor_win()
  local function is_editor(w)
    local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
    return ft ~= "snacks_terminal" and ft ~= "neo-tree"
        and vim.api.nvim_win_get_config(w).relative == ""
  end
  local cur = vim.api.nvim_get_current_win()
  if is_editor(cur) then return cur end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor(w) then return w end
  end
end

-- Feed keys to Neovim without re-triggering our own mappings.
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

-- The wheel, from normal or visual mode. Claiming the click below leaves you in
-- normal mode over a terminal buffer that may be showing an alternate-screen
-- program (tmux, an agent TUI, htop): there the buffer *is* the visible screen
-- with no scrollback behind it, so nvim has nothing to scroll and the wheel does
-- nothing at all — while in terminal mode it still works, because the event is
-- forwarded to the program, which does keep history. So hand it back.
--
-- <Esc> leads so this works from visual mode too, where a bare `i` is a text
-- object prefix rather than "enter terminal mode". It costs the selection, but
-- there is nothing off-screen to extend a selection onto anyway.
--
-- What the test measures is "this buffer has no scrollback", not "this is the
-- alternate screen" — those are the same thing for an alt-screen program and
-- only that thing in general. nvim *pads* a terminal buffer out to the grid:
-- measured, a shell that has printed one line sits at 18 buffer rows in an
-- 18-row grid, 17 of them blank. So a fresh shell matches too, and gets its
-- wheel forwarded to a program that ignores it, leaving you in terminal mode
-- where you were in normal mode. One <Esc> or click undoes that, and nvim had
-- nothing to scroll either way — that's the accepted cost of the right panel
-- (always alt-screen, always matching, always correctly forwarded) working at
-- all. It stops as soon as the shell scrolls one screen: 122 rows after 60
-- lines of output, and from then on nvim keeps the wheel.
--
-- Do not "fix" this by tightening == to a stricter equality. An earlier pass
-- moved it from <= to == on the strength of a fresh shell reading 19 lines in
-- 20 rows, i.e. apparently below the grid and so protected. That reading was
-- the winbar off-by-one below, not a short buffer; with the off-by-one gone the
-- two forms are identical, because of the padding above.
--
-- The grid is *not* nvim_win_get_height. That counts the winbar row and the
-- terminal grid does not, so a panel carrying a winbar sits one short of it
-- forever and the forward branch can never fire. Measured with `less` in the
-- bottom panel: 18 buffer rows in a window reporting 19. The right panel escapes
-- it only by pinning `winbar = ""` (agents.lua) — drop that pin and scrolling
-- there silently stops working. The bottom panel keeps snacks' default
-- "<id>: <term_title>", worth having with several sessions down there, so
-- subtract the row rather than assume it's absent.
--
-- Direction-aware variants ("can nvim still scroll up?") were rejected: they
-- forward the moment you reach either end, so scrolling to the bottom of real
-- scrollback would throw you into terminal mode just as you got there.
--
-- The pointer check comes first because a wheel event is positional while a
-- buffer-local mapping is not: nvim scrolls the window under the pointer, but
-- picks the mapping from the *focused* buffer. With a panel focused and the
-- pointer over the editor, this fired for the panel and put us in terminal mode
-- there — measured — for a scroll that belonged to another window entirely.
--
-- No liveness check: a panel whose process died (snacks keeps the buffer when one
-- exits non-zero) needs none. `i` on a dead terminal buffer enters terminal mode
-- silently rather than erroring, and there is nothing to detect it with anyway —
-- measured, `&channel` keeps its number and nvim_get_chan_info still answers
-- after the process is gone.
local function wheel(key)
  return function()
    local grid = vim.api.nvim_win_get_height(0) - (vim.wo.winbar ~= "" and 1 or 0)
    if vim.fn.getmousepos().winid ~= vim.api.nvim_get_current_win()
        or vim.api.nvim_buf_line_count(0) > grid then
      feed(key)
    else
      feed("<Esc>i" .. key)
    end
  end
end

-- Mouse handling shared by both panels, so a click means the same thing in
-- either one. A shell never asks for mouse reporting, so nvim keeps the events
-- and the bottom panel has always behaved this way for free: a click leaves
-- terminal mode, a drag makes a Visual selection. Alternate-screen programs
-- *do* enable reporting — agent TUIs, and tmux when a session is wrapped in one
-- — so nvim forwarded every click and drag to them and neither was selectable.
-- A mapping is checked before that forwarding, so claim the press and replay it
-- in normal mode: the drag, release and selection that follow are then ordinary
-- nvim, and a yank lands in the system clipboard like any other.
--
-- The replayed <LeftMouse> carries no coordinates of its own — nvim decodes them
-- into its mouse position when the event arrives, before mappings run, and reads
-- them back from there — so the click lands where you clicked.
--
-- <LeftDrag> is mapped as well as <LeftMouse> for the click that *enters* a
-- panel from another window: snacks' auto_insert startinserts on BufEnter, so
-- the press is spent switching windows and the drag arrives in terminal mode
-- with nothing having claimed it.
--
-- Only the left button: the wheel and right-click are never claimed in terminal
-- mode, so a program's own scrollback and menus still work — and `wheel` above
-- hands the wheel back to it from normal mode too.
--
-- Scoped to the panels rather than every terminal buffer on purpose. Lazygit
-- (<leader>gg) and the btop float open their own terminals outside the panel
-- manager, and both are worth clicking around in, so they keep their mouse. The
-- flip side is that an alternate-screen program started *inside* a panel — a
-- `tmux a` or an htop at the bottom panel's prompt — does give up left-click.
function M.terminal_keys()
  return {
    term_wheel_up = {
      "<ScrollWheelUp>",
      wheel("<ScrollWheelUp>"),
      mode = { "n", "v" },
      desc = "Scroll the program, not the buffer",
    },
    term_wheel_down = {
      "<ScrollWheelDown>",
      wheel("<ScrollWheelDown>"),
      mode = { "n", "v" },
      desc = "Scroll the program, not the buffer",
    },
    term_mouse = {
      "<LeftMouse>",
      function() feed("<C-\\><C-n><LeftMouse>") end,
      mode = "t",
      desc = "Click to normal mode",
    },
    term_mouse_drag = {
      "<LeftDrag>",
      function() feed("<C-\\><C-n><LeftDrag>") end,
      mode = "t",
      desc = "Drag to visual select",
    },
  }
end

return M
