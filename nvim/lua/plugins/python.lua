-- Python: pyright (types/completion) + ruff (lint/format), both from the LazyVim python extra.
-- pyright picks its root via the nearest pyproject.toml, so in gs-main each Django service
-- (django-backend/<service>/) is its own workspace. Point pyright at that service's uv `.venv`
-- so third-party imports (django, rest_framework, ...) resolve.
--
-- Type checker switch: `:PyChecker pyright|mypy|both` or <leader>cy to cycle; the choice persists.
-- pyright always stays attached for completion/navigation; in "mypy" mode only its type diagnostics
-- are turned off. mypy runs on read/save through nvim-lint with the django-stubs plugin, which knows
-- AUTH_USER_MODEL and other Django magic pyright can't see. Config: ~/.config/mypy/django.ini.
-- mypy runs via `uv run --with` in the service dir, so nothing is added to the repo or its .venv.

local MODES = { "pyright", "mypy", "both" }
local state_file = vim.fn.stdpath("state") .. "/python_type_checker"

local function read_mode()
  local ok, lines = pcall(vim.fn.readfile, state_file)
  local mode = ok and lines[1] or nil
  return vim.tbl_contains(MODES, mode) and mode or "pyright"
end

vim.g.python_type_checker = read_mode()

local function pyright_checks_on()
  return vim.g.python_type_checker ~= "mypy"
end

local function pyright_analysis()
  local on = pyright_checks_on()
  return {
    -- The repo enforces no type checker; "basic" keeps real errors, drops strict noise.
    typeCheckingMode = on and "basic" or "off",
    diagnosticSeverityOverrides = {
      -- Django adds reverse relations/managers at runtime (e.g. User.membership), which
      -- pyright can't see. Keep typos visible as warnings instead of false errors.
      reportAttributeAccessIssue = on and "warning" or "none",
    },
  }
end

-- Nearest Django service dir (has manage.py + .venv); mypy must run there so the plugin can import settings.
local function service_root(file)
  local manage = vim.fs.find("manage.py", { path = vim.fs.dirname(file), upward = true })[1]
  local root = manage and vim.fs.dirname(manage)
  return root and vim.uv.fs_stat(root .. "/.venv") and root or nil
end

local function run_mypy(buf)
  if vim.g.python_type_checker == "pyright" then
    return
  end
  local root = service_root(vim.api.nvim_buf_get_name(buf))
  if root then
    vim.api.nvim_buf_call(buf, function()
      require("lint").try_lint("mypy_django", { cwd = root })
    end)
  end
end

-- Defined at startup, not in the nvim-lint spec: nvim-lint lazy-loads on the first BufReadPost,
-- which would be too late to catch that same event.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("python_mypy_django", { clear = true }),
  pattern = "*.py",
  callback = function(ev)
    run_mypy(ev.buf)
  end,
})

local function set_mode(mode)
  vim.g.python_type_checker = mode
  pcall(vim.fn.writefile, { mode }, state_file)

  for _, client in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
    client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
      python = { analysis = pyright_analysis() },
    })
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  end

  if mode == "pyright" then
    vim.diagnostic.reset(require("lint").get_namespace("mypy_django"))
  else
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "python" then
        run_mypy(buf)
      end
    end
  end
  vim.notify("Python type checker: " .. mode)
end

vim.api.nvim_create_user_command("PyChecker", function(opts)
  set_mode(opts.args)
end, {
  nargs = 1,
  complete = function()
    return MODES
  end,
})

vim.keymap.set("n", "<leader>cy", function()
  local i = (vim.fn.index(MODES, vim.g.python_type_checker) + 1) % #MODES
  set_mode(MODES[i + 1])
end, { desc = "Cycle Python type checker (pyright/mypy/both)" })

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
            config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
              analysis = pyright_analysis(),
            })
          end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function()
      local lint = require("lint")
      lint.linters.mypy_django = vim.tbl_deep_extend("force", lint.linters.mypy, {
        cmd = "uv",
        -- nvim-lint replaces the whole environment when `env` is set, so start from the current one.
        -- DYLD_FALLBACK_LIBRARY_PATH lets WeasyPrint/python-magic find Homebrew's pango and libmagic,
        -- because the plugin imports every Django app.
        env = vim.tbl_extend("force", vim.fn.environ(), {
          DJANGO_SETTINGS_MODULE = "core.config.test",
          DYLD_FALLBACK_LIBRARY_PATH = "/opt/homebrew/lib",
        }),
      })
      -- django-stubs 6.1.x supports mypy < 2.5.
      lint.linters.mypy_django.args = vim.list_extend({
        "run",
        "--no-sync",
        "--with",
        "mypy<2.5",
        "mypy",
        "--config-file",
        vim.fn.expand("~/.config/mypy/django.ini"),
      }, lint.linters.mypy.args)
    end,
  },
}
