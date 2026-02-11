# Modern CLI Tools Guide

Your terminal just got a major upgrade. This guide covers each tool — what it does,
why it matters, and how to use it. Practice the examples as you go.

---

## Table of Contents

1. [bat — Better cat](#1-bat--better-cat)
2. [eza — Better ls](#2-eza--better-ls)
3. [fd — Better find](#3-fd--better-find)
4. [ripgrep (rg) — Better grep](#4-ripgrep-rg--better-grep)
5. [fzf — Fuzzy Finder](#5-fzf--fuzzy-finder)
6. [zoxide — Smarter cd](#6-zoxide--smarter-cd)
7. [delta — Better git diffs](#7-delta--better-git-diffs)
8. [bat-theme — Theme Switcher](#8-bat-theme--theme-switcher)
9. [How They Work Together](#9-how-they-work-together)
10. [Tmux Integration Tips](#10-tmux-integration-tips)

---

## 1. bat — Better cat

**What it replaces:** `cat`
**What it adds:** Syntax highlighting, line numbers, git diff markers

### Basic Usage

```bash
# View a file (syntax highlighted!)
bat ~/.bashrc

# The alias means 'cat' now uses bat
cat ~/.bashrc              # same as bat, thanks to alias

# Plain output (for piping to other commands)
catp ~/.bashrc | grep alias

# View multiple files
bat file1.txt file2.txt

# Show only specific lines
bat --line-range 10:20 ~/.bashrc

# Show all supported languages
bat --list-languages
```

### Key Concepts

- **Automatic paging**: Long files open in a scrollable viewer (like `less`)
- **Git integration**: Modified lines show `+` and `-` markers in the gutter
- **Your alias `catp`**: Use this when piping output — it strips colors/formatting
- **Man pages**: Your config uses bat to render man pages with syntax highlighting.
  Try: `man tmux`
- **Theme (`BAT_THEME`)**: Your syntax theme is stored in `~/.config/bat/env` and
  sourced by your shell. Both bat and delta share this single setting — change it
  once and both tools update. Use the `bat-theme` command to switch themes
  interactively (see [bat-theme section](#8-bat-theme--theme-switcher)).

### Practice

```bash
# 1. Compare these — notice the difference
catp ~/.bashrc             # plain, for piping
cat ~/.bashrc              # highlighted, for reading

# 2. Look at a config file with line numbers
bat -n ~/.tmux.conf.local

# 3. View a specific section
bat --line-range 30:50 ~/.bashrc
```

---

## 2. eza — Better ls

**What it replaces:** `ls`
**What it adds:** Icons, colors, git status, tree view

### Basic Usage

```bash
# Regular listing (with icons!)
ls

# Detailed listing with git status
ll

# Show hidden files
la

# Tree view (2 levels deep)
lt

# Tree view (3 levels deep)
ltt

# Sort by modification time (newest first)
ls --sort=modified

# Sort by size
ls -l --sort=size

# Show only directories
ls -D

# Show only files
ls -f
```

### Key Flags

| Flag | Meaning |
|------|---------|
| `-l` | Long format (permissions, size, dates) |
| `-a` | Show hidden files |
| `-T` | Tree view |
| `--git` | Show git status per file |
| `--icons` | Show file type icons (already in your alias) |
| `--sort=` | Sort by: name, size, modified, extension |
| `-r` | Reverse sort order |
| `--no-permissions` | Hide permission columns |

### Practice

```bash
# 1. Go to a git repo and see git status alongside files
cd ~/Projects/terminal-capture && ll

# 2. Tree view of a project
lt ~/Projects/terminal-capture

# 3. Find the biggest files
ls -l --sort=size --reverse ~

# 4. List only directories
ls -D ~
```

---

## 3. fd — Better find

**What it replaces:** `find`
**What it adds:** Simpler syntax, speed, respects .gitignore, regex by default

### Basic Usage

```bash
# Find files by name (partial match, case-insensitive by default)
fd bashrc ~

# Find by extension
fd -e md ~/Tools/Learn

# Find only directories
fd -t d projects ~

# Find only files
fd -t f config ~

# Find hidden files too (normally excluded)
fd -H .bashrc ~

# Find and delete (careful!)
fd -t f '\.tmp$' --exec rm {}

# Find with a depth limit
fd -d 2 -e sh ~/.local
```

### vs find — Side by Side

```bash
# OLD WAY with find:
find ~/Projects -name "*.md" -type f

# NEW WAY with fd:
fd -e md ~/Projects

# OLD WAY: find files modified in last hour
find . -mmin -60 -type f

# NEW WAY:
fd --changed-within 1h
```

### Key Flags

| Flag | Meaning |
|------|---------|
| `-e ext` | Filter by extension |
| `-t f` | Files only |
| `-t d` | Directories only |
| `-H` | Include hidden files |
| `-d N` | Max depth |
| `-x cmd` | Execute command on each result |
| `-E pattern` | Exclude pattern |
| `--changed-within` | Filter by modification time |

### Practice

```bash
# 1. Find all markdown files in your home directory
fd -e md ~

# 2. Find all shell scripts
fd -e sh ~

# 3. Find files changed today
fd --changed-within 1d ~

# 4. Find all directories named "config"
fd -t d config ~
```

---

## 4. ripgrep (rg) — Better grep

**What it replaces:** `grep`
**What it adds:** Speed, .gitignore awareness, recursive by default, better output

### Basic Usage

```bash
# Search for text in current directory (recursive by default!)
rg "alias" ~/.bashrc

# Search all files in a directory
rg "TODO" ~/Projects

# Case-insensitive search
rg -i "error" /var/log/syslog

# Search for a whole word only
rg -w "cat" ~/.bashrc

# Search specific file types
rg -t bash "alias"
rg -t md "tmux"

# Show N lines of context around matches
rg -C 3 "fzf" ~/.bashrc

# Count matches per file
rg -c "alias" ~/.bashrc

# List only filenames with matches
rg -l "tmux" ~

# Search with regex
rg "alias \w+=" ~/.bashrc
```

### vs grep — Side by Side

```bash
# OLD WAY:
grep -r "TODO" --include="*.py" ~/Projects

# NEW WAY:
rg -t py "TODO" ~/Projects

# OLD WAY:
grep -rn "function" . --color=auto

# NEW WAY:
rg "function" .
# (line numbers and color are on by default)
```

### Key Flags

| Flag | Meaning |
|------|---------|
| `-i` | Case insensitive |
| `-w` | Whole word match |
| `-l` | List filenames only |
| `-c` | Count matches per file |
| `-C N` | N lines of context |
| `-t type` | Filter by file type |
| `-g glob` | Filter by glob pattern |
| `--hidden` | Search hidden files too |
| `-v` | Invert match (lines NOT matching) |

### Practice

```bash
# 1. Find every alias in your shell configs
rg "^alias" ~/.bashrc ~/.zshrc

# 2. Search for tmux references in your home directory
rg "tmux" ~ --max-depth 2

# 3. Find all TODO/FIXME comments in a project
rg "TODO|FIXME" ~/Projects

# 4. Search for a function definition
rg "^[a-z_]+\(\)" ~/.bashrc
```

---

## 5. fzf — Fuzzy Finder

**What it is:** An interactive fuzzy search tool. Type a few characters and it
narrows down results in real-time. This is the most powerful tool in this list.

### Your Configuration

Your fzf runs in **full-screen mode** (`--height=100%`) with a clean, rounded
border and reverse layout (results appear top-down). These defaults are set via
`FZF_DEFAULT_OPTS` in your bashrc. The `Ctrl-T` shortcut includes a bat-powered
file preview — you see the file contents before selecting it.

### Keyboard Shortcuts (Already Configured)

These work anywhere in your terminal:

| Shortcut | What it does |
|----------|-------------|
| `Ctrl-R` | Fuzzy search command history |
| `Ctrl-T` | Fuzzy search files (with preview!) |
| `Alt-C` | Fuzzy cd into a directory |

**Try `Ctrl-R` right now** — start typing a command you ran before.

### Using fzf in Commands

```bash
# Open a file (fzf picks it)
nano $(fzf)

# cd to a directory
cd $(fd -t d | fzf)

# Kill a process interactively
kill -9 $(ps aux | fzf | awk '{print $2}')

# Git checkout a branch
git checkout $(git branch | fzf)

# View a file with bat, chosen by fzf
bat $(fzf)
```

### Using fzf with Pipes

```bash
# Pick a line from any command output
history | fzf

# Choose from git log
git log --oneline | fzf

# Select a tmux session to attach
tmux list-sessions | fzf | cut -d: -f1 | xargs tmux attach -t
```

### Searching Tricks

When the fzf prompt is open:
- Type normally for fuzzy matching: `brc` matches `.bashrc`
- Use `'` prefix for exact match: `'bashrc`
- Use `^` for prefix match: `^src`
- Use `$` for suffix match: `.md$`
- Use `!` to negate: `!test`
- Combine with spaces: `^src .js$ !test`

### Practice

```bash
# 1. Press Ctrl-R and type "git" — see all git commands you've run
# 2. Press Ctrl-T and type "bashrc" — find and insert the file path
# 3. Press Alt-C and type "learn" — cd into ~/Tools/Learn
# 4. Try: bat $(fzf)   — pick a file and view it
```

---

## 6. zoxide — Smarter cd

**What it replaces:** `cd`
**What it adds:** Learns your most-visited directories and jumps to them by keyword

### Basic Usage

```bash
# Jump to a directory by keyword (partial name works)
z learn               # jumps to ~/Tools/Learn
z projects            # jumps to ~/Projects
z capture             # jumps to ~/Projects/terminal-capture

# Interactive mode (uses fzf to pick)
zi                    # shows all known directories
zi tmux               # shows directories matching "tmux"

# Regular cd still works
cd ~/Learn

# See what zoxide has learned
zoxide query --list
```

### How It Works

1. Every time you `cd` into a directory, zoxide records it
2. It tracks how often and how recently you visit each directory
3. When you type `z foo`, it picks the best match based on frequency + recency
4. The more you use it, the smarter it gets

### Key Point

**zoxide needs to learn your directories first.** For the first day or two,
use `cd` normally. After that, `z` will know your favorite spots.

### Practice

```bash
# 1. Visit some directories to teach zoxide
cd ~/Learn
cd ~/Projects/terminal-capture
cd ~/.local/bin
cd ~

# 2. Now try jumping back
z learn               # should go to ~/Learn
z capture             # should go to ~/Projects/terminal-capture

# 3. Interactive mode
zi                    # pick from all known directories
```

---

## 7. delta — Better git diffs

**What it replaces:** The default `git diff` pager
**What it adds:** Syntax highlighting, side-by-side view, line numbers, hunk navigation

### How It Works

Delta is configured as your git pager — you don't call it directly. Every `git`
command that shows diffs (`diff`, `log -p`, `show`, `stash show -p`) automatically
uses delta for output.

**Config location:** `~/Tools/Shell/config/delta.gitconfig` (included from `~/.gitconfig`)

### Basic Usage

```bash
# See staged/unstaged changes — delta renders them automatically
git diff

# Side-by-side diff (already your default)
git diff

# View a specific commit
git show HEAD

# Log with patches
git log -p

# Diff two branches
git diff main..feature-branch
```

### Navigating Diffs

When viewing a diff, delta uses `less` as the pager. Key navigation:

| Key | Action |
|-----|--------|
| `n` | Jump to next file/hunk |
| `N` | Jump to previous file/hunk |
| `q` | Quit |
| `/text` | Search forward |
| `?text` | Search backward |
| `Space` | Page down |
| `b` | Page up |

The `n`/`N` navigation comes from the `navigate = true` setting — it makes delta
set special markers that `less` can jump between. This is extremely useful in large
diffs with many files.

### Your Settings

| Setting | Value | What it does |
|---------|-------|-------------|
| `side-by-side` | `true` | Old and new code shown left/right |
| `line-numbers` | `true` | Line numbers in the gutter |
| `navigate` | `true` | `n`/`N` jumps between hunks |
| Theme | `$BAT_THEME` | Shared with bat (change with `bat-theme`) |

### Overriding Defaults

You can temporarily change delta's behavior with flags:

```bash
# Disable side-by-side for a narrow terminal
git diff --no-ext-diff         # bypass delta entirely
git -c delta.side-by-side=false diff   # delta without side-by-side
```

### Theme

Delta uses the same `$BAT_THEME` environment variable as bat. Change the theme
once with `bat-theme` and both tools update together.

### Practice

```bash
# 1. Make a small change to any file, then view the diff
echo "# test" >> /tmp/test.txt && cd /tmp && git init && git add . && git commit -m "init"
echo "# change" >> test.txt
git diff                        # see delta in action

# 2. Try navigating — press n/N to jump between sections

# 3. View a real project's log
cd ~/Projects/terminal-capture
git log -p --follow -- capture  # see the history of a file

# 4. Clean up
rm -rf /tmp/test.txt /tmp/.git
```

---

## 8. bat-theme — Theme Switcher

**What it does:** Interactive fzf picker that lets you browse and set syntax
themes for both bat and delta at once.

### Usage

```bash
# Pick a theme — preview uses ~/.bashrc by default
bat-theme

# Pick a theme — preview uses a specific file
bat-theme somefile.py
bat-theme ~/.tmux.conf.local
```

### How It Works

1. Lists all bat themes and opens them in fzf
2. The right panel shows a live preview of your chosen file in each theme
3. When you pick one, it writes `export BAT_THEME="ThemeName"` to `~/.config/bat/env`
4. Run `r` (reload bashrc) to apply — both bat and delta pick up the change

### The Single-Source-of-Truth Concept

Instead of configuring themes separately for bat, delta, and any other tool,
your setup uses one file (`~/.config/bat/env`) as the single source:

```
~/.config/bat/env          ← stores: export BAT_THEME="theme-name"
    ↓ sourced by
~/.bashrc                  ← sets $BAT_THEME in your shell
    ↓ used by
bat                        ← syntax highlighting theme
delta                      ← git diff theme
bat-theme                  ← reads current theme, sets new one
```

Change it once, everything updates.

### Practice

```bash
# 1. Run bat-theme and browse themes (press Escape to cancel)
bat-theme

# 2. Pick a theme you like, then reload
r

# 3. Check that bat uses the new theme
cat ~/.bashrc

# 4. Check that delta uses it too
cd ~/Projects/terminal-capture && git log -1 -p
```

---

## 9. How They Work Together

These tools are designed to complement each other. Here are real workflows:

### "Find and read a file"
```bash
# fzf picks the file, bat displays it
bat $(fzf)
```

### "Find text in a project, then open the file"
```bash
# rg finds matches, fzf lets you pick, then open in editor
rg -l "pattern" | fzf | xargs nano
```

### "Find a file by name, see its contents"
```bash
# fd finds by name, fzf picks, bat shows
fd -e py | fzf --preview 'bat --color=always {}' | xargs nano
```

### "Jump to a project and explore it"
```bash
z myproject     # zoxide jumps there
lt              # eza shows tree view
ll              # eza shows detailed listing
```

### "Search history for a complex command"
```bash
# Press Ctrl-R, type a few characters from the command
# fzf shows matching history entries
# Press Enter to use it
```

---

## 10. Tmux Integration Tips

Your shell config is built to work inside tmux. Here's what to know:

### Prompt is the Same Everywhere (Locally)
Starship shows the same prompt inside and outside tmux. Hostname and username
only appear in **SSH sessions** (`ssh_only = true` in starship.toml), not based
on whether you're in tmux. When you SSH to your Pi, you'll see
`catchashu10@raspi` — otherwise it's just `directory (branch) ❯`.

### History Sharing Across Panes
Your history is written after every command (`history -a`), so if you run
a command in pane 1, you can press `Ctrl-R` in pane 2 and find it right away.

### Tmux Quick Commands

```bash
t               # attach to tmux or start a new session
t work          # attach to "work" session or create it
tl              # list all sessions
tk work         # kill the "work" session
td              # detach from current session
tp htop         # run htop in a floating popup
```

### Terminal Title
Your shell automatically sets the terminal title to show what command you're
running and which directory you're in. This helps tmux auto-name your windows.

### fzf Inside Tmux
fzf works beautifully inside tmux panes. The popup appears inline within your
pane, not as a new window. All keybindings (Ctrl-R, Ctrl-T, Alt-C) work normally.

---

## Quick Reference Card

| Tool | Replaces | Key Command | What It Does |
|------|----------|-------------|-------------|
| bat | cat | `cat file` | View file with syntax highlighting |
| eza | ls | `ls`, `ll`, `lt` | List files with icons and git status |
| fd | find | `fd pattern` | Find files fast |
| rg | grep | `rg pattern` | Search file contents fast |
| fzf | — | `Ctrl-R/T`, `Alt-C` | Fuzzy find anything |
| zoxide | cd | `z dirname` | Jump to directories by keyword |
| delta | git diff pager | `git diff` | Beautiful side-by-side diffs |
| bat-theme | — | `bat-theme` | Switch bat + delta themes with fzf |

---

## Your Aliases Cheat Sheet

```
LISTING
  ls     → eza with icons
  ll     → eza long format with git status
  la     → eza with hidden files
  lt     → eza tree (2 levels)
  ltt    → eza tree (3 levels)

VIEWING
  cat    → bat (syntax highlighted)
  catp   → bat plain (for piping)

SEARCHING
  fd     → fdfind

NAVIGATION
  ..     → cd ..
  ...    → cd ../..
  ....   → cd ../../..
  z      → zoxide (smart cd)
  zi     → zoxide interactive (with fzf)

SHELL
  c      → clear
  r      → reload shell config
  e      → edit shell config
  h      → last 30 history entries
  path   → show $PATH, one entry per line

TMUX
  t      → tmux attach/create
  tl     → tmux list sessions
  tk     → tmux kill session
  td     → tmux detach
  tp     → tmux floating popup

TOOLS
  bat-theme → interactive theme switcher (bat + delta)
  mkcd      → mkdir + cd in one command
  extract   → extract any archive (.tar.gz, .zip, .7z, etc.)
```
