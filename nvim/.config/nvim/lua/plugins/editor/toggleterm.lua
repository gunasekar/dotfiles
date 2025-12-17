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
      open_mapping = [[<c-`>]],

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
        width = math.floor(vim.o.columns * 0.6),
        height = math.floor(vim.o.lines * 0.6),
        winblend = 0,
      },

      -- Winbar settings
      winbar = {
        enabled = false,
        name_formatter = function(term)
          return term.name
        end,
      },
    })

    -- Keymaps
    local keymap = vim.keymap

    -- Global toggle mapping that works in all modes
    keymap.set({ "n", "i", "v", "t" }, "<C-`>", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })

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

    -- Terminal navigation (already in keymaps.lua but good to note)
    -- <C-h/j/k/l> to navigate between windows from terminal mode
    -- <Esc> to exit terminal mode

    -- Function to create custom terminals
    local Terminal = require("toggleterm.terminal").Terminal

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
