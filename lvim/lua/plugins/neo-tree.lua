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
          copy_absolute_path = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path)
            vim.notify("Copied: " .. path)
          end,
          copy_relative_path = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            local rel = vim.fn.fnamemodify(path, ":.")
            vim.fn.setreg("+", rel)
            vim.notify("Copied: " .. rel)
          end,
        },
        window = {
          mappings = {
            ["oo"] = "opencode_add",
            ["yp"] = "copy_absolute_path",
            ["yr"] = "copy_relative_path",
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
