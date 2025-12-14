-- Core editor options
local opt = vim.opt
local g = vim.g

-- Leader keys (set early)
g.mapleader = " "
g.maplocalleader = "\\"

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.numberwidth = 2

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "split" -- Show live preview of substitutions

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.linebreak = true
opt.showmode = false -- Don't show mode in command line (shown in statusline)
opt.pumheight = 10 -- Maximum number of items in popup menu
opt.pumblend = 10 -- Popup menu transparency
opt.winblend = 0 -- Window transparency

-- Font (GUI clients only - terminal uses terminal font)
opt.guifont = "Hack Nerd Font Mono:h13"

-- Behavior
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen" -- Keep screen position on splits
opt.equalalways = false -- Don't auto-equalize window sizes (keeps layout static)
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.undolevels = 10000
opt.confirm = true -- Confirm before closing unsaved buffers

-- Auto-reload files changed outside Neovim
opt.autoread = true -- Auto-reload files when changed externally

-- Completion
opt.completeopt = "menu,menuone,noselect"
opt.shortmess:append("c") -- Don't show completion messages

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300
opt.lazyredraw = false -- Don't redraw during macros

-- Scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Folding (using treesitter)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Command line
opt.cmdheight = 1
opt.showcmd = true

-- Formatting
opt.formatoptions = "jcroqlnt" -- tcqj format options

-- Misc
opt.virtualedit = "block" -- Allow cursor beyond end of line in visual block mode
opt.conceallevel = 2 -- Hide concealed text
opt.spelllang = "en_us"
opt.spelloptions:append("camel") -- Spell check camelCase words

-- Filetype detection for Docker Compose
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "docker-compose*.yaml", "docker-compose*.yml", "compose.yaml", "compose.yml" },
  callback = function()
    vim.bo.filetype = "yaml.docker-compose"
  end,
})
