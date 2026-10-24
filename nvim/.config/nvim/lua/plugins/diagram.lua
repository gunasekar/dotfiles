-- Mermaid / PlantUML / D2 diagrams, drawn only in the read-only markdown view.
-- Repos:
--   https://github.com/3rd/diagram.nvim   -- detects fenced diagram blocks, renders them
--   https://github.com/3rd/image.nvim     -- draws the resulting image in the buffer
--
-- FOLLOWS THE MARKDOWN PREVIEW, NO KEY OF ITS OWN:
--   A buffer being edited never shows images: markdown stays as written. When
--   <leader>ui flips it into the read-only rendered view (plugins/markdown.lua),
--   markview fires MarkviewEnable and the diagrams draw; flipping back fires
--   MarkviewDisable and clears them. The view is locked, so its text can't change
--   under the images. Both plugins load on the first preview.
--
-- REQUIREMENTS (host-level, not managed by lazy.nvim):
--   * A terminal speaking the KITTY GRAPHICS PROTOCOL.
--       Works:    Kitty, WezTerm.
--       Does NOT: Terminal.app, plain xterm. There the preview shows the
--       fenced source as a code block.
--   * ImageMagick CLI ........... `magick`  -> already installed (/opt/homebrew/bin/magick)
--   * mermaid-cli ............... `mmdc`    -> already installed (/opt/homebrew/bin/mmdc)
--   * (optional, PlantUML) ...... `plantuml` on PATH
--   Override detection with `vim.g.diagram_inline = true|false` when the guess is
--   wrong (e.g. a tmux server started from kitty, later attached from Terminal.app,
--   still inherits kitty's env).
-- tmux users: add `set -g allow-passthrough on` to ~/.tmux.conf or images won't pass through.

-- Kitty-graphics terminals announce themselves through env vars. TERM survives SSH
-- (xterm-kitty); the *_ID / *_PANE vars survive into tmux, where
-- TERM_PROGRAM becomes "tmux".
local function has_kitty_graphics()
  if vim.g.diagram_inline ~= nil then
    return vim.g.diagram_inline
  end
  local env = vim.env
  -- tmux inside tmux (e.g. a trails session attached from a pane): image.nvim wraps
  -- its escapes for one tmux layer only, so the outer tmux mangles them and prints
  -- fragments like "101m" over the screen. The client of a nested tmux is itself
  -- a tmux, so its termname is tmux-*/screen-*.
  if env.TMUX then
    local client = vim.trim(vim.fn.system({ "tmux", "display-message", "-p", "#{client_termname}" }))
    if client:match("^tmux") or client:match("^screen") then
      return false
    end
  end
  if env.KITTY_WINDOW_ID or env.WEZTERM_PANE then
    return true
  end
  local term, program = env.TERM or "", env.TERM_PROGRAM or ""
  return term:match("kitty") ~= nil or program == "WezTerm"
end

-- Wire diagram rendering to markview's enable/disable events. Runs from `init`, so
-- it costs nothing until a preview opens; `require("diagram")` then loads both plugins.
local function attach_to_markview_preview()
  local group = vim.api.nvim_create_augroup("diagram_markview_preview", { clear = true })

  -- diagram.nvim acts on the current window's buffer; borrow the buffer's window.
  local function in_window_of(buf, fn)
    local win = vim.fn.win_findbuf(buf)[1]
    if win then
      vim.api.nvim_win_call(win, fn)
    end
  end

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MarkviewEnable",
    callback = function(ev)
      if has_kitty_graphics() then
        in_window_of(ev.data.buffer, function()
          require("diagram").render()
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MarkviewDisable",
    callback = function(ev)
      if package.loaded["diagram"] then
        in_window_of(ev.data.buffer, function()
          require("diagram").clear()
        end)
      end
    end,
  })
end

return {
  {
    "3rd/image.nvim",
    -- No build step: the `magick_cli` processor uses the ImageMagick CLI directly,
    -- so the `magick` LuaRock (and luarocks/hererocks) is not needed.
    build = false,
    -- Lazy: only loaded when diagram.nvim (which depends on this) is loaded by
    -- the first preview.
    lazy = true,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      -- Draw only what diagram.nvim hands over. Every built-in integration attaches
      -- to plain filetypes and would draw in the buffer being edited, and image
      -- files belong to snacks.image (editor/snacks.lua).
      integrations = {
        markdown = { enabled = false },
        asciidoc = { enabled = false },
        typst = { enabled = false },
        neorg = { enabled = false },
        syslang = { enabled = false },
      },
      hijack_file_patterns = {},
      max_width = 120,
      max_height = 48,
      max_width_window_percentage = 90,
      max_height_window_percentage = 80,
      window_overlap_clear_enabled = true, -- hide images when a float/popup overlaps
      -- Must stay false. When true, image.nvim registers FocusLost/FocusGained
      -- autocmds that toggle `disable_decorator_handling`. Focusing the Claude
      -- terminal split fires FocusLost (the terminal does focus-event reporting),
      -- but FocusGained doesn't reliably fire on return — leaving the flag stuck
      -- `true`, which permanently disables the decoration provider so diagrams
      -- never render again until Neovim restarts.
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = true,
    },
  },

  {
    "3rd/diagram.nvim",
    dependencies = { "3rd/image.nvim" },
    lazy = true,
    init = attach_to_markview_preview,
    -- `opts` must be a function: `require("diagram.integrations.markdown")` can only
    -- succeed once diagram.nvim is on the runtimepath. Evaluating it inside the spec
    -- table (at config-load time) runs before lazy.nvim loads the plugin and fails.
    opts = function()
      return {
        -- Render fenced ```mermaid / ```plantuml / ```d2 blocks in Markdown buffers.
        integrations = {
          require("diagram.integrations.markdown"),
        },
        -- No events: diagram.nvim never renders on its own, so the edited buffer
        -- stays image-free. attach_to_markview_preview() drives every render.
        events = {
          render_buffer = {},
          clear_buffer = {},
        },
        renderer_options = {
          mermaid = {
            -- `dark` theme draws light text, edge labels, and connector lines —
            -- legible on the transparent (black terminal) background. `neutral`
            -- assumes a light page, so its dark-grey labels vanish on black.
            theme = "dark", -- neutral | default | dark | forest
            background = "transparent",
            -- Controls the PNG's physical size: mmdc renders at this scale,
            -- image.nvim then displays it at natural size (its max_* options
            -- only shrink, never enlarge). Higher scale = larger diagrams.
            scale = 3,
            -- diagram.nvim flags ANY mmdc stderr output as a render failure,
            -- even when the exit code is 0 and the PNG renders fine. `--quiet`
            -- silences mmdc's progress/warning chatter so only genuine errors
            -- (non-zero exits) still surface a notification.
            cli_args = { "--quiet" },
          },
          plantuml = {
            charset = "utf-8",
          },
          d2 = {
            theme_id = 1,
          },
        },
      }
    end,
  },
}
