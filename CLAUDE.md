# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A dotfiles-style configuration repo that tracks shell and tmux configs, scripts, and themes. Real config files live here; dotfile locations (`~/.bashrc`, `~/.tmux.conf.local`, etc.) are symlinks pointing into this repo. Deleting this folder breaks all configs.

## Setup

```bash
# Full setup on a new machine
git clone http://tools.ashukumar.com ~/Tools && ~/Tools/install.sh

# Individual tool setup
~/Tools/Shell/install.sh    # CLI tools + shell configs
~/Tools/Tmux/install.sh     # Tmux + gpakosz framework + themes
```

No build system, test framework, or linter. All scripts are plain bash.

## Architecture

### Symlink Model

Installers create symlinks FROM standard dotfile paths TO this repo:
- `~/.bashrc` -> `Shell/config/bashrc`
- `~/.tmux.conf.local` -> `Tmux/config/tmux.conf.local`
- `~/.tmux/themes/` -> `Tmux/themes/` (directory symlink)
- Scripts in `*/scripts/` -> `~/.local/bin/`

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
- Each tool folder follows the pattern: `README.md`, `install.sh`, `config/`, `scripts/`, `themes/`
- `Learn/` contains reference guides (documentation only, no executable code)
