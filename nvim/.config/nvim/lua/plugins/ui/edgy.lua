-- Panel layout manager: pins neo-tree (left), terminals (bottom/right) into
-- stable slots so Neovim's window equalization never steals their dimensions.
-- Both bottom and right slots share ft = "snacks_terminal", so filters on the
-- buffer name discriminate them: trails/claude/cursor-agent go right,
-- plain shell goes bottom. Buffer names look like: term://...//<pid>:/path/to/cmd
--
-- The picker is `trails` (plugins/agents.lua runs it by absolute path when it can,
-- by bare name otherwise), so the name ends in "/trails" or ":trails". Anchored at
-- the end, because "trails" is a word a plain shell's path could also contain, and
-- spelled out because a miss lands every agent panel silently in the *bottom* slot.
local function is_right_terminal(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name:find("claude", 1, true) ~= nil
      or name:find("cursor-agent", 1, true) ~= nil
      or name:match("[:/]trails$") ~= nil
end

local function is_float_terminal(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name:find("btop", 1, true) ~= nil
      or name:find("htop", 1, true) ~= nil
end

-- Resizable slots. Edgy re-applies each view's `size` on every WinResized, so
-- a mouse drag is snapped straight back. Sizes are read through `size()`
-- instead, and a drag or a `<C-w>` step below is recorded here, so it sticks —
-- per slot rather than per window, so it survives toggling the panel off and
-- on (edgy's own per-window override dies with the window). In memory only: a
-- new nvim starts from the defaults. `<C-w>=` in a panel forgets them.
local defaults = { left = 30, bottom = 20, right = 0.4 }
local sizes = {}

local function size(pos)
  return function() return sizes[pos] or defaults[pos] end
end

local function dim_of(pos)
  return (pos == "left" or pos == "right") and "width" or "height"
end

-- What edgy would set the slot to right now, in cells.
local function target(pos)
  local s = sizes[pos] or defaults[pos]
  local max = dim_of(pos) == "width" and vim.o.columns or vim.o.lines
  return math.max(s < 1 and math.floor(max * s) or s, 1)
end

local function step(dim, amount)
  return function(win)
    local pos = win.view.edgebar.pos
    if dim_of(pos) ~= dim then return end
    sizes[pos] = math.max(target(pos) + amount, 1)
    require("edgy.layout").update()
  end
end

-- Only a mouse drag is recorded. Anything else that resizes a panel is a
-- layout change, not a choice: opening the agent panel squeezes the editor to
-- one column and hands the rest to neo-tree (measured: 30 -> 117), a terminal
-- resize reflows every window. Recording those is what edgy is there to undo.
--
-- Must be registered before edgy's own WinResized handler, which would
-- otherwise snap the window back before this sees the new size. The flag
-- outlives the release and drops at the next key instead: a quick last drag
-- and its release can arrive together, ahead of that drag's WinResized.
local function record_resizes()
  local dragging = false
  local drag, release = vim.keycode("<LeftDrag>"), vim.keycode("<LeftRelease>")
  vim.on_key(function(key)
    dragging = key == drag or (key == release and dragging)
  end, vim.api.nvim_create_namespace("edgy_remember_size"))

  vim.api.nvim_create_autocmd("WinResized", {
    group = vim.api.nvim_create_augroup("edgy_remember_size", { clear = true }),
    callback = function()
      if not dragging then return end
      for _, win in ipairs(vim.v.event.windows) do
        local w = vim.api.nvim_win_is_valid(win) and require("edgy.editor").get_win(win)
        if w then
          local pos = w.view.edgebar.pos
          local dim = dim_of(pos)
          local current = vim.api["nvim_win_get_" .. dim](win)
          if current ~= target(pos) then sizes[pos] = current end
        end
      end
    end,
  })
end


return {
  "folke/edgy.nvim",
  event = "VeryLazy",
  config = function(_, opts)
    record_resizes()
    require("edgy").setup(opts)
  end,
  opts = {
    animate = { enabled = false },

    left = {
      {
        ft = "neo-tree",
        size = { width = size("left") },
        pinned = true,  -- reserve the slot even when neo-tree is toggled off
        open = "Neotree",
      },
    },

    bottom = {
      {
        ft = "snacks_terminal",
        size = { height = size("bottom") },
        wo = { winbar = false },
        filter = function(buf, _win)
          return not is_right_terminal(buf) and not is_float_terminal(buf)
        end,
      },
    },

    right = {
      -- Claude Code and Cursor share this slot. The mutual-exclusion logic in
      -- agents.lua keeps them alternating, so only one is visible at a time.
      {
        ft = "snacks_terminal",
        size = { width = size("right") },
        wo = { winbar = false },
        filter = function(buf, _win)
          return is_right_terminal(buf)
        end,
      },
    },

    -- Applied to every edgy-managed window
    wo = {
      winfixwidth    = true,
      winfixheight   = true,
      spell          = false,
      signcolumn     = "no",
      number         = false,
      relativenumber = false,
      winhighlight   = "Normal:NeoTreeNormal,NormalNC:NeoTreeNormalNC",
    },

    exit_when_last = false,

    -- In a panel (normal mode): step the slot's size, or forget every
    -- remembered size. Replaces edgy's per-window versions so a step sticks
    -- the same way a drag does.
    keys = {
      ["<c-w>>"]    = step("width", 2),
      ["<c-w><lt>"] = step("width", -2),
      ["<c-w>+"]    = step("height", 2),
      ["<c-w>-"]    = step("height", -2),
      ["<c-w>="]    = function(win)
        sizes = {}
        win.view.edgebar:equalize()
      end,
    },
  },

  keys = {
    {
      "<leader>up",
      function()
        -- No load needed first: every manager registers itself when its spec
        -- file is evaluated (plugins/agents.lua calls term_sessions.new at the
        -- top level), which lazy does during setup, long before this can fire.
        require("util.term_sessions").picker()
      end,
      desc = "Pick panel/session",
    },
    { "<leader>uP", function() require("edgy").goto_main() end, desc = "Focus editor (Edgy)" },
  },
}
