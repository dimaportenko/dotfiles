-- Live grep with raw ripgrep args typed in the prompt, e.g. `foo -g *.py` or `"foo bar" -t ts`.
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
      config = function()
        LazyVim.on_load("telescope.nvim", function()
          local telescope = require("telescope")
          local lga_actions = require("telescope-live-grep-args.actions")
          telescope.setup({
            extensions = {
              live_grep_args = {
                auto_quoting = true,
                mappings = {
                  i = {
                    -- <C-k> is taken by move_selection_previous in telescope.lua
                    ["<C-o>"] = lga_actions.quote_prompt(),
                    ["<C-y>"] = lga_actions.quote_prompt({ postfix = " -g " }),
                  },
                },
              },
            },
          })
          telescope.load_extension("live_grep_args")
        end)
      end,
    },
  },
}
