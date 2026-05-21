# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Neovim Configuration Overview

This is a modular Neovim configuration written in Lua, using lazy.nvim as the plugin manager. The configuration follows a structured approach with clear separation of concerns.

## Directory Structure

```
nvim/
├── init.lua                 # Entry point - loads all modules
├── lazy-lock.json          # Plugin version lock file
└── lua/dimaportenko/       # Main configuration modules
    ├── lazy.lua            # Lazy.nvim bootstrap and setup
    ├── options.lua         # Neovim options
    ├── keymaps.lua         # Key mappings
    ├── colorscheme.lua     # Theme configuration (Catppuccin)
    ├── lsp/                # Language Server Protocol setup
    │   ├── init.lua        # LSP initialization with Mason
    │   ├── handlers.lua    # LSP handlers and capabilities
    │   ├── none-ls.lua     # Null-ls replacement for formatting/linting
    │   └── settings/       # Per-language LSP configurations
    ├── plugins/            # Individual plugin configurations
    │   └── init.lua        # Plugin list and specs
    └── [other modules]     # Feature-specific configurations
```

## Key Components

### Plugin Management
- **lazy.nvim** - Modern plugin manager with lazy loading support
- Plugins defined in `plugins/init.lua` with individual configs in `plugins/` directory
- Lock file (`lazy-lock.json`) ensures consistent versions

### Language Server Protocol (LSP)
- **Mason** - LSP installer and manager
- Currently configured servers: `lua_ls`, `rust_analyzer`, `clangd`, `gopls`, `denols`
- Migrating from null-ls to none-ls for formatting/linting

### Notable Features
- **Telescope** - Fuzzy finder with custom simulator picker
- **nvim-cmp** - Completion with Supermaven AI support
- **Treesitter** - Advanced syntax highlighting
- **Git integration** - Gitsigns and fugitive
- **Terminal** - Toggleterm for integrated terminal
- **File management** - nvim-tree and oil.nvim

## Common Commands

### Plugin Management
- `:Lazy` - Open lazy.nvim UI
- `:Lazy sync` - Update all plugins
- `:Lazy health` - Check plugin health

### LSP Commands
- `:Mason` - Open Mason UI to install/manage language servers
- `:LspInfo` - Show active LSP clients
- `:LspRestart` - Restart LSP servers

### Development
- `<leader>` is mapped to space
- Check `keymaps.lua` for all custom mappings

## Development Guidelines

1. **Module Organization**: Each feature should have its own module under `lua/dimaportenko/`
2. **Plugin Configuration**: Complex plugin configs go in separate files under `plugins/`
3. **LSP Settings**: Language-specific LSP settings go in `lsp/settings/`
4. **Lazy Loading**: Use lazy.nvim's features to defer plugin loading when possible

## Current TODOs
- [x] Add tag selection with mini.nvim (mini.ai)
- [ ] Migrate from null-ls to efm-langserver

## Testing Changes
After making configuration changes:
1. Restart Neovim or source the file: `:source %`
2. Check for errors: `:checkhealth`
3. For plugin changes: `:Lazy sync` then restart Neovim