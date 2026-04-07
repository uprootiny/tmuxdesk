# tmuxdesk

Distributed tmux configuration for a fleet of SSH servers. One deploy command gives you synchronized sessions, cross-node navigation, and a status line that shows your entire fleet at a glance.

```
🜂●3 ∴●2 ☰○1 ∞✕ ∇●1
```

Five servers. Five sigils. Fifteen characters of fleet state in your terminal.

## Quick start

**Prerequisites:** tmux 3.2+, bash 4+, fzf (optional but recommended), SSH access between nodes.

### 1. Clone and configure

```bash
git clone https://github.com/uprootiny/tmuxdesk.git
cd tmuxdesk
```

Edit `fleet.conf` with your nodes:

```
# name       ssh_alias    sigil  ip
hyle         hyle         🜂      173.212.203.211
hub2         hub2         ∴      149.102.137.139
```

Each node needs a `conf/host-<name>.conf` file. Copy an existing one as a template.

### 2. Deploy

```bash
./deploy.sh              # all nodes
./deploy.sh hyle nabla   # specific nodes
./deploy.sh --dry-run    # preview what would happen
./deploy.sh --verify     # check fleet health without deploying
```

This validates configs, rsyncs to each node, writes `~/.tmux.conf`, and hot-reloads tmux. The `--verify` flag checks reachability, config presence, and sigil correctness across the fleet.

### 3. Start the heartbeat

On each node, add to crontab (`crontab -e`):

```
* * * * * ~/.tmux/tmuxdesk/bin/mesh-heartbeat.sh
* * * * * sleep 30 && ~/.tmux/tmuxdesk/bin/mesh-heartbeat.sh
```

Or run the loop directly (good for testing):

```bash
~/.tmux/tmuxdesk/bin/mesh-heartbeat-loop.sh &
```

That's it. Open tmux and your fleet status appears in the status bar.

## What you get

### Status bar

Your status line shows every node in the fleet:

| Symbol | Meaning |
|:------:|---------|
| `●` | Online, attached sessions |
| `○` | Online, no attached sessions |
| `◌` | Stale (1 missed heartbeat) |
| `✕` | Offline |

### Keybindings

| Key | What it does |
|-----|-------------|
| `Prefix + f` | **Fuzzy jumper** — search all sessions and panes (local + fleet) |
| `Prefix + G` | **Project search** — find repos across all nodes by name |
| `Prefix + F` | Fleet health dashboard (load, uptime, sessions) |
| `Prefix + B` | Broadcast a command to all nodes |
| `Prefix + P` | Pick a preset layout |
| `Prefix + S` | Create or switch to a named session |
| `Prefix + Tab` | Cycle layout forward |
| `Prefix + M-l` | Cycle layout backward |
| `Prefix + h/j/k/l` | Navigate panes (vi-style) |
| `Prefix + \|` | Split horizontal |
| `Prefix + -` | Split vertical |
| `Prefix + r` | Reload config |
| `Prefix + m` | Toggle mouse |

### Fuzzy jumper (`Prefix + f`)

Lists every session and pane across the entire fleet. Select a remote session and it opens an SSH window to that node. Local sessions switch instantly. Preview shows pane content.

### Project search (`Prefix + G`)

Finds git repos across all nodes. Shows branch, recent activity (commits/files in last 7 days), associated tmux sessions, and Claude Code session history. Actions:

- **Enter** — SSH to the project directory
- **Ctrl-S** — Attach to the tmux session
- **Ctrl-C** — Browse Claude Code history

### Presets (`Prefix + P`)

Pre-built window layouts:

| Preset | Layout |
|--------|--------|
| `dev-3pane` | Editor + terminal + logs |
| `pair-2pane` | Side-by-side |
| `monitor-4pane` | Quad monitoring grid |
| `agent-orchestra` | 3-pane AI agent workspace |
| `gpu-monitor` | nvidia-smi + htop + disk |
| `nix-workshop` | NixOS config + build + store |

## How it works

### Three layers

```
Layer 3: Runtime state — state/*.sessions, state/*.projects
         Ephemeral, mesh-propagated, never deployed.

Layer 2: Host config — conf/host-<name>.conf
         Per-node status segments (GPU, git branch, NixOS gen).
         Extends the base via set -ga (append, never override).

Layer 1: Base config — conf/tmux.base.conf
         Terminal settings, keybindings, status bar skeleton,
         mesh hooks, TPM/resurrect/continuum.
```

### Mesh protocol

When you create or close a tmux session, a hook fires `mesh-announce.sh`. It writes the local session list to `state/local.sessions` and pushes it to every peer via SSH. Each peer stores it as `state/<hostname>.sessions`.

The status bar reads these files every 5 seconds (no SSH, just local file reads) and renders the fleet summary.

**Staleness model:**

```
push every 30s → fresh < 60s → stale < 120s → offline
                   ●/○           ◌              ✕
```

State files older than 5 minutes are pruned automatically.

### Adding a node

1. Add a line to `fleet.conf`
2. Create `conf/host-<name>.conf` (copy from an existing one)
3. Run `./deploy.sh <name>`

### Removing a node

Delete its line from `fleet.conf` and its host config. Redeploy.

## The fleet

| Sigil | Node | Role |
|:-----:|------|------|
| 🜂 | hyle | Primary ops, session persistence |
| ∴ | hub2 | Coordination, repos, deploys |
| ☰ | finml | ML training, GPU compute |
| ∞ | karlsruhe | NixOS, deterministic builds |
| ∇ | nabla | GCP elastic compute |

## Optional extras

### Fleet status server (Rust)

A tiny HTTP server that serves mesh state as JSON. Useful for dashboards or the web codex.

```bash
cd fleet-status && cargo build --release
./target/release/fleet-status-server --bind 0.0.0.0:7600 --dir ~/.tmux/tmuxdesk
```

Endpoints: `/status` (full JSON), `/compact` (sigil string), `/projects`, `/health`.

### iTerm2 integration

Per-host color profiles for iTerm2 with `tmux -CC` gateway mode:

```bash
./iterm/install-profiles.sh
```

Each node gets a distinct color theme. Sessions appear as native iTerm tabs.

### Nix flake

```bash
nix develop                    # dev shell with tmux, fzf, rust
nix build .#fleet-status       # build the status server
```

Home-manager module:

```nix
programs.tmuxdesk = {
  enable = true;
  hostName = "karlsruhe";
  heartbeat.enable = true;     # systemd timer, 30s interval
};
```

NixOS module:

```nix
services.tmuxdesk-fleet-status = {
  enable = true;
  bind = "0.0.0.0:7600";
};
```

## File structure

```
tmuxdesk/
├── fleet.conf              # node definitions
├── deploy.sh               # fleet-wide deployment
├── conf/
│   ├── tmux.base.conf      # shared config (all nodes)
│   └── host-*.conf         # per-node overrides
├── bin/
│   ├── mesh-announce.sh    # push state to peers
│   ├── mesh-status.sh      # render fleet status bar
│   ├── mesh-heartbeat.sh   # periodic push + prune
│   ├── fuzzy-session-pane.sh  # Prefix+f jumper
│   ├── fleet-search.sh     # Prefix+G project search
│   ├── fleet-health.sh     # Prefix+F dashboard
│   ├── fleet-broadcast.sh  # Prefix+B run everywhere
│   ├── project-index.sh    # scan git repos for search
│   └── ...
├── presets/                 # window layout templates
├── fleet-status/            # Rust HTTP server
├── iterm/                   # iTerm2 profiles
├── web/                     # ClojureScript codex
└── flake.nix               # Nix packaging
```

## Requirements

- tmux 3.2+ (tested through 3.5a)
- bash 4+ on fleet nodes (macOS ships bash 3 — use Homebrew or Nix)
- fzf for fuzzy features (degrades gracefully without it)
- SSH key auth between all fleet nodes
- TPM (`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`)

## License

MIT
