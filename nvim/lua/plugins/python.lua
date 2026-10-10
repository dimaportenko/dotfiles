-- Python: pyright (types/completion) + ruff (lint/format), both from the LazyVim python extra.
-- pyright picks its root via the nearest pyproject.toml, so in gs-main each Django service
-- (django-backend/<service>/) is its own workspace. Point pyright at that service's uv `.venv`
-- so third-party imports (django, rest_framework, ...) resolve.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          before_init = function(_, config)
            local venv_python = (config.root_dir or vim.fn.getcwd()) .. "/.venv/bin/python"
            if vim.uv.fs_stat(venv_python) then
              config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
                pythonPath = venv_python,
              })
            end
          end,
          settings = {
            python = {
              analysis = {
                -- The repo enforces no type checker; "basic" keeps real errors, drops strict noise.
                typeCheckingMode = "basic",
                diagnosticSeverityOverrides = {
                  -- Django adds reverse relations/managers at runtime (e.g. User.membership), which
                  -- pyright can't see. Keep typos visible as warnings instead of false errors.
                  reportAttributeAccessIssue = "warning",
                },
              },
            },
          },
        },
      },
    },
  },
}
