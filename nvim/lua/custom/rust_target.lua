--- Switching the rust-analyzer target (e.g. macOS <-> iOS).
---
--- rust-analyzer analyses one target at a time, so the target decides which
--- `#[cfg(target_os = ...)]` branches are live code and which are greyed out.
---
--- rustaceanvim ships `:RustAnalyzer target <triple>`, but it does not work
--- with the default (function-form) `server.settings`, which is what we and
--- LazyVim use. `rustaceanvim.lsp.set_target_arch` stops the client, then in
--- the restart callback writes `cargo.target` into the *stopped* client's
--- settings table -- but `M.start` builds the new client from
--- `vim.deepcopy(config.server)`, so the new client gets a fresh copy and the
--- target is dropped. (It also writes that field from an async `rustc --print
--- target-list` callback that usually lands after the new client has already
--- started.) The mutation only survives when `server.settings` is a plain
--- table, since then every client shares one reference.
---
--- So we own the target instead: `M.settings` is installed as
--- `server.settings` (see `lua/plugins/rust.lua`) and stamps the current
--- target into the settings every time a client starts. Switching is then just
--- "record the target, restart the client", with no ordering to get wrong.
---
--- Only installed targets are offered for completion: rust-analyzer needs a
--- std for the target to analyse anything, so the full `rustc --print
--- target-list` would be noise.
local M = {}

--- Label for "no explicit target, let cargo use the host".
local HOST = "host"

--- Current target triple, or nil for the host default.
---@type string|nil
M.target = nil

local cache = nil

--- Installed targets, host entry first. Cached for the session; `:RustTarget!`
--- refreshes it after a `rustup target add`.
---@return string[]
function M.targets()
  if cache then
    return cache
  end
  local out = vim.fn.systemlist({ "rustup", "target", "list", "--installed" })
  if vim.v.shell_error ~= 0 then
    vim.notify("rustup target list failed: " .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return { HOST }
  end
  cache = { HOST }
  for _, line in ipairs(out) do
    local target = vim.trim(line)
    if target ~= "" then
      table.insert(cache, target)
    end
  end
  return cache
end

function M.invalidate()
  cache = nil
end

--- `server.settings` hook: rustaceanvim's default settings loader, plus our
--- target. `default_settings` is deep-copied per client start, so writing to
--- it here cannot leak into the next client -- which is exactly why setting
--- `cargo.target = nil` reliably clears a previously set target.
---@param project_root string|nil
---@param default_settings table|nil
---@return table
function M.settings(project_root, default_settings)
  local settings = require("rustaceanvim.config.server").load_rust_analyzer_settings(project_root, {
    default_settings = default_settings,
  })
  local ra = settings["rust-analyzer"]
  ra.cargo = ra.cargo or {}
  ra.cargo.target = M.target
  return settings
end

--- Stops rust-analyzer and starts it again through `rustaceanvim.lsp.start`,
--- which is the only path that re-evaluates `server.settings`.
---
--- `:RustAnalyzer restart` cannot be used: it delegates to Neovim's builtin
--- `:lsp restart` (see rustaceanvim's `ftplugin/rust.lua`), which rebuilds the
--- client from its stored resolved config. That skips rustaceanvim's `M.start`
--- entirely, so `M.settings` never runs and the new client comes back with the
--- previous target.
---@param bufnr number
local function restart(bufnr)
  local lsp = require("rustaceanvim.lsp")
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" })
  if #clients == 0 then
    lsp.start(bufnr)
    return
  end
  for _, client in ipairs(clients) do
    client:stop()
  end
  local timer = assert(vim.uv.new_timer())
  local attempts = 50
  timer:start(200, 100, function()
    local stopped = vim.iter(clients):all(function(client)
      return client:is_stopped()
    end)
    attempts = attempts - 1
    if not stopped and attempts > 0 then
      return
    end
    timer:stop()
    timer:close()
    vim.schedule(function()
      if not stopped then
        vim.notify("rust-analyzer did not stop; starting anyway", vim.log.levels.WARN)
      end
      lsp.start(bufnr)
    end)
  end)
end

--- Records the target and restarts rust-analyzer so it re-reads the settings.
---@param target string a triple, or "host" for the host default
function M.set(target)
  M.target = target ~= HOST and target or nil
  local label = M.target or "host default"
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" }) == 0 then
    vim.notify("rust-analyzer target: " .. label .. " (applies when it attaches)")
    return
  end
  restart(bufnr)
  vim.notify("rust-analyzer target: " .. label .. " (restarting)")
end

function M.pick()
  vim.ui.select(M.targets(), {
    prompt = "rust-analyzer target (current: " .. (M.target or HOST) .. ")",
    format_item = function(target)
      local current = (M.target or HOST) == target and " (current)" or ""
      return (target == HOST and "host default" or target) .. current
    end,
  }, function(choice)
    if choice then
      M.set(choice)
    end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("RustTarget", function(opts)
    if opts.bang then
      M.invalidate()
    end
    if opts.args == "" then
      M.pick()
    else
      M.set(opts.args)
    end
  end, {
    nargs = "?",
    bang = true,
    desc = "Set the rust-analyzer target (no arg: pick from a list; ! refreshes the cache)",
    complete = function(arg_lead)
      return vim.tbl_filter(function(target)
        return vim.startswith(target, arg_lead)
      end, M.targets())
    end,
  })
end

return M
