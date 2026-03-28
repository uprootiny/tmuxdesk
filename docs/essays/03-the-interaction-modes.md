# 🜂 The Interaction Modes

*Keybindings, sessions, and spatial arrangement*

---

Every keybinding is a mnemonic. `Prefix+s` for the session tree. `Prefix+S` for session-on-demand. `Prefix+f` for the fuzzy jumper. `Prefix+P` for presets. `Prefix+F` for fleet health. Uppercase generally means "more" — a stronger variant of the lowercase action.

## Session-on-Demand

The foundational interaction. `session-ensure.sh` is nine lines: if a session exists, switch to it; if not, create it and switch. This collapses the create/select distinction. You always say *where you want to be* and the system ensures you get there.

```
Prefix+S → "⊕ session:" → type "deploy" → ↵
```

If `deploy` exists: switch. If not: create, then switch. The prompt shows `⊕` — the astronomical earth symbol, grounding. You're declaring a place to stand.

This matters because tmux sessions are *named workspaces*. A session called `deploy` persists across disconnections. You SSH in tomorrow and it's still there — same panes, same layout, same scrollback. Session-on-demand means you never think about whether a workspace exists. You just name it and arrive.

## Fuzzy Jumping

`Prefix+f` opens a full-screen `fzf` popup listing every session and every pane across the local tmux server. Each row shows:

```
* session deploy          age:2h14m  host:hyle  windows:3
  pane deploy:1.2 [term]  age:2h14m  host:hyle  cwd:/home/... cmd:bash :: last output line
```

The columns: type (session/pane), name, age, host, context. The preview pane on the right shows the last 120 lines of the selected pane's content. `Ctrl+r` refreshes live.

This is the *telescope* — you see everything at once and land precisely where you need to be. No tree-walking, no remembering window numbers. Type a few characters, see the match, press enter.

If `fzf` isn't installed, the binding falls back to `choose-tree -Zw` — tmux's built-in hierarchical picker. Graceful degradation.

## Layout Cycling

`Prefix+Tab` rotates through tmux's five built-in layouts:

| # | Layout | Description |
|---|--------|-------------|
| 1 | tiled | Equal-sized grid |
| 2 | even-horizontal | Side-by-side columns |
| 3 | even-vertical | Stacked rows |
| 4 | main-horizontal | Large top + small bottom |
| 5 | main-vertical | Large left + small right |

`Prefix+L` cycles backward.

State is tracked *per window* — a tmux user option keyed by `@layout_idx_<session>_<window>`. Cycling in your editor window doesn't affect your monitor window. The display message shows the current layout name and position: `⊞ main-vertical [5/5]`.

## Presets

Named pane topologies invoked through `Prefix+P`:

**`dev-3pane`** — Main-vertical layout: a large editor pane on the left, terminal top-right, logs/repl bottom-right. Accepts a session name and working directory. Idempotent: if the session exists, switches to it.

**`monitor-4pane`** — Tiled grid. Accepts up to four commands as arguments:

```bash
monitor-4pane.sh mymon htop "tail -f /var/log/syslog" "watch df -h" "nethogs"
```

Each command is sent to its respective pane.

**`pair-2pane`** — Side-by-side split. For pairing, diff work, or comparing two views of the same project.

All presets are idempotent and respect `base-index 1`.

## Splits and Navigation

Splits inherit context:

| Binding | Action |
|---------|--------|
| `Prefix+\|` | Vertical split, inherits cwd |
| `Prefix+-` | Horizontal split, inherits cwd |
| `Prefix+c` | New window, inherits cwd |

Pane navigation is vi-native:

| Binding | Action |
|---------|--------|
| `Prefix+h/j/k/l` | Move left/down/up/right |
| `Prefix+H/J/K` | Resize left/down/up (repeatable) |

Copy mode:

| Binding | Action |
|---------|--------|
| `v` | Begin selection |
| `C-v` | Toggle rectangle select |
| `y` | Yank (copy + exit) |
| `Escape` | Cancel |

## Utility Bindings

| Binding | Action |
|---------|--------|
| `Prefix+r` | Reload config (`⟳ config reloaded`) |
| `Prefix+m` | Toggle mouse on/off |
| `Prefix+F` | Fleet health popup |

The terminal becomes a text object — navigable, composable, precise.

---

*Previous: [☰ The Architecture](02-the-architecture.md) · Next: [∞ The Infrastructure](04-the-infrastructure.md)*
