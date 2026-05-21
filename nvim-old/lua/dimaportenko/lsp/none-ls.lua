local status, none_ls = pcall(require, "none-ls")
if not status then
  return
end

none_ls.setup({
  debug = true,
  sources = {
    none_ls.builtins.formatting.eslint,
    none_ls.builtins.formatting.swiftformat,
    none_ls.builtins.formatting.gofumpt,
    none_ls.builtins.formatting.goimports_reviser,
    none_ls.builtins.formatting.clang_format,
  }
})
