-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable autoformat for markdown files
vim.api.nvim_create_autocmd({ "FileType" }, {
  -- pattern = { "toml", "json", "css" },
  pattern = { "markdown" },
  callback = function()
    vim.b.autoformat = false
    vim.diagnostic.enable(false, { bufnr = 0 })
    vim.keymap.set("n", "<leader>m", "<cmd>MarkdownPreview<cr>", { buffer = true, desc = "Markdown Preview" })
  end,
})

-- Custom commands
vim.api.nvim_create_user_command("CopyRelativeBufferPath", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("CopyBufferPath", function()
  local path = vim.api.nvim_buf_get_name(0)
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("LspRestart", function(opts)
  local bufnr = opts.bang and nil or 0
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    vim.notify("No active LSP clients", vim.log.levels.WARN)
    return
  end
  local names = {}
  for _, c in ipairs(clients) do
    table.insert(names, c.name)
    vim.lsp.stop_client(c.id)
  end
  vim.defer_fn(function()
    vim.cmd.edit()
    vim.notify("Restarted LSP: " .. table.concat(names, ", "), vim.log.levels.INFO)
  end, 200)
end, { bang = true, desc = "Restart LSP clients (use ! for all buffers)" })
