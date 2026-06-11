# Tools

Centralized tracking of tool configurations, scripts, and settings. Each subfolder owns its tool-specific installer/uninstaller. Most tool configs are symlinked into place; machine-local shell rc files are copied from repo templates so they can drift per system.

## Purpose

- Track all configurations in one place
- Easily replicate setup on any new machine
- Document settings, shortcuts, and known issues
- Version control friendly: repo holds defaults and tool-owned configs, while machine-local shell rc files can drift outside the repo

## Tool Index

| Tool | Folder | Status | Description |
|------|--------|--------|-------------|
| [Shell](Shell/) | `<repo>/Shell/` | Configured | Bash/Zsh configs, CLI tools (bat, eza, fd, rg, fzf, zoxide), Starship prompt |
| [Nvim](Nvim/) | `<repo>/Nvim/` | Configured | LazyVim-based Neovim setup with flavor support |
| [Tmux](Tmux/) | `<repo>/Tmux/` | Configured | Terminal multiplexer with gpakosz framework, 15 themes, capture tools |
| [Learn](Learn/) | `<repo>/Learn/` | Maintained | In-depth learning guides for all tools |

## Structure

Each tool folder follows this pattern:

```
<repo>/<ToolName>/
├── README.md              # Full documentation
├── install.sh             # Tool-specific installer
├── uninstall.sh           # Tool-specific uninstaller
├── config/                # Config files, when a tool has one default flavor
├── <flavor>/              # Flavor-specific config, e.g. Nvim/lazyNvim
├── scripts/               # Scripts (the real files live here)
├── themes/                # Themes (if applicable)
└── ...
```

The top-level `install.sh`, `uninstall.sh`, and `health.sh` are thin orchestration scripts. Install/uninstall scripts run tool-level scripts in a safe order for setup/teardown, and can also target specific tools. `health.sh` is read-only and checks whether expected files, symlinks, commands, and generated folders look correct.

```bash
./install.sh              # install Shell, Nvim, Tmux; prompts before non-symlink changes
./install.sh --dry-run    # preview install actions without changing the system
./install.sh Nvim         # install only Nvim
./install.sh Shell Tmux   # install only Shell and Tmux
./install.sh --allow-all  # install without confirmation prompts

./uninstall.sh            # uninstall Tmux, Nvim, Shell; prompts before non-symlink changes
./uninstall.sh --dry-run  # preview uninstall actions without changing the system
./uninstall.sh Nvim       # uninstall only Nvim
./uninstall.sh --allow-all # uninstall without confirmation prompts

./health.sh               # check Repo, Shell, Nvim, Tmux
./health.sh Nvim          # check only Nvim
./health.sh Shell Tmux    # check selected tools
./health.sh --color=always # force colored output, useful when piped/logged
```

Shared installer utilities live in `setup/helpers.sh` (sourced by tool scripts). Scripts resolve paths relative to their own location, so the repo can be cloned under any folder name.

Install/uninstall safety model:

- Symlink-only changes, such as linking a repo config into `~/.config`, are allowed by default.
- Non-symlink system changes prompt by default. Examples: package installs, `apt update`, GitHub downloads, copying `~/.bashrc`/`~/.zshrc`, backing up existing files, editing `~/.gitconfig`, cloning/updating `~/.tmux`, creating runtime directories, or restoring backup files.
- Pass `--dry-run` to preview planned install/uninstall actions without changing files, installing packages, downloading tools, editing configs, or removing symlinks.
- Pass `--allow-all` when you intentionally want the installer/uninstaller to perform those non-symlink changes without stopping for confirmation.
- `--color=always`, `--color=never`, and `--no-color` are available on install, uninstall, and health scripts.

After running `install.sh`, machine-local shell rc files are copied from repo templates, while tool-owned configs/scripts are symlinked back to this repo:
```
~/.bashrc               copied from <repo>/Shell/config/bashrc
~/.zshrc                copied from <repo>/Shell/config/zshrc
~/.config/starship.toml → <repo>/Shell/config/starship.toml
~/.config/bat/env       → <repo>/Shell/config/bat-env
~/.config/nvim          → <repo>/Nvim/lazyNvim
~/.tmux.conf.local      → <repo>/Tmux/config/tmux.conf.local
~/.local/bin/bat-theme  → <repo>/Shell/scripts/bat-theme
~/.local/bin/tmux-theme → <repo>/Tmux/scripts/tmux-theme
~/.local/bin/capture    → <repo>/Tmux/scripts/capture
~/.local/bin/tmux-capture → <repo>/Tmux/scripts/tmux-capture
```

**Not symlinked:** `~/.gitconfig` stays per-machine (different user.name/email per host) and uses `[include]` to pull in `<repo>/Shell/config/delta.gitconfig`. `Shell/install.sh` writes the current absolute repo path into that include, so it works no matter where the repo was cloned.

`Shell/install.sh` backs up any existing `~/.bashrc`/`~/.zshrc` to timestamped `.bak.*` files before copying the repo templates. `Shell/uninstall.sh` leaves copied rc files in place; it only restores backups when removing an older owned symlink.

## Quick Setup on a New Machine

```bash
git clone https://github.com/catchashu10/tools.git <repo>
<repo>/install.sh
```

The scripts do not depend on the clone folder name.

The top-level `install.sh` runs all tool installers in order. Each tool can also be installed or uninstalled independently with its own `install.sh` or `uninstall.sh`. Run `health.sh` any time to safely inspect the expected setup without changing system state.
