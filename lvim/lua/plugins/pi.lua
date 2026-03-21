return {
  "pablopunk/pi.nvim",
  cmd = { "PiAsk", "PiAskSelection", "PiCancel" },
  keys = {
    { "<leader>ia", mode = { "n", "x" } },
    { "<leader>is", mode = "x" },
    { "<leader>if", mode = "n" },
  },
  config = function()
    local ok, pi = pcall(require, "pi")
    if ok then
      pi.setup()
    else
      vim.notify("pi.nvim not available", vim.log.levels.WARN)
    end

    local pi_buf = nil
    local pi_win = nil

    local function open_pi_terminal()
      vim.cmd("vsplit")
      pi_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_width(pi_win, math.floor(vim.o.columns * 0.5))

      if pi_buf and vim.api.nvim_buf_is_valid(pi_buf) then
        vim.api.nvim_win_set_buf(pi_win, pi_buf)
      else
        pi_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(pi_win, pi_buf)
        vim.fn.termopen("pi", {
          on_exit = function()
            pi_win = nil
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
      end

      open_pi_terminal()
    end

    vim.keymap.set({ "n", "x" }, "<leader>ia", function()
      vim.cmd("stopinsert")
      toggle_pi_terminal()
    end, { desc = "Toggle pi" })

    vim.keymap.set("x", "<leader>is", "<cmd>PiAskSelection<cr>", { desc = "Ask pi with selection" })
    vim.keymap.set("n", "<leader>if", "<cmd>PiAsk<cr>", { desc = "Ask pi about file" })
  end,
}
