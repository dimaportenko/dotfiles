-- require("rntools").setup()

local Terminal = require('toggleterm.terminal').Terminal
local opts = {noremap = true, silent = true}

-- React Native start --
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

local rnstart = Terminal:new(config)

function _RNSTART_TOGGLE()
  rnstart:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>r", "<cmd>lua _RNSTART_TOGGLE()<CR>", opts)
-- End React Native start --

-- Package scripts --
local telescope = require('telescope')
function _PACKAGE_SCRIPTS()
  telescope.extensions.packagescript.scripts()
end

-- vim.api.nvim_set_keymap("n", "<leader>p", "<cmd>lua _PACKAGE_SCRIPTS()<CR>", opts)
-- End Package scripts --

-- Lazygit
local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float",
})

function _LAZYGIT()
	lazygit:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua _LAZYGIT()<CR>", opts)
-- End Lazygit
