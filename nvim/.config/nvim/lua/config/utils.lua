-- Utility functions for Neovim
local M = {}

-- Toggle between Go test and source files
M.toggle_go_test = function()
  -- Get the current buffer's file name
  local current_file = vim.fn.expand("%:p")
  if string.match(current_file, "_test.go$") then
    -- If the current file ends with '_test.go', try to find the corresponding non-test file
    local non_test_file = string.gsub(current_file, "_test.go$", ".go")
    if vim.fn.filereadable(non_test_file) == 1 then
      -- Open the corresponding non-test file if it exists
      vim.cmd.edit(non_test_file)
      print("Switched to source file")
    else
      print("No corresponding source file found")
    end
  else
    -- If the current file is a non-test file, try to find the corresponding test file
    local test_file = string.gsub(current_file, ".go$", "_test.go")
    if vim.fn.filereadable(test_file) == 1 then
      -- Open the corresponding test file if it exists
      vim.cmd.edit(test_file)
      print("Switched to test file")
    else
      print("No corresponding test file found")
    end
  end
end

-- Get line numbers for highlighted lines in visual mode
-- Returns format: L80 (single line) or L80-L85 (range)
M.get_highlighted_line_numbers = function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  if start_line == 0 or end_line == 0 then
    print("No visual selection found")
    return
  end

  -- Ensure start_line is always less than or equal to end_line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local result
  if start_line == end_line then
    -- Single line: L80
    result = string.format("L%d", start_line)
  else
    -- Range: L80-L85
    result = string.format("L%d-L%d", start_line, end_line)
  end

  -- Copy to clipboard
  vim.fn.setreg("+", result)
  print("Copied: " .. result)
  return result
end

-- Open current file in GitHub (if in a git repo)
M.open_in_github = function()
  local filepath = vim.fn.expand("%:p")
  local line = vim.fn.line(".")

  -- Get git root
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("Not in a git repository")
    return
  end

  -- Get remote URL
  local remote_url = vim.fn.systemlist("git config --get remote.origin.url")[1]
  if vim.v.shell_error ~= 0 then
    print("No remote origin found")
    return
  end

  -- Convert SSH URL to HTTPS if needed
  remote_url = string.gsub(remote_url, "git@github%.com:", "https://github.com/")
  remote_url = string.gsub(remote_url, "%.git$", "")

  -- Get relative path
  local rel_path = string.gsub(filepath, "^" .. git_root .. "/", "")

  -- Get current branch
  local branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]

  -- Construct GitHub URL
  local url = string.format("%s/blob/%s/%s#L%d", remote_url, branch, rel_path, line)

  -- Open in browser (macOS)
  vim.fn.system("open " .. vim.fn.shellescape(url))
  print("Opened in GitHub: " .. url)
end

-- Create user commands
vim.api.nvim_create_user_command("GoToggleTest", M.toggle_go_test, { desc = "Toggle between Go test and source file" })
vim.api.nvim_create_user_command("CopyLineNumbers", M.get_highlighted_line_numbers,
  { desc = "Copy line numbers from visual selection", range = true })
vim.api.nvim_create_user_command("OpenInGitHub", M.open_in_github, { desc = "Open current file in GitHub" })

-- Keymap for Go test toggle
vim.keymap.set("n", "<leader>gt", M.toggle_go_test, { desc = "Toggle Go test/source" })

return M
