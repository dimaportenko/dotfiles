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
              local ok, opencode = pcall(require, "opencode")
              if ok and opencode then
                opencode.prompt("@" .. path)
              else
                vim.notify("opencode not available", vim.log.levels.WARN)
              end
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
