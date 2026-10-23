-- Git integration plugins
-- All git-related functionality: signs, hunks, blame, CodeDiff, and LazyGit TUI

-- A git diff view in a float, the way <leader>gg is LazyGit: a second Neovim in a
-- floating terminal, opened on the git root of the current file. When that Neovim exits,
-- the float goes with it. CodeDiff builds its view from the windows of a tab of its own,
-- so it can't be a float itself. A native float, not a snacks terminal, so
-- edgy never moves it into a panel slot.
local function repo_root()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = (file ~= "" and vim.bo.buftype == "") and vim.fs.dirname(file) or vim.fn.getcwd()
  return vim.fs.root(dir, ".git") or dir
end

local function diff_float(title, args)
  local root = repo_root()
  local cols, lines = vim.o.columns, vim.o.lines
  local w, h = math.floor(cols * 0.9), math.floor(lines * 0.9)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((cols - w) / 2),
    row = math.floor((lines - h) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })
  -- No tab bar in there: the view opens a tab of its own beside Neovim's empty first
  -- one, and the bar would only show that [No Name] and the view's internal buffer name.
  -- And `q` quits it wherever the view hasn't mapped `q` itself (CodeDiff's history
  -- panel), since that Neovim is there for the float alone. NVIM_DIFF_FLOAT tells its
  -- plugins where they are: the markdown renderers stay out (plugins/markdown.lua), so a
  -- diff shows the markdown as written.
  local base = { vim.v.progpath, "-c", "set showtabline=0", "-c", "nnoremap q <cmd>qa!<cr>" }
  vim.fn.jobstart(vim.list_extend(base, args), {
    term = true,
    env = { NVIM_DIFF_FLOAT = "1" },
    cwd = root,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end

-- CodeDiff in that float, titled with what it shows: "Changes · trails". It exits that
-- Neovim itself when its view closes (`q`).
local function codediff_float(title, ...)
  local args = { ... }
  table.insert(args, "--exit-on-close")
  diff_float(title, { "-c", "CodeDiff " .. table.concat(args, " ") })
end

local function codediff_changes()
  codediff_float("Changes · " .. vim.fs.basename(repo_root()))
end

local function codediff_branch_history()
  codediff_float("History · " .. vim.fs.basename(repo_root()), "history")
end

-- History of the current file: by its path, since `%` in that other Neovim is its own
-- empty buffer.
local function codediff_file_history()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("No file here to show the history of", vim.log.levels.WARN)
    return
  end
  codediff_float("History · " .. vim.fs.basename(file), "history", vim.fn.fnameescape(file))
end

return {
  -- CodeDiff: VS Code's diff view, whole files side by side, coloured by side (red what
  -- was, green what is) with character-level highlights. Fetches its prebuilt diff
  -- library on first use. Each key opens it in a float; `q` closes it. :CodeDiff opens
  -- it in a tab instead.
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", codediff_changes, desc = "Diff: changes (float)" },
      { "<leader>gh", codediff_branch_history, desc = "Diff: branch history (float)" },
      { "<leader>gH", codediff_file_history, desc = "Diff: file history (float)" },
    },
    opts = {
      diff = {
        filler_text = "·", -- faint centre dots for lines only one side has (CodeDiffFiller)
      },
      -- Files as a directory tree, not a flat list, in the changes explorer and under
      -- each commit in history. `i` toggles back to the list.
      explorer = { view_mode = "tree" },
      history = { view_mode = "tree" },
    },
  },

  -- Gitsigns: Git decorations and hunk operations
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Next hunk" })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Previous hunk" })

          -- Actions (standard gitsigns keymaps using <leader>h prefix)
          map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
          map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
          map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Stage hunk" })
          map("v", "<leader>hr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Reset hunk" })
          map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
          map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
          map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
          map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
          end, { desc = "Blame line" })
          map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
          map("n", "<leader>hD", function()
            gs.diffthis("~")
          end, { desc = "Diff this ~" })

          -- Text object
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
        end,
      })
    end,
  },

  -- Lazygit: Beautiful Git TUI integration
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
      { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit Current File" },
    },
  },
}
