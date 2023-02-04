local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end

require("dimaportenko.lsp.lsp-installer")
require("dimaportenko.lsp.handlers").setup()
require("dimaportenko.lsp.null-ls")

