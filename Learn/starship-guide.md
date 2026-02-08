# Starship Prompt Guide

A fast, customizable prompt for any shell. Starship replaces the default bash/zsh
prompt with a single config file that works everywhere.

---

## Table of Contents

1. [What is Starship?](#1-what-is-starship)
2. [Your Config File](#2-your-config-file)
3. [How Modules Work](#3-how-modules-work)
4. [Your Active Modules](#4-your-active-modules)
5. [Customizing Colors and Symbols](#5-customizing-colors-and-symbols)
6. [Common Modules Reference](#6-common-modules-reference)
7. [Practice Exercises](#7-practice-exercises)

---

## 1. What is Starship?

**What it replaces:** The custom `PS1`/`PROMPT` logic in your `.bashrc` and `.zshrc`
**What it adds:** Git info, language versions, command duration, SSH detection — all in one prompt

### Why use it?

- **One config, every shell**: Same prompt in bash, zsh, fish, etc.
- **Fast**: Written in Rust — git status shows up instantly
- **Per-pane**: Each tmux pane shows its own git info (the old approach polled
  globally from the status bar every 10 seconds)
- **Smart defaults**: Only shows modules when relevant (Node version only in
  Node projects, SSH hostname only when connected remotely)

### How it was set up

```bash
# Installed to ~/.local/bin/starship
# Initialized at the end of ~/.bashrc and ~/.zshrc:
eval "$(starship init bash)"   # in .bashrc
eval "$(starship init zsh)"    # in .zshrc
```

---

## 2. Your Config File

Starship is configured with a single TOML file:

```
~/.config/starship.toml
```

### TOML Basics

TOML is a simple config format. Here's what you need to know:

```toml
# Comments start with #

# Top-level keys (general settings)
command_timeout = 500

# Sections use [brackets]
[directory]
style = "bold blue"
truncation_length = 3

# Strings use quotes
[character]
success_symbol = "[>](green)"
```

### Editing the config

```bash
# Open in your editor
nano ~/.config/starship.toml

# Changes take effect on the next prompt (no reload needed!)
```

---

## 3. How Modules Work

Starship's prompt is built from **modules**. Each module shows one piece of info:

```
catchashu10@pi in ~/Projects/myapp on  main [!2+1] via  v20.11.0 took 3s
❯
```

| Part | Module | When it shows |
|------|--------|---------------|
| `catchashu10@pi` | username + hostname | SSH sessions only |
| `~/Projects/myapp` | directory | Always |
| ` main` | git_branch | Inside a git repo |
| `[!2+1]` | git_status | When there are changes |
| ` v20.11.0` | nodejs | In a Node.js project |
| `took 3s` | cmd_duration | Commands taking >2s |
| `❯` | character | Always (green=ok, red=error) |

### Key concept: modules are context-aware

- **git_branch** only appears inside a git repository
- **nodejs** only appears when `package.json` exists
- **hostname** only appears in SSH sessions
- If a module has nothing to show, it's hidden entirely

### The format string

The top-level `format` in your config controls module order:

```toml
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$nodejs\
$cmd_duration\
$line_break\
$character"""
```

`$line_break` puts the cursor on a new line below the info.

---

## 4. Your Active Modules

### character — The prompt symbol

```toml
[character]
success_symbol = "[❯](bold #9ece6a)"    # green when last command succeeded
error_symbol = "[❯](bold #f7768e)"      # red when last command failed
```

### directory — Current path

```toml
[directory]
style = "bold #7aa2f7"           # Tokyo Night blue
truncation_length = 3            # show last 3 directories
truncate_to_repo = true          # truncate to git repo root
```

`truncate_to_repo` means inside `~/Projects/myapp/src/components`, you'll see
`myapp/src/components` instead of `~/P/m/s/components`.

### git_branch — Branch name

```toml
[git_branch]
symbol = " "                    # nerd font git icon
style = "bold #bb9af7"           # purple
```

### git_status — Working tree status

```toml
[git_status]
staged = "+$count"       # files added to staging area
modified = "!$count"     # files changed but not staged
untracked = "?$count"    # new files git doesn't track
ahead = "⇡$count"       # commits ahead of remote
behind = "⇣$count"      # commits behind remote
```

These symbols match what the old tmux `git_info` showed, so the info
looks familiar — it just lives in your prompt now.

### cmd_duration — How long commands take

```toml
[cmd_duration]
min_time = 2_000         # only show for commands >2 seconds
```

### nodejs — Node.js version

```toml
[nodejs]
symbol = " "            # nerd font node icon
```

Only appears when the current directory has a `package.json` or `node_modules/`.

### hostname + username — SSH indicator

```toml
[hostname]
ssh_only = true          # hidden on local machine

[username]
show_always = false      # hidden on local machine
```

When you SSH to your Raspberry Pi, you'll see `catchashu10@pi` at the start
of the prompt. On your local WSL, it's hidden.

---

## 5. Customizing Colors and Symbols

### Color formats

Starship accepts colors in several formats:

```toml
style = "bold blue"              # named color
style = "bold #7aa2f7"           # hex color (Tokyo Night blue)
style = "fg:#7aa2f7 bg:#1a1b26"  # foreground + background
style = "bold italic #e0af68"    # multiple attributes
```

### Available attributes

`bold`, `italic`, `underline`, `dimmed`, `inverted`, `blink`, `strikethrough`

### Bracket format strings

The `[text](style)` syntax lets you style specific parts:

```toml
# The > symbol in green bold
success_symbol = "[❯](bold green)"

# Branch name in purple, preceded by an icon
format = "on [$symbol$branch]($style) "
```

### Your Tokyo Night palette

| Color | Hex | Used for |
|-------|-----|----------|
| Blue | `#7aa2f7` | Directory |
| Purple | `#bb9af7` | Git branch |
| Yellow | `#e0af68` | Git status |
| Green | `#9ece6a` | Success symbol, Node |
| Red | `#f7768e` | Error symbol |
| Cyan | `#2ac3de` | SSH hostname |
| Muted | `#565f89` | Command duration |

---

## 6. Common Modules Reference

Modules you might want to add later:

| Module | What it shows | Trigger |
|--------|--------------|---------|
| `python` | Python version + virtualenv | `.py` files, `venv/` |
| `rust` | Rust version | `Cargo.toml` |
| `golang` | Go version | `.go` files |
| `docker_context` | Docker context | `Dockerfile` |
| `aws` | AWS profile/region | `AWS_PROFILE` set |
| `gcloud` | GCP project | `gcloud` configured |
| `kubernetes` | K8s context | `kubeconfig` present |
| `battery` | Battery level | Laptop with battery |
| `time` | Current time | Disabled by default |
| `memory_usage` | RAM usage | Disabled by default |

### Adding a module

1. Add the module name to the `format` string
2. Add a `[module_name]` section with your settings

Example — adding Python:

```toml
# In the format string, add $python where you want it:
format = """
...\
$nodejs\
$python\
$cmd_duration\
..."""

# Then configure it:
[python]
format = "via [$symbol($version)]($style) "
symbol = " "
style = "#e0af68"
```

---

## 7. Practice Exercises

### Exercise 1: See it in action

```bash
# Go to a git repo
cd ~/Projects/terminal-capture

# Notice: branch name and status appear in your prompt
# Make a change and see the status update
echo "test" >> /tmp/test.txt   # this won't show (not in repo)
touch test-file                 # this WILL show as ?1 (untracked)
rm test-file                    # clean up
```

### Exercise 2: Trigger different modules

```bash
# See Node version appear
cd ~/some-node-project    # or any directory with package.json
# The  icon + version appears

# See SSH hostname appear
ssh ashu.pi
# Your prompt now shows catchashu10@pi
```

### Exercise 3: Change a color

```bash
# Open the config
nano ~/.config/starship.toml

# Change the directory color from blue to green:
# [directory]
# style = "bold #9ece6a"

# Save — next prompt immediately uses the new color!
```

### Exercise 4: Add the time module

```bash
# Add to ~/.config/starship.toml:

# In format string, add $time before $line_break
# Then add:
# [time]
# disabled = false
# format = "at [$time]($style) "
# style = "#565f89"
```

### Exercise 5: Check what Starship detects

```bash
# See all active modules and their values
starship explain

# See the raw config Starship is using
starship print-config
```

---

## Quick Reference

```
Config file:     ~/.config/starship.toml
Changes:         Instant (next prompt)
Docs:            https://starship.rs/config/
Debug:           starship explain
Full config:     starship print-config
All modules:     https://starship.rs/config/#modules
```

---

## Before and After

**Before** (old setup):
- Git info polled every 10s in tmux status bar (global, not per-pane)
- Custom `__git_branch()` in `.bashrc` and `vcs_info` in `.zshrc`
- Different prompt logic for inside/outside tmux

**After** (Starship):
- Git info in each pane's prompt (per-pane, instant)
- One config file (`starship.toml`) for both shells
- Same prompt everywhere — tmux or not, bash or zsh
