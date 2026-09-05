# Execution Model

The single canon of how a lane playbook is executed. Written for **the executing session** — the resident driver (`drive-epic`) walking a lane inline, or a manual lane session invoked directly. Both playbooks (`lanes/mature-playbook.md`, `lanes/deliver-playbook.md`) reference this file for all dispatch mechanics and never restate them; each playbook declares only its own sequence, durable seams, durable surface, exit edges, and resume key.

## 1. Leaf rule (permanent)

Every dispatched worker works **directly** — it never dispatches sub-agents, and its final message **is** the deliverable, returned to its dispatcher as the Agent-tool result (never `SendMessage`). Only the top-level session dispatches workers.

This is permanent architecture, not an interim workaround. It follows a verified harness limitation: Agent-tool workers launch asynchronously (no blocking dispatch mode exists at any depth), and completion wake-ups reliably reach only the top-level session — a session that is itself a subagent and ends its turn with a child in flight is **never re-invoked**; the child's completion routes to the top-level session instead. So a nested lane subagent strands at its first phase dispatch. The executing session therefore walks each lane's sequence itself and dispatches every phase worker as its own leaf.

**One-shot.** A dispatched worker's life is exactly one turn. When its turn ends its context is gone for good: the dispatcher never re-enters it — not by `SendMessage`, not by any continuation — and a fix round is a **fresh leaf** given the artifact path and the findings (the revision-round input block in the drafter prompts). Rationale: a worker parked across a review round outlives its prompt cache and is re-woken cold at its full prefix, an order of magnitude above a fresh leaf's read of the same artifact, and its context only grows across rounds. On Claude Code the plugin's `hooks/hooks.js` module refuses the `SendMessage` when loaded (AGENTS.md § Deterministic Skeleton names the load precondition); on every runtime the rule is the contract.

## 2. Tier pins

Every dispatch carries an explicit model-tier pin per the AGENTS.md tier table (Frontier `fable` / Capable `opus` / Standard `sonnet` / Fast `haiku` on Claude Code); `hook-require-model-pin.sh` enforces the explicit pin. A dispatch that omits the pin silently inherits the session model — a defect, never a default.

Immediately before the pin is written, the executing session performs the **fable-policy lookup** for that gate (the AGENTS.md gate-policy table): a fable-seated gate whose policy is `deferred` or `soft` may substitute a lower tier under the recorded scarcity rules, and one whose policy is `hard` parks rather than substitutes. The policy is pre-declared per gate, never improvised mid-lane; see AGENTS.md § Fable Availability Policy (the gate-policy table + the substitution/park machinery). The pin the policy produces is the one the hook checks.

## 3. Dual-wake await

Await every dispatch by dual-wake: the native completion notification is primary; the background `await-worker.sh` v2 backstop is the content-based check (final-lines terminal-record, STALLED on stall, chunk-bounded); pinned fallback is foreground chunked awaits. Wakes for already-reaped manifest entries are ignored — the reap record is the dedup marker. **Silence is never success.**

## 4. STALLED handling

On `STALLED`: **stop the worker** (the agent-layer primitive) and **confirm it finished** — a terminal record, or stop-success plus transcript quiescence (mtime stable, no new writes). Then take a `RESUMABLE` exit iff durable checkpoints are **new since this dispatch**; otherwise count one no-progress attempt toward the per-ticket retry ceiling and escalate per the lane's stop conditions.

## 5. Progress seams, `RESUMABLE`, and the continuation brief (lane-neutral)

The executing session records each lane progress marker **itself, as the boundary is crossed** — never batched at the end:

- for **deliver**, these are `# Lane Checkpoint` comments (the pinned-header comment species, unchanged);
- for **mature**, they are its orchestrator **state-transition durable writes** — the mature lane's state transitions are themselves its markers, not a separate `# Lane Checkpoint` species (see the mature playbook).

Each playbook declares its own durable progress seams — deliver's internal checkpoints, mature's four state transitions. The **mechanics** are stated only here and are shared by both lanes:

- **(a)** A `RESUMABLE` exit is legal for **either** lane — deliver and mature alike carry it.
- **(b)** Before any `RESUMABLE`, hard capacity-park (`pending-capacity`), or `refresh-park` exit, the session pushes its in-progress work to **its lane's declared durable surface** — deliver commits on its own child branch/worktree (the lane **never** touches the epic branch, per the isolation invariant); mature pushes back to the epic branch (its existing per-boundary push target) — and posts/updates a **continuation brief** keyed to that surface's SHA plus the last seam crossed. That key is the successor's resume anchor.
- **(c)** A successor **resumes at the recorded seam**, re-entering there rather than re-running completed phases.

This symmetry lets a hard capacity-park at a mature-lane gate resume instead of restarting from scratch — the spec drafter and the final spec-review round are both hard-policy fable gates and both live in the mature lane, so a park there would otherwise strand the fully drafted, loop-reviewed spec in an ephemeral worktree and force a second scarce fable spec-authoring dispatch.

**Continuation brief** (posted as a ticket comment): current state per the lane's seam contract with evidence links; the next action and one line of why; live concerns from notes; anything in flight that must not be redone.

## 6. Manifest discipline

Append every dispatch to the session's dispatch manifest at the epic worktree's **absolute path** (`<epic-worktree-abs>/.dodi/dispatch-manifest-<session-run-id>.jsonl`). Reap at close-out (`reap-workers.sh`; stop any straggler; append reap records). Wakes for reaped entries are ignored (§3). A manifest entry is never a handle to resume a worker — it exists for wake attribution and reaping only (§ 1, one-shot).

## 7. Parallelism invariants (serial now, seams ready)

One lane in flight at a time is **current policy, not architecture**. The invariants below are stated so a future release can enable N concurrent leaf implementers without re-architecture; any such flip must preserve all five:

- **(a)** Every lane's mutations are isolated in a per-lane ephemeral worktree; the epic worktree has exactly **one** writing session.
- **(b)** The dispatch manifest is keyed by worker id and supports N live entries.
- **(c)** Wake attribution is by worker id — never by "the worker" definite article.
- **(d)** Merges, PM state advances, and register writes are serial in the driver by construction.
- **(e)** Concurrent lanes require **disjoint predicted file surfaces** (shared config, schema, or generated files count as overlap; when in doubt, serialize). One-lane-in-flight makes this currently vacuous — it is carried as a dormant invariant any future parallel flip must re-enforce.
