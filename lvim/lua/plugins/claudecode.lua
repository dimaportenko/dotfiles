return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal_cmd = "~/.claude/local/claude",
      terminal = {
        provider = "snacks",
        snacks_win_opts = {
          position = "right",
          width = 0.5, -- 40% of editor width
        },
      },
    },
  },
}
