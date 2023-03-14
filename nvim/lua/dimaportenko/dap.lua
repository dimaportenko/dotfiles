require("neodev").setup({
  library = { plugins = { "nvim-dap-ui" }, types = true },
  ...
})

require("dapui").setup({
  icons = {
    expanded = "",
    collapsed = "",
  },
})

local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

keymap("n", "<leader>db", ":lua require'dap'.toggle_breakpoint()<CR>", opts)
keymap("n", "<leader>dc", ":lua require'dap'.continue()<CR>", opts)

