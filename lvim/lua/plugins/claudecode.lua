return {
  {
    dir = "~/work/github/claudecode.nvim",
    -- "coder/claudecode.nvim",

    -- cmd = {
    --   "ClaudeCode",
    --   "ClaudeCodeAdd",
    --   "ClaudeCodeSend",
    --   "ClaudeCodeTreeAdd",
    --   "ClaudeCodeOpen",
    --   "ClaudeCodeClose",
    --   "ClaudeCodeToggle",
    --   "ClaudeCodeFocus",
    -- },
    keys = {
      { "<leader>af", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add file to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    },
    opts = {
      -- terminal_cmd = "~/.claude/local/claude",
      diff_opts = {
        enabled = false, -- Disable diff feature
      },
      terminal = {
        provider = "snacks",
        snacks_win_opts = {
          position = "right",
          width = 0.5, -- 50% of editor width
        },
      },
    },
  },
}
