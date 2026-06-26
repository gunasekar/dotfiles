-- Terminal plugin for Neovim
-- Provides persistent terminals with toggleable windows
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    local main_terminal = {
      bufnr = nil,
      winid = nil,
    }

    local function terminal_height()
      return math.floor(vim.o.lines * 0.3)
    end

    local function is_valid_window(win)
      return win and vim.api.nvim_win_is_valid(win)
    end

    local function is_valid_buffer(buf)
      return buf and vim.api.nvim_buf_is_valid(buf)
    end

    local function is_main_editor_window(win)
      if not is_valid_window(win) then
        return false
      end

      local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
      if not ok or not is_valid_buffer(buf) then
        return false
      end

      local filetype = vim.bo[buf].filetype
      local buftype = vim.bo[buf].buftype
      return buftype == ""
        and filetype ~= "neo-tree"
        and filetype ~= "snacks_terminal"
        and filetype ~= "toggleterm"
    end

    local function find_main_editor_window()
      local current = vim.api.nvim_get_current_win()
      if is_main_editor_window(current) then
        return current
      end

      local best_win = nil
      local best_width = 0
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_main_editor_window(win) then
          local width = vim.api.nvim_win_get_width(win)
          if width > best_width then
            best_win = win
            best_width = width
          end
        end
      end

      return best_win
    end

    local function configure_main_terminal_window()
      vim.wo.winfixheight = true
      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.signcolumn = "no"
      vim.bo.buflisted = false
      vim.bo.bufhidden = "hide"
      vim.cmd("startinsert")
    end

    local function toggle_main_terminal()
      if is_valid_window(main_terminal.winid) then
        vim.api.nvim_win_close(main_terminal.winid, false)
        main_terminal.winid = nil
        return
      end

      local target_win = find_main_editor_window()
      if not target_win then
        vim.notify("No main editor window available for terminal", vim.log.levels.WARN)
        return
      end

      vim.api.nvim_set_current_win(target_win)
      vim.cmd("rightbelow " .. terminal_height() .. "split")
      main_terminal.winid = vim.api.nvim_get_current_win()

      if is_valid_buffer(main_terminal.bufnr) then
        vim.api.nvim_win_set_buf(main_terminal.winid, main_terminal.bufnr)
      else
        vim.cmd("terminal")
        main_terminal.bufnr = vim.api.nvim_get_current_buf()
      end

      configure_main_terminal_window()
    end

    require("toggleterm").setup({
      -- Size of terminal (relative sizes that adapt to screen)
      size = function(term)
        if term.direction == "horizontal" then
          -- 30% of screen height (adapts to any screen size)
          return terminal_height()
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
      -- Always reopen in insert mode (don't restore the last-used mode)
      persist_mode = false,

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

    -- Always enter insert mode when focusing a toggleterm window
    -- (covers window navigation into an already-open terminal, where
    --  start_in_insert does not fire)
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      pattern = "term://*",
      callback = function()
        if vim.bo.filetype == "toggleterm" then
          vim.cmd("startinsert")
        end
      end,
      desc = "Start in insert mode when focusing a toggleterm",
    })

    -- Keymaps
    local keymap = vim.keymap

    -- Global toggle mapping that works in all modes
    keymap.set({ "n", "i", "v", "t" }, "<C-`>", toggle_main_terminal, { desc = "Toggle main-column terminal" })

    -- Toggle terminals with different layouts (using relative sizes)
    keymap.set("n", "<leader>th", function()
      toggle_main_terminal()
    end, { desc = "Toggle main-column terminal (30% height)" })
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
