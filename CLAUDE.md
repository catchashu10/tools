# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A dotfiles-style configuration repo that tracks shell, Neovim, tmux configs, scripts, and themes. Most real tool configs live here and standard config locations symlink back into this repo. Shell rc files (`~/.bashrc`, `~/.zshrc`) are copied from repo templates instead, so each machine can customize them without dirtying the repo.

## Setup

```bash
# Full setup on a new machine. The repo folder can be named anything.
git clone https://github.com/catchashu10/tools.git <repo> && <repo>/install.sh
# Preview first with <repo>/install.sh --dry-run.
# Use <repo>/install.sh --allow-all only when approved to skip confirmation prompts.

# Individual tool setup
<repo>/Shell/install.sh    # CLI tools + shell configs
<repo>/Nvim/install.sh     # LazyVim-based Neovim config
<repo>/Tmux/install.sh     # Tmux + gpakosz framework + themes

# Individual tool teardown
<repo>/Shell/uninstall.sh
<repo>/Nvim/uninstall.sh
<repo>/Tmux/uninstall.sh

# Health check, read-only
<repo>/health.sh             # Repo + Shell + Nvim + Tmux
<repo>/health.sh Nvim        # Only Nvim
<repo>/health.sh --color=always
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

All `install.sh` and `uninstall.sh` scripts source `setup/helpers.sh` which provides:
- shared UI helpers with section dividers, status icons, color controls, clear mode labels, and final grouped summaries
- `confirm_change message` - prompts before non-symlink system changes unless `--allow-all` is active; in `--dry-run` mode it reports the planned change and returns without modifying state
- `ensure_dir path reason` - creates directories only after confirmation when needed
- `symlink_config src dest` - creates/updates symlinks; prompts before backing up/replacing non-symlink destinations
- `install_pkg name` - prompts, then installs via apt or brew
- `install_github_binary owner/repo binary` - prompts, then downloads from GitHub releases as fallback

### Theme System (Tmux + Starship)

Theme files in `Tmux/themes/*.conf` define 17 colour variables. The `tmux-theme` script swaps colour blocks between `# THEME_START` and `# THEME_END` markers in `tmux.conf.local` and updates the `palette = "..."` line in `starship.toml` so the prompt matches. Adding a theme requires creating the `.conf` file, adding a `[palettes.<name>]` section in `starship.toml`, and adding a menu entry in `tmux.conf.local`.

Starship uses 7 semantic palette colors: `success`, `error`, `directory`, `git_branch`, `git_status`, `muted`, `accent`. All 15 themes have matching palettes in both tmux and starship.

## Conventions

- All text files use LF line endings (enforced via `.gitattributes` for WSL compatibility)
- Scripts must be `#!/usr/bin/env bash` with `set -e`
- Each tool folder follows the pattern: `README.md`, `install.sh`, `uninstall.sh`, `config/` or flavor folders like `lazyNvim/`, `scripts/`, `themes/`
- Top-level `install.sh` and `uninstall.sh` are orchestration wrappers and should call tool-specific scripts rather than duplicating tool logic; they must propagate `--dry-run`, `--allow-all`, and color options to child scripts. Top-level `install.sh --check` should run `health.sh` after install completes; selected tools map to selected health checks, while no selected tools runs all health checks.
- Install/uninstall scripts may perform symlink-only changes by default, but must prompt before non-symlink state changes such as package installs, downloads, file copies/backups, git clones/pulls, directory creation, backup restoration, or editing non-symlink config files. `--dry-run` must preview both symlink and non-symlink changes without modifying state.
- Top-level `health.sh` is read-only and should report setup issues without modifying files, installing packages, or running sync/update commands. It should also support `health.sh Backups` to list known timestamped installer backups without changing state.
- Scripts should resolve paths relative to their own location (`SCRIPT_DIR=...`) and must not hardcode the repo's top-level folder name
- `Learn/` contains reference guides (documentation only, no executable code)
