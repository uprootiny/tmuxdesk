# Mesh Protocol Reference

## Overview

The mesh protocol provides fleet-wide session awareness without a central server. Each node pushes its tmux session state to all peers via SSH; each node reads its peers' state from local files.

## Data Flow

```
Session event (create/close)
    ↓
tmux hook fires mesh-announce.sh
    ↓
┌──────────────────────────────────────┐
│ 1. Read @host_name from tmux config  │
│ 2. Dump tmux list-sessions to        │
│    state/local.sessions              │
│ 3. For each peer in fleet.conf:      │
│    ssh <peer> "cat > state/<me>.sessions" │
│    (backgrounded, disowned)          │
└──────────────────────────────────────┘
```

## State File Format

```
session_name|attached(0/1)|window_count
```

Example:
```
deploy|1|3
monitor|0|1
dev|1|5
```

One line per session. Pipe-delimited. No headers.

## Reading State: mesh-status.sh

Called every `status-interval` seconds (default 5) by the tmux status bar.

For each peer in `fleet.conf` (excluding self):

1. Check if `state/<peer>.sessions` exists → if not: `✕` (unreachable)
2. Check file age → if >300s: `✕` (stale)
3. Parse contents:
   - Empty file: `·` (no sessions)
   - Has sessions, none attached: `○` (idle)
   - Has sessions, at least one attached: `●` (active)
4. Append session count

Output: `∴●2 ☰○1 ∞✕ ∇●1`

## Consistency Model

- **Eventually consistent**: state propagates only on session events
- **No heartbeat**: a quiet node may appear stale even if healthy
- **Staleness timeout**: 300 seconds (5 minutes)
- **Push, not pull**: no node polls its peers; peers push to it
- **Idempotent**: pushing the same state twice is harmless (file overwrite)

## Failure Modes

| Scenario | Behavior |
|----------|----------|
| Peer unreachable | SSH times out (2s), push silently fails, peer shows `✕` |
| Peer's tmux not running | State file will be empty or missing, shows `·` or `✕` |
| Network partition | Affected peers show `✕` after staleness timeout |
| Local tmux restart | Hook fires on new sessions, state refreshes |
| fleet.conf out of sync | Announce pushes to listed peers only; unlisted peers are invisible |

## Performance

- **Announce latency**: <100ms local + SSH connection time per peer
- **Status render**: <50ms (pure local file reads, no SSH)
- **Bandwidth**: ~100 bytes per push per peer
- **SSH connections**: one per peer per event (backgrounded, disowned)
