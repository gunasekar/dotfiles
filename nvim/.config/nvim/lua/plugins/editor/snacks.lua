-- Snacks.nvim - Collection of small QoL plugins
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- Handle large files gracefully
    bigfile = { enabled = true },

    -- Dashboard on startup
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },

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
    -- Snacks dashboard
    {
      "<leader>;",
      function()
        Snacks.dashboard()
      end,
      desc = "Dashboard",
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

    -- Create new file with template
    {
      "<leader>fn",
      function()
        Snacks.new()
      end,
      desc = "New File",
    },
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

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle
          .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
          :map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.inlay_hints():map("<leader>uh")
      end,
    })
  end,
}
