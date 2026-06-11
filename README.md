# Tools

Centralized tracking of all tool configurations, scripts, and settings. Each subfolder contains the actual config files, and an installer that symlinks them into place.

## Purpose

- Track all configurations in one place
- Easily replicate setup on any new machine
- Document settings, shortcuts, and known issues
- Version control friendly (repo holds real files, dotfile locations are symlinks)

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
├── install.sh             # Installer (creates symlinks)
├── config/                # Config files, when a tool has one default flavor
├── <flavor>/              # Flavor-specific config, e.g. Nvim/lazyNvim
├── scripts/               # Scripts (the real files live here)
├── themes/                # Themes (if applicable)
└── ...
```

Shared installer utilities live in `setup/helpers.sh` (sourced by all install scripts).

After running `install.sh`, symlinks point **from** dotfile locations **to** this repo:
```
~/.bashrc               → <repo>/Shell/config/bashrc
~/.zshrc                → <repo>/Shell/config/zshrc
~/.config/starship.toml → <repo>/Shell/config/starship.toml
~/.config/bat/env       → <repo>/Shell/config/bat-env
~/.config/nvim          → <repo>/Nvim/lazyNvim
~/.tmux.conf.local      → <repo>/Tmux/config/tmux.conf.local
~/.local/bin/bat-theme  → <repo>/Shell/scripts/bat-theme
~/.local/bin/tmux-theme → <repo>/Tmux/scripts/tmux-theme
~/.local/bin/capture    → <repo>/Tmux/scripts/capture
~/.local/bin/tmux-capture → <repo>/Tmux/scripts/tmux-capture
```

**Not symlinked:** `~/.gitconfig` stays per-machine (different user.name/email per host) and uses `[include]` to pull in `~/Tools/Shell/config/delta.gitconfig`.

Edit the files anywhere — the symlink ensures both paths reference the same file.

## Quick Setup on a New Machine

```bash
git clone http://tools.ashukumar.com ~/Tools
~/Tools/install.sh
```

The top-level `install.sh` runs all tool installers in order. Each tool's README also has a standalone "Replicating on a New Machine" section.
