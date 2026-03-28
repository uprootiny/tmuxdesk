# tmuxdesk ∴ codex

Distributed terminal infrastructure across a 5-node fleet.

## Essays

Six interlinked essays on the system's design, philosophy, and operation.

| # | Sigil | Title | Subject |
|---|-------|-------|---------|
| 1 | ∴ | [The Fleet](essays/01-the-fleet.md) | Distributed identity and the naming of machines |
| 2 | ☰ | [The Architecture](essays/02-the-architecture.md) | Layered configuration and the mesh protocol |
| 3 | 🜂 | [The Interaction Modes](essays/03-the-interaction-modes.md) | Keybindings, sessions, and spatial arrangement |
| 4 | ∞ | [The Infrastructure](essays/04-the-infrastructure.md) | SSH mesh, deploy fabric, and the machines beneath |
| 5 | ∇ | [The Resource](essays/05-the-resource.md) | What runs where, and the orchestration of agents |
| 6 | ⊕ | [The Import](essays/06-the-import.md) | Why sigils, why terminals, why any of this |

## Architecture Reference

Technical documentation for operators and contributors.

| Document | Contents |
|----------|----------|
| [Config Layers](architecture/config-layers.md) | The three-layer configuration model |
| [Mesh Protocol](architecture/mesh-protocol.md) | Session state propagation and consistency model |
| [Deploy Flow](architecture/deploy-flow.md) | How deploy.sh converges the fleet |
| [Adding Nodes](architecture/adding-nodes.md) | Step-by-step runbook for fleet expansion |
| [Keybinding Map](architecture/keybinding-map.md) | Complete keybinding reference with mnemonics |

## The Fleet

```
          🜂 hyle
         ╱  |  ╲
        ╱   |   ╲
  ∴ hub2 ─── ☰ finml ─── ∇ nabla
        ╲   |   ╱
         ╲  |  ╱
          ∞ karlsruhe
```

| Sigil | Node | IP | Role |
|-------|------|----|------|
| 🜂 | hyle | 173.212.203.211 | Creative fire — primary ops |
| ∴ | hub2 | 149.102.137.139 | Coordination — repos, deploy |
| ☰ | finml | 5.189.145.105 | Pattern — ML, finance compute |
| ∞ | karlsruhe | 45.90.121.59 | Pure — NixOS, reproducibility |
| ∇ | nabla | 35.252.20.194 | Gradient — GCP elastic compute |

## Web View

The essays are also available as an interactive ClojureScript app:

```bash
cd web && npm run dev    # development with hot reload
cd web && npm run build  # production build → public/js/main.js
```

Serve `web/public/` with any static file server.
