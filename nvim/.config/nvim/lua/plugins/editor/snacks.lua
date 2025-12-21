-- Snacks.nvim - Collection of small QoL plugins
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

    -- Terminal (disabled - using toggleterm instead)
    -- {
    --   "<c-/>",
    --   function()
    --     Snacks.terminal()
    --   end,
    --   desc = "Toggle Terminal (Snacks)",
    --   mode = { "n", "t" },
    -- },
  },

  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for easier access
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command
      end,
    })
  end,
}
