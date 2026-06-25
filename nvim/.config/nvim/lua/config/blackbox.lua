-- blackbox.nvim — passive vim.notify recorder with automatic purge and source tagging.
-- Log location: stdpath("data")/blackbox.log  (~/.local/share/nvim/blackbox.log)
--
-- Commands:
--   :Blackbox       — open the log file in a split
--   :BlackboxClear  — wipe the log file
--
-- To customise, edit the M.setup({}) call at the bottom of this file.

local M = {}
local _installed = false
local _cached_size_bytes = nil  -- invalidated on purge, avoids per-notify file open

M.config = {
  log_path     = vim.fn.stdpath("data") .. "/blackbox.log",
  max_age_days = 7,
  max_size_kb  = 1024, -- stop appending once the file exceeds this size
  levels       = { vim.log.levels.ERROR, vim.log.levels.WARN },
}

local LEVEL_NAMES = {
  [vim.log.levels.ERROR] = "ERROR",
  [vim.log.levels.WARN]  = "WARN",
  [vim.log.levels.INFO]  = "INFO",
  [vim.log.levels.DEBUG] = "DEBUG",
}

-- Build a fast lookup set from the levels list
local level_set = {}
local function rebuild_level_set()
  level_set = {}
  for _, l in ipairs(M.config.levels) do
    level_set[l] = true
  end
end

local function file_size_bytes()
  if _cached_size_bytes then return _cached_size_bytes end
  local f = io.open(M.config.log_path, "r")
  if not f then _cached_size_bytes = 0; return 0 end
  local size = f:seek("end") or 0
  f:close()
  _cached_size_bytes = size
  return _cached_size_bytes
end

-- Walk the call stack and return the first frame outside this module
local function get_source()
  local trace = debug.traceback("", 2)
  for line in trace:gmatch("[^\n]+") do
    local src = line:match("^%s+(.-):%d+:")
    if src
      and not src:match("config[/.]blackbox")  -- skip only this exact module
      and not src:match("%[C%]")
      and not src:match("vim/shared")
    then
      src = src:gsub(".*/lua/", ""):gsub("%.lua$", "")
      return src
    end
  end
  return "?"
end

-- vim.notify msg can be any type; coerce to string safely
local function to_str(v)
  if type(v) == "string" then return v end
  if type(v) == "nil"    then return "<nil>" end
  return vim.inspect(v)
end

local function append(msg, level)
  if not level_set[level] then return end
  if file_size_bytes() >= M.config.max_size_kb * 1024 then return end
  local src = get_source()
  local f = io.open(M.config.log_path, "a")
  if not f then return end
  local line = string.format("[%s] [%s] [%s] %s\n",
    os.date("%Y-%m-%d %H:%M:%S"),
    LEVEL_NAMES[level] or tostring(level),
    src,
    to_str(msg))
  f:write(line)
  f:close()
  _cached_size_bytes = (_cached_size_bytes or 0) + #line
end

local function purge_old_entries()
  _cached_size_bytes = nil  -- invalidate cache after purge

  local f = io.open(M.config.log_path, "r")
  if not f then return end
  local content = f:read("*a")
  f:close()

  local cutoff = os.time() - M.config.max_age_days * 24 * 60 * 60
  local kept = {}
  for line in content:gmatch("[^\n]+") do
    local y, mo, d, h, mi, s = line:match("^%[(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)%]")
    if y then
      local t = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d),
                          hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
      -- Guard against os.time returning -1 on DST-ambiguous timestamps
      if t and t ~= -1 and t >= cutoff then kept[#kept + 1] = line end
    else
      kept[#kept + 1] = line  -- keep lines that don't parse rather than silently drop
    end
  end

  local tmp = M.config.log_path .. ".tmp"
  local out, err = io.open(tmp, "w")
  if out then
    out:write(#kept > 0 and (table.concat(kept, "\n") .. "\n") or "")
    out:close()
    os.rename(tmp, M.config.log_path)
  else
    local fb = io.open(M.config.log_path, "a")
    if fb then
      fb:write(string.format("[%s] [ERROR] [blackbox] purge failed: %s\n",
        os.date("%Y-%m-%d %H:%M:%S"), err or "unknown"))
      fb:close()
    end
  end
end

local function make_wrapper(next_notify)
  return function(msg, level, opts)
    append(msg, level)
    return next_notify(msg, level, opts)
  end
end

local function register_commands()
  vim.api.nvim_create_user_command("Blackbox", function()
    vim.cmd("split " .. vim.fn.fnameescape(M.config.log_path))
  end, { desc = "Open blackbox.nvim log" })

  vim.api.nvim_create_user_command("BlackboxClear", function()
    local f = io.open(M.config.log_path, "w")
    if f then
      f:close()
      _cached_size_bytes = 0
      -- INFO level won't self-log unless the user adds INFO to levels (harmless if they do)
      vim.notify("blackbox.nvim log cleared", vim.log.levels.INFO)
    else
      vim.notify("blackbox.nvim: failed to clear log: " .. M.config.log_path, vim.log.levels.ERROR)
    end
  end, { desc = "Clear blackbox.nvim log" })
end

function M.setup(opts)
  if _installed then return end
  _installed = true

  local levels_override = opts and opts.levels
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  -- tbl_deep_extend merges arrays by index rather than replacing, so apply levels explicitly
  if levels_override then M.config.levels = levels_override end
  rebuild_level_set()

  vim.notify = make_wrapper(vim.notify)

  -- Re-wrap after VeryLazy so we sit on top of Noice (or any plugin that replaces vim.notify)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      vim.notify = make_wrapper(vim.notify)
    end,
  })

  register_commands()
  purge_old_entries()
end

-- ── User config ────────────────────────────────────────────────────────────────
M.setup({
  -- log_path     = vim.fn.stdpath("data") .. "/blackbox.log",
  -- max_age_days = 7,
  -- max_size_kb  = 1024,
  -- levels       = { vim.log.levels.ERROR, vim.log.levels.WARN },
})

return M
