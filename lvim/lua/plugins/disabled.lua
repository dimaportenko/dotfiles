return {
  -- disable mini.indentscope
  {
    "snacks.nvim",
    opts = {
      indent = {
        enabled = true,
        scope = { enabled = false },
        animate = { enabled = false },
      },
    },
  },

  -- disable LSP inlay hints
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },

  -- disable ]c [c treesitter keymaps (conflict with gitsigns)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      textobjects = {
        move = {
          goto_next_start = { ["]c"] = false },
          goto_previous_start = { ["[c"] = false },
        },
      },
    },
  },
}
