-- Keymaps configuration
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Leader key is set in options.lua as space

-- Better escape
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- Insert mode selection (IDE-like behavior with Shift+Arrow)
keymap.set("i", "<S-Left>", "<C-o>vh", { desc = "Select left" })
keymap.set("i", "<S-Right>", "<C-o>vl", { desc = "Select right" })
keymap.set("i", "<S-Up>", "<C-o>vk", { desc = "Select up" })
keymap.set("i", "<S-Down>", "<C-o>vj", { desc = "Select down" })
keymap.set("i", "<S-Home>", "<C-o>v0", { desc = "Select to line start" })
keymap.set("i", "<S-End>", "<C-o>v$", { desc = "Select to line end" })

-- Better window navigation
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Resize windows
keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffer navigation
keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
-- Buffer deletion: <leader>bd (delete), <leader>bD (delete all) - defined in plugins/editor/snacks.lua

-- Make <C-w>q behave like <leader>sx (close window only, keep buffer)
keymap.set("n", "<C-w>q", "<cmd>close<CR>", { desc = "Close current split" })

-- Override :bd to use safer buffer deletion that preserves window layout
-- This prevents neo-tree from expanding when closing the last buffer
vim.api.nvim_create_user_command("Bd", function(opts)
  -- Use Snacks.bufdelete() which handles window layout properly
  if opts.args ~= "" then
    -- Parse buffer number/name from args
    local bufnr = tonumber(opts.args) or vim.fn.bufnr(opts.args)
    Snacks.bufdelete(bufnr)
  else
    Snacks.bufdelete()
  end
end, { bang = true, nargs = "?", complete = "buffer", desc = "Safe buffer delete" })

-- Create command abbreviation so :bd maps to :Bd
vim.cmd([[cnoreabbrev <expr> bd (getcmdtype() == ':' && getcmdline() == 'bd') ? 'Bd' : 'bd']])

-- Better indenting
keymap.set("v", "<", "<gv", { desc = "Indent left" })
keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Move text up and down
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })
keymap.set("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
keymap.set("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })

-- Better line joining
keymap.set("n", "J", "mzJ`z", { desc = "Join lines keeping cursor position" })

-- Center screen on navigation
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
keymap.set("n", "n", "nzzzv", { desc = "Next search result and center" })
keymap.set("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- Clear search highlight
keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Quick save
keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all files" })

-- Quick quit
keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
keymap.set("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all without saving" })

-- Split windows
keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })

-- Paste without yanking
keymap.set("v", "p", '"_dP', { desc = "Paste without yanking" })
keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })

-- Delete without yanking
keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- Yank to system clipboard
keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })

-- Copy file paths to clipboard (non-leader for speed)
keymap.set("n", "Yp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Yank absolute file path" })

keymap.set("n", "Yr", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Yank relative file path" })

keymap.set("n", "Yf", function()
  local path = vim.fn.expand("%:t")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Yank filename only" })

-- Open file from clipboard path
keymap.set("n", "<leader>fp", function()
  local path = vim.fn.getreg("+"):gsub("^%s*(.-)%s*$", "%1")
  Snacks.input({ prompt = "Open file:", default = path }, function(value)
    if value and value ~= "" then
      vim.cmd.edit(value)
    end
  end)
end, { desc = "Open file from clipboard" })

-- Select all
keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })

-- Better terminal navigation
keymap.set("t", "<C-h>", "<C-\\><C-N><C-w>h", { desc = "Terminal: Move to left window" })
keymap.set("t", "<C-j>", "<C-\\><C-N><C-w>j", { desc = "Terminal: Move to bottom window" })
keymap.set("t", "<C-k>", "<C-\\><C-N><C-w>k", { desc = "Terminal: Move to top window" })
keymap.set("t", "<C-l>", "<C-\\><C-N><C-w>l", { desc = "Terminal: Move to right window" })
keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle options
keymap.set("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle line wrap" })
keymap.set("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })
keymap.set("n", "<leader>tr", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })

-- Diagnostic keymaps
keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
keymap.set("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show diagnostic error" })
keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Open diagnostic list" })

-- Toggle inline diagnostic messages (virtual text)
local diagnostics_visible = false
keymap.set("n", "<leader>td", function()
  diagnostics_visible = not diagnostics_visible
  vim.diagnostic.config({
    virtual_text = diagnostics_visible,
  })
  if diagnostics_visible then
    print("Diagnostics: inline messages enabled")
  else
    print("Diagnostics: inline messages hidden (use <leader>de to view)")
  end
end, { desc = "Toggle diagnostic virtual text" })
