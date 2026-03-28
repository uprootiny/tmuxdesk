# ∴ The Fleet

*On distributed identity and the naming of machines*

---

Five nodes scattered across European data centres and one cloud region, each carrying a Unicode sigil as its true name. Not hostnames — those are arbitrary strings assigned by providers. The sigils encode *character*: what each machine *does* in the topology, rendered in a tradition older than computing itself.

## The Nodes

**[🜂 hyle](02-the-architecture.md)** bears the alchemical sign for fire. It is the primary creative node — where sessions ignite, where drafts begin, where the most volatile work happens. Fire transforms; hyle is where raw material becomes artifact.

**[∴ hub2](04-the-infrastructure.md)** carries the therefore-sign from mathematical logic. A conclusion follows its premises: hub2 hosts repositories, coordinates deploys, draws inferences from the state of the fleet. If hyle is the forge, hub2 is the ledger.

**[☰ finml](05-the-resource.md)** is marked with the heaven trigram from the I Ching — three unbroken yang lines, the creative principle in its purest form. Fitting for a machine that reads patterns in financial data and trains models to divine structure from noise. The oracle computes.

**[∞ karlsruhe](04-the-infrastructure.md)** wears the lemniscate. Running NixOS, every build is a fixed point in an infinite series. Nothing drifts. The system profile is a mathematical object: given the same inputs, you get the same machine. Infinity through determinism.

**[∇ nabla](05-the-resource.md)** takes the del operator — the gradient. A GCP instance, ephemeral by nature, its purpose is descent: toward the minimum of some loss function, toward the solution of some problem that needs cloud-scale compute for a bounded time. It appears, differentiates, and dissolves.

## The Constellation

Together they form not a cluster but a *constellation* — each node visible to the others through the [mesh protocol](02-the-architecture.md), each identifiable at a glance by its glyph in the status line. The fleet is legible. You look at the bottom of your terminal and see:

```
🜂●3 ∴●2 ☰○1 ∞✕ ∇●1
```

Three sentences of state compressed into fifteen characters.

| Sigil | Node | Role | Tradition |
|-------|------|------|-----------|
| 🜂 | hyle | creative fire | Alchemical Symbols (U+1F700) |
| ∴ | hub2 | coordination | Mathematical Logic |
| ☰ | finml | pattern/ML | I Ching (Yijing), ~1000 BCE |
| ∞ | karlsruhe | pure/NixOS | John Wallis, 1655 |
| ∇ | nabla | GCP compute | Hamilton's nabla, 1837 |

---

*Next: [☰ The Architecture](02-the-architecture.md)*
