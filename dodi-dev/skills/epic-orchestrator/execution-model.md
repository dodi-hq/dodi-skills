# Execution Model

The single canon of how a lane playbook is executed. Written for **the executing session** — the resident driver (`drive-epic`) walking a lane inline, or a manual lane session invoked directly. Both playbooks (`lanes/mature-playbook.md`, `lanes/deliver-playbook.md`) reference this file for all dispatch mechanics and never restate them; each playbook declares only its own sequence, durable seams, durable surface, exit edges, and resume key.

## 1. Leaf rule (permanent)

Every dispatched worker works **directly** — it never dispatches sub-agents, and its final message **is** the deliverable, returned to its dispatcher as the Agent-tool result (never `SendMessage`). Only the top-level session dispatches workers.

This is permanent architecture, not an interim workaround. It follows a verified harness limitation: Agent-tool workers launch asynchronously (no blocking dispatch mode exists at any depth), and completion wake-ups reliably reach only the top-level session — a session that is itself a subagent and ends its turn with a child in flight is **never re-invoked**; the child's completion routes to the top-level session instead. So a nested lane subagent strands at its first phase dispatch. The executing session therefore walks each lane's sequence itself and dispatches every phase worker as its own leaf.

**One-shot.** A dispatched worker's life is exactly one turn. When its turn ends its context is gone for good: the dispatcher never re-enters it — not by `SendMessage`, not by any continuation — and a fix round is a **fresh leaf** given the artifact path and the findings (the revision-round input block in the drafter prompts). Rationale: a worker parked across a review round outlives its prompt cache and is re-woken cold at its full prefix, an order of magnitude above a fresh leaf's read of the same artifact, and its context only grows across rounds. On Claude Code the plugin's `hooks/hooks.js` module refuses the `SendMessage` when loaded (AGENTS.md § Deterministic Skeleton names the load precondition); on every runtime the rule is the contract.

## 2. Tier pins

Every dispatch carries an explicit model-tier pin per the AGENTS.md tier table (Frontier `fable` / Capable `opus` / Standard `sonnet` / Fast `haiku` on Claude Code); `hook-require-model-pin.sh` enforces the explicit pin on the Claude Code and Grok Build hook surfaces. A dispatch that omits the pin silently inherits the session model — a defect, never a default. Canonical skill frontmatter and Claude-native examples keep `model: fable`; another runtime translates the Frontier tier to its native executor instead of sending that Claude alias blindly.

Resolve the gate's canonical tier and policy first, then select the native executor inside the current runtime. Claude Code Frontier uses the `fable` alias at its declared `xhigh` effort, and Grok Build keeps the existing `grok-4.6` at `xhigh` mapping. Codex Frontier uses Astra at the highest supported reasoning configuration. Resolve the native Astra model spelling and its highest supported effort from the model/tool metadata available at dispatch time; do not freeze a versioned native id in this contract. Loading a skill does not itself change a running Codex session.

Astra and Fable are equivalent Frontier executors; choosing Astra creates no tier-degraded marker or make-up debt. A qualified Astra dispatch satisfies every hard Frontier gate, and a qualified Astra review may discharge any existing `FABLE_MAKEUP` obligation over that obligation's original required scope. A manual session already running qualified Astra satisfies the Frontier self-check without entering `operator-choice`.

Immediately before the native pin is written, the executing session performs the **Frontier-policy lookup** for that gate (the AGENTS.md gate-policy table): a Frontier-seated gate whose policy is `deferred` or `soft` may substitute a lower tier under the recorded scarcity rules, and one whose policy is `hard` parks rather than substitutes. Availability is runtime-local. Apply capacity/tier-unavailable detection to the selected native Frontier executor, retry twice with spacing, then take the existing policy and invocation-mode route; do not infer another runtime's capacity or hand the work to it. The policy is pre-declared per gate, never improvised mid-lane; see AGENTS.md § Frontier Availability Policy (the gate-policy table + the substitution/park machinery). The native pin the policy produces is the one the applicable hook checks.

`FLORIST_EPIC_TIER=standard` still resolves its spec/plan and review gates to their existing Capable seats, so those gates create no Frontier availability event or substitution record. Delivery-tier routing still changes implementers and fix workers only. The Grok mapping and its documented native-model-overlap qualifications are unchanged. Canonical tier names by themselves do not prove native model diversity; for each new reviewer round the dispatcher records the native request using `review` § Native Executor Evidence on the round's existing next-boundary surface.

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

This symmetry lets a hard capacity-park at a mature-lane gate resume instead of restarting from scratch — the spec drafter and the final spec-review round are both hard-policy Frontier gates and both live in the mature lane, so a park there would otherwise strand the fully drafted, loop-reviewed spec in an ephemeral worktree and force a second scarce Frontier spec-authoring dispatch.

**Continuation brief** (posted as a ticket comment): current state per the lane's seam contract with evidence links; the next action and one line of why; live concerns from notes; anything in flight that must not be redone. When a review gate is unfinished, carry every completed round's `review-executor:` record and the running gate-ledger tally so a successor preserves provenance and resumes the same round count.

## 6. Manifest discipline

Append every dispatch to the session's dispatch manifest at the epic worktree's **absolute path** (`<epic-worktree-abs>/.dodi/dispatch-manifest-<session-run-id>.jsonl`). Reap at close-out (`reap-workers.sh`; stop any straggler; append reap records). Wakes for reaped entries are ignored (§3). A manifest entry is never a handle to resume a worker — it exists for wake attribution and reaping only (§ 1, one-shot).

## 7. Parallelism invariants (serial now, seams ready)

One lane in flight at a time is **current policy, not architecture**. The invariants below are stated so a future release can enable N concurrent leaf implementers without re-architecture; any such flip must preserve all five:

- **(a)** Every lane's mutations are isolated in a per-lane ephemeral worktree; the epic worktree has exactly **one** writing session.
- **(b)** The dispatch manifest is keyed by worker id and supports N live entries.
- **(c)** Wake attribution is by worker id — never by "the worker" definite article.
- **(d)** Merges, PM state advances, and register writes are serial in the driver by construction.
- **(e)** Concurrent lanes require **disjoint predicted file surfaces** (shared config, schema, or generated files count as overlap; when in doubt, serialize). One-lane-in-flight makes this currently vacuous — it is carried as a dormant invariant any future parallel flip must re-enforce.

## 8. Session re-entry (operator-facing)

An idle session costs nothing while it sits. The entire cost of a pause is charged on **the next turn taken in that session**, and it scales with the context that session had accumulated: the harness prompt cache has a bounded TTL (1h on Claude Code), and past it the whole conversation is re-written to cache at the write rate — on a Frontier seat, ~80× the per-token cache-read rate. A resident driver holding 600k tokens costs more to wake than a full lane costs to run.

- **After a pause long enough to have crossed the cache TTL, the first action in a long-lived session is a reset, never a prompt.** On Claude Code that is `/clear`: local, free, no API turn, new session. The cold path is the proven one — Boot rebuilds from durable state, which is the same path a refresh-park successor takes.
- **Asking the session whether to reset costs exactly as much as not resetting.** The question is itself a turn, and it re-caches the whole context before it can be answered. Decide it at the keyboard, not in the transcript.
- **If the context must survive the pause, compact _before_ stopping, while the cache is still warm.** A warm compaction reads the context at the read rate; compacting after the pause pays the full re-cache and then discards what it paid for — the worst of the three options.
- **This is not a clock rule and never becomes one.** It governs operator re-entry only. The cache TTL is a harness property, not a workflow clock: no session takes an exit, a park, a succession, or a hand-off from it, and the three driver exits stay count- and event-based (`drive-epic` § Park, refresh-park, and bloat).
