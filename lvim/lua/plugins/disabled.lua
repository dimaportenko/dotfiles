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
}
