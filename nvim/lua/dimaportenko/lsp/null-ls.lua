local status, null_ls = pcall(require, "null-ls")
if not status then
  return
end

null_ls.setup({
  debug = true,
  sources = {
    require("null-ls").builtins.formatting.eslint,
    require("null-ls").builtins.formatting.swiftformat,
  }
})

-- require("null-ls").setup({
--   debug = true,
--     sources = {
--         require("null-ls").builtins.formatting.eslint,
--         require("null-ls").builtins.formatting.prettier,
--         require("null-ls").builtins.diagnostics.eslint,
--         require("null-ls").builtins.diagnostics.tsc,
--         require("null-ls").builtins.completion.spell,
--     },
-- })
-- local null_ls_status_ok, null_ls = pcall(require, "null-ls")
-- if not null_ls_status_ok then
--   return
-- end
--
-- -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
-- local formatting = null_ls.builtins.formatting
-- -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
-- local diagnostics = null_ls.builtins.diagnostics
--
-- null_ls.setup {
--   debug = true,
--   sources = {
--     formatting.prettier.with { extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" } },
--     formatting.black.with { extra_args = { "--fast" } },
--     -- formatting.yapf,
--     formatting.stylua,
--     diagnostics.flake8,
--   },
-- }
