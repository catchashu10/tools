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
| Unified capture | `~/.local/bin/capture` | Auto-detect Zellij/Tmux capture |
| Capture output | `~/.tmux-context/` | Captured pane contents |

## Symlinks in This Folder

```
~/Tools/Tmux/
├── config.local        → ~/.tmux.conf.local
├── framework           → ~/.tmux/
├── themes              → ~/.tmux/themes/
├── scripts-tmux-theme  → ~/.local/bin/tmux-theme
├── scripts-tmux-capture→ ~/.local/bin/tmux-capture
├── scripts-capture     → ~/.local/bin/capture
└── capture-output      → ~/.tmux-context/
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
| `dracula` | Bold — purple, pink, cyan, orange |
| `nord` | Cool blues — frost blue, teal, aurora orange |
| `tokyo-night` | Deep blue — blue, magenta, orange, cyan |

### Switching Themes

**Interactive menu:** `Ctrl-a T` — popup menu to select a theme

**Command line:** `tmux-theme <name>`

```bash
tmux-theme catppuccin-mocha
tmux-theme dracula
tmux-theme nord
tmux-theme tokyo-night
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

1. Clone gpakosz/.tmux:
   ```bash
   git clone https://github.com/gpakosz/.tmux.git ~/.tmux
   ln -s -f .tmux/.tmux.conf ~/.tmux.conf
   ```

2. Copy config:
   ```bash
   cp ~/Tools/Tmux/config.local ~/.tmux.conf.local
   ```

3. Copy themes:
   ```bash
   cp -r ~/Tools/Tmux/themes/ ~/.tmux/themes/
   ```

4. Copy scripts:
   ```bash
   cp ~/Tools/Tmux/scripts-tmux-theme ~/.local/bin/tmux-theme
   cp ~/Tools/Tmux/scripts-tmux-capture ~/.local/bin/tmux-capture
   cp ~/Tools/Tmux/scripts-capture ~/.local/bin/capture
   chmod +x ~/.local/bin/tmux-theme ~/.local/bin/tmux-capture ~/.local/bin/capture
   ```

5. Create output directory:
   ```bash
   mkdir -p ~/.tmux-context
   ```

6. Start tmux and install plugins: `Ctrl-a I`
