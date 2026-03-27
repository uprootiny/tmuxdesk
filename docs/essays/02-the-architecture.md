# ☰ The Architecture

*Layered configuration and the mesh protocol*

---

tmuxdesk is a three-layer system. Each layer has a clear responsibility and a clear boundary.

## Layer 1: The Base

`tmux.base.conf` — shared across every node. Vi keybindings, session logging, the status bar skeleton, the [keybinding vocabulary](03-the-interaction-modes.md). This layer encodes the invariants: what is true of *every* terminal session regardless of which machine hosts it.

The base establishes:

- **Terminal**: true colour support, 200k history, zero escape-time
- **Numbering**: 1-indexed windows and panes, auto-renumber on close
- **Navigation**: vi-style pane movement (`h/j/k/l`), resize (`H/J/K`), vi copy mode
- **Status bar**: left (sigil + session + host), right (mesh + window position + time)
- **Hooks**: session-created and session-closed fire `mesh-announce.sh`
- **Keybindings**: the full [interaction vocabulary](03-the-interaction-modes.md)

Nothing in the base is host-specific. If you removed all host configs, every node would still have a coherent, navigable tmux environment.

## Layer 2: Per-Host

Above the base: per-host configuration files. Each one sets `@host_sigil` and `@host_name`, then *appends* to the status line with `set -ga status-right`:

- **`host-hyle.conf`** — TPM, tmux-resurrect, tmux-continuum for session persistence. Deskfloor integration status.
- **`host-hub2.conf`** — Git branch of the tmuxdesk repo itself in the status line. Faster status refresh (3s) for coordination awareness.
- **`host-finml.conf`** — GPU utilization and temperature via `nvidia-smi` (degrades gracefully). Load average via `λ`.
- **`host-karlsruhe.conf`** — NixOS generation number (`∂`). Nix profile count (`∫`).
- **`host-nabla.conf`** — GCP zone from metadata API. Load average.

The key design choice: `set -ga` (append) rather than `set -g` (replace). Host configs *extend* the base — they never contradict it. The status line composes left-to-right: base segments first, then host-specific segments.

## Layer 3: Runtime State

The `state/` directory is populated by the mesh protocol at runtime. It is never deployed — it's per-node, ephemeral, gitignored. It contains:

```
state/
├── local.sessions      # this node's session dump
├── hyle.sessions       # pushed by hyle via SSH
├── hub2.sessions       # pushed by hub2
├── finml.sessions      # pushed by finml
└── ...
```

Each `.sessions` file is a pipe-delimited list:

```
session_name|attached(0/1)|window_count
```

This format is deliberately simple. No JSON, no binary protocol. A session file can be read with `cat`, parsed with `awk`, debugged with `less`. The complexity budget is spent elsewhere.

## The Mesh Protocol

When a tmux session is created or destroyed on any node, a hook fires `mesh-announce.sh`. This script:

1. Reads `@host_name` from tmux config to identify itself
2. Dumps `tmux list-sessions` to `state/local.sessions`
3. For each peer in `fleet.conf` (excluding self): pushes the dump via SSH to `state/<myname>.sessions` on the remote

All pushes are backgrounded and disowned — fire and forget. SSH connections use `ConnectTimeout=2` and `BatchMode=yes`. A peer that's unreachable simply doesn't get updated.

On the reading side, `mesh-status.sh` iterates `fleet.conf`, reads each peer's state file, checks staleness (>300s = dead), and renders:

```
∴●2 ☰○1 ∞✕ ∇●1
  │  │    │    └─ nabla: 1 session, attached
  │  │    └────── karlsruhe: unreachable or stale
  │  └─────────── finml: 1 session, detached
  └────────────── hub2: 2 sessions, attached
```

The protocol is eventually consistent. There is no heartbeat — state propagates only on session events. A quiet node that doesn't create or destroy sessions may appear stale even though it's healthy. This is an acceptable trade-off: the status line reflects *activity*, not merely *reachability*.

## The Deploy Loop

`deploy.sh` closes the loop. [Full details →](../architecture/deploy-flow.md)

One command rsyncs the configuration tree to every node, writes a two-line `~/.tmux.conf` that sources base + host, and hot-reloads tmux. The fleet converges in seconds.

This is infrastructure as text. No containers, no orchestrators, no YAML. Shell scripts, SSH, rsync. The simplest tools that could possibly work — because the problem is simple: keep five terminal environments coherent and aware of each other.

---

*Previous: [∴ The Fleet](01-the-fleet.md) · Next: [🜂 The Interaction Modes](03-the-interaction-modes.md)*
