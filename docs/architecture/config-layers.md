# Configuration Layers

## Overview

tmuxdesk uses a three-layer configuration model. Each layer has a single responsibility and a clear boundary.

```
┌──────────────────────────────────────┐
│ Layer 3: Runtime State               │  state/*.sessions
│ (per-node, ephemeral, gitignored)    │  populated by mesh-announce.sh
├──────────────────────────────────────┤
│ Layer 2: Per-Host Config             │  conf/host-<name>.conf
│ (identity, host-specific status)     │  sets @host_sigil, @host_name
├──────────────────────────────────────┤
│ Layer 1: Base Config                 │  conf/tmux.base.conf
│ (invariants: keys, status, hooks)    │  shared across all nodes
└──────────────────────────────────────┘
```

## Layer 1: Base Config

**File**: `conf/tmux.base.conf`
**Scope**: every node, every session

Contains:
- Terminal settings (true colour, escape-time, history)
- Window/pane numbering (1-indexed, auto-renumber)
- Pane border styling
- Status bar skeleton (left + right templates)
- All keybindings (vi nav, splits, reload, fuzzy jump, presets, etc.)
- Vi copy mode bindings
- Session logging hooks
- Mesh hooks (session-created, session-closed → mesh-announce.sh)

**Design rule**: nothing in the base references a specific host. If you `grep` for any hostname or IP in `tmux.base.conf`, you find nothing.

## Layer 2: Per-Host Config

**Files**: `conf/host-<name>.conf`
**Scope**: one specific node

Always contains:
```tmux
set -g @host_sigil "<sigil>"
set -g @host_name "<name>"
```

Optionally appends host-specific status segments:
```tmux
set -ga status-right ' #[fg=colour244]│ #[fg=colour136]⊢ #(some-command)'
```

**Design rule**: use `set -ga` (append) not `set -g` (replace). Host configs extend the base, never contradict it. The status line composes left-to-right: base segments first, then host-specific.

### Per-Host Features

| Node | Config | Special Features |
|------|--------|-----------------|
| 🜂 hyle | host-hyle.conf | TPM, resurrect, continuum, deskfloor status |
| ∴ hub2 | host-hub2.conf | Git branch display, 3s status interval |
| ☰ finml | host-finml.conf | GPU util/temp (`⊿`), load average (`λ`) |
| ∞ karlsruhe | host-karlsruhe.conf | NixOS generation (`∂`), profile count (`∫`) |
| ∇ nabla | host-nabla.conf | GCP zone, load average (`λ`) |

## Layer 3: Runtime State

**Directory**: `state/`
**Scope**: per-node, ephemeral
**Persistence**: gitignored, never deployed

Contains `.sessions` files written by `mesh-announce.sh`:
- `local.sessions` — this node's own state
- `<peer>.sessions` — received from peers via SSH

Read by `mesh-status.sh` every `status-interval` seconds.

## The Bootstrap

`~/.tmux.conf` on each node is a two-line file written by `deploy.sh`:

```tmux
source-file ~/.tmux/tmuxdesk/conf/tmux.base.conf
source-file ~/.tmux/tmuxdesk/conf/host-<name>.conf
```

This is the only tmuxdesk-managed file outside `~/.tmux/tmuxdesk/`. It's the entry point that chains the layers.

## Composition Example

On hub2, the status-right composes as:

```
Base:     mesh-status | window-pos | datetime
Host:     | ⊢ git-branch
Result:   ∴●2 ☰○1 ∞✕ ∇●1 │ 1/3 │ 21-Mar 18:22 │ ⊢ master
```

On finml:

```
Base:     mesh-status | window-pos | datetime
Host:     | ⊿ gpu-util | λ load
Result:   🜂●3 ∴●2 ∞✕ ∇●1 │ 1/2 │ 21-Mar 18:22 │ ⊿ 78% 62°C │ λ 2.34
```

Each node's status bar is unique, but all share the same foundational structure.
