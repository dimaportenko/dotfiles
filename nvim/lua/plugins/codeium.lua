return {
  {
    "Exafunction/codeium.nvim",
    opts = function(_, opts)
      opts.virtual_text = opts.virtual_text or {}
      opts.virtual_text.enabled = false
      return opts
    end,
    config = function(_, opts)
      local codeium = require("codeium")
      codeium.setup(opts)

      if codeium.s then
        codeium.s.enabled = false
      end
    end,
  },
}
