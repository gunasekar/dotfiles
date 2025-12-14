-- Autocommands configuration
local api = vim.api

-- Auto-reload files when changed externally
-- This triggers when you focus Neovim or move cursor
local autoread_group = api.nvim_create_augroup("AutoReload", { clear = true })

api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = autoread_group,
  pattern = "*",
  callback = function()
    -- Only check if file exists and buffer is not modified
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
  desc = "Auto-reload files changed outside Neovim",
})

-- Show notification when file is auto-reloaded
api.nvim_create_autocmd("FileChangedShellPost", {
  group = autoread_group,
  pattern = "*",
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
  end,
  desc = "Notify when file is reloaded",
})

-- Highlight yanked text briefly
local highlight_group = api.nvim_create_augroup("YankHighlight", { clear = true })
api.nvim_create_autocmd("TextYankPost", {
  group = highlight_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
  desc = "Highlight yanked text",
})

-- Restore cursor position when opening a file
local restore_cursor_group = api.nvim_create_augroup("RestoreCursor", { clear = true })
api.nvim_create_autocmd("BufReadPost", {
  group = restore_cursor_group,
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = "Restore cursor position",
})

-- Close certain filetypes with 'q'
local close_with_q_group = api.nvim_create_augroup("CloseWithQ", { clear = true })
api.nvim_create_autocmd("FileType", {
  group = close_with_q_group,
  pattern = {
    "help",
    "lspinfo",
    "man",
    "qf",
    "checkhealth",
    "startuptime",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true, desc = "Close window" })
  end,
  desc = "Close certain windows with 'q'",
})

-- Auto-create directories when saving a file
local auto_mkdir_group = api.nvim_create_augroup("AutoMkdir", { clear = true })
api.nvim_create_autocmd("BufWritePre", {
  group = auto_mkdir_group,
  pattern = "*",
  callback = function(event)
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
  desc = "Auto-create parent directories when saving",
})

-- Disable diagnostics in node_modules
local disable_diagnostics_group = api.nvim_create_augroup("DisableDiagnostics", { clear = true })
api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = disable_diagnostics_group,
  pattern = "*/node_modules/*",
  callback = function()
    vim.diagnostic.enable(false, { bufnr = 0 })
  end,
  desc = "Disable diagnostics in node_modules",
})

-- Trim trailing whitespace on save (optional - uncomment if desired)
-- local trim_whitespace_group = api.nvim_create_augroup("TrimWhitespace", { clear = true })
-- api.nvim_create_autocmd("BufWritePre", {
--   group = trim_whitespace_group,
--   pattern = "*",
--   callback = function()
--     local save_cursor = vim.fn.getpos(".")
--     vim.cmd([[%s/\s\+$//e]])
--     vim.fn.setpos(".", save_cursor)
--   end,
--   desc = "Trim trailing whitespace on save",
-- })
