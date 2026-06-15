-- Swift / Apple-platform development for Ook Reader.
-- See ~/work/home/ook-reader/RESEARCH.md (Phase 0).
return {
  -- 1. sourcekit-lsp: Apple's LSP, ships with Xcode (/usr/bin/sourcekit-lsp).
  --    For .xcodeproj/.xcworkspace projects it reads buildServer.json, generated
  --    per-project by `xcode-build-server config -scheme <S> -workspace <W>`.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sourcekit = {
          -- Restrict to Swift so it doesn't fight clangd over c/cpp/objc.
          filetypes = { "swift" },
          capabilities = {
            workspace = {
              -- Required for sourcekit-lsp to pick up file changes reliably.
              didChangeWatchedFiles = { dynamicRegistration = true },
            },
          },
        },
      },
    },
  },

  -- 2. xcodebuild.nvim: build / run / test on simulators & devices,
  --    wraps the official `xcodebuild` + `xcrun simctl` tools.
  --    Also wires debugging here (nvim-dap + codelldb) so we don't clobber
  --    LazyVim's dap.core nvim-dap config — we only attach the Swift adapter.
  {
    "wojciech-kulik/xcodebuild.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
    },
    -- Lazy-load: only pull in xcodebuild (+ telescope/nui/dap) when actually
    -- doing Swift work — on a .swift buffer, an :Xcodebuild* command, or a
    -- keybinding below. Keeps it out of the startup path for every other file.
    ft = { "swift" },
    cmd = {
      "XcodebuildPicker", "XcodebuildBuild", "XcodebuildBuildRun", "XcodebuildTest",
      "XcodebuildSelectScheme", "XcodebuildSelectDevice", "XcodebuildSetup",
      "XcodebuildToggleLogs",
    },
    keys = {
      -- build / run / test
      { "<leader>X", "<cmd>XcodebuildPicker<cr>", desc = "Xcodebuild actions" },
      { "<leader>xb", "<cmd>XcodebuildBuild<cr>", desc = "Build project" },
      { "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", desc = "Build & run" },
      { "<leader>xt", "<cmd>XcodebuildTest<cr>", desc = "Run tests" },
      -- <leader>xl (Toggle logs) lives in lua/config/keymaps.lua (loads after this).
      { "<leader>xs", "<cmd>XcodebuildSelectScheme<cr>", desc = "Select scheme" },
      { "<leader>xc", "<cmd>XcodebuildSelectDevice<cr>", desc = "Select device" },
      -- debugging. Keys avoid LazyVim dap.core (<leader>dr/dt are taken). Once a
      -- session starts, LazyVim's <leader>dc/db/di/do step controls apply.
      { "<leader>dd", function() require("xcodebuild.integrations.dap").build_and_debug() end, desc = "Build & debug" },
      { "<leader>dn", function() require("xcodebuild.integrations.dap").debug_without_build() end, desc = "Debug (no build)" },
      { "<leader>dT", function() require("xcodebuild.integrations.dap").debug_tests() end, desc = "Debug tests" },
      { "<leader>dx", function() require("xcodebuild.integrations.dap").terminate_session() end, desc = "Terminate xcode debug session" },
    },
    config = function()
      require("xcodebuild").setup({})
      -- Xcode 16+ (we run 26.5) uses Apple's bundled lldb-dap — no codelldb.
      -- setup(true) = also load persisted breakpoints.
      require("xcodebuild.integrations.dap").setup(true)
    end,
  },

  -- Note: <leader>xt is freed from LazyVim's Todo (Trouble) in
  -- lua/plugins/todo-comments.lua so XcodebuildTest above can own it.

  -- 3. Swift syntax / treesitter.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "swift" } },
  },
}
