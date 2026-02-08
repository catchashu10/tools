# Tmux Interactive Lessons — Beginner to Advanced

A progressive, hands-on guide to mastering tmux. Each lesson builds on the previous one.

> **Prefix key**: `Ctrl-a` (hold Ctrl + press a, release both, then press the action key)
> **Secondary prefix**: `Ctrl-Space`

---

## Lesson 1: What is Tmux & Your First Session

### The Concept

Think of tmux like this:

```
Without tmux:
  Terminal window = your shell session
  Close terminal = session dies

With tmux:
  Terminal window → tmux server → session → shell
  Close terminal = session keeps running
  Reconnect later = pick up right where you left off
```

Tmux has 3 layers (think of it like a building):

```
Session   = the building      (a project/workspace)
  Window  = a floor           (like browser tabs)
    Pane  = a room on a floor (split views within a tab)
```

### The Prefix Key

Almost every tmux shortcut starts with a **prefix key**. The prefix is:

> **`Ctrl-a`** (hold Ctrl, press a, release both)

You press the prefix first, then the action key. They are **not** held together — it's a two-step combo.

```
Ctrl-a  d
│         │
│         └── press d (alone) — this is the action
└──────────── hold Ctrl + press a together, then release — this is the prefix
```

### Key Bindings

| Shortcut | Action |
|----------|--------|
| `Ctrl-a d` | Detach from session (keeps running) |

### Commands

| Command | Flags | Description |
|---------|-------|-------------|
| `tmux new -s <name>` | `-s` = session name | Create a named session |
| `tmux ls` | | List all sessions |
| `tmux attach -t <name>` | `-t` = target | Reattach to a session |
| `tmux kill-session -t <name>` | `-t` = target | Kill a session |

### The `-t` Flag

`-t` means **target**. You'll see it everywhere in tmux. It's how you tell tmux **which** session/window/pane you're talking about. Without `-t`, tmux guesses (usually picks the most recent session).

### Exercise

1. Create a session: `tmux new -s learn`
2. Look at the status bar at the bottom — session name on left, window name in center
3. Detach: `Ctrl-a` then `d`
4. List sessions: `tmux ls` — see your session is still alive
5. Reattach: `tmux attach -t learn`

---

## Lesson 2: Panes — Splitting Your Workspace

Panes let you see **multiple terminals side by side** in one window.

### Splitting

```
Ctrl-a  _          Vertical split (left | right)
┌───────┬───────┐
│       │       │
│       │       │
└───────┴───────┘

Ctrl-a  -          Horizontal split (top / bottom)
┌───────────────┐
│               │
├───────────────┤
│               │
└───────────────┘
```

Easy to remember:
- **`_`** (underscore) → splits vertically (left/right)
- **`-`** (dash) → splits horizontally (top/bottom)

### Navigating Between Panes

Vim-style keys (`h j k l`):

```
        k
        ↑
   h ←     → l
        ↓
        j
```

### Key Bindings

| Shortcut | Action | Repeatable? |
|----------|--------|-------------|
| `Ctrl-a _` | Vertical split (left/right) | No |
| `Ctrl-a -` | Horizontal split (top/bottom) | No |
| `Ctrl-a h` | Move to left pane | Yes |
| `Ctrl-a j` | Move to down pane | Yes |
| `Ctrl-a k` | Move to up pane | Yes |
| `Ctrl-a l` | Move to right pane | Yes |
| `Ctrl-a` + arrow keys | Same as h/j/k/l | Yes |
| `Ctrl-a z` | Zoom/unzoom pane (fullscreen toggle) | No |
| `Ctrl-a x` | Kill current pane (asks confirmation) | No |
| `exit` | Close pane by exiting the shell | — |
| Mouse click | Click on a pane to focus it | — |

### Repeat Bindings

When a binding is **repeatable** (`-r` flag), after pressing it once you get a repeat window (~500ms) where you can press the action key again without the prefix:

```
Ctrl-a  h  h  h  h
│       │  │  │  │
│       │  └──┴──┴── no prefix needed, just keep pressing
│       └──────────── first action (triggers repeat window)
└──────────────────── prefix (only needed once)
```

### Exercise

Build this 3-pane layout:

```
┌──────────────┬──────────────┐
│              │              │
│     1        │      2       │
│              │              │
│              ├──────────────┤
│              │      3       │
│              │              │
└──────────────┴──────────────┘
```

Steps:
1. `Ctrl-a _` — vertical split (now you have left and right)
2. Navigate to the right pane: `Ctrl-a l`
3. `Ctrl-a -` — horizontal split the right pane
4. Practice navigating between all 3 panes using `Ctrl-a h/j/k/l`
5. Try zooming: `Ctrl-a z` on any pane, then `Ctrl-a z` again to unzoom

---

## Lesson 3: Windows — Tabs in Tmux

If panes are split views, **windows are tabs**. Look at your status bar — you'll see something like `1:claude*` (window 1, named "claude", `*` means active).

### Key Bindings

| Shortcut | Action | Repeatable? |
|----------|--------|-------------|
| `Ctrl-a c` | Create new window | No |
| `Ctrl-a Ctrl-l` | Next window | Yes |
| `Ctrl-a Ctrl-h` | Previous window | Yes |
| `Ctrl-a 1`, `2`, `3`... | Jump to window by number | No |
| `Ctrl-a Tab` | Last window (toggle between two most recent) | No |
| `Ctrl-a ,` | Rename current window | No |
| `Ctrl-a &` | Kill window (asks confirmation) | No |
| `Ctrl-a w` | Window tree (interactive picker) | No |

> **Note**: `prefix + n` / `prefix + p` are NOT bound to next/previous in the gpakosz config. Use `Ctrl-h` / `Ctrl-l` instead.

### Exercise

1. `Ctrl-a c` — create a new window
2. Run `htop` or `top` in the new window
3. `Ctrl-a ,` — rename it to `monitor`
4. `Ctrl-a c` — create a third window, rename to `scratch`
5. Practice switching:
   - `Ctrl-a 1` → window 1
   - `Ctrl-a 2` → window 2
   - `Ctrl-a Ctrl-l` / `Ctrl-a Ctrl-h` → next/previous
   - `Ctrl-a Tab` → toggle between last two windows
6. Kill extra windows: `Ctrl-a &` (type `y` to confirm)

---

## Lesson 4: Sessions — Organizing Projects

Sessions are like **separate desktops** — one per project:

```
Session: "webdev"          Session: "notes"         Session: "server"
┌──────────────────┐      ┌──────────────────┐     ┌──────────────────┐
│ Window 1: editor │      │ Window 1: vim    │     │ Window 1: logs   │
│ Window 2: server │      │ Window 2: files  │     │ Window 2: htop   │
│ Window 3: git    │      └──────────────────┘     └──────────────────┘
└──────────────────┘
```

### Key Bindings

| Shortcut | Action |
|----------|--------|
| `Ctrl-a Ctrl-c` | Create new session (prompts for name) |
| `Ctrl-a $` | Rename current session |
| `Ctrl-a s` | Session tree (interactive switch) |
| `Ctrl-a (` | Previous session |
| `Ctrl-a )` | Next session |
| `Ctrl-a d` | Detach |

### Session Tree (`Ctrl-a s`)

The session tree is your **command center**:
- Use `j`/`k` or arrows to navigate
- **Right arrow** expands a session to show its windows/panes
- **Left arrow** collapses it
- `Enter` to select and switch
- `q` to quit

| Shortcut | View |
|----------|------|
| `Ctrl-a s` | Session tree (grouped by session) |
| `Ctrl-a w` | Window tree (shows all windows across all sessions) |

### Commands

| Command | Description |
|---------|-------------|
| `tmux new -s <name>` | Create named session |
| `tmux new -s <name> -d` | Create detached (in background) |
| `tmux ls` | List all sessions |
| `tmux kill-session -t <name>` | Kill a session |
| `tmux attach -t <name>` | Attach to a session |

### Exercise

1. `Ctrl-a Ctrl-c` — create `project-a`
2. `Ctrl-a Ctrl-c` — create `project-b`
3. `Ctrl-a s` — open session tree, see all 3 sessions
4. Navigate and switch between them
5. Try `Ctrl-a (` and `Ctrl-a )` to cycle
6. Clean up: `tmux kill-session -t project-a` and `tmux kill-session -t project-b`

---

## Lesson 5: Copy Mode — Scrolling, Searching, Copying

Copy mode turns your pane into a navigable text buffer — like a read-only vim.

### Entering and Exiting

| Shortcut | Action |
|----------|--------|
| `Ctrl-a [` | Enter copy mode |
| `q` or `Escape` | Exit copy mode |
| Scroll with mouse | Also enters copy mode |

### Navigation (Vi-Style)

| Key | Action |
|-----|--------|
| `k` / `j` | Scroll up / down one line |
| `Ctrl-u` | Half page up |
| `Ctrl-d` | Half page down |
| `g` | Jump to top of history |
| `G` | Jump to bottom |

### Searching

| Key | Action |
|-----|--------|
| `/` then text | Search forward |
| `?` then text | Search backward |
| `n` | Next match |
| `N` | Previous match |

This is exactly like searching in vim.

### Copying Text

The flow:

```
Enter copy mode → Navigate → Start selection → Move → Copy → Paste
```

| Key | Action |
|-----|--------|
| `Space` | Start selection (like vim visual mode) |
| Move keys | Extend selection |
| `Enter` | Copy selection and exit copy mode |
| `Ctrl-a p` | Paste |

### Exercise

1. Run `seq 1 200` to generate text
2. `Ctrl-a [` — enter copy mode
3. Press `g` to jump to top, `G` to jump to bottom
4. Press `/`, type `142`, press Enter — jumps to that line
5. Press `q` to exit
6. Run `seq 1 10`
7. `Ctrl-a [` → navigate to `3` → `Space` → press `j` down to `7` → `Enter`
8. `Ctrl-a p` — paste what you copied

---

## Lesson 6: Resizing & Layouts

### Resizing Panes

| Shortcut | Action | Repeatable? |
|----------|--------|-------------|
| `Ctrl-a H` | Resize left by 2 cells | Yes |
| `Ctrl-a J` | Resize down by 2 cells | Yes |
| `Ctrl-a K` | Resize up by 2 cells | Yes |
| `Ctrl-a L` | Resize right by 2 cells | Yes |
| Mouse drag | Drag pane border | — |

The pattern: **lowercase `hjkl` navigates**, **uppercase `HJKL` resizes**.

### Preset Layouts

| Shortcut | Layout |
|----------|--------|
| `Ctrl-a Alt-1` | Even horizontal — all panes side by side |
| `Ctrl-a Alt-2` | Even vertical — all panes stacked |
| `Ctrl-a Alt-3` | Main horizontal — one big top, rest below |
| `Ctrl-a Alt-4` | Main vertical — one big left, rest right |
| `Ctrl-a Alt-5` | Tiled — equal grid |
| `Ctrl-a Space` | Cycle through layouts |

### Swapping Panes

| Shortcut | Action |
|----------|--------|
| `Ctrl-a <` | Swap current pane with previous |
| `Ctrl-a >` | Swap current pane with next |
| `Ctrl-a q` | Show pane numbers (press number to jump) |

### Exercise

1. Create a 3-pane layout: `Ctrl-a _` then `Ctrl-a -`
2. Run something different in each pane to tell them apart
3. Press `Ctrl-a Space` repeatedly — watch panes rearrange
4. Try resizing with `H/J/K/L`
5. Try swapping with `Ctrl-a <` and `Ctrl-a >`
6. Press `Ctrl-a q` to see pane numbers

---

## Lesson 7: Advanced Workflows & Muscle Memory

### 1. Session Persistence (Resurrect + Continuum)

| Shortcut | Action |
|----------|--------|
| `Ctrl-a Ctrl-s` | Save all sessions manually |
| `Ctrl-a Ctrl-r` | Restore saved sessions |

Continuum auto-saves every 10 minutes. If your machine restarts, sessions restore automatically.

### 2. Command Mode

Press **`Ctrl-a :`** to open the tmux command prompt:

```
: new-window -n mywindow
: split-window -h
: rename-session work
: kill-pane
: setw synchronize-panes on
```

Useful for commands without a shortcut, or when you forget a binding.

### 3. Moving Panes Between Windows

| Shortcut | Action |
|----------|--------|
| `Ctrl-a !` | Break pane — sends current pane to its own new window |
| Command: `join-pane -s :2` | Join window 2's pane into current window |

`-s` = source (where to take from), `-t` = target (where to send to)

### 4. Synchronize Panes

Sends the same keystrokes to **all panes** simultaneously:

```
Ctrl-a :   then   setw synchronize-panes on     (enable)
Ctrl-a :   then   setw synchronize-panes off    (disable)
```

Extremely useful for running the same command on multiple servers.

### 5. Config Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl-a e` | Edit config in vim |
| `Ctrl-a r` | Reload config |
| `Ctrl-a S` | Toggle scroll direction (natural/normal) |
| `Ctrl-a m` | Toggle mouse on/off |

### 6. Tmux Popup (`tp`)

The `tp` function runs a command in a **floating popup window** that overlays your
current pane. The popup closes automatically when the command finishes.

```bash
tp htop               # system monitor in a popup
tp bash               # quick scratch shell (Ctrl-d to close)
tp "git log --oneline"  # peek at git history without leaving your pane
```

**Why use it?** When you want to run a quick command without creating a new pane
or window. The popup floats over your workspace and disappears when done — no
cleanup needed.

### 7. Scroll Direction Toggle (`Ctrl-a S`)

This binding exists because tmux can't distinguish trackpad scrolling from
mouse wheel scrolling — they both send the same event. The problem: natural
scrolling feels right on a trackpad but backwards with a mouse wheel.

If you switch between devices (e.g., iPad with trackpad and a desktop with a
mouse), press `Ctrl-a S` to flip the scroll direction. The current setting is
shown briefly in the status bar when you toggle.

---

## Complete Cheat Sheet

```
SESSION
  Ctrl-a Ctrl-c       New session (prompts for name)
  Ctrl-a $             Rename session
  Ctrl-a s             Session tree (switch sessions)
  Ctrl-a ( / )         Previous / next session
  Ctrl-a d             Detach

WINDOW
  Ctrl-a c             New window
  Ctrl-a ,             Rename window
  Ctrl-a Ctrl-h/l      Previous / next window
  Ctrl-a 1-9           Jump to window by number
  Ctrl-a Tab           Last window (toggle)
  Ctrl-a w             Window tree
  Ctrl-a &             Kill window

PANE
  Ctrl-a _             Vertical split (left/right)
  Ctrl-a -             Horizontal split (top/bottom)
  Ctrl-a h/j/k/l       Navigate panes
  Ctrl-a H/J/K/L       Resize panes
  Ctrl-a z             Zoom / unzoom
  Ctrl-a x             Kill pane
  Ctrl-a < / >         Swap pane
  Ctrl-a q             Show pane numbers
  Ctrl-a !             Break pane to new window
  Ctrl-a Space         Cycle layouts
  Ctrl-a Alt-1 to 5    Preset layouts

COPY MODE
  Ctrl-a [             Enter copy mode
  / or ?               Search forward / backward
  n / N                Next / previous match
  Space                Start selection
  Enter                Copy selection
  Ctrl-a p             Paste
  g / G                Top / bottom of history
  Ctrl-u / Ctrl-d      Half page up / down
  q                    Exit copy mode

ADVANCED
  Ctrl-a :             Command mode
  Ctrl-a Ctrl-s        Save sessions (resurrect)
  Ctrl-a Ctrl-r        Restore sessions (resurrect)
  Ctrl-a S             Toggle scroll direction (trackpad/mouse)
  Ctrl-a e             Edit config
  Ctrl-a r             Reload config
  Ctrl-a m             Toggle mouse
  tp <cmd>             Run command in floating popup

COMMANDS
  tmux new -s <name>           Create named session
  tmux new -s <name> -d        Create detached session
  tmux ls                      List sessions
  tmux attach -t <name>        Attach to session
  tmux kill-session -t <name>  Kill session
```

---

## Config Notes

- **Config file**: `~/.tmux.conf.local` (your customizations)
- **Framework**: gpakosz/.tmux at `~/.tmux/`
- **Prefix**: `Ctrl-a` (primary), `Ctrl-Space` (secondary)
- **Plugins**: tmux-resurrect, tmux-continuum, tmux-yank
- **Settings**: mouse on, vi mode, 50000 history, 10ms escape-time, natural scroll toggle
