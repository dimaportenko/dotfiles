return {
  "pablopunk/pi.nvim",
  event = "VeryLazy",
  config = function()
    local ok, pi = pcall(require, "pi")
    if ok then
      pi.setup()
    else
      vim.notify("pi.nvim not available", vim.log.levels.WARN)
    end

    local pi_buf = nil
    local pi_win = nil
    local pi_job = nil

    local function open_pi_terminal()
      vim.cmd("vsplit")
      pi_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_width(pi_win, math.floor(vim.o.columns * 0.5))

      if pi_buf and vim.api.nvim_buf_is_valid(pi_buf) then
        vim.api.nvim_win_set_buf(pi_win, pi_buf)
      else
        pi_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(pi_win, pi_buf)
        pi_job = vim.fn.jobstart("pi", {
          term = true,
          on_exit = function()
            pi_win = nil
            pi_job = nil
          end,
        })
      end

      vim.cmd("startinsert")
    end

    local function toggle_pi_terminal()
      if pi_win and vim.api.nvim_win_is_valid(pi_win) then
        vim.api.nvim_win_close(pi_win, true)
        pi_win = nil
        return
      end

      if pi_buf and not vim.api.nvim_buf_is_valid(pi_buf) then
        pi_buf = nil
        pi_job = nil
      end

      open_pi_terminal()
    end

    local function ensure_pi_terminal()
      if pi_buf and not vim.api.nvim_buf_is_valid(pi_buf) then
        pi_buf = nil
        pi_job = nil
      end

      if not (pi_buf and vim.api.nvim_buf_is_valid(pi_buf) and pi_job) then
        open_pi_terminal()
        return
      end

      if not (pi_win and vim.api.nvim_win_is_valid(pi_win)) then
        vim.cmd("vsplit")
        pi_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_width(pi_win, math.floor(vim.o.columns * 0.5))
        vim.api.nvim_win_set_buf(pi_win, pi_buf)
        vim.cmd("startinsert")
      end
    end

    local function send_to_pi(text)
      if not text or text == "" then
        vim.notify("Nothing to send to pi", vim.log.levels.WARN)
        return
      end

      ensure_pi_terminal()

      if not pi_job then
        vim.notify("pi is not ready yet", vim.log.levels.WARN)
        return
      end

      vim.fn.chansend(pi_job, text)

      -- Focus the pi terminal window and enter insert mode
      if pi_win and vim.api.nvim_win_is_valid(pi_win) then
        vim.api.nvim_set_current_win(pi_win)
      end
      vim.cmd("startinsert")
    end

    local function get_visual_selection()
      -- Exit visual mode to set '< and '> marks for the current selection
      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(esc, "x", false)

      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      local start_line = start_pos[2]
      local start_col = start_pos[3]
      local end_line = end_pos[2]
      local end_col = end_pos[3]

      if start_line == 0 or end_line == 0 then
        return nil
      end

      local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
      if #lines == 0 then
        return nil
      end

      lines[1] = string.sub(lines[1], start_col)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)

      return {
        text = table.concat(lines, "\n"),
        start_line = start_line,
        end_line = end_line,
      }
    end

    local function send_selection_with_file_context()
      local selection = get_visual_selection()
      if not selection or selection.text == "" then
        vim.notify("No selection to send to pi", vim.log.levels.WARN)
        return
      end

      local file = vim.fn.expand("%:p")
      if file == "" then
        vim.notify("No file in current buffer", vim.log.levels.WARN)
        return
      end

      local relative_file = vim.fn.fnamemodify(file, ":.")
      local message = string.format("@%s#L%d-%d\n", relative_file, selection.start_line, selection.end_line)

      send_to_pi(message)
    end

    local function send_current_file_path()
      local file = vim.fn.expand("%:p")
      if file == "" then
        vim.notify("No file in current buffer", vim.log.levels.WARN)
        return
      end

      local relative_file = vim.fn.fnamemodify(file, ":.")
      send_to_pi(string.format("@%s\n", relative_file))
    end

    vim.keymap.set({ "n", "x" }, "<leader>ia", function()
      vim.cmd("stopinsert")
      toggle_pi_terminal()
    end, { desc = "Toggle pi" })

    vim.keymap.set("x", "<leader>is", function()
      send_selection_with_file_context()
    end, { desc = "Send selection to pi" })

    vim.keymap.set("n", "<leader>if", function()
      send_current_file_path()
    end, { desc = "Send file path to pi" })
  end,
}
