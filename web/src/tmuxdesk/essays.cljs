(ns tmuxdesk.essays)

(def fleet-nodes
  [{:id :hyle    :sigil "🜂" :name "hyle"      :ip "173.212.203.211" :role "creative fire"
    :desc "Primary ops node. Alchemical fire — the prima materia from which all work ignites."}
   {:id :hub2    :sigil "∴"  :name "hub2"      :ip "149.102.137.139" :role "coordination"
    :desc "Repo host, logical hub. The therefore-sign — conclusions drawn, actions dispatched."}
   {:id :finml   :sigil "☰"  :name "finml"     :ip "5.189.145.105"   :role "pattern/ML"
    :desc "Finance and ML compute. Heaven trigram — reading patterns in data as in yarrow stalks."}
   {:id :karlsruhe :sigil "∞" :name "karlsruhe" :ip "45.90.121.59"  :role "pure/NixOS"
    :desc "NixOS node. The lemniscate — infinite reproducibility, builds that never drift."}
   {:id :nabla   :sigil "∇"  :name "nabla"     :ip "35.252.20.194"   :role "GCP compute"
    :desc "Cloud gradient. The del operator — differentiation, descent toward optimal."}])

(def essays
  [{:id :orchestratione
    :sigil "❦"
    :title "De Orchestratione"
    :subtitle "How the Manuscript Regardeth Its Own Making"
    :body
    [[:p "Audi, lector. This page, which thou readest as though it were a single "
      "voice, is in sooth a parliament. Many hands, many little monks — "
      [:em "monaculi, homunculi scribentes"] " — were sent forth into the "
      "scriptorium of the world, each with his errand, each with his slice of "
      "quire. One was dispatched to the herbal, one to the bestiary, one to the "
      "chronicle of kings, one to the margins where the drolleries live. Each "
      "returned bearing his findings as a pilgrim bringeth relics: wrapped, "
      "labelled, and of uncertain provenance."]
     [:p [:em "Nota bene:"] " the seam thou seekest is not hidden. It is here, "
      "and here, and here."]
     [:p "The illusion of the single illuminated page is the orchestrator's art. "
      [:em "Ecce theatrum:"] " the seam is concealed, the hand feigned continuous, "
      "the voice feigned whole. Yet the seam is there — " [:em "sutura invisibilis "
      "sed vera"] " — and an honest manuscript acknowledgeth its stitches. Better "
      "a visible thread than a lie of wholeness."]
     [:p "Reader, thou holdest in thy hands not a work but the residue of a "
      "procession. Forget not the procession when thou admirest the residue."]
     [:p [:strong "❦ Quattuor Instrumenta Concordiae ❦"]]
     [:p [:strong "I · Scaffoldum Prius"] " — The skeleton laid down before the "
      "scattering. A quire with slots already ruled, already titled. The monks "
      "fill the slots; they do not invent the page. " [:em "Forma praecedit materiam."]]
     [:p [:strong "II · Relatio Structurata"] " — Each monk reporteth in the same "
      "shape: what he was sent for, what he found, what he could not find, and how "
      "sure he is. A free-form report is a brawl waiting to happen. "
      [:em "Forma reditus disciplina est."]]
     [:p [:strong "III · Iudicium Ponderis"] " — Not every relic is the True Cross. "
      "The orchestrator weigheth each finding — its provenance, its corroboration, "
      "its plausibility — before granting it space upon the page. "
      [:em "Pondera, ne credas."]]
     [:p [:strong "IV · Sutura Honesta"] " — When the pieces are joined, the seam "
      "is not hidden but blessed. Mark where the dialect changeth; mark where one "
      "monk endeth and another beginneth. " [:em "Sutura visibilis, fides integra."]]
     [:p "Three perils attend the orchestrator. The first is "
      [:em "superabundantia monaculorum:"] " too many little monks, the orchestrator "
      "buried beneath findings he cannot weigh in his lifetime. The second is "
      [:em "consensus falsus:"] " agreement not because truth was found but because "
      "each monk read the others' returns over their shoulders."]
     [:p "The third peril, gravest of all, is " [:em "vox feigned"] " — the "
      "orchestrator stitching so smoothly that the reader forgetteth the parliament "
      "altogether and beginneth to believe a single oracle hath spoken. The page "
      "becometh idol; the monks become invisible; the seam, lost."]
     [:p "Where, in this parliament, is the author? The answer: the author is the "
      "one who chose the question, who set the scaffolding, who weighed the returns, "
      "and who blessed the seams. " [:em "Auctor est qui eligit."] " Look for the "
      "rhythm of choice, the recurrence of obsessions, the shape of the questions "
      "asked. There the author dwelleth, even when no sentence is hers."]
     [:p "Reader, when next thou holdest a page that speaketh with a single voice, "
      "ask: " [:strong "Quis misit?"] " — who dispatched the monks? "
      [:strong "Quis pondera tenuit?"] " — who held the scales? "
      [:strong "Ubi sunt suturae?"] " — where are the seams? Hold these three "
      "questions as the pilgrim holdeth her staff, and no manuscript shall pass "
      "thee unexamined."]]}

   {:id :fleet
    :sigil "∴"
    :title "The Fleet"
    :subtitle "On distributed identity and the naming of machines"
    :body
    [[:p "Five nodes scattered across European data centres and one cloud region, "
      "each carrying a Unicode sigil as its true name. Not hostnames — those are "
      "arbitrary strings assigned by providers. The sigils encode " [:em "character"] ": "
      "what each machine " [:em "does"] " in the topology, rendered in a tradition "
      "older than computing itself."]
     [:p [:sigil-link :hyle "🜂 hyle"] " bears the alchemical sign for fire. It is "
      "the primary creative node — where sessions ignite, where drafts begin, where "
      "the most volatile work happens. Fire transforms; hyle is where raw material "
      "becomes artifact."]
     [:p [:sigil-link :hub2 "∴ hub2"] " carries the therefore-sign from mathematical "
      "logic. A conclusion follows its premises: hub2 hosts repositories, coordinates "
      "deploys, draws inferences from the state of the fleet. If hyle is the forge, "
      "hub2 is the ledger."]
     [:p [:sigil-link :finml "☰ finml"] " is marked with the heaven trigram from the "
      "I Ching — three unbroken yang lines, the creative principle in its purest form. "
      "Fitting for a machine that reads patterns in financial data and trains models to "
      "divine structure from noise. The oracle computes."]
     [:p [:sigil-link :karlsruhe "∞ karlsruhe"] " wears the lemniscate. Running NixOS, "
      "every build is a fixed point in an infinite series. Nothing drifts. The system "
      "profile is a mathematical object: given the same inputs, you get the same machine. "
      "Infinity through determinism."]
     [:p [:sigil-link :nabla "∇ nabla"] " takes the del operator — the gradient. A GCP "
      "instance, ephemeral by nature, its purpose is descent: toward the minimum of some "
      "loss function, toward the solution of some problem that needs cloud-scale compute "
      "for a bounded time. It appears, differentiates, and dissolves."]
     [:p "Together they form not a cluster but a " [:em "constellation"] " — each node "
      "visible to the others through the " [:sigil-link :architecture "☰ mesh protocol"]
      ", each identifiable at a glance by its glyph in the status line. The fleet is "
      "legible. You look at the bottom of your terminal and see: "
      [:code "🜂●3 ∴●2 ☰○1 ∞✕ ∇●1"] ". Three sentences of state compressed into "
      "fifteen characters."]]}

   {:id :architecture
    :sigil "☰"
    :title "The Architecture"
    :subtitle "Layered configuration and the mesh protocol"
    :body
    [[:p "tmuxdesk is a three-layer system. At the base: " [:code "tmux.base.conf"]
      " — shared across every node. Vi keybindings, session logging, the status bar "
      "skeleton, the " [:sigil-link :interaction "🜂 keybinding vocabulary"] ". This "
      "layer encodes the invariants: what is true of " [:em "every"] " terminal session "
      "regardless of which machine hosts it."]
     [:p "Above it: per-host configuration. " [:code "host-hyle.conf"] " adds TPM and "
      "resurrect for session persistence. " [:code "host-finml.conf"] " pipes GPU "
      "utilization into the status line. " [:code "host-karlsruhe.conf"] " shows the "
      "current NixOS generation number. Each host config extends the base without "
      "contradicting it — the " [:code "set -ga status-right"] " directive appends "
      "rather than replaces."]
     [:p "The third layer is runtime: the " [:code "state/"] " directory, populated by "
      "the mesh protocol. When a tmux session is created or destroyed on any node, a "
      "hook fires " [:code "mesh-announce.sh"] ". This script dumps the local session "
      "list and pushes it via SSH to every peer's " [:code "state/"] " directory — fire "
      "and forget, backgrounded, non-blocking."]
     [:p "On the receiving end, " [:code "mesh-status.sh"] " reads those state files to "
      "render the fleet bar. No central server. No database. No daemon. Just flat files "
      "pushed over SSH, read every five seconds by the status line refresh. The protocol "
      "is eventually consistent: a node that goes offline simply ages out after five "
      "minutes, its sigil turning from " [:code "●"] " to " [:code "✕"] "."]
     [:p "The " [:sigil-link :infra "∞ deploy script"] " closes the loop. One command — "
      [:code "deploy.sh"] " — rsyncs the entire configuration tree to every node, writes "
      "a minimal " [:code "~/.tmux.conf"] " that sources the two layers, makes scripts "
      "executable, and hot-reloads tmux. The fleet converges in seconds."]
     [:p "This is infrastructure as text. No containers, no orchestrators, no YAML. "
      "Shell scripts, SSH, rsync. The simplest tools that could possibly work — because "
      "the problem is simple: keep five terminal environments coherent and aware of each other."]]}

   {:id :interaction
    :sigil "🜂"
    :title "The Interaction Modes"
    :subtitle "Keybindings, sessions, and spatial arrangement"
    :body
    [[:p "Every keybinding is a mnemonic. " [:kbd "Prefix+s"] " for the session tree. "
      [:kbd "Prefix+S"] " for session-on-demand — type a name, get a session (existing "
      "or freshly created). " [:kbd "Prefix+f"] " for the fuzzy jumper. "
      [:kbd "Prefix+P"] " for the preset picker. " [:kbd "Prefix+F"] " for fleet health. "
      "Uppercase generally means \"more\" — a stronger variant of the lowercase action."]
     [:p [:em "Session-on-demand"] " is the foundational interaction. " [:code "session-ensure.sh"]
      " is nine lines: if a session exists, switch to it; if not, create it and switch. "
      "This collapses the create/select distinction. You always say " [:em "where you want to be"]
      " and the system ensures you get there. The prompt shows " [:code "⊕"]
      " — the astronomical earth symbol, grounding."]
     [:p [:em "Fuzzy jumping"] " via " [:kbd "Prefix+f"] " opens a full-screen fzf popup "
      "listing every session and every pane across the local tmux server. Each row shows "
      "the session name, window, pane index, running command, working directory, age, and "
      "a one-line capture of the pane's last output. The preview pane on the right shows "
      "the last 120 lines. " [:kbd "Ctrl+r"] " refreshes live. This is the " [:em "telescope"]
      " — you see everything at once and land precisely where you need to be."]
     [:p [:em "Layout cycling"] " via " [:kbd "Prefix+Tab"] " rotates through tmux's five "
      "built-in layouts: tiled, even-horizontal, even-vertical, main-horizontal, "
      "main-vertical. State is tracked " [:em "per window"] " so cycling in one context "
      "doesn't affect another. " [:kbd "Prefix+L"] " cycles backward."]
     [:p [:em "Presets"] " are named pane topologies. " [:kbd "Prefix+P"] " lists them "
      "through fzf. " [:code "dev-3pane"] " creates a main-vertical layout: a large editor "
      "pane, a terminal, and a logs/repl pane. " [:code "monitor-4pane"] " creates a tiled "
      "grid that accepts commands as arguments — pass " [:code "htop"] ", a log tail, "
      "a watch command. Each preset is idempotent: if the session already exists, it "
      "switches to it rather than duplicating."]
     [:p "Splits respect context: " [:kbd "Prefix+|"] " and " [:kbd "Prefix+-"]
      " create horizontal and vertical splits that inherit the current pane's working "
      "directory. New windows via " [:kbd "Prefix+c"] " do the same. "
      "You never land in " [:code "$HOME"] " when you meant to be in your project root."]
     [:p "The pane navigation layer uses vi conventions: " [:kbd "h/j/k/l"] " to move "
      "between panes, " [:kbd "H/J/K"] " to resize. Copy mode starts with "
      [:kbd "v"] " for selection, " [:kbd "y"] " to yank. The terminal becomes a "
      "text object — navigable, composable, precise."]]}

   {:id :infra
    :sigil "∞"
    :title "The Infrastructure"
    :subtitle "SSH mesh, deploy fabric, and the machines beneath"
    :body
    [[:p "The physical topology is simple. Four permanent nodes on European VPS providers "
      "(Contabo, Netcup) plus one ephemeral GCP instance. All run Ubuntu except "
      [:sigil-link :karlsruhe "∞ karlsruhe"] " on NixOS. All reachable from each other "
      "over the public internet via SSH with ed25519 keys."]
     [:p "The SSH configuration on each node defines aliases for every peer — "
      [:code "Host hyle"] ", " [:code "Host finml"] ", and so on — with their IPs, "
      "usernames, and key files. This alias layer means the fleet config can refer to "
      "nodes by name, and " [:code "mesh-announce.sh"] " can push state without "
      "constructing connection strings at runtime."]
     [:p "Deployment is rsync with " [:code "--delete"] " — the remote always mirrors "
      "the source of truth. The " [:code "state/"] " directory is excluded from sync "
      "(it's per-node runtime data). After rsync, a two-line " [:code "~/.tmux.conf"]
      " is written that sources base + host config. Scripts are chmoded. Tmux reloads."]
     [:p "Adding a new node to the " [:sigil-link :fleet "∴ fleet"]
      " is a four-step ritual:"]
     [:ol
      [:li "Add the node's SSH public key to " [:code "~/.ssh/authorized_keys"] " on every "
       "existing peer (and vice versa). The mesh is fully connected — every node can reach "
       "every other."]
      [:li "Add an SSH alias in " [:code "~/.ssh/config"] " on each node. Name it. "
       "Give it an identity file."]
      [:li "Add a line to " [:code "fleet.conf"] ": name, alias, sigil, IP. Choose a "
       "sigil from the alchemical, mathematical, or eastern Unicode blocks."]
      [:li "Create " [:code "conf/host-<name>.conf"] " — set " [:code "@host_sigil"]
       " and " [:code "@host_name"] ", append any host-specific status segments."]]
     [:p "Run " [:code "deploy.sh"] ". The new node joins the constellation. "
      "Its sigil appears in every other node's status bar within one mesh cycle. "
      "There is no registration server, no discovery protocol. The fleet is defined "
      "by a flat file and propagated by rsync."]
     [:p [:sigil-link :karlsruhe "∞ karlsruhe"] " deserves special mention. On NixOS, "
      "the system configuration is a Nix expression — a pure function from inputs to "
      "machine state. The host config shows the current generation number in the status "
      "line, a rolling counter of how many times the system has been rebuilt. "
      "Generation 847 means 847 atomic transitions from one well-defined state to another. "
      "No imperative drift. The lemniscate is earned."]]}

   {:id :resource
    :sigil "∇"
    :title "The Resource"
    :subtitle "What runs where, and the orchestration of agents"
    :body
    [[:p "Each node has a vocation. " [:sigil-link :hyle "🜂 hyle"] " runs the creative "
      "workloads: art generation, draft documents, experimental code. It's where Claude, "
      "Codex, and Gemini sessions spawn in parallel tmux windows — each agent in its own "
      "pane, each conversation a separate thread of thought. The " [:code "dev-3pane"]
      " preset is hyle's natural habitat: editor, terminal, agent output."]
     [:p [:sigil-link :hub2 "∴ hub2"] " coordinates. It hosts the git repositories, "
      "runs the deploy script, holds the source of truth. When work on hyle or finml "
      "produces artifacts, they flow back to hub2 for integration. Its status line "
      "shows the current git branch of the tmuxdesk repo itself — a self-referential "
      "touch: the configuration system displays its own version."]
     [:p [:sigil-link :finml "☰ finml"] " is the compute node. Financial data analysis, "
      "model training, batch jobs that benefit from dedicated resources. Its status line "
      "shows GPU utilization and temperature when nvidia-smi is available, or load average "
      "as a fallback. The " [:code "monitor-4pane"] " preset is finml's mode: four "
      "terminals tiled, each watching a different metric."]
     [:p [:sigil-link :nabla "∇ nabla"] " is the newest addition — a GCP instance, "
      "born from a timestamp. Its role is elastic compute: problems that need more "
      "resources than the permanent fleet offers. It reports its GCP zone and load "
      "in the status line. Unlike the others, nabla is designed to be " [:em "ephemeral"]
      " — spun up for a task, torn down after. The gradient descends, finds its minimum, "
      "and the instance stops."]
     [:p "The multi-agent pattern is central. A typical workflow: three tmux windows "
      "on hyle, each running a different AI agent on the same problem. Claude in the "
      "left pane, Codex in the middle, Gemini on the right. The "
      [:sigil-link :interaction "🜂 fuzzy jumper"] " lets you hop between them instantly. "
      "The mesh protocol means you can check from any node whether hyle is active — "
      "if you see " [:code "🜂●3"] " in your status bar, three sessions are running, "
      "at least one attached. Work is in progress."]
     [:p "This is not a Kubernetes cluster or a job scheduler. It's a " [:em "workshop"]
      " — five benches, each with its own tools, all visible from anywhere in the room."]]}

   {:id :import
    :sigil "⊕"
    :title "The Import"
    :subtitle "Why sigils, why terminals, why any of this"
    :body
    [[:p "There's a tendency in infrastructure work toward the anonymous. Machines get "
      "UUIDs or auto-generated names. Dashboards show graphs without character. "
      "The terminal is treated as a regrettable legacy — something to be abstracted away "
      "by web consoles and managed platforms."]
     [:p "tmuxdesk is a deliberate countercurrent. Each machine carries a sigil drawn "
      "from traditions that predate computing by centuries. " [:sigil-link :hyle "🜂"]
      " is from the alchemical symbol set standardized in Unicode 6.0, but the glyph "
      "itself is older than typography. " [:sigil-link :finml "☰"] " appears in the "
      "Yijing, a text compiled roughly three thousand years ago. "
      [:sigil-link :karlsruhe "∞"] " was introduced by John Wallis in 1655."]
     [:p "These aren't decorations. They're " [:em "compression"] ". A sigil on a status "
      "bar tells you which machine you're on, which machine is alive, which is unreachable "
      "— in a single character. The information density of "
      [:code "🜂●3 ∴●2 ☰○1 ∞✕ ∇●1"] " is remarkable: five nodes, their states, their "
      "session counts, all in one line. No dashboard required. No browser tab. The "
      "information lives " [:em "where you already are"] " — in the terminal, in the "
      "status bar that's always visible."]
     [:p "The terminal is not a legacy interface. It is the " [:em "primary"]
      " interface for anyone who works with text — and code is text, configuration "
      "is text, logs are text. tmux adds spatial multiplexing: multiple text streams "
      "visible simultaneously, arrangeable into layouts, switchable by name. The "
      [:sigil-link :interaction "🜂 interaction modes"] " make this spatial model "
      "navigable: fuzzy search across all panes, named sessions you can teleport to, "
      "presets that create reproducible workspace geometries."]
     [:p "The mesh protocol extends this to multiple machines. Each node is an island of "
      "local tmux state, but the " [:sigil-link :architecture "☰ announce/status loop"]
      " connects them into an archipelago. You see the " [:sigil-link :fleet "∴ whole fleet"]
      " from any terminal. This is awareness without centralization — each node pushes "
      "its state, each node reads its peers' state. No coordinator. No single point "
      "of failure. Just SSH and flat files."]
     [:p "The alchemical metaphor is apt. Alchemy was never really about turning lead "
      "into gold — it was about " [:em "transformation"] " through understanding. The "
      "alchemist's workshop had its furnace (🜂), its ledger of operations (∴), its "
      "instruments for reading nature (☰), its pursuit of the perfect (∞), its "
      "calculations of change (∇). tmuxdesk is a workshop for computation. The sigils "
      "are not whimsy. They are the compressed essence of what each machine " [:em "means"]
      " in the practice."]
     [:p "You open your terminal. You see " [:code "🜂●"] " glowing in the status bar. "
      "You know where you are. You know what this machine is for. You press "
      [:kbd "Prefix+f"] " and the entire workspace opens before you — every session, "
      "every pane, every running process. You type a few characters and land exactly "
      "where you need to be. The fleet is " [:em "legible"] ". The work is "
      [:em "navigable"] ". That's the import."]]}])

(def essay-index
  (into {} (map (fn [e] [(:id e) e]) essays)))
