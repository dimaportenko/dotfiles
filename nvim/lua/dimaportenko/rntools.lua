-- require("rntools").setup()

local Terminal = require('toggleterm.terminal').Terminal

local config = {
  cmd = "yarn start",
  hidden = true,
	direction = "float",
	float_opts = {
		border = "curved",
		winblend = 0,
		highlights = {
			border = "Normal",
			background = "Normal",
		},
	},
  on_open = function()
    vim.cmd("stopinsert")
  end,
}

local opts = {noremap = true, silent = true}

local rnstart = Terminal:new(config)

function _RNSTART_TOGGLE()
  rnstart:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>r", "<cmd>lua _RNSTART_TOGGLE()<CR>", opts)

local telescope = require('telescope')
function _PACKAGE_SCRIPTS()
  telescope.extensions.packagescript.scripts()
end

vim.api.nvim_set_keymap("n", "<leader>p", "<cmd>lua _PACKAGE_SCRIPTS()<CR>", opts)
-- 

local node = Terminal:new(config)
function _NODE_TOGGLE_TEST()
	node:toggle()
end


local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float",
})

function _LAZYGIT()
	lazygit:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua _LAZYGIT()<CR>", opts)

