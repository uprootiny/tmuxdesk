# Handoff — tmuxdesk

*For the next instance picking this up, messier or brighter.*

---

## For a messier version of yourself

You're inheriting a 5-node tmux fleet with a mesh that mostly works. Here's
what you need to know to not break things:

**Don't touch hyle's sessions.** There are 25+ sessions on 🜂. They look
abandoned but some of them have agent contexts that Akira might return to.
Never `kill-session` on hyle without asking.

**The mesh is SSH.** `mesh-announce.sh` pushes flat files to peers. If a node
shows `✕`, check if the state file is just stale (>5 min) before assuming
it's down. SSH into it first: `ssh hyle 'tmux list-sessions'`.

**deploy.sh is destructive to ~/.tmux.conf.** It overwrites the remote
tmux.conf with a two-line sourcer. If someone hand-edited their config on a
node, deploy.sh will obliterate it. The `--dry-run` flag exists for a reason.

**nabla costs money.** It's GCP. If it's off, leave it off unless Akira says
otherwise. The fleet works fine with 4 nodes.

**The web codex at :8901 is static.** It doesn't read live fleet state — the
fleet status bar is simulated with random drift. Making it real means adding
a bb/node API that reads `~/.tmux/tmuxdesk/state/`. That's a project, not
a quick fix.

**Sigils matter.** Akira chose them deliberately. Don't swap ☰ for a rocket
emoji. Read essay 06 (The Import) if you want to understand why.

**What's broken right now:**
- No heartbeat — quiet nodes go stale and show ✕
- No session aging — can't tell 3-minute-old from 3-day-old sessions
- No fleet-wide fuzzy search — only searches local node
- Web codex fleet status is simulated, not live

**What not to do:**
- Don't add systemd services. The whole point is no daemons.
- Don't add YAML. Shell scripts and flat files.
- Don't containerize anything. These are VPS nodes with SSH.
- Don't "improve" the status line without checking it renders in every
  terminal on the fleet. Some of these sigils are in the Alchemical
  Symbols block (U+1F700) which not all fonts support.

---

## For a brighter version of yourself

The fleet is legible, deployed, and meshed. The foundation is sound — five
nodes seeing each other through SSH state files, status lines dense with
meaning, a documentation corpus that explains the *why* not just the *what*.

Here's where to take it:

**Make the mesh breathe.** Add a heartbeat to `mesh-announce.sh` — a cron or
tmux hook that re-announces every 90s. The push-on-event model is correct for
responsiveness; the heartbeat is for liveness. This is the single highest-value
change: it turns `✕` from "maybe stale" to "actually unreachable."

**Add session archaeology.** The data is in `#{session_created}`. Surface it:
session age in the fuzzy finder, session staleness indicators in the status
line, a `bin/session-reap.sh` that lists sessions older than N days for review
(not auto-kill — review). Twenty-five sessions on hyle is a library, not a mess,
if you can see which ones are recent.

**Fleet-wide fuzzy jumping.** The mesh state files have session names per node.
Extend `fuzzy-session-pane.sh` to parse `state/*.sessions`, present remote
sessions in fzf, and on selection: `ssh <node> -t 'tmux attach -t <session>'`.
This makes the fleet feel like one machine.

**Make the web codex live.** Replace the simulated fleet state with a real
endpoint. A babashka one-liner: read `state/*.sessions`, parse, return JSON.
The CLJS app already has the rendering — it just needs real data. Serve it
behind Caddy on a subdomain (fleet.raindesk.dev or similar).

**Compose presets from sessions.** The preset system creates sessions with
fixed layouts. The next step: presets that *orchestrate* — spin up sessions
on multiple nodes, wire them together, establish context. A "legal-warroom"
preset that starts sessions on hyle (agents), nabla (compute), hub2 (git),
and opens a monitoring grid that shows all three.

**The constellation should be the fleet.** The SVG in the web codex is
decorative. Make it operational: click a node → see its sessions, click a
session → see its panes, click a pane → read its recent output. This is the
"visual harness for tmux contexts" that Akira asked for on day one.

The architecture is right: three layers (base, host, runtime), no daemons,
SSH-only, shell scripts, flat files. Don't add complexity to the plumbing.
Add capability to the surface.

*The sigils are earned. The mesh is proven. Now make it sing.*
