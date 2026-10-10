-- Snacks.picker.lsp_symbols(): the default layout gives the symbol list 40% of the screen
-- (half of an 80%-wide popup). Stack the preview under the list so the list gets the full 80%.
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        lsp_symbols = {
          layout = { preset = "vertical", layout = { width = 0.8 } },
        },
      },
    },
  },
}
