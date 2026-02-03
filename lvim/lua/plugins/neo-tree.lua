return {
  -- file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",

    opts = {
      filesystem = {
        filtered_items = {
          visible = true, -- Show hidden files by default
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        commands = {
          -- Add file/directory to opencode
          opencode_add = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            if path then
              require("opencode").prompt("@" .. path)
            end
          end,
        },
        window = {
          mappings = {
            ["oo"] = "opencode_add",
          },
        },
      },
      window = {
        mappings = {
          ["/"] = "noop",
        },
      },
    },
  },
}
