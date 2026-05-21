-- Markview.nvim — alternative Markdown renderer, used instead of
-- render-markdown.nvim (which is disabled in markdown.lua).
-- Repo: https://github.com/OXY2DEV/markview.nvim
--
-- Requires Neovim >= 0.10.3 and the `markdown` + `markdown_inline`
-- treesitter parsers (already installed via lsp/treesitter.lua).

return {
  {
    "OXY2DEV/markview.nvim",
    -- Only one Markdown renderer should be active at a time. To switch:
    -- set `enabled = false` here and `enabled = true` in markdown.lua.
    enabled = true,
    -- Do NOT lazy-load: markview is already internally lazy-loaded. Deferring
    -- it only delays previews on startup (per upstream docs). Loading after the
    -- colorscheme also ensures correct highlight groups.
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = function()
      -- Plain headings: no preset. `style = "simple"` highlights the whole
      -- heading line with `hl`. The base `MarkviewHeadingN` groups carry a
      -- background (→ full-width bar), so we point `hl` at `MarkviewHeadingNSign`
      -- instead — those are foreground-only, giving left-aligned colored
      -- heading text per level with no bars, no icons, no sign-column glyph.
      local function plain_heading(level)
        return {
          style = "simple",
          hl = ("MarkviewHeading%dSign"):format(level),
          sign = "",
        }
      end

      return {
        markdown = {
          headings = {
            enable = true,
            heading_1 = plain_heading(1),
            heading_2 = plain_heading(2),
            heading_3 = plain_heading(3),
            heading_4 = plain_heading(4),
            heading_5 = plain_heading(5),
            heading_6 = plain_heading(6),
          },
        },
      }
    end,
  },
}
