# Adding a Node to the Fleet

## Prerequisites

- SSH access to the new node as `uprootiny`
- An ed25519 keypair on the new node (or one you can deploy)
- A sigil chosen from alchemical, mathematical, or eastern Unicode blocks
- A short name (lowercase, no spaces)

## Step-by-Step

### 1. Key Exchange

The mesh requires full SSH connectivity: every node must reach every other.

**On the new node**, get its public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

**On each existing peer**, authorize the new node:
```bash
echo "<new-node-pubkey>" >> ~/.ssh/authorized_keys
```

**On the new node**, authorize each existing peer:
```bash
# Collect from each peer
ssh hyle 'cat ~/.ssh/id_ed25519.pub' >> ~/.ssh/authorized_keys
ssh hub2 'cat ~/.ssh/id_ed25519.pub' >> ~/.ssh/authorized_keys
# ... etc
```

Or if deploying from a machine that already has access to all peers, you can script this. The key is: every node's `authorized_keys` contains every other node's public key.

### 2. SSH Alias

**On every node** (including the new one), add to `~/.ssh/config`:

```ssh-config
Host <name>
    HostName <ip>
    User uprootiny
    IdentityFile ~/.ssh/id_ed25519
    IdentityFile ~/.ssh/fleet_key
    StrictHostKeyChecking accept-new
```

Verify: `ssh <name> hostname` should work from every peer.

### 3. Fleet Registration

Add a line to `fleet.conf`:

```
<name>    <ssh-alias>    <sigil>    <ip>
```

Example:
```
nabla    nabla    ∇    35.252.20.194
```

### 4. Host Config

Create `conf/host-<name>.conf`:

```tmux
# <name> — <sigil> <description>
set -g @host_sigil "<sigil>"
set -g @host_name "<name>"

# Optional: host-specific status segments
set -ga status-right ' #[fg=colour244]│ #[fg=colour109]λ #(awk "{printf \"%%s\", \$1}" /proc/loadavg)'
```

The minimum viable host config is just `@host_sigil` and `@host_name`. Everything else is optional enrichment.

### 5. Deploy

```bash
./deploy.sh                  # full fleet (updates fleet.conf everywhere)
# or
./deploy.sh <name>           # just the new node
./deploy.sh <name> hub2 ...  # new node + peers that need updated fleet.conf
```

### 6. Verify

```bash
# On the new node:
ssh <name> '~/.tmux/tmuxdesk/bin/sigil-status.sh'
# Should output: <sigil>●1 (or similar)

# On any existing peer:
ssh hub2 '~/.tmux/tmuxdesk/bin/mesh-status.sh'
# Should include <sigil>✕ (no state yet) or <sigil>●N
```

The new node will show `✕` for peers until a session event triggers mesh-announce on those peers. Start a tmux session on any peer (or run `mesh-announce.sh` manually) to propagate state.

## Choosing a Sigil

Draw from these Unicode blocks:

| Block | Range | Examples |
|-------|-------|----------|
| Alchemical Symbols | U+1F700–1F77F | 🜂 🜄 🜁 🜃 🝆 🝊 |
| Mathematical Operators | U+2200–22FF | ∴ ∵ ∇ ∂ ∮ ⊕ ⊗ |
| CJK / I Ching | U+4DC0–4DFF | ☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷ |
| Miscellaneous Mathematical | U+27C0–27EF | ⟁ ⟐ ⟟ |
| Letterlike Symbols | U+2100–214F | ℵ ℘ ℑ ℜ |

The sigil should render correctly in your terminal emulator (test with `echo`). Avoid emoji — they're variable-width and render inconsistently. Prefer single-codepoint symbols that occupy one cell.

## Removing a Node

1. Remove its line from `fleet.conf`
2. Delete `conf/host-<name>.conf`
3. Deploy: `./deploy.sh`
4. Optionally: remove state files on peers (`rm state/<name>.sessions` on each)
5. Optionally: remove SSH alias and authorized_keys entries
