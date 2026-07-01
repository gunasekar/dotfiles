-- Snacks.nvim - Collection of small QoL plugins

-- CWD is pinned on first open so snacks.terminal.tid() always returns the
-- same ID regardless of which window has focus when the key is pressed.
local shell_cwd = nil

local function toggle_bottom_panel()
  local shell_t = shell_cwd and Snacks.terminal.get(nil, {
    count = 1, cwd = shell_cwd, create = false,
  })
  if shell_t and shell_t:valid() then
    shell_t:hide()
  else
    if not shell_cwd then shell_cwd = vim.fn.getcwd() end
    Snacks.terminal.toggle(nil, {
      win = { position = "bottom", height = 20 },
      count = 1,
      cwd = shell_cwd,
    })
  end
end

-- Native float for a process monitor: btop if installed, htop otherwise.
-- Bypasses snacks/edgy so it never lands in a panel slot.
local monitor_cmd = vim.fn.executable("btop") == 1 and "btop" or "htop"
local monitor = { buf = nil, win = nil }
local function toggle_htop()
  if monitor.win and vim.api.nvim_win_is_valid(monitor.win) then
    vim.api.nvim_win_close(monitor.win, false)
    monitor.win = nil
    return
  end
  if monitor.buf and not vim.api.nvim_buf_is_valid(monitor.buf) then
    monitor.buf = nil
  end
  local cols, lines = vim.o.columns, vim.o.lines
  local w, h = math.floor(cols * 0.8), math.floor(lines * 0.8)
  monitor.win = vim.api.nvim_open_win(
    monitor.buf or vim.api.nvim_create_buf(false, true),
    true,
    {
      relative = "editor",
      width    = w,
      height   = h,
      col      = math.floor((cols - w) / 2),
      row      = math.floor((lines - h) / 2),
      style    = "minimal",
      border   = "rounded",
    }
  )
  monitor.buf = vim.api.nvim_win_get_buf(monitor.win)
  if vim.bo[monitor.buf].buftype ~= "terminal" then
    vim.fn.termopen(monitor_cmd, {
      on_exit = function()
        vim.schedule(function()
          if monitor.win and vim.api.nvim_win_is_valid(monitor.win) then
            vim.api.nvim_win_close(monitor.win, true)
          end
          monitor.buf = nil
          monitor.win = nil
        end)
      end,
    })
  end
  -- normal-mode q closes the float without killing the process
  vim.keymap.set("n", "q", toggle_htop, { buffer = monitor.buf, desc = "Close monitor float" })
  vim.cmd("startinsert")
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- Handle large files gracefully
    bigfile = { enabled = true },

    -- Buffer deletion that preserves window layout
    bufdelete = { enabled = true },

    -- Better input prompts
    input = { enabled = true },

    -- Notification system
    notifier = {
      enabled = true,
      timeout = 3000,
      top_down = false, -- Stack from bottom to top (bottom-right corner)
      margin = { top = 0, right = 1, bottom = 0 },
    },

    -- File picker (alternative to Telescope)
    picker = {
      enabled = true,
      sources = {
        files = { hidden = true },
      },
    },

    -- File explorer (alternative to Neo-tree)
    explorer = { enabled = false }, -- Disabled: using Neo-tree instead

    -- Fast file loading
    quickfile = { enabled = true },

    -- Scope detection
    scope = { enabled = true },

    -- Better statuscolumn
    statuscolumn = { enabled = true },

    -- Highlight word under cursor
    words = { enabled = true },

    -- Scroll animations (disabled - can be distracting)
    scroll = { enabled = false },

    -- Indent guides (disabled - using indent-blankline)
    indent = { enabled = false },
  },

  keys = {
    -- Words navigation
    {
      "]]",
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = "Next Reference",
      mode = { "n", "t" },
    },
    {
      "[[",
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = "Prev Reference",
      mode = { "n", "t" },
    },

    -- Snacks picker (alternative to Telescope)
    {
      "<leader><space>",
      function()
        Snacks.picker.smart()
      end,
      desc = "Smart Find (Snacks)",
    },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>sn",
      function()
        Snacks.picker.notifications()
      end,
      desc = "Search Notifications",
    },

    -- Snacks explorer (disabled - using Neo-tree)
    -- {
    --   "<leader>E",
    --   function()
    --     Snacks.explorer()
    --   end,
    --   desc = "Explorer (Snacks)",
    -- },

    -- Buffer management with Snacks
    {
      "<leader>bb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Browse Buffers (Snacks)",
    },
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    {
      "<leader>bD",
      function()
        Snacks.bufdelete.all()
      end,
      desc = "Delete All Buffers",
    },

    -- Notifications
    {
      "<leader>un",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss All Notifications",
    },
    {
      "<leader>nh",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },

    -- Git with Snacks
    {
      "<leader>gB",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Git Browse",
    },
    {
      "<leader>gf",
      function()
        Snacks.lazygit.log_file()
      end,
      desc = "Lazygit Current File History",
    },
    {
      "<leader>gl",
      function()
        Snacks.lazygit.log()
      end,
      desc = "Lazygit Log (cwd)",
    },

    -- Bottom panel — single key toggles shell + any project terminals together
    { "<C-`>", toggle_bottom_panel, desc = "Toggle bottom panel", mode = { "n", "i", "v", "t" } },
    { "<leader>H", toggle_htop, desc = "Toggle htop" },
  },

  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        _G.dd = function(...) Snacks.debug.inspect(...) end
        _G.bt = function() Snacks.debug.backtrace() end
        vim.print = _G.dd
      end,
    })
  end,
}
