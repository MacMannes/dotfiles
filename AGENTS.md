# AGENTS.md

## Repository Structure

This is a macOS/Linux dotfiles repository using XDG Base Directory conventions.
Each application has its own subdirectory containing config files in their expected
locations.

### Key Paths

- `zsh/` - Shell configuration with modular `.zshrc.d/` structure
- `nvim/.config/nvim/` - LazyVim-based Neovim setup
- `aerospace/.config/aerospace/` - AeroSpace window manager (macOS)
- `hyprland/.config/hypr/` - Hyprland window manager (Linux)
- `hyprland-arch/` - Arch Linux-specific Hyprland overrides
- `waybar-arch/.config/waybar/` - Waybar status bar (Linux)
- `ghostty/.config/ghostty/` - Ghostty terminal emulator
- `git/.gitconfig` - Git configuration
- `lazygit/.config/lazygit/` - Lazygit configuration
- `scripts/` - Custom shell scripts (automatically added to PATH)
- `borders/.config/borders/` - Borders utility (macOS)
- `karabiner/.config/karabiner/` - Karabiner-Elements key remapping (macOS)
- `leaderkey/` - LeaderKey app config (macOS, uses `Library/Application Support/`)
- `starship/.config/starship.toml` - Starship prompt
- `yazi/.config/yazi/` - Yazi file manager
- `lazygit/.config/lazygit/` - Lazygit
- `ripgrep/.config/ripgrep/` - Ripgrep config
- `posting/.config/posting/` - Posting HTTP client
- `presenterm/.config/presenterm/` - Presenterm terminal slides
- `tock/.config/tock/` - Tock timer
- `orcaslicer/` - OrcaSlicer 3D printing config (uses `Library/Application Support/`)
- `personal/` - Personal/private configs (e.g. OrcaSlicer profiles)
- `pi/` - Pi coding agent config/sessions

## Shell Configuration (zsh/)

The zsh setup uses a modular approach:

- Main config: `zsh/.zshrc` (12 lines, sources files by OS and number prefix)
- Modules: `zsh/.zshrc.d/*.zsh` (numbered 00-90 for load order)
- OS-specific: `zsh/.zshrc.d/os/macos.zsh` and `linux.zsh`
- Custom overrides: `zsh/.zshrc.d/custom/` (e.g. `plugins` for local antidote plugin overrides)
- Shared aliases: `zsh/.aliases.sh`
- Plugin manager: Antidote (loads from `.zsh_plugins.txt`)

**Important**: Configuration files load in numbered order (00-90). Add new modules
following this pattern.

## Neovim (nvim/)

Uses LazyVim starter template with specific extras enabled:

- TypeScript/JavaScript development stack (`lang.typescript`, `lang.json`, `lang.yaml`, `lang.markdown`)
- Copilot + Copilot Chat
- DAP debugging, refactoring, testing core
- ESLint + Prettier formatting
- Additional: `editor.inc-rename`, `util.mini-hipatterns`

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

No central installation script at repo root. GNU Stow appears to be the intended linking mechanism (`.stow-local-ignore` present in some dirs like `leaderkey/`). Manual stow per-directory expected.

## Development Notes

- No CI/automation detected
- No build/test/lint tooling at repo root
- Git ignores: `.DS_Store`, Karabiner automatic backups, `/pi/.pi/agent/sessions/`, `/pi/.pi/agent/auth.json`
- Covers both macOS (AeroSpace, Karabiner, LeaderKey, Borders) and Linux (Hyprland, Waybar) environments

