-- Markdown rendering — two renderers, only one active at a time.
-- To switch: flip the two `enabled` flags.

return {
	-- ── render-markdown.nvim ────────────────────────────────────────────────
	{
		"MeanderingProgrammer/render-markdown.nvim",
		-- Not in a diff popup (plugins/git.lua): a diff shows markdown as written.
		cond = vim.env.NVIM_DIFF_FLOAT == nil,
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
		-- Not in a diff popup (plugins/git.lua): a diff shows markdown as written.
		cond = vim.env.NVIM_DIFF_FLOAT == nil,
		-- Never renders while editing: markdown shows as written, and <leader>ui flips
		-- the buffer into a read-only rendered view (diagrams too, plugins/diagram.lua)
		-- and back. Locking the buffer is what keeps rendering out of the way of
		-- edits: nothing can be typed into the rendered view.
		keys = {
			{
				"<leader>ui",
				function()
					local buf = vim.api.nvim_get_current_buf()
					if not vim.list_contains({ "markdown", "quarto", "rmd" }, vim.bo[buf].filetype) then
						vim.notify("Not a markdown buffer", vim.log.levels.INFO)
						return
					end
					local actions = require("markview.actions")
					local preview = vim.b[buf].markdown_preview
					if preview then
						actions.disable(buf)
						vim.bo[buf].modifiable = preview.modifiable
						vim.b[buf].markdown_preview = nil
					else
						vim.b[buf].markdown_preview = { modifiable = vim.bo[buf].modifiable }
						vim.bo[buf].modifiable = false
						actions.enable(buf)
					end
				end,
				desc = "Toggle read-only markdown preview",
			},
		},
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
					enable = false, -- only in the read-only view (<leader>ui, see keys above)
					-- Neovim 0.12.2 compat: markview's set_query guard has a pcall edge
					-- case (get_parser returning nil before treesitter is active) that
					-- lets it call vim.treesitter.start() on non-markdown buffers, causing
					-- an assert failure. Restricting filetypes here prevents attach() from
					-- ever being called for typst/asciidoc where the crash occurs.
					filetypes = { "markdown", "quarto", "rmd" },
					-- No hybrid mode: rendering only happens in the read-only view, where
					-- nothing is edited, so nothing should flip back to raw under the
					-- cursor (tables included). Empty also keeps "n" in markview's derived
					-- `concealcursor`, so bold `**` / italic `_` stay hidden on the cursor's
					-- line. Cost: smart tables are virtual text over zero-height rows, so
					-- the cursor is hidden while it crosses a table.
					hybrid_modes = {},
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
