# Deploy Flow Reference

## Command

```bash
./deploy.sh [--dry-run] [node1] [node2] ...
```

- No arguments: deploy to all nodes in `fleet.conf`
- Named arguments: deploy to matching nodes only
- `--dry-run`: preview actions without executing

## Sequence per Node

```
deploy_node(name, alias)
│
├── 1. SSH: mkdir -p ~/.tmux/tmuxdesk/{bin,conf,presets,state}
│       └── ConnectTimeout=5, BatchMode=yes
│       └── Failure → skip node, increment failed count
│
├── 2. rsync -avz --delete
│       ├── Source: $REPO_DIR/
│       ├── Dest: $alias:~/.tmux/tmuxdesk/
│       ├── Excludes: .git, state/*, .claude/, .gitignore
│       └── --delete ensures remote mirrors source
│
├── 3. SSH: write ~/.tmux.conf
│       ├── source-file ~/.tmux/tmuxdesk/conf/tmux.base.conf
│       └── source-file ~/.tmux/tmuxdesk/conf/host-${name}.conf
│
├── 4. SSH: chmod +x bin/*.sh presets/*.sh
│
└── 5. SSH: tmux source-file ~/.tmux.conf
        └── Succeeds silently if tmux running
        └── Reports "tmux not running" otherwise
```

## What Gets Deployed

```
~/.tmux/tmuxdesk/
├── bin/                    # all scripts
├── conf/                   # all configs (base + all hosts)
├── presets/                # all presets
├── state/                  # empty (excluded from sync, created by mkdir)
├── deploy.sh              # the script itself
└── fleet.conf             # fleet definition
```

Note: every node receives *all* host configs, not just its own. This is intentional — it simplifies rsync and lets you inspect any node's config from any other node.

## The Two-Line tmux.conf

After rsync, the script writes:

```tmux
# Managed by tmuxdesk — do not edit directly
source-file ~/.tmux/tmuxdesk/conf/tmux.base.conf
source-file ~/.tmux/tmuxdesk/conf/host-${name}.conf
```

This is the *only* file written outside `~/.tmux/tmuxdesk/`. It's the bootstrap that connects the system tmux config to the managed configuration tree.

## Dry Run

With `--dry-run`, the script prints what it would do without executing:

```
=== Deploying to hyle (hyle) ===
  [dry-run] rsync /path/to/tmuxdesk/ → hyle:~/.tmux/tmuxdesk/
  [dry-run] write ~/.tmux.conf sourcing base + host-hyle.conf
```

## Exit Behavior

- Deploys all targeted nodes even if some fail
- Reports total nodes targeted and total failures
- Exit code 0 regardless (failures are logged, not fatal)
