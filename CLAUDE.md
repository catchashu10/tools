# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A dotfiles-style configuration repo that tracks shell, Neovim, tmux configs, scripts, and themes. Most real tool configs live here and standard config locations symlink back into this repo. Shell rc files (`~/.bashrc`, `~/.zshrc`) are copied from repo templates instead, so each machine can customize them without dirtying the repo.

## Setup

```bash
# Full setup on a new machine. The repo folder can be named anything.
git clone https://github.com/catchashu10/tools.git <repo> && <repo>/install.sh

# Individual tool setup
<repo>/Shell/install.sh    # CLI tools + shell configs
<repo>/Nvim/install.sh     # LazyVim-based Neovim config
<repo>/Tmux/install.sh     # Tmux + gpakosz framework + themes

# Individual tool teardown
<repo>/Shell/uninstall.sh
<repo>/Nvim/uninstall.sh
<repo>/Tmux/uninstall.sh
```

No build system, test framework, or linter. All scripts are plain bash.

## Architecture

### Install Model

Installers copy machine-local shell rc files but symlink tool-owned config paths back to this repo:
- `~/.bashrc` copied from `Shell/config/bashrc`
- `~/.zshrc` copied from `Shell/config/zshrc`
- `~/.config/nvim` -> `Nvim/lazyNvim`
- `~/.tmux.conf.local` -> `Tmux/config/tmux.conf.local`
- `~/.tmux/themes/` -> `Tmux/themes/` (directory symlink)
- Scripts in `*/scripts/` -> `~/.local/bin/`

Shell rc files are copied because they drift per system. Tool uninstallers should leave regular copied rc files alone, and should only restore backups when removing older repo-owned symlinks.

Exception: `~/.gitconfig` is NOT symlinked (per-machine user.name/email). It uses `[include]` to pull in `Shell/config/delta.gitconfig`.

### Shared Helpers

All `install.sh` scripts source `setup/helpers.sh` which provides:
- `symlink_config src dest` - backs up existing file, creates symlink
- `install_pkg name` - installs via apt or brew
- `install_github_binary owner/repo binary` - downloads from GitHub releases as fallback
- `step` / `warn` - colored output helpers

### Theme System (Tmux + Starship)

Theme files in `Tmux/themes/*.conf` define 17 colour variables. The `tmux-theme` script swaps colour blocks between `# THEME_START` and `# THEME_END` markers in `tmux.conf.local` and updates the `palette = "..."` line in `starship.toml` so the prompt matches. Adding a theme requires creating the `.conf` file, adding a `[palettes.<name>]` section in `starship.toml`, and adding a menu entry in `tmux.conf.local`.

Starship uses 7 semantic palette colors: `success`, `error`, `directory`, `git_branch`, `git_status`, `muted`, `accent`. All 15 themes have matching palettes in both tmux and starship.

## Conventions

- All text files use LF line endings (enforced via `.gitattributes` for WSL compatibility)
- Scripts must be `#!/usr/bin/env bash` with `set -e`
- Each tool folder follows the pattern: `README.md`, `install.sh`, `uninstall.sh`, `config/` or flavor folders like `lazyNvim/`, `scripts/`, `themes/`
- Top-level `install.sh` and `uninstall.sh` are orchestration wrappers and should call tool-specific scripts rather than duplicating tool logic
- Scripts should resolve paths relative to their own location (`SCRIPT_DIR=...`) and must not hardcode the repo's top-level folder name
- `Learn/` contains reference guides (documentation only, no executable code)
