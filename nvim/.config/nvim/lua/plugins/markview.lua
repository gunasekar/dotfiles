-- Markview.nvim — alternative Markdown renderer, used instead of
-- render-markdown.nvim (which is disabled in markdown.lua).
-- Repo: https://github.com/gunasekar/markview.nvim
--
-- Requires Neovim >= 0.10.3 and the `markdown` + `markdown_inline`
-- treesitter parsers (already installed via lsp/treesitter.lua).

return {
  {
    -- Adds smart tables (`tables.smart_wrap`, see below). Pinned to the
    -- `feat/table-text-wrap` branch.
    "gunasekar/markview.nvim",
    branch = "feat/table-text-wrap",
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
        preview = {
          -- Show rendered preview in normal mode (no raw on the cursor line);
          -- raw markdown is revealed only in insert/edit mode. `hybrid_modes`
          -- is left empty (markview default) so normal mode stays fully
          -- previewed. To edit a wrapped table, enter insert mode.
          hybrid_modes = {},
        },
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
          tables = {
            -- Smart tables. Oversized tables shrink columns
            -- (widest first) to `wrap_width`, then word-wrap any cell that still
            -- does not fit. Works WITH your global `wrap = true`: the table is
            -- drawn as virtual lines over the (hidden) source rows. Enter insert
            -- mode to edit the raw source (hybrid mode is off; see `preview`).
            smart_wrap = true,
            -- Cap the rendered table at 90% of the window width (0<n<=1 = a
            -- fraction; n>1 = an absolute column count).
            wrap_width = 0.9,
            -- Smallest a column may shrink to before long words are hard-broken.
            wrap_minwidth = 6,
            -- Thin rule between data rows (grid style). Colour comes from
            -- `hl.row_separator` (defaults to the table border colour).
            row_separator = true,
          },
        },
      }
    end,
  },
}
