local M = {}

-- State management
local claude_state = {
  buf = nil,
  win = nil,
}

-- Check if buffer is valid and terminal is still running
local function is_buffer_valid(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  -- Check if buffer still has a running terminal
  local chan = vim.b[buf].terminal_job_id
  if not chan then
    return false
  end

  -- Try to get job status (returns 0 if running)
  local ok, status = pcall(vim.fn.jobwait, { chan }, 0)
  return ok and status[1] == -1
end

-- Check if window is valid and visible
local function is_window_visible(win)
  return win and vim.api.nvim_win_is_valid(win)
end

-- Close the Claude window
local function close_window()
  if is_window_visible(claude_state.win) then
    vim.api.nvim_win_close(claude_state.win, true)
    claude_state.win = nil
  end
end

-- Open the Claude window
local function open_window()
  -- Create or reuse buffer
  if not is_buffer_valid(claude_state.buf) then
    -- Create new terminal buffer
    claude_state.buf = vim.api.nvim_create_buf(false, true)
  end

  local width = math.floor(vim.o.columns * 0.4)

  -- Create floating window
  local opts = {
    win = 0,
    split = "right",
    width = width,
  }

  claude_state.win = vim.api.nvim_open_win(claude_state.buf, true, opts)

  if vim.bo[claude_state.buf].buftype ~= "terminal" then
    vim.cmd.term()
    local job_id = vim.bo[claude_state.buf].channel
    vim.fn.chansend(job_id, "claude\n\r")
  end

  -- Enter insert mode in the terminal
  vim.cmd("startinsert")

  -- Set up window-local keymaps for easy closing
  local opts_keymap = { noremap = true, silent = true, buffer = claude_state.buf }
  vim.keymap.set("t", "<C-O>", function()
    close_window()
  end, opts_keymap)
end

-- Toggle function
function M.toggle()
  if is_window_visible(claude_state.win) then
    close_window()
  else
    open_window()
  end
end

-- Setup function to register command
function M.setup()
  vim.api.nvim_create_user_command("ClaudeToggle", function()
    M.toggle()
  end, {})

  -- Set up global keymap for normal mode
  vim.keymap.set("n", "<C-O>", function()
    M.toggle()
  end, { noremap = true, silent = true, desc = "Toggle Claude terminal" })
end

-- Auto-setup when required
-- M.setup()

return M
