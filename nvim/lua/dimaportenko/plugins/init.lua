-- Copilot config
local copilot_config = require("dimaportenko/copilot").config;

return {
  -- My plugins here
  "nvim-lua/popup.nvim",          -- An implementation of the Popup API from vim in Neovim
  "nvim-lua/plenary.nvim",        -- Useful lua functions used ny lots of plugins
  "windwp/nvim-autopairs",        -- Autopairs, integrates with both cmp and treesitter
  "numToStr/Comment.nvim",        -- Easily comment stuff
  "kyazdani42/nvim-web-devicons", -- devicons for the tree explorer
  "kyazdani42/nvim-tree.lua",     -- tree explorer plugin
  "akinsho/bufferline.nvim",      -- buffers ui
  "moll/vim-bbye",                -- buffers ui dependencies
  "akinsho/toggleterm.nvim",      -- toggle terminal
  "hoob3rt/lualine.nvim",         -- statusline"

  -- Lazy loading:
  -- Load on specific commands
  { 'tpope/vim-dispatch', opt = true,       cmd = { 'Dispatch', 'Make', 'Focus', 'Start' } },

  -- Plugins can have post-install/update hooks
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  },

  -- colorscheme
  -- use 'folke/tokyonight.nvim'
  { "catppuccin/nvim",    as = "catppuccin" },

  -- cmp plugins
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      -- copilot
      'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip',
      {
        "zbirenbaum/copilot.lua",
        event = { "VimEnter" },
        config = function()
          vim.defer_fn(function()
            require("copilot").setup(copilot_config)
          end, 100)
        end,
      },
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end
      },

    }
  }, -- The completion plugin


  "hrsh7th/cmp-buffer",       -- buffer completions
  "hrsh7th/cmp-path",         -- path completions
  "hrsh7th/cmp-cmdline",      -- cmdline completions
  "saadparwaiz1/cmp_luasnip", -- snippet completions
  "hrsh7th/cmp-nvim-lsp",     -- lsp completion
  "hrsh7th/cmp-nvim-lua",     -- lua completion

  -- snippets
  "L3MON4D3/LuaSnip",             --snippet engine
  "rafamadriz/friendly-snippets", -- a bunch of snippets to use


  -- npm plugin
  {
    dir = '~/work/nvim/plugins/cmp-npm',
    config = true,
    dependencies = {
      'nvim-lua/plenary.nvim'
    }
  },

  -- LSP
  {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",

    -- Useful status updates for LSP
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {}, tag = 'legacy' },

    -- Additional lua configuration, makes nvim stuff amazing!
    'folke/neodev.nvim',
  },

  "jose-elias-alvarez/null-ls.nvim", -- for formatters and linters
  "MunifTanjim/prettier.nvim",       -- prettier

  -- Telescope
  "nvim-telescope/telescope.nvim", -- Fuzzy finder

  -- Run package json scripts
  -- { dir = "~/work/nvim/plugins/telescope-js-package-scripts.nvim", config = true },

  -- use "~/work/nvim/plugins/telescope-simulators.nvim"
  "dimaportenko/telescope-simulators.nvim",

  { dir = "~/work/nvim/plugins/project-cli-commands.nvim" },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  'nvim-treesitter/nvim-treesitter-context',

  "JoosepAlviste/nvim-ts-context-commentstring",

  -- Git
  "lewis6991/gitsigns.nvim",
  "tpope/vim-fugitive",

  -- use {
  --   "folke/which-key.nvim",
  --   config = function()
  --     require("which-key").setup {}
  --   end
  -- }

  -- Docs
  "nanotee/luv-vimdocs", -- lua docs in nvim help
  "milisims/nvim-luaref",


  {
    dir = "~/work/nvim/plugins/telescope-toggleterm.nvim",
    dependencies = {
      "akinsho/nvim-toggleterm.lua",
      "nvim-telescope/telescope.nvim",
      "nvim-lua/popup.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension "toggleterm"
    end,
  },

  -- debugging
  'mfussenegger/nvim-dap',
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap" }
  },

  -- rust tools
  'simrat39/rust-tools.nvim',

  -- Local plugins
  -- use "~/work/nvim/plugins/stackmap.nvim"
  -- use "~/work/nvim/plugins/rntools.nvim"

}
