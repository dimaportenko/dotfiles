return {
  "waldnzwrld/cursor-agent.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    vim.g.cursor_agent_config = {
      window_mode = "attached",
      position = "right",
      width = 0.5,
    }
  end,
  config = function()
    require("cursor-agent").setup(vim.g.cursor_agent_config or {})

    -- Keymaps
    vim.keymap.set("n", "<leader>ka", ":CursorAgent<CR>", { desc = "Cursor Agent: Toggle terminal" })
    vim.keymap.set("v", "<leader>ka", ":CursorAgentSelection<CR>", { desc = "Cursor Agent: Send selection" })
    vim.keymap.set("n", "<leader>kf", ":CursorAgentBuffer<CR>", { desc = "Cursor Agent: Send buffer" })
  end,
}
