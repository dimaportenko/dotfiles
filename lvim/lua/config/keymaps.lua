-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- map({ "n" }, "<leader>w", "<cmd>bdelete<cr>", { desc = "Down", expr = true, silent = true })
map("n", "<leader>w", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })

map({ "n" }, "<leader>p", "<cmd>Telescope project_cli_commands open<cr>", { desc = "Open project tasks" })
map({ "n" }, "<leader>;", "<cmd>Telescope project_cli_commands running<cr>", { desc = "Running project tasks" })

-- keymap("n", "<leader>;", ":Telescope project_cli_commands running<cr>", opts)
-- keymap("n", "<leader>p", ":Telescope project_cli_commands open<cr>", opts)
