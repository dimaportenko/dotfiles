return {
  "zbirenbaum/copilot.lua",
  enabled = false,
  cmd = "Copilot",
  build = ":Copilot auth",
  opts = {
    panel = {
      enabled = false,
      auto_refresh = false,
      keymap = {
        jump_prev = "[[",
        jump_next = "]]",
        accept = "<CR>",
        refresh = "gr",
        -- open = "<C-CR>"
      },
    },
    suggestion = {
      enabled = false,
      auto_trigger = true,
      debounce = 75,
      keymap = {
        accept = "<M-CR>",
        next = "<M-Tab>",
        prev = "<M-S-Tab>",
        dismiss = "<C-]>",
      },
    },
    filetypes = {
      markdown = true,
    }
  },
}
