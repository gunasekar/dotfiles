-- Terminal plugin for Neovim
-- Provides persistent terminals with toggleable windows
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      -- Size of terminal (relative sizes that adapt to screen)
      size = function(term)
        if term.direction == "horizontal" then
          -- 30% of screen height (adapts to any screen size)
          return math.floor(vim.o.lines * 0.3)
        elseif term.direction == "vertical" then
          -- 40% of screen width (adapts to any screen size)
          return math.floor(vim.o.columns * 0.4)
        end
      end,

      -- Open terminal in insert mode
      open_mapping = [[<c-\>]],

      -- Hide the number column in terminal buffers
      hide_numbers = true,

      -- Shade the terminal background
      shade_terminals = true,
      shading_factor = 2,

      -- Start in insert mode
      start_in_insert = true,

      -- Insert mode mappings
      insert_mappings = true,
      terminal_mappings = true,

      -- Persist terminals across sessions
      persist_size = true,
      persist_mode = true,

      -- Terminal direction: 'vertical' | 'horizontal' | 'tab' | 'float'
      direction = "horizontal",

      -- Close terminal on process exit
      close_on_exit = true,

      -- Shell to use
      shell = vim.o.shell,

      -- Auto scroll to bottom on output
      auto_scroll = true,

      -- Floating terminal settings
      float_opts = {
        border = "curved",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        winblend = 0,
      },

      -- Winbar settings
      winbar = {
        enabled = false,
        name_formatter = function(term)
          return term.name
        end,
      },

      -- Fix terminal window size (prevents resizing)
      on_open = function(term)
        if term.direction == "horizontal" then
          vim.wo[term.window].winfixheight = true
        elseif term.direction == "vertical" then
          vim.wo[term.window].winfixwidth = true
        end
      end,
    })

    -- Keymaps
    local keymap = vim.keymap

    -- Toggle terminals with different layouts (using relative sizes)
    keymap.set("n", "<leader>th", function()
      local size = math.floor(vim.o.lines * 0.3)
      vim.cmd("ToggleTerm size=" .. size .. " direction=horizontal")
    end, { desc = "Toggle horizontal terminal (30% height)" })
    keymap.set("n", "<leader>tv", function()
      local size = math.floor(vim.o.columns * 0.4)
      vim.cmd("ToggleTerm size=" .. size .. " direction=vertical")
    end, { desc = "Toggle vertical terminal (40% width)" })
    keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>",
      { desc = "Toggle floating terminal" })

    -- Quick terminal toggle (Ctrl+\)
    keymap.set({ "n", "t" }, "<C-\\>", "<cmd>ToggleTerm<cr>",
      { desc = "Toggle terminal" })

    -- Terminal navigation (already in keymaps.lua but good to note)
    -- <C-h/j/k/l> to navigate between windows from terminal mode
    -- <Esc> to exit terminal mode

    -- Function to create custom terminals
    local Terminal = require("toggleterm.terminal").Terminal

    -- Node REPL
    local node = Terminal:new({
      cmd = "node",
      direction = "float",
      hidden = true
    })

    function _NODE_TOGGLE()
      node:toggle()
    end

    keymap.set("n", "<leader>tn", "<cmd>lua _NODE_TOGGLE()<CR>",
      { desc = "Toggle Node REPL" })

    -- Python REPL
    local python = Terminal:new({
      cmd = "python3",
      direction = "float",
      hidden = true
    })

    function _PYTHON_TOGGLE()
      python:toggle()
    end

    keymap.set("n", "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<CR>",
      { desc = "Toggle Python REPL" })

    -- Htop terminal
    local htop = Terminal:new({
      cmd = "htop",
      direction = "float",
      hidden = true
    })

    function _HTOP_TOGGLE()
      htop:toggle()
    end

    keymap.set("n", "<leader>tH", "<cmd>lua _HTOP_TOGGLE()<CR>",
      { desc = "Toggle htop" })
  end,
}
