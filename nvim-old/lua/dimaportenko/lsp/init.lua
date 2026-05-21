-- Setup neodev before LSP config for proper Neovim Lua development
require("neodev").setup()

require("mason").setup()

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

local servers = {
  lua_ls = require "dimaportenko.lsp.settings.lua_ls".settings,
  rust_analyzer = require "dimaportenko.lsp.settings.rust_analyzer".settings,
  -- clangd = require "dimaportenko.lsp.settings.clangd".settings,
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
    -- "lua_ls",
    -- "denols",
    -- "ruff_lsp",
    -- "pylsp",
    -- "sourcekit",
    -- "sourcekit-lsp",,
  }
}

require("dimaportenko.lsp.handlers").setup()
local on_attach = require("dimaportenko.lsp.handlers").on_attach
local capabilities = require("dimaportenko.lsp.handlers").capabilities

-- require 'dimaportenko.lsp.settings.gopls'
-- require 'dimaportenko.lsp.settings.clangd'

-- mason_lspconfig.setup_handlers {
--   function(server_name)
--     require('lspconfig')[server_name].setup {
--       capabilities = capabilities,
--       on_attach = on_attach,
--       settings = servers[server_name],
--     }
--   end,
-- }

local lspconfig = require 'lspconfig'
-- deno
-- lspconfig.denols.setup {
--   capabilities = capabilities,
--   on_attach = on_attach,
--   root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
-- }

-- tsserver
lspconfig.ts_ls.setup {
  -- autostart = false,
  -- single_file_support = false,
  -- root_dir = lspconfig.util.root_pattern("package.json"),
  capabilities = capabilities,
  on_attach = on_attach,
}
