-- Telescope fuzzy finder
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
          width = 0.87,
          height = 0.80,
        },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<C-u>"] = false,
            ["<C-d>"] = false,
            ["<C-x>"] = actions.delete_buffer, -- Delete buffer in buffer picker
          },
          n = {
            ["q"] = actions.close,
            ["dd"] = actions.delete_buffer, -- Delete buffer with dd in normal mode
          },
        },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--glob=!.git/",
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    })

    telescope.load_extension("fzf")

    -- Keymaps
    local keymap = vim.keymap

    -- File finding
    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Find recent files" })

    -- Text search
    keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Find text (live grep)" })
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find word under cursor" })

    -- Buffer navigation (primary workflow for 7+ buffers)
    keymap.set("n", "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", { desc = "Find buffers (recent first)" })
    keymap.set("n", "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", { desc = "Switch buffer" })
    keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
    keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })

    -- Help and diagnostics
    keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Find help" })
    keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Find diagnostics" })

    -- Git integration
    keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Git commits" })
    keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Git status" })
  end,
}
