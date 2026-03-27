<p align="center">
  <br>
  <strong><code>🜂 ∴ ☰ ∞ ∇</code></strong>
  <br><br>
</p>

<h1 align="center">tmuxdesk</h1>

<p align="center">
  <em>distributed terminal infrastructure for a 5-node fleet</em>
  <br>
  <strong>sigil-addressed &middot; mesh-aware &middot; self-deploying</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/nodes-5-5588cc?style=flat-square" alt="5 nodes">
  <img src="https://img.shields.io/badge/tmux-3.2%E2%80%933.5-44aa88?style=flat-square" alt="tmux 3.2-3.5">
  <img src="https://img.shields.io/badge/web_ui-ClojureScript-cc8844?style=flat-square" alt="ClojureScript">
  <img src="https://img.shields.io/badge/deploy-rsync+ssh-707088?style=flat-square" alt="rsync+ssh">
</p>

---

```
🜂●3 ∴●2 ☰○1 ∞✕ ∇●1
```

Five servers. Five Unicode sigils. One tmux configuration that deploys itself across the fleet, propagates session state through a mesh protocol, and renders the whole topology in fifteen characters at the bottom of your terminal.

## The Fleet

```
            🜂 hyle
           ╱  │  ╲
          ╱   │   ╲
    ∴ hub2 ── ☰ finml ── ∇ nabla
          ╲   │   ╱
           ╲  │  ╱
            ∞ karlsruhe
```

| Sigil | Node | Role | Tradition |
|:-----:|------|------|-----------|
| 🜂 | **hyle** | Creative fire &mdash; primary ops, session persistence | Alchemical Symbols (U+1F700) |
| ∴ | **hub2** | Coordination &mdash; repos, deploys, fleet state | Mathematical logic |
| ☰ | **finml** | Pattern &mdash; ML training, financial compute | I Ching heaven trigram, ~1000 BCE |
| ∞ | **karlsruhe** | Pure &mdash; NixOS, deterministic builds | John Wallis, 1655 |
| ∇ | **nabla** | Gradient &mdash; GCP elastic compute | Hamilton's nabla, 1837 |

Each sigil encodes *character*: not where a machine lives, but what it *does* in the topology. You look at your status line and read the fleet like a sentence.

## Architecture

Three layers, strictly composed:

```
┌─────────────────────────────────────────────────────┐
│  Layer 3: Runtime State                             │
│  state/*.sessions — mesh-propagated, ephemeral      │
├─────────────────────────────────────────────────────┤
│  Layer 2: Per-Host                                  │
│  conf/host-<name>.conf — extends base via set -ga   │
│                                                     │
│  🜂 hyle       TPM + resurrect + continuum          │
│  ∴ hub2       git branch status, 3s refresh         │
│  ☰ finml      GPU utilization, load average         │
│  ∞ karlsruhe  NixOS generation, nix store count     │
│  ∇ nabla      GCP zone from metadata API            │
├─────────────────────────────────────────────────────┤
│  Layer 1: Base                                      │
│  conf/tmux.base.conf — invariants across all nodes  │
│                                                     │
│  256-color • 200k history • vi mode • 1-indexed     │
│  session logging • pane navigation • mesh hooks     │
│  fuzzy session/pane jumper • layout cycling          │
│  preset picker • fleet health popup                 │
└─────────────────────────────────────────────────────┘
```

**Key design choice:** host configs use `set -ga` (append) not `set -g` (replace). The status line composes left-to-right: base segments first, then host-specific segments. Host configs *extend* the base &mdash; they never contradict it.

## Keybindings

All bindings work identically on every node.

| Binding | Action |
|---------|--------|
| `Prefix + h/j/k/l` | Navigate panes (vi-style) |
| `Prefix + H/J/K/L` | Resize panes |
| `Prefix + \|` | Split horizontal |
| `Prefix + -` | Split vertical |
| `Prefix + f` | Fuzzy session/pane jumper (fzf) |
| `Prefix + s` | Session tree |
| `Prefix + S` | Create/attach session by name |
| `Prefix + P` | Preset picker (fzf) |
| `Prefix + F` | Fleet health dashboard |
| `Prefix + Tab` | Cycle layout forward |
| `Prefix + L` | Cycle layout backward |
| `Prefix + m` | Toggle mouse |
| `Prefix + r` | Reload config |

## Mesh Protocol

Session state propagates across the fleet via `mesh-announce.sh`, fired on tmux `session-created` and `session-closed` hooks.

```
┌──────────┐  ssh fire-and-forget  ┌──────────┐
│ 🜂 hyle   │ ───────────────────▶ │ ∴ hub2   │
│           │                      │          │
│ state/    │ ◀─────────────────── │ state/   │
│  hub2.s   │                      │  hyle.s  │
│  finml.s  │   (all nodes push    │  finml.s │
│  ...      │    to all peers)     │  ...     │
└──────────┘                      └──────────┘
```

Each node writes its session list to `state/local.sessions`, then pushes it to every peer as `state/<hostname>.sessions`. The status bar reads all state files to render the fleet-wide `🜂●3 ∴●2 ☰○1` summary.

State is eventually consistent, fire-and-forget, and ephemeral. The `state/` directory is never deployed &mdash; it exists only at runtime.

## Deploy

One script. One command. Full fleet convergence.

```bash
./deploy.sh                     # deploy to all nodes
./deploy.sh hyle nabla          # deploy to specific nodes
./deploy.sh --dry-run           # preview without changes
```

`deploy.sh` does:
1. `rsync` the repo to `~/.tmux/tmuxdesk/` on each target
2. Write `~/.tmux.conf` sourcing `base + host-<name>.conf`
3. `chmod +x` all scripts
4. `tmux source-file` to hot-reload (if tmux is running)

Adding a new node: add a line to `fleet.conf`, create `conf/host-<name>.conf`, run `deploy.sh <name>`.

```
# fleet.conf
# name       ssh_alias    sigil  ip
hyle         hyle         🜂      173.212.203.211
hub2         hub2         ∴      149.102.137.139
finml        finml        ☰      5.189.145.105
karlsruhe    karlsruhe    ∞      45.90.121.59
nabla        nabla        ∇      35.252.20.194
```

## Presets

Pre-built window layouts launched via `Prefix + P`:

| Preset | Layout |
|--------|--------|
| `dev-3pane` | Editor top, two shells bottom |
| `monitor-4pane` | Quad-split monitoring grid |
| `pair-2pane` | Side-by-side pairing |

## Fuzzy Jumper

`Prefix + f` opens a full-screen fzf popup that indexes every session and pane across the local tmux server:

- Live preview of pane contents (last 120 lines)
- Session age, window count, attached state
- Pane working directory, running command, last output line
- `Ctrl-R` to refresh without closing

## iTerm Integration

tmuxdesk pairs with iTerm2 Dynamic Profiles for native macOS integration:

- **`tmux -CC`** mode: remote tmux windows become native iTerm tabs
- **Per-host color themes**: each server has a distinct visual identity that carries through to every breakout window
- **Reconnection**: gateway profiles auto-reconnect on SSH disconnect
- **Session picker**: fzf-powered session selection per host

| Profile | Theme | Sigil |
|---------|-------|:-----:|
| hyle | Steel blue | 🜂 |
| finml | Warm amber | ☰ |
| hub2 | Forest green | ∴ |
| karlsruhe | Soft violet | ∞ |
| nabla | Ocean teal | ∇ |

## Web Codex

An interactive ClojureScript (Reagent) app that renders the six essays on the system's design and philosophy, with a live constellation map and simulated fleet state.

```bash
cd web && npm run dev      # development with hot reload
cd web && npm run build    # production → public/js/main.js
```

### The Essays

| # | Sigil | Title | Subject |
|---|:-----:|-------|---------|
| 1 | ∴ | The Fleet | Distributed identity and the naming of machines |
| 2 | ☰ | The Architecture | Layered configuration and the mesh protocol |
| 3 | 🜂 | The Interaction Modes | Keybindings, sessions, and spatial arrangement |
| 4 | ∞ | The Infrastructure | SSH mesh, deploy fabric, the machines beneath |
| 5 | ∇ | The Resource | What runs where, orchestration of agents |
| 6 | ⊕ | The Import | Why sigils, why terminals, why any of this |

## File Structure

```
tmuxdesk/
├── fleet.conf                    # node definitions
├── deploy.sh                     # fleet-wide deployment
├── conf/
│   ├── tmux.base.conf            # Layer 1: shared invariants
│   ├── host-hyle.conf            # Layer 2: per-host overrides
│   ├── host-hub2.conf
│   ├── host-finml.conf
│   ├── host-karlsruhe.conf
│   └── host-nabla.conf
├── bin/
│   ├── fleet-health.sh           # Prefix+F dashboard
│   ├── fuzzy-session-pane.sh     # Prefix+f jumper
│   ├── layout-cycle.sh           # Prefix+Tab/L
│   ├── mesh-announce.sh          # session state propagation
│   ├── mesh-status.sh            # fleet status line renderer
│   ├── session-ensure.sh         # Prefix+S create-or-attach
│   └── sigil-status.sh           # sigil rendering helper
├── presets/
│   ├── dev-3pane.sh
│   ├── monitor-4pane.sh
│   └── pair-2pane.sh
├── state/                        # runtime only, never deployed
│   ├── local.sessions
│   └── <peer>.sessions
├── web/                          # ClojureScript codex app
│   ├── shadow-cljs.edn
│   ├── src/tmuxdesk/
│   │   ├── core.cljs
│   │   ├── essays.cljs
│   │   └── sigils.cljs
│   └── public/
│       ├── index.html
│       ├── css/style.css
│       └── js/main.js
└── docs/
    ├── index.md
    ├── essays/                   # 6 interlinked essays
    └── architecture/             # technical reference
```

## Requirements

- tmux 3.2+ (tested on 3.2a through 3.5a)
- bash 4+ / zsh
- fzf (optional, graceful degradation to `choose-tree`)
- SSH access between all fleet nodes
- Node.js + shadow-cljs (web codex only)

## Philosophy

Terminals are not primitive. They are the most information-dense, lowest-latency interface available. A single status line can encode more fleet state than a dashboard full of charts &mdash; if the symbology is right.

tmuxdesk treats the terminal as a *first-class distributed system interface*. Sigils are not decoration; they are an addressing scheme drawn from traditions that have been compressing meaning into glyphs for millennia.

---

<p align="center">
  <code>🜂 ∴ ☰ ∞ ∇</code>
  <br>
  <em>distributed terminal infrastructure</em>
</p>
