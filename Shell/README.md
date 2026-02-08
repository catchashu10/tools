# Shell Setup

Bash and Zsh configs with modern CLI tools and Starship prompt.

## Quick Reference

| Alias / Command | Action |
|-----------------|--------|
| `ls`, `ll`, `la`, `lt` | eza with icons, git status, tree view |
| `cat`, `catp` | bat with syntax highlighting (catp = plain for piping) |
| `fd` | fd-find (fast file search, respects .gitignore) |
| `rg` | ripgrep (fast content search) |
| `z foo` | zoxide — jump to most-visited directory matching "foo" |
| `zi foo` | zoxide — interactive selection with fzf |
| `Ctrl-R` | fzf fuzzy history search |
| `Ctrl-T` | fzf fuzzy file search (with bat preview) |
| `Alt-C` | fzf fuzzy cd into directory |
| `t` / `t name` | Attach to tmux session (or create it) |
| `tl` / `tk` / `td` | tmux list / kill / detach |
| `c` | clear |
| `r` | reload shell config |
| `e` | edit shell config |
| `mkcd dir` | mkdir + cd in one step |
| `extract file` | extract any archive format |

## File Locations

| File | Location | Purpose |
|------|----------|---------|
| **Bash config** | **`~/.bashrc`** | Symlink → repo `config/bashrc` |
| **Zsh config** | **`~/.zshrc`** | Symlink → repo `config/zshrc` |
| **Starship config** | **`~/.config/starship.toml`** | Symlink → repo `config/starship.toml` |
| Starship binary | `~/.local/bin/starship` | Cross-shell prompt |

## Repo Structure

```
~/Tools/Shell/
├── README.md                         # This file
├── install.sh                        # Run this on a new machine
└── config/
    ├── bashrc                        # Bash configuration
    ├── zshrc                         # Zsh configuration
    └── starship.toml                 # Starship prompt theme
```

After install, symlinks point FROM dotfile locations TO this repo:
```
~/.bashrc                → ~/Tools/Shell/config/bashrc
~/.zshrc                 → ~/Tools/Shell/config/zshrc
~/.config/starship.toml  → ~/Tools/Shell/config/starship.toml
```

## What's Included

### CLI Tools

| Tool | Command | Replaces | Purpose |
|------|---------|----------|---------|
| [bat](https://github.com/sharkdp/bat) | `batcat` / `bat` | `cat` | Syntax highlighting, line numbers |
| [eza](https://github.com/eza-community/eza) | `eza` | `ls` | Icons, git status, tree view |
| [fd](https://github.com/sharkdp/fd) | `fdfind` / `fd` | `find` | Fast, respects .gitignore |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `rg` | `grep` | Fast content search |
| [fzf](https://github.com/junegunn/fzf) | `fzf` | — | Fuzzy finder (Ctrl-R, Ctrl-T, Alt-C) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `z` / `zi` | `cd` | Learns frequent directories |
| [Starship](https://starship.rs/) | `starship` | PS1 | Cross-shell prompt with git info |

### Shell Config Highlights

| Feature | Details |
|---------|---------|
| History | 50K entries, shared across tmux panes, timestamped, deduped |
| Completion | Case-insensitive, arrow-key menu (zsh) |
| Terminal title | Auto-set to current command + directory |
| Safety aliases | `rm -I`, `mv -i`, `cp -i` |
| fzf + fd | File/directory search respects .gitignore, bat preview |
| NVM | Node version manager (lazy-loaded from `~/.nvm`) |
| PATH | `~/.local/bin` added automatically |

### Starship Prompt

Tokyo Night color scheme with modules:

| Module | Shows | Color |
|--------|-------|-------|
| Directory | Truncated path | Blue `#7aa2f7` |
| Git branch | Branch name with icon | Purple `#bb9af7` |
| Git status | +staged !modified ?untracked | Yellow `#e0af68` |
| Command duration | For commands >2s | Muted `#565f89` |
| Node.js | Version (in Node projects) | Green `#9ece6a` |
| Hostname | SSH sessions only | Cyan `#2ac3de` |
| Character | `❯` (green = ok, red = error) | Green/Red |

## Replicating on a New Machine

```bash
# 1. Clone the repo
git clone http://tools.ashukumar.com ~/Tools
# or: git clone https://github.com/catchashu10/tools.git ~/Tools

# 2. Run the installer
~/Tools/Shell/install.sh

# 3. Restart your shell
exec bash   # or: exec zsh

# 4. Install Node.js (optional)
nvm install --lts
```

The installer handles everything: zsh, CLI tools (bat, eza, fd, ripgrep, fzf, zoxide), starship, NVM, config symlinks, and PATH setup.
