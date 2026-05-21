# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim-based Neovim configuration with AI-assisted coding (Claude Code + Copilot), TypeScript/Python language support, and a Catppuccin theme.

## Architecture

```
lua/
├── config/           # LazyVim overrides (options, keymaps, autocmds)
│   ├── lazy.lua      # Plugin manager bootstrap and settings
│   ├── options.lua   # Global editor options
│   ├── keymaps.lua   # Custom key bindings
│   └── autocmds.lua  # Autocommands (e.g., autoformat disabling)
├── plugins/          # Plugin specs (each file = one plugin config)
└── custom/           # Custom Lua modules (non-plugin code)
```

**Key conventions:**
- Plugin configs go in `lua/plugins/` as separate files
- Each plugin file exports a lazy.nvim spec table
- LazyVim extras are enabled via `lazyvim.json` (not Lua code)
- LSP/language support uses LazyVim extras (`lang.typescript`, `lang.python`, etc.)

## Commands

**Apply config changes:**
- Restart Neovim, or `:source %` for the current file
- `:Lazy sync` - Update plugins and apply lazy-lock.json

**Plugin management:**
- `:Lazy` - Open plugin manager UI
- `:Lazy update` - Update all plugins
- `:Mason` - Manage LSP servers, formatters, linters

**Claude Code integration:**
- `:ClaudeCode` or `<C-O>` - Toggle Claude terminal (right panel, 40% width)

## Enabled LazyVim Extras

From `lazyvim.json`:
- **AI**: `ai.claudecode`, `ai.copilot`
- **Languages**: `lang.typescript`, `lang.python`, `lang.json`, `lang.markdown`, `lang.tailwind`, `lang.toml`
- **Tools**: `formatting.prettier`, `linting.eslint`, `editor.telescope`, `editor.neo-tree`

## Key Customizations

**Completion** (`lua/plugins/blink.lua`): Uses blink.cmp with super-tab preset and Copilot integration

**Theme** (`lua/plugins/colorscheme.lua`): Catppuccin Mocha with transparent background

**Autoformat disabled** (`lua/config/autocmds.lua`): For `toml`, `json`, `css` files

**Custom keymaps** (`lua/config/keymaps.lua`):
- `<leader>w` - Delete buffer
- `<leader>p` - Project tasks (Telescope)
- `<A-z>` / `<C-x>` - Exit terminal mode

**Telescope** (`lua/plugins/telescope.lua`): Heavy customization with `<C-g>` to toggle hidden/ignored files

## Code Style

- Use StyLua for formatting (configured in `stylua.toml`)
- Follow existing patterns: return lazy.nvim spec tables from plugin files
- Keep plugin configs minimal; leverage LazyVim defaults where possible
