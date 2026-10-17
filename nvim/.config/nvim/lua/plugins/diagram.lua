-- Inline diagram + image rendering for Markdown (Mermaid / PlantUML / D2 / images)
-- Repos:
--   https://github.com/3rd/diagram.nvim   -- detects fenced diagram blocks, renders them
--   https://github.com/3rd/image.nvim     -- draws the resulting image in the buffer
--
-- DEFAULT OFF, TOGGLE ON:
--   The plugins are installed but rendering starts DISABLED. Nothing loads or
--   renders until you press the toggle:
--       <leader>ui   Toggle inline images/diagrams
--   First press loads both plugins, enables rendering, and draws the current
--   buffer. Press again to hide. (See <leader>u "UI/Toggle" in which-key.)
--
-- REQUIREMENTS (host-level, not managed by lazy.nvim):
--   * A terminal speaking the KITTY GRAPHICS PROTOCOL.
--       Works:    WezTerm, Kitty, Ghostty.  <-- current default is Ghostty.
--       Does NOT: iTerm2, Terminal.app, plain xterm.
--   * ImageMagick CLI ........... `magick`  -> already installed (/opt/homebrew/bin/magick)
--   * mermaid-cli ............... `mmdc`    -> already installed (/opt/homebrew/bin/mmdc)
--   * (optional, PlantUML) ...... `plantuml` on PATH
--
-- QUICK LOOK FALLBACK (non-graphics terminals: Terminal.app, iTerm2, ...):
--   Inline drawing is impossible there, so <leader>ui instead renders the diagram
--   under the cursor and opens it in Quick Look (`qlmanage -p`; `vim.ui.open` off
--   macOS). Detection is env-based — see `has_kitty_graphics()`. Override it with
--   `vim.g.diagram_inline = true|false` when the guess is wrong (e.g. a tmux server
--   started from Ghostty, later attached from Terminal.app, still inherits Ghostty's env).
-- tmux users: add `set -g allow-passthrough on` to ~/.tmux.conf or images won't pass through.

-- Kitty-graphics terminals announce themselves through env vars. TERM survives SSH
-- (xterm-kitty / xterm-ghostty); the *_DIR / *_ID vars survive into tmux, where
-- TERM_PROGRAM becomes "tmux". Unknown terminals get the Quick Look fallback,
-- which works everywhere, rather than an inline toggle that silently draws nothing.
local function has_kitty_graphics()
  if vim.g.diagram_inline ~= nil then
    return vim.g.diagram_inline
  end
  local env = vim.env
  if env.KITTY_WINDOW_ID or env.GHOSTTY_RESOURCES_DIR or env.WEZTERM_PANE then
    return true
  end
  local term, program = env.TERM or "", env.TERM_PROGRAM or ""
  return term:match("kitty") ~= nil
    or term:match("ghostty") ~= nil
    or program == "ghostty"
    or program == "WezTerm"
end

-- Shared by diagram.nvim's setup and the Quick Look path, so both render identically
-- (and hit the same diagram-cache PNG).
local renderer_options = {
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
}

-- The cached PNGs are dark-theme on a transparent background: fine over the terminal,
-- unreadable light-on-white in Quick Look. Flatten a copy onto the colorscheme's
-- Normal background (magick is already required by image.nvim's processor).
local function flatten_for_viewer(png)
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local color = bg and string.format("#%06x", bg) or "#1e1e1e"
  local out = png:gsub("%.png$", "") .. "-" .. color:sub(2) .. ".png"
  if vim.fn.filereadable(out) == 1 then
    return out
  end
  local res = vim.system({ "magick", png, "-background", color, "-flatten", out }):wait()
  return res.code == 0 and out or png
end

local function open_in_viewer(png)
  local file = flatten_for_viewer(png)
  if vim.fn.executable("qlmanage") == 1 then
    -- -p is the Quick Look panel; qlmanage blocks until it closes, so run detached.
    vim.system({ "qlmanage", "-p", file }, { detach = true, stdout = false, stderr = false })
  else
    vim.ui.open(file)
  end
end

-- Render the fenced diagram under the cursor with diagram.nvim's own renderer and
-- show it in the system viewer. The renderer returns a cached path at once, or an
-- mmdc/plantuml/d2 job to wait on.
local function quicklook_diagram_at_cursor()
  local integration = require("diagram.integrations.markdown")
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.tbl_contains(integration.filetypes, vim.bo[bufnr].filetype) then
    vim.notify("No diagrams in this filetype", vim.log.levels.INFO)
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local found
  for _, diagram in ipairs(integration.query_buffer_diagrams(bufnr)) do
    -- range covers only the info string (```mermaid line); the block runs one line
    -- per source line plus the closing fence.
    local _, newlines = diagram.source:gsub("\n", "")
    if row >= diagram.range.start_row and row <= diagram.range.start_row + newlines + 1 then
      found = diagram
      break
    end
  end
  if not found then
    vim.notify("No diagram under the cursor", vim.log.levels.INFO)
    return
  end

  local renderer
  for _, r in ipairs(integration.renderers) do
    if r.id == found.renderer_id then
      renderer = r
      break
    end
  end
  local result = renderer and renderer.render(found.source, renderer_options[renderer.id] or {})
  if not result then
    return -- renderer already notified (e.g. mmdc missing)
  end

  local function show()
    if vim.fn.filereadable(result.file_path) == 0 then
      vim.notify("Diagram render failed: " .. found.renderer_id, vim.log.levels.ERROR)
      return
    end
    open_in_viewer(result.file_path)
  end

  if not result.job_id then
    return show()
  end
  vim.notify("Rendering " .. found.renderer_id .. " diagram…", vim.log.levels.INFO)
  local timer = assert(vim.uv.new_timer())
  timer:start(
    100,
    100,
    vim.schedule_wrap(function()
      if vim.fn.jobwait({ result.job_id }, 0)[1] ~= -1 and not timer:is_closing() then
        timer:stop()
        timer:close()
        show()
      end
    end)
  )
end

return {
  {
    "3rd/image.nvim",
    -- No build step: the `magick_cli` processor uses the ImageMagick CLI directly,
    -- so the `magick` LuaRock (and luarocks/hererocks) is not needed.
    build = false,
    -- Lazy: only loaded when diagram.nvim (which depends on this) is loaded by
    -- the toggle key below. Not tied to a filetype, so opening Markdown alone
    -- does nothing until you toggle.
    lazy = true,
    config = function(_, opts)
      require("image").setup(opts)
      -- Start with rendering OFF; <leader>ui flips it on.
      require("image").disable()
    end,
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
    -- Loaded on first toggle press (not on filetype), keeping Markdown buffers
    -- render-free until you ask for it. Pressing the key loads diagram.nvim,
    -- which pulls in image.nvim (disabled), then the callback enables + renders.
    keys = {
      {
        "<leader>ui",
        function()
          if not has_kitty_graphics() then
            return quicklook_diagram_at_cursor()
          end
          local image = require("image")
          if image.is_enabled() then
            image.disable()
            vim.notify("Inline images/diagrams: off", vim.log.levels.INFO)
          else
            image.enable()
            -- diagram.nvim renders on render_buffer events (incl. BufWinEnter);
            -- fire one so the current buffer draws immediately on enable.
            vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = 0 })
            vim.notify("Inline images/diagrams: on", vim.log.levels.INFO)
          end
        end,
        desc = "Toggle inline images/diagrams (Quick Look off-graphics)",
      },
    },
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
        renderer_options = renderer_options,
      }
    end,
  },
}
