local status, null_ls = pcall(require, "null-ls")
if not status then
  return
end

null_ls.setup({
  debug = true,
  sources = {
    null_ls.builtins.formatting.eslint,
    null_ls.builtins.formatting.swiftformat,
    null_ls.builtins.formatting.gofumpt,
    null_ls.builtins.formatting.goimports_reviser,
  }
})
