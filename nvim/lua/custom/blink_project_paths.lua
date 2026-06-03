local M = {}

local cache = {}

local default_opts = {
  cache_ttl_ms = 30000,
  max_items = 5000,
  root_markers = { ".git", "package.json", "pyproject.toml", "Cargo.toml", "go.mod" },
  exclude = { ".git", "node_modules", ".next", "dist", "build", "target", ".venv" },
}

local function get_root(bufnr, opts)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local start = filename ~= "" and vim.fs.dirname(filename) or vim.uv.cwd()

  return vim.fs.root(start, opts.root_markers) or vim.uv.cwd()
end

local function get_mention(context)
  local line_to_cursor = context.line:sub(1, context.cursor[2])
  local start_col = line_to_cursor:match("()@[%w%._%-%/]*$")

  if not start_col then
    return nil
  end

  return {
    range = {
      start = { line = context.cursor[1] - 1, character = start_col - 1 },
      ["end"] = { line = context.cursor[1] - 1, character = context.cursor[2] },
    },
  }
end

local function command_for_scan(opts)
  if vim.fn.executable("fd") == 1 then
    local cmd = { "fd", ".", "--hidden", "--follow", "--type", "f", "--type", "d", "--max-results", tostring(opts.max_items) }

    for _, pattern in ipairs(opts.exclude) do
      vim.list_extend(cmd, { "--exclude", pattern })
    end

    return cmd
  end

  local cmd = { "find", "." }

  if #opts.exclude > 0 then
    table.insert(cmd, "(")
    for index, pattern in ipairs(opts.exclude) do
      if index > 1 then
        table.insert(cmd, "-o")
      end
      vim.list_extend(cmd, { "-name", pattern })
    end
    vim.list_extend(cmd, { ")", "-prune", "-o" })
  end

  vim.list_extend(cmd, { "(", "-type", "f", "-o", "-type", "d", ")", "-print" })

  return cmd
end

local function parse_entries(root, stdout, opts)
  local entries = {}

  for line in stdout:gmatch("[^\r\n]+") do
    local path = line:gsub("^%./", ""):gsub("/$", "")

    if path ~= "" and path ~= "." then
      local stat = vim.uv.fs_stat(root .. "/" .. path)

      if stat and (stat.type == "file" or stat.type == "directory") then
        entries[#entries + 1] = {
          path = path,
          is_dir = stat.type == "directory",
        }
      end
    end

    if #entries >= opts.max_items then
      break
    end
  end

  table.sort(entries, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end

    return a.path:lower() < b.path:lower()
  end)

  return entries
end

local function entries_to_items(entries, mention)
  local kinds = require("blink.cmp.types").CompletionItemKind
  local items = {}

  for _, entry in ipairs(entries) do
    local path = entry.is_dir and (entry.path .. "/") or entry.path
    local text = "@" .. path

    items[#items + 1] = {
      label = text,
      kind = entry.is_dir and kinds.Folder or kinds.File,
      filterText = text,
      sortText = (entry.is_dir and "1" or "2") .. entry.path:lower(),
      textEdit = {
        newText = text,
        range = mention.range,
      },
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      detail = entry.is_dir and "directory" or "file",
    }
  end

  return items
end

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  self.opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  return self
end

function M:enabled()
  return vim.tbl_contains({ "markdown", "mdx", "markdown.mdx" }, vim.bo.filetype)
end

function M:get_trigger_characters()
  return { "@" }
end

function M:get_completions(context, callback)
  local mention = get_mention(context)

  if not mention then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local root = get_root(context.bufnr, self.opts)
  local now = vim.uv.now()
  local cached = cache[root]

  if cached and (now - cached.timestamp) < self.opts.cache_ttl_ms then
    callback({
      items = entries_to_items(cached.entries, mention),
      is_incomplete_forward = false,
      is_incomplete_backward = false,
    })
    return
  end

  local cancelled = false

  vim.system(command_for_scan(self.opts), { cwd = root, text = true }, function(result)
    vim.schedule(function()
      if cancelled then
        return
      end

      local entries = {}
      if result.code == 0 then
        entries = parse_entries(root, result.stdout or "", self.opts)
        cache[root] = { entries = entries, timestamp = vim.uv.now() }
      end

      callback({
        items = entries_to_items(entries, mention),
        is_incomplete_forward = false,
        is_incomplete_backward = false,
      })
    end)
  end)

  return function()
    cancelled = true
  end
end

return M
