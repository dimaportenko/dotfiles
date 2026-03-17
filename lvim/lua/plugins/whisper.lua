return {
  "Avi-D-coder/whisper.nvim",
  opts = {
    model = "large-v3",
    keybind = "<C-g>",
    manual_trigger_key = "<Space>",
    step_ms = 5000,
    length_ms = 8000,
  },
  config = function(_, opts)
    require("whisper").setup(opts)
  end,
}
