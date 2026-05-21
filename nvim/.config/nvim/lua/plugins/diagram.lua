-- Inline diagram rendering for Markdown (Mermaid / PlantUML / D2)
-- Repos:
--   https://github.com/3rd/diagram.nvim   -- detects fenced diagram blocks, renders them
--   https://github.com/3rd/image.nvim     -- draws the resulting image in the buffer
--
-- REQUIREMENTS (host-level, not managed by lazy.nvim):
--   * A terminal speaking the KITTY GRAPHICS PROTOCOL.
--       Works:    WezTerm, Kitty, Ghostty.
--       Does NOT: iTerm2, Terminal.app, plain xterm.  <-- current default is iTerm2.
--   * ImageMagick CLI ........... `magick`  -> already installed (/opt/homebrew/bin/magick)
--   * mermaid-cli ............... `mmdc`    -> already installed (/opt/homebrew/bin/mmdc)
--   * (optional, PlantUML) ...... `plantuml` on PATH
--
-- If you stay on iTerm2 these plugins load but render nothing — switch terminals first.
-- tmux users: add `set -g allow-passthrough on` to ~/.tmux.conf or images won't pass through.

return {
  {
    "3rd/image.nvim",
    -- No build step: the `magick_cli` processor uses the ImageMagick CLI directly,
    -- so the `magick` LuaRock (and luarocks/hererocks) is not needed.
    build = false,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        -- Keep the Markdown integration so plain ![](img.png) links also render.
        -- diagram.nvim handles the ```mermaid fences separately.
        markdown = {
          enabled = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown" },
        },
      },
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
    ft = { "markdown" },
    -- `opts` must be a function: `require("diagram.integrations.markdown")` can only
    -- succeed once diagram.nvim is on the runtimepath. Evaluating it inside the spec
    -- table (at config-load time) runs before lazy.nvim loads the plugin and fails.
    opts = function()
      return {
        -- Render fenced ```mermaid / ```plantuml / ```d2 blocks in Markdown buffers.
        integrations = {
          require("diagram.integrations.markdown"),
        },
        -- diagram.nvim's default render_buffer events are
        -- { "InsertLeave", "BufWinEnter", "TextChanged" }. `clear_buffer` fires
        -- on BufLeave, so focusing another window (e.g. the Claude terminal)
        -- clears the diagram — but BufWinEnter only fires the FIRST time a
        -- buffer is shown in a window, not when you re-focus a window that
        -- already displays it. So returning never re-rendered. Add BufEnter
        -- so re-focusing the markdown buffer redraws the diagram.
        events = {
          render_buffer = { "InsertLeave", "BufWinEnter", "BufEnter", "TextChanged" },
          clear_buffer = { "BufLeave" },
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
