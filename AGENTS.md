# AGENTS.md

## Repository Structure

This is a macOS/Linux dotfiles repository using XDG Base Directory conventions.
Each application has its own subdirectory containing config files in their expected
locations.

### Key Paths

- `zsh/` - Shell configuration with modular `.zshrc.d/` structure
- `nvim/.config/nvim/` - LazyVim-based Neovim setup
- `aerospace/.config/aerospace/` - AeroSpace window manager
- `git/.gitconfig` - Git configuration

## Shell Configuration (zsh/)

The zsh setup uses a modular approach:

- Main config: `zsh/.zshrc` (12 lines, sources files by OS and number prefix)
- Modules: `zsh/.zshrc.d/*.zsh` (numbered 00-90 for load order)
- OS-specific: `zsh/.zshrc.d/os/macos.zsh` and `linux.zsh`
- Plugin manager: Antidote (loads from `.zsh_plugins.txt`)

**Important**: Configuration files load in numbered order (00-90). Add new modules
following this pattern.

## Neovim (nvim/)

Uses LazyVim starter template with specific extras enabled:

- TypeScript/JavaScript development stack
- Copilot + Copilot Chat
- DAP debugging, refactoring, testing core
- ESLint + Prettier formatting

Code style: Stylua formatting with 4-space indents, 120-column width.

**Key files**:

- `nvim/.config/nvim/lazyvim.json` - LazyVim extras configuration
- `nvim/.config/nvim/snippets/typescript/` - Custom TypeScript snippets
- `nvim/.config/nvim/stylua.toml` - Lua formatting rules

## Window Management

AeroSpace configuration includes:

- Auto-starts `borders` utility on startup
- 14 persistent workspaces: 1-9, 0, F, M, S, T
- Accordion padding: 48px
- Mouse follows focus between monitors

## Application Structure

Each application directory mirrors its install location:

- `.config/` subdirs → `~/.config/`
- `Library/Application Support/` → `~/Library/Application Support/`

No central installation or symlink script detected. Manual linking expected.

## Development Notes

- No CI/automation detected
- No build/test/lint tooling at repo root
- Git ignores: `.DS_Store`, Karabiner automatic backups
- Primary focus: macOS development environment (TypeScript, 3D printing configs present)

