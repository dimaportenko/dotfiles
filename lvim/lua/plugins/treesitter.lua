return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      move = {
        keys = {
          goto_next_start = { ["]c"] = false },
          goto_previous_start = { ["[c"] = false },
        },
      },
    },
  },
}
