local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- Copilot config
local copilot_config = require("dimaportenko/copilot").config;

-- Install your plugins here
return packer.startup(function(use)
  -- My plugins here
  use "wbthomason/packer.nvim" -- Have packer manage itself
  use "nvim-lua/popup.nvim" -- An implementation of the Popup API from vim in Neovim
  use "nvim-lua/plenary.nvim" -- Useful lua functions used ny lots of plugins
  use "windwp/nvim-autopairs" -- Autopairs, integrates with both cmp and treesitter
  use "numToStr/Comment.nvim" -- Easily comment stuff
  use "kyazdani42/nvim-web-devicons" -- devicons for the tree explorer
  use "kyazdani42/nvim-tree.lua" -- tree explorer plugin
  use "akinsho/bufferline.nvim" -- buffers ui
  use "moll/vim-bbye" -- buffers ui dependencies
  use "akinsho/toggleterm.nvim" -- toggle terminal
  use "hoob3rt/lualine.nvim" -- statusline"

  -- Lazy loading:
  -- Load on specific commands
  use { 'tpope/vim-dispatch', opt = true, cmd = { 'Dispatch', 'Make', 'Focus', 'Start' } }

  -- Plugins can have post-install/update hooks
  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  })

  -- colorscheme
  -- use 'folke/tokyonight.nvim'
  use { "catppuccin/nvim", as = "catppuccin" }

  -- cmp plugins
  use {
    "hrsh7th/nvim-cmp",
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' },
    requires = {
      -- copilot
      {
        "zbirenbaum/copilot.lua",
        event = { "VimEnter" },
        config = function()
          vim.defer_fn(function()
            require("copilot").setup(copilot_config)
          end, 100)
        end,
      },
    }
  } -- The completion plugin

  use {
    "zbirenbaum/copilot-cmp",
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end
  }

  use "hrsh7th/cmp-buffer" -- buffer completions
  use "hrsh7th/cmp-path" -- path completions
  use "hrsh7th/cmp-cmdline" -- cmdline completions
  use "saadparwaiz1/cmp_luasnip" -- snippet completions
  use "hrsh7th/cmp-nvim-lsp" -- lsp completion
  use "hrsh7th/cmp-nvim-lua" -- lua completion

  -- snippets
  use "L3MON4D3/LuaSnip" --snippet engine
  use "rafamadriz/friendly-snippets" -- a bunch of snippets to use


  -- npm plugin
  use {
    '~/work/nvim/plugins/cmp-npm',
    requires = {
      'nvim-lua/plenary.nvim'
    }
  }

  -- LSP
  use {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",

    -- Useful status updates for LSP
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {} },

    -- Additional lua configuration, makes nvim stuff amazing!
    'folke/neodev.nvim',
  }

  use "jose-elias-alvarez/null-ls.nvim" -- for formatters and linters
  use "MunifTanjim/prettier.nvim" -- prettier

  -- Telescope
  use "nvim-telescope/telescope.nvim" -- Fuzzy finder

  -- Run package json scripts
  use "~/work/nvim/plugins/telescope-js-package-scripts.nvim"

  -- use "~/work/nvim/plugins/telescope-simulators.nvim"
  use "dimaportenko/telescope-simulators.nvim"

  use "~/work/nvim/plugins/project-cli-commands.nvim"

  -- Treesitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  }
  use "JoosepAlviste/nvim-ts-context-commentstring"

  -- Git
  use "lewis6991/gitsigns.nvim"
  use "f-person/git-blame.nvim"
  use "tpope/vim-fugitive"

  -- use {
  --   "folke/which-key.nvim",
  --   config = function()
  --     require("which-key").setup {}
  --   end
  -- }

  -- Docs
  use "nanotee/luv-vimdocs" -- lua docs in nvim help
  use "milisims/nvim-luaref"


  use {
    "~/work/nvim/plugins/telescope-toggleterm.nvim",
    event = "TermOpen",
    requires = {
      "akinsho/nvim-toggleterm.lua",
      "nvim-telescope/telescope.nvim",
      "nvim-lua/popup.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension "toggleterm"
    end,
  }

  -- debugging
  use 'mfussenegger/nvim-dap'
  use { "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap" } }

  -- rust tools
  use 'simrat39/rust-tools.nvim'

  -- Local plugins
  -- use "~/work/nvim/plugins/stackmap.nvim"
  -- use "~/work/nvim/plugins/rntools.nvim"

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
