require("mason").setup()

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

local servers = {
  lua_ls = require "dimaportenko.lsp.settings.lua_ls".settings,
  rust_analyzer = require "dimaportenko.lsp.settings.rust_analyzer".settings,
  clangd = require "dimaportenko.lsp.settings.clangd".settings,
}

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

require("dimaportenko.lsp.handlers").setup()
local on_attach = require("dimaportenko.lsp.handlers").on_attach
local capabilities = require("dimaportenko.lsp.handlers").capabilities

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
    }
  end,
}
require("dimaportenko.lsp.null-ls")
