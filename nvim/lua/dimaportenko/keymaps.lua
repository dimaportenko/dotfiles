local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Do not yank when deleting
keymap("n", "x", '"_x', opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Split
keymap("n", "ss", ":split<Enter>", opts)
keymap("n", "sv", ":vsplit<Enter>", opts)

-- Insert --
-- Press jk fast to enter
-- keymap("i", "jj", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- Telescope
-- keymap("n", "<leader>f", "<cmd>Telescope find_files hidden=true<cr>", opts)
-- keymap("n", "<leader>f", "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false }))<cr>", opts)
-- keymap("n", "<leader>t", "<cmd>Telescope live_grep<cr>", opts)
-- keymap("n", "<leader>t", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", opts)
keymap("n", "<leader>b", "<cmd>Telescope buffers<cr>", opts)
-- keymap("n", "<leader>;", "<cmd>Telescope toggleterm<cr>", opts)
keymap("n", "<leader>[", "<cmd>Telescope resume<cr>", opts)
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
-- vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>co', require('telescope.builtin').commands, { desc = '[C][O]mmands' })

-- harpoon
vim.keymap.set('n', '<leader>sh', require("harpoon.ui").toggle_quick_menu, { desc = '[S]earch [H]arpoon' })
vim.keymap.set('n', '<leader>dh', require("harpoon.mark").add_file, { desc = 'ad[D] [H]arpoon' })

-- Nvimtree
keymap("n", "<leader>e", ":NvimTreeToggle<cr>", opts)

-- PlenaryTestFile
-- keymap('n', '<leader>t', '<Plug>PlenaryTestFile', opts)

-- Cloase buffer
keymap("n", "<leader>w", ":Bdelete<cr>", opts)

-- Close quick fix
keymap("n", "<leader>cl", ":ccl<cr>", opts)

-- Prettier
-- keymap("n", "<M-p>", ":Prettier<cr>", opts)
keymap("n", "<M-l>", ":Prettier<cr>", opts)
-- keymap("n", "<leader>l", ":Prettier<cr>", opts)
-- keymap("n", "<leader>cf", ":Format<cr>", opts)

keymap("n", "<leader>p", ":Telescope project_cli_commands open<cr>", opts)
keymap("n", "<leader>;", ":Telescope project_cli_commands running<cr>", opts)

-- switch case 
vim.api.nvim_set_keymap(
  'n', '<Leader>sc', '<cmd>lua require("dimaportenko.micro_plugins.switch_case").switch_case()<CR>',
  { noremap = true, silent = true }
)


-- Format based on the file type
local function is_filetype_in_list(file_type, filetypes)
  for _, ft in ipairs(filetypes) do
    if ft == file_type then
      return true
    end
  end
  return false
end

function _RUN_FORMAT_BY_FILETYPE()
  local file_type = vim.bo.filetype

  -- print("file_type - ", file_type)
  local filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
    "liquid",
  }

  if is_filetype_in_list(file_type, filetypes) then -- Add keymaps for Prettier files
    vim.cmd("Prettier")
  else -- Add keymaps for other files
    vim.cmd("Format")
  end
end

vim.api.nvim_set_keymap("n", "<leader>l", "<cmd>lua _RUN_FORMAT_BY_FILETYPE()<CR>", opts)

