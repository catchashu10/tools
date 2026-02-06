# Tools

Centralized tracking of all tool configurations, scripts, and settings. Each subfolder contains symlinks to actual config files and a README documenting the setup.

## Purpose

- Track all configurations in one place
- Easily replicate setup on any new machine
- Document settings, shortcuts, and known issues
- Version control friendly (symlinks point to actual files)

## Tool Index

| Tool | Folder | Status | Description |
|------|--------|--------|-------------|
| [Tmux](Tmux/) | `~/Tools/Tmux/` | Configured | Terminal multiplexer with gpakosz framework, 5 themes, capture tools |

## Structure

Each tool folder follows this pattern:

```
~/Tools/<ToolName>/
├── README.md              # Full documentation
├── config.*               # Symlink(s) to config files
├── scripts-*              # Symlink(s) to scripts
├── themes/                # Symlink to themes (if applicable)
└── ...                    # Other relevant symlinks
```

Symlinks point to the **actual file locations** (e.g., `~/.config/`, `~/.local/bin/`), so editing either the symlink or the original updates the same file.

## Quick Setup on a New Machine

Each tool's README has a "Replicating on a New Machine" section with copy-paste commands.
