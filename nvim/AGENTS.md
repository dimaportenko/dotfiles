# AGENTS.md

Guidelines for AI coding agents working with this LazyVim-based Neovim configuration.

## Repository Overview

This is a LazyVim-based Neovim configuration featuring:
- AI-assisted coding (Claude Code, OpenCode, Codeium)
- TypeScript/Python/C++ language support
- Catppuccin Mocha theme with transparent background
- Telescope, Neo-tree, and custom keybindings

## Project Structure

```
lua/
├── config/           # LazyVim config overrides
│   ├── lazy.lua      # Plugin manager bootstrap
│   ├── options.lua   # Global editor options (vim.opt, vim.g)
│   ├── keymaps.lua   # Custom key bindings
│   └── autocmds.lua  # Autocommands
├── plugins/          # Plugin specs (one file per plugin/feature)
└── custom/           # Custom Lua modules (non-plugin code)

lazyvim.json          # LazyVim extras configuration (NOT Lua)
stylua.toml           # Lua formatter configuration
```

## Commands

### Apply Configuration Changes
```vim
:source %             " Reload current file
:Lazy sync            " Update plugins and apply lazy-lock.json
```

### Plugin Management
```vim
:Lazy                 " Open plugin manager UI
:Lazy update          " Update all plugins
:Mason                " Manage LSP servers, formatters, linters
```

### Linting and Formatting
```bash
# Format Lua files with StyLua
stylua lua/

# Format a single file
stylua lua/plugins/telescope.lua

# Check formatting without modifying
stylua --check lua/
```

### Validation
```bash
# Check Lua syntax (from Neovim)
:luafile %

# Validate lazy.nvim specs
:Lazy health
```

## Code Style Guidelines

### Formatting (stylua.toml)
- **Indentation**: 2 spaces (NOT tabs)
- **Max line width**: 120 characters
- **Formatter**: StyLua

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Local variables | snake_case | `local toggle_hidden`, `local claude_state` |
| Functions | snake_case | `function is_buffer_valid()` |
| Module tables | Capital M | `local M = {}` |
| Plugin file names | kebab-case.lua | `neo-tree.lua`, `claude-toggle.lua` |
| Config file names | lowercase.lua | `keymaps.lua`, `options.lua` |

### Import Patterns
```lua
-- Module-level requires at top of file
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Inline requires for lazy-loaded or conditional code
require("telescope.builtin").find_files({...})
```

### Plugin Spec Patterns

**Pattern 1: Simple opts (preferred)**
```lua
return {
  "plugin/name",
  opts = { setting = value },
}
```

**Pattern 2: Multiple plugins**
```lua
return {
  { "plugin/one", opts = {...} },
  { "plugin/one", opts = {...} },
}
```

**Pattern 3: With config function**
```lua
return {
  "plugin/name",
  config = function()
    ---@type plugin.Opts
    vim.g.plugin_opts = {...}
    vim.keymap.set("n", "<leader>x", function() ... end)
  end,
}
```

**Pattern 4: Disabling features/keymaps**
```lua
return {
  { "plugin/name", opts = { feature = { enabled = false } } },
  { "plugin/keys", keys = { { "]c", false } } },  -- Disable keymap
}
```

**Pattern 5: Skip entire file**
```lua
-- stylua: ignore
if true then return {} end
```

### Custom Module Pattern
```lua
local M = {}

-- Private state
local state = { buf = nil, win = nil }

-- Private function
local function private_helper()
  -- implementation
end

-- Public function
function M.toggle(opts)
  -- implementation
end

function M.setup()
  vim.api.nvim_create_user_command("CommandName", function()
    M.toggle()
  end, {})
end

return M
```

### Keymap Definition Pattern
```lua
local map = vim.keymap.set

-- Function callback with description
map("n", "<leader>w", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })

-- Command string
map("n", "<leader>p", "<cmd>Telescope project_cli_commands open<cr>", { desc = "Open project tasks" })

-- Multiple modes
map({ "n", "x" }, "<leader>a", function() ... end, { desc = "Description" })
```

### Comment Styles
```lua
-- Single line explanation
---@param opts table  -- LuaDoc type annotation
---@type opencode.Opts
-- stylua: ignore  -- Disable formatting for next line
```

## Error Handling

```lua
-- Check buffer validity
if not buf or not vim.api.nvim_buf_is_valid(buf) then
  return false
end

-- Protected calls
local ok, result = pcall(vim.fn.jobwait, { chan }, 0)
if ok and result[1] == -1 then
  -- handle success
end

-- User notifications
vim.notify("Message", vim.log.levels.INFO)
vim.notify("Error message", vim.log.levels.ERROR)
```

## Important Conventions

1. **Plugin configs** go in `lua/plugins/` as separate files returning lazy.nvim spec tables
2. **Custom modules** (non-plugin) go in `lua/custom/`
3. **LazyVim extras** are enabled via `lazyvim.json`, NOT Lua imports
4. **Keep configs minimal** - leverage LazyVim defaults where possible
5. **Prefer `opts = {}`** over `config = function()` when possible
6. **Use `-- stylua: ignore`** to disable formatting for specific lines

## Enabled LazyVim Extras (lazyvim.json)

- **AI**: claudecode, codeium
- **Languages**: typescript, python, json, markdown, tailwind, toml, clangd, cmake
- **Tools**: prettier, eslint, telescope, neo-tree

## Testing Changes

1. Make changes to Lua files
2. Either restart Neovim or run `:source %` for the current file
3. Run `:Lazy sync` if plugin specs changed
4. Check `:messages` for errors
5. Run `:checkhealth` for diagnostics

## Files NOT to Modify

- `lazy-lock.json` - Auto-generated plugin lockfile
- `lazyvim.json` - Only modify via LazyVim extras UI (`:LazyExtras`)
- `.neoconf.json` - LSP configuration (auto-generated)
