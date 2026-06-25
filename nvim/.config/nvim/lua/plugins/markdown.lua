-- Markdown rendering — two renderers, only one active at a time.
-- To switch: flip the two `enabled` flags.

return {
	-- ── render-markdown.nvim ────────────────────────────────────────────────
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		ft = { "markdown" },
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
			-- Rounded box-drawing borders instead of plain pipes.
			pipe_table = { preset = "round" },
			-- Top/bottom border decorators on fenced code blocks.
			code = { border = "thick" },
			-- Re-enable checkboxes (lazy preset disables them).
			checkbox = { enabled = true },
			-- Show HTML comments (<!-- ... -->) instead of concealing them.
			html = { comment = { conceal = false } },
			-- Remove full-width background bars behind headings.
			heading = { backgrounds = {} },
		},
	},

	-- ── markview.nvim ───────────────────────────────────────────────────────
	{
		-- Stock upstream markview. Known cosmetic limitation until the
		-- `fix/tostring-word-attached-code-span` PR (gunasekar fork) is merged
		-- upstream: word-attached code spans like call(`x`) show raw backticks
		-- inside smart tables and can drift table borders.
		"OXY2DEV/markview.nvim",
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
					-- Neovim 0.12.2 compat: markview's set_query guard has a pcall edge
					-- case (get_parser returning nil before treesitter is active) that
					-- lets it call vim.treesitter.start() on non-markdown buffers, causing
					-- an assert failure. Restricting filetypes here prevents attach() from
					-- ever being called for typst/asciidoc where the crash occurs.
					filetypes = { "markdown", "quarto", "rmd" },
					-- Reveal the raw markdown of the node under the cursor in these
					-- modes, so a NORMAL, visible cursor moves through the table the
					-- usual Vim way (the fitted render is virtual text over zero-height
					-- rows, where the cursor would otherwise be invisible).
					--
					-- `raw_previews` (below) scopes markview's OWN extmark decorations
					-- to tables, so headings/links/inline-code stay rendered under the
					-- cursor. But note a SECOND, separate mechanism: markview derives
					-- `concealcursor` as (preview.modes MINUS hybrid_modes). Listing "n"
					-- here drops it from concealcursor, so Neovim natively un-conceals
					-- treesitter-concealed markup (bold `**`, italic `_`) on the cursor's
					-- line in normal mode. That is inherent to wanting a visible cursor
					-- on the table — raw_previews cannot suppress it (it is conceallevel,
					-- not an extmark). Accepted as the cost of the visible-cursor feature.
					--
					-- Trade-off: a wide table shows raw (briefly unfitted) while the
					-- cursor is on it. Modes: "n" normal, "v"/"V" visual, "i" insert.
					hybrid_modes = { "n", "v", "V", "i" },
					raw_previews = {
						markdown = { "tables" },
						-- markview reveals every node of any language it is NOT told
						-- to filter, so listing only `markdown` leaves the inline
						-- language wide open — inline `code`, links, highlights, etc.
						-- still flip to raw under the cursor. `{ "none" }` is a
						-- no-match inclusion (reveal nothing inline), so only tables
						-- ever drop to raw.
						markdown_inline = { "none" },
					},
				},
				-- Route table rendering through markview-smart-tables.nvim. It fits
				-- oversized tables to the window (works WITH your global `wrap = true`)
				-- and falls back to markview's stock table renderer otherwise.
				renderers = {
					markdown_table = function(buffer, item)
						require("markview-smart-tables").render(buffer, item)
					end,
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
				},
			}
		end,
	},

	-- ── markview-smart-tables.nvim ─────────────────────────────────────────
	{
		-- Smart tables for markview: oversized tables shrink columns (widest
		-- first) to `wrap_width`, word-wrap overflowing cells, and re-fit on
		-- window resize.
		-- Repo: https://github.com/gunasekar/markview-smart-tables.nvim
		"gunasekar/markview-smart-tables.nvim",
		lazy = false,
		opts = {
			-- Cap rendered tables at 90% of the window width (0<n<=1 = fraction;
			-- n>1 = absolute column count).
			wrap_width = 0.9,
			-- Smallest a column may shrink to before long words are hard-broken.
			wrap_minwidth = 6,
		},
	},
}
