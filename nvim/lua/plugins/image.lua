return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      doc = {
        -- render images inline in markdown/html/norg/tsx etc.
        inline = true,
        -- also show a floating preview when the cursor is on an image
        float = true,
        max_width = 80,
        max_height = 40,
      },
      convert = {
        notify = true,
      },
    },
  },
}
