--- Telescope picker over every Django URL pattern in the repo.
---
--- `parser.py` (next to this file) reads the urls.py files statically with
--- Python's `ast`, so no venv, Docker or `django.setup()` is needed. It
--- follows `include()`, expands DRF routers (list/detail plus `@action`s) and
--- traces each view to the class or function that defines it.
---
--- Results are cached per service for the session. Every parse records the
--- files it read; when the picker opens, a service whose files changed (by
--- mtime) is parsed again and the others come from the cache.
---
--- `<CR>` jumps to the view (or the `@action` method), `<C-u>` to the
--- `path()` / `router.register()` line, `<C-y>` yanks the URL path.
local M = {}

local PARSER = vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "parser.py")

---@class DjangoUrlEntry
---@field url string
---@field name string|nil
---@field view string
---@field file string|nil
---@field line integer|nil
---@field url_file string
---@field url_line integer
---@field tags string[]

---@class DjangoUrlService
---@field name string
---@field dir string
---@field entries DjangoUrlEntry[]
---@field files string[]
---@field errors string[]
---@field mtimes table<string, integer>

--- repo root -> { services = { [dir] = DjangoUrlService }, complete = boolean }
local cache = {}
local running = false

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and (stat.mtime.sec * 1e9 + stat.mtime.nsec) or -1
end

---@param service DjangoUrlService
local function is_stale(service)
  for path, recorded in pairs(service.mtimes) do
    if mtime(path) ~= recorded then
      return true
    end
  end
  return false
end

--- The buffer's file, or the cwd for scratch/terminal buffers.
local function start_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.bo.buftype == "" then
    return name
  end
  return vim.uv.cwd()
end

--- Run the parser for `dirs` (all services when nil) and merge the result into the cache.
---@param root string
---@param dirs string[]|nil
---@param done fun()
local function scan(root, dirs, done)
  local python = vim.fn.exepath("python3")
  if python == "" then
    vim.notify("django_urls: python3 not found on PATH", vim.log.levels.ERROR)
    return
  end
  local cmd = { python, "-I", PARSER, "--root", root }
  for _, dir in ipairs(dirs or {}) do
    vim.list_extend(cmd, { "--service", dir })
  end
  running = true
  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      running = false
      if obj.code ~= 0 then
        vim.notify("django_urls: parser failed\n" .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
      end
      local ok, result = pcall(vim.json.decode, obj.stdout, { luanil = { object = true, array = true } })
      if not ok then
        vim.notify("django_urls: bad parser output: " .. result, vim.log.levels.ERROR)
        return
      end
      local repo = cache[root] or { services = {}, complete = false }
      cache[root] = repo
      if not dirs then
        repo.services = {}
        repo.complete = true
      end
      local errors = {}
      for _, service in ipairs(result.services) do
        service.mtimes = {}
        for _, path in ipairs(service.files) do
          service.mtimes[path] = mtime(path)
        end
        repo.services[service.dir] = service
        for _, err in ipairs(service.errors) do
          table.insert(errors, service.name .. ": " .. err)
        end
      end
      if #errors > 0 then
        vim.notify("django_urls: skipped\n" .. table.concat(errors, "\n"), vim.log.levels.WARN)
      end
      done()
    end)
  end)
end

--- Fresh services for `scope`, rescanning only what changed. Calls `cb(services)`.
---@param scope "all"|"current"
---@param cb fun(services: DjangoUrlService[], root: string)
local function collect(scope, cb)
  if running then
    vim.notify("django_urls: still parsing, try again in a moment", vim.log.levels.INFO)
    return
  end
  local start = start_path()
  local root = vim.fs.root(start, ".git") or vim.uv.cwd()
  local repo = cache[root]

  if scope == "current" then
    local dir = vim.fs.root(start, "manage.py")
    if not dir then
      vim.notify("django_urls: no manage.py above " .. start, vim.log.levels.WARN)
      return
    end
    local service = repo and repo.services[dir]
    if service and not is_stale(service) then
      return cb({ service }, root)
    end
    return scan(root, { dir }, function()
      cb({ cache[root].services[dir] }, root)
    end)
  end

  local function all()
    local services = vim.tbl_values(cache[root].services)
    table.sort(services, function(a, b)
      return a.name < b.name
    end)
    cb(services, root)
  end
  if not repo or not repo.complete then
    return scan(root, nil, all)
  end
  local stale = {}
  for dir, service in pairs(repo.services) do
    if is_stale(service) then
      table.insert(stale, dir)
    end
  end
  if #stale == 0 then
    return all()
  end
  scan(root, stale, all)
end

local function open_at(file, line)
  vim.cmd.edit(vim.fn.fnameescape(file))
  pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
  vim.cmd("normal! zz")
end

---@param services DjangoUrlService[]
---@param opts { title: string, show_service: boolean }
local function picker(services, opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local results, widths = {}, { service = 0, url = 0, name = 0 }
  for _, service in ipairs(services) do
    for _, entry in ipairs(service.entries) do
      entry.service = service.name
      table.insert(results, entry)
      widths.service = math.max(widths.service, #service.name)
      widths.url = math.max(widths.url, #entry.url)
      widths.name = math.max(widths.name, #(entry.name or ""))
    end
  end
  if #results == 0 then
    vim.notify("django_urls: no URL patterns found", vim.log.levels.WARN)
    return
  end

  local items = {}
  if opts.show_service then
    table.insert(items, { width = widths.service })
  end
  vim.list_extend(items, {
    { width = math.min(widths.url, 70) },
    { width = math.min(widths.name, 40) },
    { remaining = true },
  })
  local displayer = entry_display.create({ separator = "  ", items = items })

  local function make_entry(e)
    local tags = #e.tags > 0 and ("[" .. table.concat(e.tags, ",") .. "]") or ""
    return {
      value = e,
      ordinal = table.concat({ e.service, e.url, e.name or "", e.view, tags }, " "),
      filename = e.file or e.url_file,
      lnum = e.line or e.url_line,
      display = function()
        local columns = {}
        if opts.show_service then
          table.insert(columns, { e.service, "TelescopeResultsComment" })
        end
        vim.list_extend(columns, {
          e.url,
          { e.name or "", "TelescopeResultsIdentifier" },
          { e.view .. (tags ~= "" and (" " .. tags) or ""), "TelescopeResultsFunction" },
        })
        return displayer(columns)
      end,
    }
  end

  pickers
    .new({}, {
      prompt_title = opts.title,
      finder = finders.new_table({ results = results, entry_maker = make_entry }),
      sorter = conf.generic_sorter({}),
      previewer = conf.grep_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        local function goto_url_line()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            open_at(selection.value.url_file, selection.value.url_line)
          end
        end
        local function yank_url()
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end
          vim.fn.setreg("+", selection.value.url)
          vim.fn.setreg('"', selection.value.url)
          vim.notify("Yanked " .. selection.value.url)
        end
        map({ "i", "n" }, "<C-u>", goto_url_line, { desc = "open urls.py line" })
        map({ "i", "n" }, "<C-y>", yank_url, { desc = "yank URL path" })
        return true
      end,
    })
    :find()
end

---@param opts? { scope?: "all"|"current" }
function M.pick(opts)
  local scope = (opts and opts.scope) or "all"
  collect(scope, function(services, root)
    local title = scope == "all" and ("Django URLs · " .. vim.fs.basename(root))
      or ("Django URLs · " .. services[1].name)
    picker(services, { title = title, show_service = scope == "all" })
  end)
end

--- Drop the cache so the next pick parses everything again.
function M.refresh()
  cache = {}
  vim.notify("django_urls: cache cleared")
end

function M.setup()
  vim.api.nvim_create_user_command("DjangoUrls", function(cmd)
    local arg = cmd.args ~= "" and cmd.args or "all"
    if arg == "refresh" then
      M.refresh()
      return M.pick({ scope = "all" })
    end
    M.pick({ scope = arg })
  end, {
    nargs = "?",
    complete = function()
      return { "all", "current", "refresh" }
    end,
    desc = "Search Django URL patterns",
  })
end

return M
