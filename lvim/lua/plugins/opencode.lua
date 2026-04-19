return {
  "NickvanDyke/opencode.nvim",
  cmd = { "OpencodeAdd", "OpencodeTreeAdd" },
  keys = {
    { "<leader>ao", mode = { "n", "x" } },
    { "<C-x>", mode = { "n", "x" } },
    { "<leader>oa", mode = { "n" } },
    { "<leader>os", mode = { "n", "x" } },
    { "goo" },
    { "<S-C-u>" },
    { "<S-C-d>" },
    { "<leader>of" },
  },
  dependencies = {
    -- Required for snacks provider (input, picker, terminal)
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    local ok, opencode = pcall(require, "opencode")
    if not ok then
      vim.notify("opencode.nvim not available", vim.log.levels.WARN)
      return
    end

    local opencode_cmd = "opencode --port 0" -- --port flag required for nvim plugin communication
    local function half_screen_win_opts()
      return {
        split = "right",
        width = math.floor(vim.o.columns * 0.5),
      }
    end

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = function()
          require("opencode.terminal").start(opencode_cmd, half_screen_win_opts())
        end,
        stop = function()
          require("opencode.terminal").stop()
        end,
        toggle = function()
          require("opencode.terminal").toggle(opencode_cmd, half_screen_win_opts())
        end,
      },
    }

    -- Required for opts.events.reload
    vim.o.autoread = true

    -- Keymaps
    vim.keymap.set({ "n", "x" }, "<leader>ao", function()
      opencode.ask("@this: ", { submit = true })
    end, { desc = "Ask opencode" })

    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      opencode.select()
    end, { desc = "Execute opencode action…" })

    vim.keymap.set({ "n", "t" }, "<leader>oa", function()
      opencode.toggle()
    end, { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "<leader>os", function()
      return opencode.operator("@this ")
    end, { expr = true, desc = "Add range to opencode" })

    vim.keymap.set("n", "goo", function()
      return opencode.operator("@this ") .. "_"
    end, { expr = true, desc = "Add line to opencode" })

    vim.keymap.set("n", "<S-C-u>", function()
      opencode.command("session.half.page.up")
    end, { desc = "opencode half page up" })

    vim.keymap.set("n", "<S-C-d>", function()
      opencode.command("session.half.page.down")
    end, { desc = "opencode half page down" })

    -- Remap increment/decrement since <C-a> and <C-x> are used by opencode
    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })

    -- Add file to opencode (similar to ClaudeCodeAdd)
    vim.keymap.set("n", "<leader>of", function()
      local file = vim.fn.expand("%:p")
      if file ~= "" then
        opencode.prompt("@" .. file)
      else
        vim.notify("No file in current buffer", vim.log.levels.WARN)
      end
    end, { desc = "Add file to opencode" })

    -- Add file from neo-tree (for use with neo-tree mappings)
    vim.api.nvim_create_user_command("OpencodeAdd", function(opts)
      local file = opts.args
      if file and file ~= "" then
        opencode.prompt("@" .. file)
      end
    end, { nargs = 1, complete = "file", desc = "Add file to opencode" })

    -- Add tree/directory to opencode
    vim.api.nvim_create_user_command("OpencodeTreeAdd", function(opts)
      local dir = opts.args
      if dir and dir ~= "" then
        opencode.prompt("@" .. dir)
      end
    end, { nargs = 1, complete = "dir", desc = "Add directory to opencode" })
  end,
}
