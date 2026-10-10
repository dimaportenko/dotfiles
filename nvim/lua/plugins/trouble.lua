-- Document Symbols sidebar (<leader>cs): default split is 30 columns, too narrow for Python names.
return {
  "folke/trouble.nvim",
  opts = {
    modes = {
      symbols = {
        win = { size = 60 },
      },
    },
  },
}
