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
    config = function()
      require("xcodebuild").setup({})

      -- Debugging. Xcode 16+ (we run 26.5) uses Apple's bundled lldb-dap
      -- (/Applications/Xcode.app/.../usr/bin/lldb-dap) — no codelldb needed.
      -- setup(true) = also load persisted breakpoints.
      local dap = require("xcodebuild.integrations.dap")
      dap.setup(true)

      local map = vim.keymap.set
      -- build / run / test
      map("n", "<leader>X", "<cmd>XcodebuildPicker<cr>", { desc = "Xcodebuild actions" })
      map("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build project" })
      map("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & run" })
      map("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run tests" })
      map("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle logs" })
      map("n", "<leader>xs", "<cmd>XcodebuildSelectScheme<cr>", { desc = "Select scheme" })
      map("n", "<leader>xc", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select device" })
      -- debugging (codelldb via xcodebuild integration).
      -- Keys chosen to NOT collide with LazyVim dap.core (<leader>dr/dt are taken).
      -- Once a session starts, LazyVim's <leader>dc/db/di/do step controls apply.
      map("n", "<leader>dd", dap.build_and_debug, { desc = "Build & debug" })
      map("n", "<leader>dn", dap.debug_without_build, { desc = "Debug (no build)" })
      map("n", "<leader>dT", dap.debug_tests, { desc = "Debug tests" })
      map("n", "<leader>dx", dap.terminate_session, { desc = "Terminate xcode debug session" })
    end,
  },

  -- 3. Swift syntax / treesitter.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "swift" } },
  },
}
