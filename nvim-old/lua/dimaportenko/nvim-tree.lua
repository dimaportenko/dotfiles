-- following options are the default
-- each of these are documented in `:help nvim-tree.OPTION_NAME`
local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  error "Cannot load nvim-tree"
  return
end

local function my_on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set('n', 'A', api.tree.expand_all, opts('Expand All'))
  vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
  vim.keymap.set('n', 'C', api.tree.change_root_to_node, opts('CD'))
  vim.keymap.set('n', 'P', function()
    local node = api.tree.get_node_under_cursor()
    print(node.absolute_path)
  end, opts('Print Node Path'))

  vim.keymap.set('n', 'l', api.node.open.edit, opts('Open'))
  vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts('Open'))

  -- keymap move cursor 10 lines - 10j 10k
  vim.keymap.set('n', 'S-j', ':execute "normal! 10j"<CR>', opts('Jump 10 lines down'))
  vim.keymap.set('n', 'S-k', ':execute "normal! 10k"<CR>', opts('Jump 10 lines up'))

  -- vim.keymap.set('n', 'h', api.node, opts('Close'))
  -- mappings = {
  --   custom_only = false,
  --   list = {
  --     { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
  --     { key = "h", cb = tree_cb "close_node" },
  --     { key = "v", cb = tree_cb "vsplit" },
  --   },
  -- },
end

nvim_tree.setup {
  disable_netrw = true,
  hijack_netrw = true,
  open_on_tab = false,
  hijack_cursor = false,

  diagnostics = {
    enable = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },

  update_focused_file = {
    enable = true,
    update_cwd = true,
    ignore_list = {},
  },

  git = {
    enable = true,
    ignore = false,
    timeout = 500,
  },

  renderer = {
    icons = {
      glyphs = {
        default = "",
        symlink = "",
        git = {
          unstaged = "",
          staged = "S",
          unmerged = "",
          renamed = "➜",
          deleted = "",
          untracked = "U",
          ignored = "◌",
        },
        folder = {
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
        },
      },
    },
  },

  view = {
    adaptive_size = true,
    width = 30,
    -- hide_root_folder = false,
    side = "left",
    number = false,
    relativenumber = false,
  },


  actions = {
    open_file = {
      quit_on_open = false,
    }
  },

  on_attach = my_on_attach,
}
