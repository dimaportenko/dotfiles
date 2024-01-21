require("mason").setup()

require 'lspconfig'.sourcekit.setup {
  cmd = { '/usr/bin/sourcekit-lsp' }
}
-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

local servers = {
  lua_ls = require "dimaportenko.lsp.settings.lua_ls".settings,
  rust_analyzer = require "dimaportenko.lsp.settings.rust_analyzer".settings,
  clangd = require "dimaportenko.lsp.settings.clangd".settings,
  -- gopls = require "dimaportenko.lsp.settings.gopls".settings,
  -- ruff_lsp = require "dimaportenko.lsp.settings.ruff".settings,
  -- pylsp = require "dimaportenko.lsp.settings.pylsp".settings,
  -- sourcekit = require "dimaportenko.lsp.settings.sourcekit".settings,
  -- ["sourcekit-lsp"] = require "dimaportenko.lsp.settings.sourcekit".settings,

}

mason_lspconfig.setup {
  ensure_installed = {
    "lua_ls",
    "rust_analyzer",
    "clangd",
    "gopls",
    -- "ruff_lsp",
    -- "pylsp",
    -- "sourcekit",
    -- "sourcekit-lsp",,
  }
}

require("dimaportenko.lsp.handlers").setup()
local on_attach = require("dimaportenko.lsp.handlers").on_attach
local capabilities = require("dimaportenko.lsp.handlers").capabilities

require 'lspconfig'.sourcekit.setup {
  cmd = { '/usr/bin/sourcekit-lsp' },
  capabilities = capabilities,
  on_attach = on_attach,
}

require 'dimaportenko.lsp.settings.gopls'

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
