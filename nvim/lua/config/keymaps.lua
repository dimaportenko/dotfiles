-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Scope Telescope search to the nearest package root in monorepos so file and grep pickers stay focused.
local function package_root()
  local file = vim.api.nvim_buf_get_name(0)
  local start = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()

  local markers = {
    "package.json",
    "pyproject.toml",
    "go.mod",
    "Cargo.toml",
    ".git",
  }

  local found = vim.fs.find(markers, {
    path = start,
    upward = true,
    stop = vim.uv.cwd(),
  })[1]

  return found and vim.fs.dirname(found) or LazyVim.root()
end

-- map({ "n" }, "<leader>w", "<cmd>bdelete<cr>", { desc = "Down", expr = true, silent = true })
map("n", "<leader>w", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })

map("n", "<leader>W", function()
  Snacks.bufdelete.all()
end, { desc = "Delete All Buffers" })

map({ "n" }, "<leader>p", "<cmd>Telescope project_cli_commands open<cr>", { desc = "Open project tasks" })
map({ "n" }, "<leader>;", "<cmd>Telescope project_cli_commands running<cr>", { desc = "Running project tasks" })
map({ "n" }, "<leader>[", "<cmd>Telescope resume<cr>", { desc = "Telescope resume previous search" })

map("n", "<leader><leader>", function()
  require("telescope.builtin").find_files({ cwd = package_root() })
end, { desc = "Find files in package" })

map("n", "<leader>sg", function()
  require("telescope.builtin").live_grep({ cwd = package_root() })
end, { desc = "Grep in package" })

map("n", "<leader>sG", function()
  require("telescope.builtin").live_grep({ cwd = LazyVim.root() })
end, { desc = "Grep in repo" })

-- Terminal mode escape
map("t", "<A-z>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
-- map("t", "<C-x>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Copy relative path of current buffer to clipboard
map("n", "<leader>yp", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "Copy relative path" })

--- jumpt to previous buffer
map("n", "<leader><Tab>", "<C-^>", { desc = "Jump to previous buffer" })
