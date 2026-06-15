return {
  -- Free <leader>xt (LazyVim maps it to Todo/Trouble) so plugins/swift.lua can
  -- bind it to XcodebuildTest. The Telescope todo search (<leader>st) stays.
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<leader>xt", false },
    },
  },
}
