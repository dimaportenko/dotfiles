return {
  "johnseth97/codex.nvim",
  cmd = { "Codex", "CodexToggle", "CodexSelection", "CodexBuffer", "CodexFile" },
  event = "VeryLazy",
  config = function()
    local ok, codex = pcall(require, "codex")
    if not ok then
      vim.notify("codex.nvim not available", vim.log.levels.WARN)
      return
    end

    codex.setup({
      width = 0.5,
      panel = true,
      keymaps = {
        toggle = nil,
      },
    })

    local function exit_visual_mode()
      local mode = vim.fn.mode()
      if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
        return
      end

      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(esc, "nx", false)
      vim.cmd("redraw")
    end

    local function send_to_codex(text, attempt)
      if not text or text == "" then
        vim.notify("Nothing to send to Codex", vim.log.levels.WARN)
        return
      end

      exit_visual_mode()
      codex.open()

      local state_ok, state = pcall(require, "codex.state")
      if not state_ok or not state.job then
        if (attempt or 1) < 10 then
          vim.defer_fn(function()
            send_to_codex(text, (attempt or 1) + 1)
          end, 50)
          return
        end

        vim.notify("Codex is not ready yet", vim.log.levels.WARN)
        return
      end

      vim.fn.chansend(state.job, text .. "\n")
      vim.cmd("startinsert")
    end

    local function get_visual_selection()
      local mode = vim.fn.mode()
      local start_pos
      local end_pos

      if mode == "v" or mode == "V" or mode == "\22" then
        start_pos = vim.fn.getpos("v")
        end_pos = vim.fn.getcurpos()
      else
        start_pos = vim.fn.getpos("'<")
        end_pos = vim.fn.getpos("'>")
      end

      local start_line = start_pos[2]
      local start_col = start_pos[3]
      local end_line = end_pos[2]
      local end_col = end_pos[3]

      if start_line == 0 or end_line == 0 then
        return nil
      end

      if start_line > end_line or (start_line == end_line and start_col > end_col) then
        start_line, end_line = end_line, start_line
        start_col, end_col = end_col, start_col
      end

      if mode == "V" then
        start_col = 1
        end_col = math.max(1, #vim.fn.getline(end_line))
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
        vim.notify("No selection to send to Codex", vim.log.levels.WARN)
        return
      end

      local file = vim.fn.expand("%:p")
      if file == "" then
        vim.notify("No file in current buffer", vim.log.levels.WARN)
        return
      end

      local relative_file = vim.fn.fnamemodify(file, ":.")
      local message = string.format("@%s#L%d-%d\n", relative_file, selection.start_line, selection.end_line)

      send_to_codex(message)
    end

    local function send_current_file_path()
      local file = vim.fn.expand("%:p")
      if file == "" then
        vim.notify("No file in current buffer", vim.log.levels.WARN)
        return
      end

      local relative_file = vim.fn.fnamemodify(file, ":.")
      send_to_codex(string.format("@%s\n", relative_file))
    end

    vim.api.nvim_create_user_command("CodexSelection", function()
      send_selection_with_file_context()
    end, { desc = "Send selection with file context to Codex" })

    vim.api.nvim_create_user_command("CodexBuffer", function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      send_to_codex(table.concat(lines, "\n"))
    end, { desc = "Send buffer to Codex" })

    vim.api.nvim_create_user_command("CodexFile", function()
      send_current_file_path()
    end, { desc = "Send file path to Codex" })

    vim.keymap.set({ "n", "x" }, "<leader>ka", function()
      codex.toggle()
    end, { desc = "Codex: Toggle terminal" })

    vim.keymap.set("x", "<leader>ks", function()
      send_selection_with_file_context()
    end, { desc = "Codex: Send selection" })

    vim.keymap.set("n", "<leader>kf", function()
      send_current_file_path()
    end, { desc = "Codex: Send file path" })
  end,
}
