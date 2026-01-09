return {
  {
    "coder/claudecode.nvim",

    keys = {
      { "<leader>af", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add file to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeAdd<cr>", mode = "v", desc = "Add selection to Claude" },
    },
    opts = {
      terminal_cmd = "~/.claude/local/claude",
      terminal = {
        provider = "snacks",
        snacks_win_opts = {
          position = "right",
          width = 0.5, -- 50% of editor width
        },
      },
      diff_opts = {
        auto_close_on_accept = true, -- Close diff windows after accepting
        vertical_split = true, -- Use vertical splits for diffs
        open_in_current_tab = false, -- Don't create new tabs
        keep_terminal_focus = true, -- Keep focus on Claude terminal
      },
    },
  },
}
