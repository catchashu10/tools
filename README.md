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
| [Shell](Shell/) | `~/Tools/Shell/` | Configured | Bash/Zsh configs, CLI tools (bat, eza, fd, rg, fzf, zoxide), Starship prompt |
| [Tmux](Tmux/) | `~/Tools/Tmux/` | Configured | Terminal multiplexer with gpakosz framework, 15 themes, capture tools |
| [Learn](Learn/) | `~/Tools/Learn/` | Maintained | In-depth learning guides for all tools |

## Structure

Each tool folder follows this pattern:

```
~/Tools/<ToolName>/
├── README.md              # Full documentation
├── install.sh             # Installer (creates symlinks)
├── config/                # Config files (the real files live here)
├── scripts/               # Scripts (the real files live here)
├── themes/                # Themes (if applicable)
└── ...
```

After running `install.sh`, symlinks point **from** dotfile locations **to** this repo:
```
~/.bashrc               → ~/Tools/Shell/config/bashrc
~/.zshrc                → ~/Tools/Shell/config/zshrc
~/.config/starship.toml → ~/Tools/Shell/config/starship.toml
~/.tmux.conf.local      → ~/Tools/Tmux/config/tmux.conf.local
~/.local/bin/tmux-theme → ~/Tools/Tmux/scripts/tmux-theme
```
Edit the files anywhere — the symlink ensures both paths reference the same file.

## Quick Setup on a New Machine

```bash
git clone http://tools.ashukumar.com ~/Tools
~/Tools/install.sh
```

The top-level `install.sh` runs all tool installers in order. Each tool's README also has a standalone "Replicating on a New Machine" section.
