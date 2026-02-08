# Tmux Setup

Terminal multiplexer with gpakosz/.tmux framework, custom themes, and capture tools.

## Quick Reference

| Shortcut | Action |
|----------|--------|
| `Ctrl-a` | Primary prefix |
| `Ctrl-Space` | Secondary prefix |
| `Ctrl-a T` | Switch theme |
| `Ctrl-a S` | Toggle scroll direction (natural/normal) |
| `Ctrl-a Ctrl-s` | Save session (resurrect) |
| `Ctrl-a Ctrl-r` | Restore session (resurrect) |

## File Locations

| File | Location | Purpose |
|------|----------|---------|
| Framework | `~/.tmux/` | gpakosz/.tmux (git repo, don't edit) |
| Main config | `~/.tmux.conf` | Symlink → `~/.tmux/.tmux.conf` |
| **User config** | **`~/.tmux.conf.local`** | All customizations go here |
| Themes | `~/.tmux/themes/*.conf` | Theme colour definitions |
| Theme switcher | `~/.local/bin/tmux-theme` | Theme switching script |
| Tmux capture | `~/.local/bin/tmux-capture` | Capture pane contents for AI |
| Unified capture | `~/.local/bin/capture` | Capture tmux sessions by name |
| Capture output | `~/.tmux-context/` | Captured pane contents |

## Repo Structure

```
~/Tools/Tmux/
├── README.md                         # This file
├── install.sh                        # Run this on a new machine
├── config/
│   └── tmux.conf.local               # All tmux customizations
├── themes/
│   ├── catppuccin-mocha.conf
│   ├── dracula.conf
│   ├── nord.conf
│   ├── tokyo-night.conf
│   └── default.conf
└── scripts/
    ├── tmux-theme                    # Theme switcher
    ├── tmux-capture                  # Capture pane contents
    └── capture                       # Capture tmux sessions by name
```

After install, symlinks point FROM dotfile locations TO this repo:
```
~/.tmux.conf.local      → ~/Tools/Tmux/config/tmux.conf.local
~/.tmux/themes/         → ~/Tools/Tmux/themes/
~/.local/bin/tmux-theme → ~/Tools/Tmux/scripts/tmux-theme
~/.local/bin/tmux-capture → ~/Tools/Tmux/scripts/tmux-capture
~/.local/bin/capture    → ~/Tools/Tmux/scripts/capture
```

## Configuration

### Prefix Keys

| Key | Role |
|-----|------|
| `Ctrl-a` | Primary prefix (replaced default `Ctrl-b`) |
| `Ctrl-Space` | Secondary prefix |

### Settings Applied

| Setting | Value | Why |
|---------|-------|-----|
| `history-limit` | 50000 | More scrollback for debugging |
| `escape-time` | 10ms | No delay on Escape (critical for vim) |
| `focus-events` | on | Vim autoread, gitgutter refresh |
| `default-terminal` | tmux-256color | Proper terminal identification |
| `terminal-features` | xterm-256color:RGB | 24-bit color support |
| `mouse` | on | Mouse support enabled |
| `mode-keys` | vi | Vi-style keybindings |
| `copy_to_os_clipboard` | true | Copy to system clipboard |
| Powerline separators | enabled | Nerd Font arrow-style status bar |

### Plugins

| Plugin | Purpose | Shortcuts |
|--------|---------|-----------|
| tmux-resurrect | Save/restore sessions manually | `Ctrl-a Ctrl-s` / `Ctrl-a Ctrl-r` |
| tmux-continuum | Auto-save every 10 min, auto-restore | Automatic |
| tmux-yank | Better clipboard integration | Automatic in copy mode |

Plugin auto-update is **disabled** (manual control via `Ctrl-a I` to install, `Ctrl-a u` to update).

### Scroll Direction Toggle

For multi-device use (trackpad = natural scrolling, mouse = normal scrolling):

| Shortcut | Action |
|----------|--------|
| `Ctrl-a S` | Toggle between natural and normal scrolling |

Status bar shows: `scroll: natural (trackpad)` or `scroll: normal (mouse wheel)`

## Themes

### Available Themes

| Theme | Description |
|-------|-------------|
| `default` | Original gpakosz — yellow, pink, green segments |
| `catppuccin-mocha` | Soft pastels — mauve, pink, peach, blue |
| `cyberpunk` | Neon electric — hot pink, purple, cyan, orange |
| `dracula` | Bold — purple, pink, cyan, orange |
| `everforest` | Soft woodland — green, orange, aqua, yellow |
| `gruvbox` | Warm retro — orange, red, green, yellow |
| `kanagawa` | Japanese ink — violet, sakura pink, orange, spring blue |
| `nord` | Cool blues — frost blue, teal, aurora orange |
| `rose-pine` | Elegant muted — iris purple, rose, gold, foam |
| `tokyo-night` | Deep blue — blue, magenta, orange, cyan |
| **Monochrome** | |
| `mono-amber` | Warm glow — chocolate to gold gradients |
| `mono-blue` | Ocean depths — navy to sky blue gradients |
| `mono-green` | Terminal hacker — forest to mint gradients |
| `mono-purple` | Royal velvet — plum to lavender gradients |
| `mono-rose` | Soft blush — wine to pink gradients |

### Switching Themes

**Interactive menu:** `Ctrl-a T` — popup menu to select a theme

**Command line:** `tmux-theme <name>`

```bash
tmux-theme catppuccin-mocha
tmux-theme cyberpunk
tmux-theme dracula
tmux-theme everforest
tmux-theme gruvbox
tmux-theme kanagawa
tmux-theme nord
tmux-theme rose-pine
tmux-theme tokyo-night
tmux-theme mono-amber
tmux-theme mono-blue
tmux-theme mono-green
tmux-theme mono-purple
tmux-theme mono-rose
tmux-theme default
```

### Adding Custom Themes

1. Create `~/.tmux/themes/my-theme.conf` with colour definitions (use existing themes as template)
2. Add an entry to the `bind T display-menu` section in `~/.tmux.conf.local`
3. Reload: `Ctrl-a r`

Theme files define 17 colour variables that control the entire status bar appearance. Colours are swapped between `# THEME_START` and `# THEME_END` markers in `~/.tmux.conf.local`.

## Capture Tools

For AI-assisted terminal context (Claude Code, etc.):

```bash
# Capture current tmux session
capture

# Capture a specific session
capture learn
capture main
```

Output saved to `~/.tmux-context/`:
- `context.md` — Summary + last 50 lines per pane
- `pane-N-M.txt` — Full scrollback per pane

## Known Issues & Fixes

### gpakosz + tmux 3.4 command-prompt incompatibility

**Problem:** `tmux_conf_new_session_prompt=true` generates broken `command-prompt` syntax for tmux 3.4, causing error: `command command-prompt: too many arguments`

**Fix:** Set `tmux_conf_new_session_prompt=disabled` and add manual binding:
```
bind C-c command-prompt -p "new-session" "new-session -c '#{pane_current_path}' -s '%%'" #!important
```

### Scroll direction in tmux

**Problem:** tmux can't distinguish trackpad vs mouse wheel events — they both arrive as `WheelUp`/`WheelDown`.

**Fix:** Toggle binding (`Ctrl-a S`) to swap scroll direction based on current input device.

## Replicating on a New Machine

```bash
# 1. Clone the repo
git clone http://tools.ashukumar.com ~/Tools
# or: git clone https://github.com/catchashu10/tools.git ~/Tools

# 2. Run the installer
~/Tools/Tmux/install.sh

# 3. Start tmux and install plugins
tmux new -s main
# Press Ctrl-a I (wait for plugins to install)
```

That's it. The installer handles everything: tmux installation, gpakosz framework, config symlinks, themes, scripts, clipboard tools, and PATH setup.
