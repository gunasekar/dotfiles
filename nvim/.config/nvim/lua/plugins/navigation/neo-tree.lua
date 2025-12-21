-- Neo-tree file explorer with buffer number indicators
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  lazy = false, -- Load immediately
  priority = 1000,
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
    { "<leader>ef", "<cmd>Neotree reveal<CR>", desc = "Reveal current file in explorer" },
  },
  init = function()
    -- Disable netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- Auto-open neo-tree when opening a directory
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        -- Check if the argument is a directory
        local directory = vim.fn.isdirectory(data.file) == 1

        if directory then
          -- Defer to ensure neo-tree is fully loaded
          vim.defer_fn(function()
            pcall(vim.cmd, "Neotree show")
          end, 10)
        end
      end,
    })
  end,
  opts = {
    sources = { "filesystem" },
    source_selector = {
      winbar = false,
      statusline = false,
    },
    use_default_mappings = false,
    default_source = "filesystem",
    close_if_last_window = false,
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    open_files_do_not_replace_types = { "terminal", "trouble", "qf", "Trouble" },
    sort_case_insensitive = false,
    enable_normal_mode_for_inputs = false,
    -- Neo-tree specific behavior
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function()
          -- Keep the explorer clean: no numbers or sign column, not in buffer list
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = "no"
          vim.opt_local.buflisted = false
        end,
      },
    },
    default_component_configs = {
      container = {
        enable_character_fade = true,
      },
      indent = {
        indent_size = 2,
        padding = 1,
        with_markers = true,
        indent_marker = "│",
        last_indent_marker = "└",
        highlight = "NeoTreeIndentMarker",
        with_expanders = true,
        expander_collapsed = "▸",
        expander_expanded = "▾",
        expander_highlight = "NeoTreeExpander",
      },
      modified = {
        symbol = "[+]",
        highlight = "NeoTreeModified",
      },
      name = {
        trailing_slash = false,
        use_git_status_colors = true,
        highlight = "NeoTreeFileName",
      },
      git_status = {
        symbols = {
          added     = "+",
          modified  = "~",
          deleted   = "-",
          renamed   = "➜",
          untracked = "?",
          ignored   = "◌",
          unstaged  = "✗",
          staged    = "✓",
          conflict  = "!",
        },
      },
      file_size = {
        enabled = true,
        required_width = 64,
      },
      type = {
        enabled = true,
        required_width = 122,
      },
      last_modified = {
        enabled = true,
        required_width = 88,
      },
      created = {
        enabled = true,
        required_width = 110,
      },
      symlink_target = {
        enabled = false,
      },
    },
    -- Window configuration
    window = {
      position = "left",
      -- Fixed width: 30 columns (compact, widely used - LunarVim standard)
      width = 30,
      -- Keep neo-tree width fixed, don't let other windows resize it
      -- This uses Neovim's built-in window options
      mapping_options = {
        noremap = true,
        nowait = true,
      },
      mappings = {
        ["<space>"] = {
          "toggle_node",
          nowait = false,
        },
        ["<2-LeftMouse>"] = "open",
        ["<cr>"] = "open",
        ["<esc>"] = "cancel",
        ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
        ["l"] = "focus_preview",
        ["S"] = "open_split",
        ["s"] = "open_vsplit",
        ["t"] = "open_tabnew",
        ["C"] = "close_node",
        ["z"] = "close_all_nodes",
        ["a"] = {
          "add",
          config = {
            show_path = "none",
          },
        },
        ["A"] = "add_directory",
        ["d"] = "delete",
        ["r"] = "rename",
        ["y"] = "copy_to_clipboard",
        ["Yp"] = "copy_absolute_path",
        ["Yr"] = "copy_relative_path",
        ["Yf"] = "copy_filename",
        ["x"] = "cut_to_clipboard",
        ["p"] = "paste_from_clipboard",
        ["c"] = "copy",
        ["m"] = "move",
        ["q"] = "close_window",
        ["R"] = "refresh",
        ["?"] = "show_help",
        ["i"] = "show_file_details",
      },
    },
    nesting_rules = {},
    -- Custom commands
    commands = {
      -- Copy absolute file path
      copy_absolute_path = function(state)
        local node = state.tree:get_node()
        local filepath = node:get_id()
        vim.fn.setreg("+", filepath)
        print("Copied: " .. filepath)
      end,
      -- Copy relative file path
      copy_relative_path = function(state)
        local node = state.tree:get_node()
        local filepath = node:get_id()
        local relative = vim.fn.fnamemodify(filepath, ":.")
        vim.fn.setreg("+", relative)
        print("Copied: " .. relative)
      end,
      -- Copy filename only
      copy_filename = function(state)
        local node = state.tree:get_node()
        local filepath = node:get_id()
        local filename = vim.fn.fnamemodify(filepath, ":t")
        vim.fn.setreg("+", filename)
        print("Copied: " .. filename)
      end,
    },
    -- Filesystem source configuration
    filesystem = {
      -- Custom components for the filesystem view
      components = {
        -- Show buffer number for open files
        bufnr = function(config, node, state)
          local bufnr = vim.fn.bufnr(node.path)
          if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
            -- Get all loaded, listed buffers and find this buffer's position
            local buffers = vim.tbl_filter(function(buf)
              return vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf)
            end, vim.api.nvim_list_bufs())

            table.sort(buffers)

            for i, buf in ipairs(buffers) do
              if buf == bufnr then
                return {
                  text = string.format("%d ", i),
                  highlight = "NeoTreeBufferNumber",
                }
              end
            end
          end
          return {
            text = "  ",
            highlight = "NeoTreeDimText",
          }
        end,
      },
      -- Custom renderer to include buffer numbers
      renderers = {
        file = {
          { "bufnr" }, -- Buffer number at the start
          { "indent" },
          { "icon" },
          { "name", use_git_status_colors = true },
          { "git_status" },
          { "diagnostics" },
        },
      },
      filtered_items = {
        visible = false,
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_hidden = true,
        hide_by_name = {
          ".DS_Store",
          "thumbs.db",
        },
        hide_by_pattern = {},
        always_show = {},
        never_show = {},
        never_show_by_pattern = {},
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      group_empty_dirs = false,
      hijack_netrw_behavior = "open_default",
      use_libuv_file_watcher = false,
      window = {
        mappings = {
          ["<bs>"] = "navigate_up",
          ["."] = "set_root",
          ["H"] = "toggle_hidden",
          ["/"] = "fuzzy_finder",
          ["D"] = "fuzzy_finder_directory",
          ["#"] = "fuzzy_sorter",
          ["f"] = "filter_on_submit",
          ["<c-x>"] = "clear_filter",
          ["[g"] = "prev_git_modified",
          ["]g"] = "next_git_modified",
          ["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
          ["oc"] = { "order_by_created", nowait = false },
          ["od"] = { "order_by_diagnostics", nowait = false },
          ["og"] = { "order_by_git_status", nowait = false },
          ["om"] = { "order_by_modified", nowait = false },
          ["on"] = { "order_by_name", nowait = false },
          ["os"] = { "order_by_size", nowait = false },
          ["ot"] = { "order_by_type", nowait = false },
        },
        fuzzy_finder_mappings = {
          ["<down>"] = "move_cursor_down",
          ["<C-n>"] = "move_cursor_down",
          ["<up>"] = "move_cursor_up",
          ["<C-p>"] = "move_cursor_up",
        },
      },
      commands = {},
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)

    -- Set up highlight group for buffer numbers (theme-adaptive)
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "NeoTreeBufferNumber", {
          fg = vim.api.nvim_get_hl(0, { name = "Function" }).fg,
          bold = true
        })
      end,
    })
    -- Set initially
    vim.api.nvim_set_hl(0, "NeoTreeBufferNumber", {
      fg = vim.api.nvim_get_hl(0, { name = "Function" }).fg or "#61afef",
      bold = true
    })

    -- Auto-refresh neo-tree when buffers change to update buffer numbers
    local refresh_neo_tree = vim.schedule_wrap(function()
      if package.loaded["neo-tree.sources.manager"] then
        local manager = require("neo-tree.sources.manager")
        local state = manager.get_state("filesystem")
        if state then
          local renderer = require("neo-tree.ui.renderer")
          renderer.redraw(state)
        end
      end
    end)

    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
      callback = refresh_neo_tree,
    })

    -- Show buffer title in winbar at the top of each window
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      callback = function()
        local buftype = vim.bo.buftype
        local filetype = vim.bo.filetype

        -- Don't show winbar for special buffers
        if buftype ~= "" or filetype == "neo-tree" then
          vim.opt_local.winbar = nil
          return
        end

        -- Get buffer number
        local bufnr = vim.api.nvim_get_current_buf()
        local buffers = vim.tbl_filter(function(buf)
          return vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf)
        end, vim.api.nvim_list_bufs())

        table.sort(buffers)
        local buf_index = nil
        for i, buf in ipairs(buffers) do
          if buf == bufnr then
            buf_index = i
            break
          end
        end

        -- Get filename
        local filename = vim.fn.expand("%:t")
        if filename == "" then
          filename = "[No Name]"
        end

        -- Show buffer number and filename in winbar (centered)
        if buf_index then
          vim.opt_local.winbar = string.format("%%=%%#NeoTreeBufferNumber# %d %%#Normal# %s%%=", buf_index, filename)
        else
          vim.opt_local.winbar = string.format("%%=%%#Normal# %s%%=", filename)
        end
      end,
    })

    -- Buffer navigation keymaps (replacing bufferline functionality)
    local keymap = vim.keymap

    -- Cycle through buffers
    keymap.set("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
    keymap.set("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

    -- Navigate to specific buffer by number (1-9)
    for i = 1, 9 do
      keymap.set("n", "<leader>" .. i, function()
        local buffers = vim.tbl_filter(function(buf)
          return vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf)
        end, vim.api.nvim_list_bufs())

        -- Sort buffers by buffer number
        table.sort(buffers)

        if buffers[i] then
          vim.api.nvim_set_current_buf(buffers[i])
        end
      end, { desc = "Go to buffer " .. i })
    end

    -- Close other buffers
    keymap.set("n", "<leader>bo", function()
      local current_buf = vim.api.nvim_get_current_buf()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current_buf and vim.bo[buf].buflisted then
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
    end, { desc = "Close other buffers" })
  end,
}
