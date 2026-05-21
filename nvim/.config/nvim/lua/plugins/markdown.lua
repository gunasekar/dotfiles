-- Markdown rendering in the terminal
-- Repo: https://github.com/MeanderingProgrammer/render-markdown.nvim

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    -- Only one Markdown renderer should be active at a time. To switch:
    -- set `enabled = true` here and `enabled = false` in markview.lua.
    enabled = false,
    opts = {
      -- LazyVim's Markdown config — the most common community setup. The
      -- `lazy` preset already provides the code-block styling (sign = false,
      -- width = "block", right_pad = 1), plain headings (no sign glyph, no
      -- icons), and disables checkbox rendering — so none of that is repeated
      -- here. Unlike `obsidian`, it does NOT render in insert mode.
      preset = "lazy",
      completions = { lsp = { enabled = true } },
      -- Anti-conceal un-renders the cursor's line as raw text. By default it
      -- does this in every mode (so a click in normal mode reveals raw
      -- markdown). Disable it in normal/command/terminal modes — the raw line
      -- then only appears in insert mode, while editing.
      anti_conceal = {
        disabled_modes = { "n", "c", "t" },
      },
    },
  },
}
