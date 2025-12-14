-- Autocompletion configuration
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer",       -- Buffer completions
    "hrsh7th/cmp-path",         -- Path completions
    "hrsh7th/cmp-nvim-lsp",     -- LSP completions
    "hrsh7th/cmp-nvim-lua",     -- Neovim Lua API completions
    "saadparwaiz1/cmp_luasnip", -- Snippet completions
    "L3MON4D3/LuaSnip",         -- Snippet engine
    "rafamadriz/friendly-snippets", -- Collection of snippets
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    -- Load VSCode-style snippets
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "nvim_lua" },
        { name = "path" },
      }, {
        { name = "buffer" },
      }),
      formatting = {
        format = function(entry, vim_item)
          vim_item.menu = ({
            nvim_lsp = "[LSP]",
            luasnip = "[Snippet]",
            buffer = "[Buffer]",
            path = "[Path]",
            nvim_lua = "[Lua]",
          })[entry.source.name]
          return vim_item
        end,
      },
      window = {
        completion = cmp.config.window.bordered({
          border = "rounded",
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        }),
        documentation = cmp.config.window.bordered({
          border = "rounded",
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        }),
      },
      performance = {
        debounce = 60,
        throttle = 30,
        fetching_timeout = 500,
        max_view_entries = 30,
      },
    })
  end,
}
