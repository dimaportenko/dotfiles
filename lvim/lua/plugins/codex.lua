return {
  "johnseth97/codex.nvim",
  cmd = { "Codex", "CodexToggle", "CodexSelection", "CodexBuffer" },
  keys = {
    { "<leader>ka", mode = "n" },
    { "<leader>ka", mode = "v" },
    { "<leader>kf", mode = "n" },
  },
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

    local function send_to_codex(text)
      if not text or text == "" then
        vim.notify("Nothing to send to Codex", vim.log.levels.WARN)
        return
      end

      codex.open()

      local state_ok, state = pcall(require, "codex.state")
      if not state_ok or not state.job then
        vim.notify("Codex is not ready yet", vim.log.levels.WARN)
        return
      end

      vim.fn.chansend(state.job, text .. "\n")
    end

    local function get_visual_selection()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      if start_line == 0 or end_line == 0 then
        return ""
      end

      local lines = vim.fn.getline(start_line, end_line)
      return table.concat(lines, "\n")
    end

    vim.api.nvim_create_user_command("CodexSelection", function()
      send_to_codex(get_visual_selection())
    end, { desc = "Send selection to Codex" })

    vim.api.nvim_create_user_command("CodexBuffer", function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      send_to_codex(table.concat(lines, "\n"))
    end, { desc = "Send buffer to Codex" })

    vim.keymap.set("n", "<leader>ka", function()
      codex.toggle()
    end, { desc = "Codex: Toggle terminal" })

    vim.keymap.set("v", "<leader>ka", "<cmd>CodexSelection<CR>", { desc = "Codex: Send selection" })

    vim.keymap.set("n", "<leader>kf", "<cmd>CodexBuffer<CR>", { desc = "Codex: Send buffer" })
  end,
}
