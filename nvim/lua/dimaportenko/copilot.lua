local M = {}

M.config = {
  panel = {
    enabled = true,
    auto_refresh = false,
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      -- open = "<M-l>"
    },
  },
  suggestion = {
    enabled = true,
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
}


return M
