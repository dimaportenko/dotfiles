local on_attach = require("dimaportenko.lsp.handlers").on_attach
local capabilities = require("dimaportenko.lsp.handlers").capabilities

local lspconfig = require "lspconfig"
local util = require "lspconfig/util"

lspconfig.clangd.setup {
  on_attach = function(client, bufnr)
    client.server_capabilities.signatureHelpProvider = false
    on_attach(client, bufnr)
  end,
  capabilities = capabilities,
  -- cmd = {
  --   "gopls"
  -- },
  -- filetypes = {
  --   "go", "gomod", "gowork", "gotmpl"
  -- },
  -- root_dir = util.root_pattern("go.work", "go.mod", ".git"),
  -- settings = {
  --   gopls = {
  --     completeUnimported = true,
  --     usePlaceholders = true,
  --     analyses = {
  --       unusedparams = true,
  --     },
  --   },
  -- },
}

