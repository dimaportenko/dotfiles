return {
	settings = {

		Lua = {
			diagnostics = {
				globals = { "vim", "it", "describe", "before_each" },
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.stdpath("config") .. "/lua"] = true,
				},
			},
		},
	},
}
