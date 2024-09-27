return {
  "supermaven-inc/supermaven-nvim",
  -- lazy = false,
  -- cmd = { "SuperMaven" },

  -- event = "InsertEnter",

  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        -- custom keymaps
        -- accept_suggestion = "<C-p>",
        accept_suggestion = "<C-CR>",

        -- default keymaps
        -- accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
      },
      color = {
        -- suggestion_color = "#99d1db", -- catpuccin sky
        suggestion_color = "#85c1dc", -- catpuccin sapphire
        cterm = 244,
      },
      -- disable_inline_completion = true,
      disable_keymaps = true,
    })
  end,
}
