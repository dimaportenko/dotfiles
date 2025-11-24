return {
  {
    name = "claude-toggle",
    dir = vim.fn.stdpath("config") .. "/lua/custom",
    config = function()
      require("custom.claude-toggle").setup()
    end,
    lazy = false,
  },
}
