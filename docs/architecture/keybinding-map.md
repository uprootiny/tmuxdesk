# Keybinding Map

All bindings use the tmux prefix (default `Ctrl+b`).

## Navigation

| Binding | Action | Script |
|---------|--------|--------|
| `h` | Select pane left | built-in |
| `j` | Select pane down | built-in |
| `k` | Select pane up | built-in |
| `l` | Select pane right | built-in |
| `s` | Session/window tree | built-in `choose-tree -Zs` |
| `f` | Fuzzy session/pane jumper | `bin/fuzzy-session-pane.sh` |

## Sessions

| Binding | Action | Script |
|---------|--------|--------|
| `S` | Session-on-demand (create or switch) | `bin/session-ensure.sh` |
| `P` | Preset picker via fzf | inline |

## Layout

| Binding | Action | Script |
|---------|--------|--------|
| `Tab` | Cycle layout forward | `bin/layout-cycle.sh next` |
| `M-l` | Cycle layout backward | `bin/layout-cycle.sh prev` |

## Splits & Windows

| Binding | Action |
|---------|--------|
| `\|` | Vertical split (inherits cwd) |
| `-` | Horizontal split (inherits cwd) |
| `c` | New window (inherits cwd) |

## Resize (repeatable)

| Binding | Action |
|---------|--------|
| `H` | Resize pane left 5 |
| `J` | Resize pane down 5 |
| `K` | Resize pane up 5 |

## Copy Mode (emacs)

| Binding | Action |
|---------|--------|
| `C-Space` | Begin selection |
| `M-w` | Copy selection |
| `C-w` | Cut selection |
| `q` | Cancel copy mode |

## Fleet & System

| Binding | Action | Script |
|---------|--------|--------|
| `F` | Fleet health popup | `bin/fleet-health.sh` |
| `B` | Broadcast command to all nodes | `bin/fleet-broadcast.sh` |
| `G` | Project search across fleet | `bin/fleet-search.sh` |
| `r` | Reload config | sources `~/.tmux.conf` |
| `m` | Toggle mouse | displays on/off |

## Mnemonic Summary

```
Navigation:  h j k l        (vi directions)
Sessions:    s S             (small=tree, big=on-demand)
Find:        f               (fuzzy)
Presets:     P               (picker)
Layout:      Tab M-l         (tab=forward, alt-l=back)
Fleet:       F B G           (health, broadcast, grep-projects)
Splits:      | -             (visual: vertical, horizontal)
Window:      c               (create)
Resize:      H J K           (shift+direction = resize)
System:      r m             (reload, mouse)
Copy:        C-Space M-w q   (emacs: mark, copy, quit)
```
