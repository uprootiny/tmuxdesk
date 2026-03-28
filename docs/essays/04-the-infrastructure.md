# ∞ The Infrastructure

*SSH mesh, deploy fabric, and the machines beneath*

---

The physical topology is simple. Four permanent nodes on European VPS providers plus one ephemeral GCP instance. All run Ubuntu except [∞ karlsruhe](01-the-fleet.md) on NixOS. All reachable from each other over the public internet via SSH with ed25519 keys.

## The Machines

| Node | Provider | Region | OS | RAM | Purpose |
|------|----------|--------|----|-----|---------|
| 🜂 hyle | Contabo | Nuremberg | Ubuntu | — | Creative ops, agents |
| ∴ hub2 | Contabo | Düsseldorf | Ubuntu | — | Repos, coordination |
| ☰ finml | Contabo | Nuremberg | Ubuntu | — | ML, finance compute |
| ∞ karlsruhe | Netcup | Karlsruhe | NixOS | — | Reproducible builds |
| ∇ nabla | GCP | europe-west2 | Ubuntu 25.10 | — | Elastic compute |

The permanent nodes are commodity VPS instances. Nothing exotic. The value is in the *configuration* applied to them and the *mesh* connecting them, not the hardware.

## The SSH Mesh

Every node's `~/.ssh/config` defines aliases for every peer:

```ssh-config
Host hyle
    HostName 173.212.203.211
    User uprootiny
    IdentityFile ~/.ssh/fleet_key
    StrictHostKeyChecking accept-new

Host nabla
    HostName 35.252.20.194
    User uprootiny
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
```

This alias layer means `fleet.conf` and `mesh-announce.sh` refer to nodes by name. No IP addresses in application code. No connection strings assembled at runtime. `ssh hub2` just works.

The mesh is fully connected: every node can reach every other. This is required for `mesh-announce.sh` to push state to all peers. The key distribution is manual — when adding a node, you authorize its key on every peer. This is deliberate: the fleet is small enough that manual key management is simpler and more auditable than any automated PKI.

## The Deploy Script

`deploy.sh` is the single entry point for fleet convergence. [Full technical reference →](../architecture/deploy-flow.md)

```bash
./deploy.sh              # deploy to all nodes
./deploy.sh hub2 nabla   # deploy to specific nodes
./deploy.sh --dry-run    # preview without touching anything
```

For each target node, the script:

1. Creates the remote directory structure via SSH
2. Rsyncs the repo with `--delete` (remote mirrors source, excluding `.git` and `state/`)
3. Writes a two-line `~/.tmux.conf` sourcing base + host config
4. `chmod +x` all scripts
5. Reloads tmux if it's running

The remote always converges to match the source. No partial states, no manual intervention.

## Adding a New Node

The ritual for extending the fleet. [Full runbook →](../architecture/adding-nodes.md)

1. **Key exchange**: add the new node's SSH public key to `~/.ssh/authorized_keys` on every existing peer, and add each peer's key to the new node.

2. **SSH alias**: add a `Host` block to `~/.ssh/config` on each node. Name it. Give it an identity file.

3. **Fleet registration**: add a line to `fleet.conf`:
   ```
   nabla    nabla    ∇    35.252.20.194
   ```
   Name, SSH alias, sigil, IP. Choose a sigil from the alchemical, mathematical, or eastern Unicode blocks.

4. **Host config**: create `conf/host-nabla.conf`:
   ```tmux
   set -g @host_sigil "∇"
   set -g @host_name "nabla"
   # host-specific status segments...
   ```

5. **Deploy**: `./deploy.sh`. The new node joins the constellation. Its sigil appears in every other node's status bar within one mesh cycle.

There is no registration server, no discovery protocol. The fleet is defined by a flat file and propagated by rsync.

## NixOS: The Special Case

[∞ karlsruhe](01-the-fleet.md) runs NixOS. The system configuration is a Nix expression — a pure function from inputs to machine state. The host config shows the current generation number in the status line via `∂`, a rolling counter of how many times the system has been rebuilt.

Generation 847 means 847 atomic transitions from one well-defined state to another. No imperative drift. No `apt-get` that leaves the system in an undefined intermediate state. The lemniscate is earned.

The tmuxdesk deploy to karlsruhe works identically to other nodes — rsync + source-file. The NixOS configuration is managed separately; tmuxdesk doesn't touch it. Two orthogonal systems: Nix manages the *machine*, tmuxdesk manages the *terminal layer*.

---

*Previous: [🜂 The Interaction Modes](03-the-interaction-modes.md) · Next: [∇ The Resource](05-the-resource.md)*
