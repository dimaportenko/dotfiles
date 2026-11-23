-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.root_spec = { "cwd" }
vim.g.snacks_animate = false

vim.opt.wrap = true

-- Linux/Omarchy only: send yanks to the MacBook's clipboard via OSC 52 when
-- running over rex/SSH/tmux, or to Wayland locally. Uses /proc, so Linux only.
if vim.fn.has("linux") == 1 then
  require("config.remote_clipboard").setup()
end
