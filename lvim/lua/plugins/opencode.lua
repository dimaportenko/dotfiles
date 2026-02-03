return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Required for snacks provider (input, picker, terminal)
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      provider = {
        cmd = "opencode --port 0", -- --port flag required for nvim plugin communication
        snacks = {
          win = {
            width = 0.5, -- 50% of screen
          },
        },
      },
    }

    -- Required for opts.events.reload
    vim.o.autoread = true

    -- Keymaps
    vim.keymap.set({ "n", "x" }, "<leader>ao", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "Ask opencode" })

    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("opencode").select()
    end, { desc = "Execute opencode action…" })

    vim.keymap.set({ "n", "t" }, "<C-o>", function()
      require("opencode").toggle()
    end, { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "<leader>os", function()
      return require("opencode").operator("@this ")
    end, { expr = true, desc = "Add range to opencode" })

    vim.keymap.set("n", "goo", function()
      return require("opencode").operator("@this ") .. "_"
    end, { expr = true, desc = "Add line to opencode" })

    vim.keymap.set("n", "<S-C-u>", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "opencode half page up" })

    vim.keymap.set("n", "<S-C-d>", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "opencode half page down" })

    -- Remap increment/decrement since <C-a> and <C-x> are used by opencode
    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })

    -- Add file to opencode (similar to ClaudeCodeAdd)
    vim.keymap.set("n", "<leader>of", function()
      local file = vim.fn.expand("%:p")
      if file ~= "" then
        require("opencode").prompt("@" .. file)
      else
        vim.notify("No file in current buffer", vim.log.levels.WARN)
      end
    end, { desc = "Add file to opencode" })

    -- Add file from neo-tree (for use with neo-tree mappings)
    vim.api.nvim_create_user_command("OpencodeAdd", function(opts)
      local file = opts.args
      if file and file ~= "" then
        require("opencode").prompt("@" .. file)
      end
    end, { nargs = 1, complete = "file", desc = "Add file to opencode" })

    -- Add tree/directory to opencode
    vim.api.nvim_create_user_command("OpencodeTreeAdd", function(opts)
      local dir = opts.args
      if dir and dir ~= "" then
        require("opencode").prompt("@" .. dir)
      end
    end, { nargs = 1, complete = "dir", desc = "Add directory to opencode" })
  end,
}
