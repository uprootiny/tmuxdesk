# ∇ The Resource

*What runs where, and the orchestration of agents*

---

Each node has a vocation.

## 🜂 hyle — The Forge

[Hyle](01-the-fleet.md) runs the creative workloads: art generation, draft documents, experimental code. It's where Claude, Codex, and Gemini sessions spawn in parallel tmux windows — each agent in its own pane, each conversation a separate thread of thought.

The `dev-3pane` preset is hyle's natural habitat: editor left, terminal top-right, agent output bottom-right. Three agents on the same problem means three perspectives on the same code, three drafts of the same document. The [fuzzy jumper](03-the-interaction-modes.md) lets you hop between them instantly.

Hyle also runs TPM with tmux-resurrect and tmux-continuum. Sessions persist across reboots. If the machine restarts at 3 AM, your agent sessions are restored at 3:01 AM with their pane contents intact. The forge never goes cold.

## ∴ hub2 — The Ledger

Hub2 coordinates. It hosts the git repositories, runs the deploy script, holds the source of truth. When work on hyle or finml produces artifacts, they flow back to hub2 for integration.

Its status line shows the current git branch of the tmuxdesk repo itself — a self-referential touch: the configuration system displays its own version. Hub2's status interval is 3 seconds instead of the default 5, because coordination demands fresher data.

## ☰ finml — The Oracle

The compute node. Financial data analysis, model training, batch jobs that benefit from dedicated resources. Its status line shows GPU utilization and temperature when `nvidia-smi` is available (`⊿ 78% 62°C`), or load average (`λ 2.34`) as a fallback.

The `monitor-4pane` preset is finml's mode: four terminals tiled, each watching a different metric. Training loss in one pane, GPU stats in another, system load in the third, log output in the fourth.

## ∞ karlsruhe — The Archive

The NixOS node serves as the reproducible environment. Experiments that must be bit-for-bit repeatable run here. The Nix store is the laboratory notebook — every dependency versioned, every build derivation recorded.

Its status line shows the generation number (`∂ 847`) and profile count (`∫ 12p`). These are the vital signs of a NixOS system: how many times it's been rebuilt, how many profiles are maintained.

## ∇ nabla — The Gradient

The newest addition. A GCP instance, born from a timestamp (`instance-20260314-013434`), its role is elastic compute: problems that need more resources than the permanent fleet offers.

It reports its GCP zone and load in the status line. Unlike the others, nabla is designed to be *ephemeral* — spun up for a task, torn down after. The gradient descends, finds its minimum, and the instance stops.

## The Multi-Agent Pattern

The central workflow across the fleet:

```
┌─────────────────────────────────────────────────┐
│ 🜂 hyle                                         │
│ ┌─────────────┬──────────────┬─────────────────┐│
│ │             │  Claude      │  Codex          ││
│ │   editor    │  session     │  session        ││
│ │             │              │                 ││
│ │             ├──────────────┤                 ││
│ │             │  Gemini      │                 ││
│ │             │  session     │                 ││
│ └─────────────┴──────────────┴─────────────────┘│
│ status: 🜂●3 ∴●2 ☰○1 ∞✕ ∇●1                    │
└─────────────────────────────────────────────────┘
```

Three AI agents on the same problem. Switch between them with `Prefix+f`, see their output side-by-side, compare approaches. The mesh status bar tells you what else is running across the fleet — if you see `☰○1` you know finml has a detached session, probably a training job, unattended.

This is not a Kubernetes cluster or a job scheduler. It's a *workshop* — five benches, each with its own tools, all visible from anywhere in the room.

---

*Previous: [∞ The Infrastructure](04-the-infrastructure.md) · Next: [⊕ The Import](06-the-import.md)*
