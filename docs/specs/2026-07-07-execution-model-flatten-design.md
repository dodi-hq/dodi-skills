# dodi-dev 0.16.0 — Execution-Model Flatten Redesign

**Date:** 2026-07-07
**Epic:** DOD-796
**Type:** Refactor (architecture)
**Target repo:** dodi-hq/dodi-skills (plugin), ships as dodi-dev 0.16.0

## TL;DR

Dissolve the 0.14.1 interim lane abstraction: lane sequences become single-canon playbook docs under `epic-orchestrator/` that drive-epic executes natively, with `deliver-ticket`/`mature-ticket` reduced to thin manual wrappers. Add two riders the driver's dispatch ownership makes possible: workflow modes (sprint/waterfall as an assess-epic-chosen scheduling policy over the same lane primitives; hotfix declared at filing, reserved this release) and the fable availability policy (per-gate `fable-policy: hard | deferred | soft` with a `pending-capacity` park and a batched make-up queue — never a silent downgrade). pickup-next is finally deleted; the driver gains a planned context refresh every 3 merged children.

## Key Points

- **Flatten (C1):** the "inline, leaf-dispatch, dual-wake" execution contract is stated **once** in a new `epic-orchestrator/execution-model.md`; lane sequences move to `epic-orchestrator/lanes/{mature,deliver}-playbook.md`. The three duplicated copies (drive-epic + both lane skills) collapse to pointers. `lane-dispatch-prompt.md` is deleted; the leaf rule is reframed from "0.14.1 interim" to the permanent architecture.
- **Serial now, seams ready:** 0.16.0 stays one-lane-in-flight, but `execution-model.md` pins the four isolation invariants (per-lane worktrees, worker-id-keyed manifest, worker-id wake attribution, serial merges/PM writes) so a later release can enable N parallel leaf implementers without re-architecture.
- **Workflow modes (C2):** mode `sprint | waterfall | hotfix` is durable per-epic state (epic label + decision-register entry) re-read every driver loop pass; assess-epic decides sprint-vs-waterfall from inter-child coupling unless the Gate 1 delegation pre-declares it; mid-epic flips are first-class, each landing a register entry. Hotfix is *declared at filing, never derived* — 0.16.0 ships the declaration slot and routes hotfix work around the epic machinery via escalation; the full minimal-gate hotfix path is a follow-up standalone release.
- **Fable policy (C3):** every fable-seated gate declares `fable-policy` in the AGENTS.md tier table. **Hard** (park-and-wait via `pending-capacity`, guard probes for capacity return): spec authoring, final spec-review round, coherence checks, capable-tier final pre-merge round — all four Mike-ruled. **Deferred** (opus substitutes now, fable make-up batched at the integrated-head round): standard-tier child-PR final round, plan-review final round ⚠. **Soft** (substitute, no make-up): post-clean-pass confirmation sweeps, Gate 1 package drafting ⚠. Every substitution stamps `tier-degraded` on the catch-attribution tag.
- **Planned refresh (C4):** the driver parks deliberately at the first post-merge close-out after 3 merged children (⚠ default, invocation-overridable), posting the continuation brief and releasing with new exit state `refresh-park`; the guard boots the successor. Emergency bloat-park is unchanged as backstop.
- **Deletions & riders (C5):** pickup-next skill + scheduled task deleted (three stale references decoupled); resident-orchestrator spec §45 `taken-over` release-enum sync; 0.15.0 spec Change 5 erratum [C5-d] docs-only fix; the four 0.16.0 promise strings (AGENTS.md:49, deliver-ticket:57, mature-ticket:28, lane-dispatch-prompt:3) resolved.
- **⚠ Assumptions for Gate 1:** playbook home under `epic-orchestrator/` (not drive-epic); mode stored as label-plus-register-entry (label is the cheap cache, register is truth); the deferred/soft bucket assignments beyond the four hard rulings; refresh budget default of 3; the guard's fable probe as a minimal one-shot dispatch.
- **Out of scope:** actual parallel lane dispatch; full hotfix machinery (entry criteria, minimal gates, auto-filed debt ticket); machine-off/cloud operation; any change to claim discipline, Gate 2, or the coherence-ruling route.
- **Risk:** wrapper/playbook drift is designed out (wrappers carry no sequence prose — pointers only); mode label drift vs register is janitor-checked (reconcile-tickets); deleting pickup-next removes the manual fallback tick, covered by manual drive-epic invocation running the identical guard.

---

*Everything below is written for agents planning and implementing the change.*

## Background and Verified Constraints

The 0.14.1 stopgap exists because of a verified harness limitation (2026-07-05, two controlled tests, 5/5 field hangs on DOD-650): **a subagent that dispatches its own worker and yields is never re-woken** — completion notifications route to the top-level session only, and no blocking dispatch mode exists at depth ≥ 1. The consequence is durable, not interim: the top-level session must own every dispatch, and every worker must be a leaf. 0.15.0 was delivered through the inline model (epic #3, 5/5 ALIGNED coherence), proving it in the field. 0.16.0 makes the inline model the *stated architecture* and deletes the machinery that pretended otherwise.

Current duplication (research-verified): the procedural contract (leaf-worker dispatch, checkpoint-posting-as-you-go, tier pins, dual-wake await) appears three times — `drive-epic/SKILL.md` drive-loop step 3, `deliver-ticket/SKILL.md` §Execution Model, `mature-ticket/SKILL.md` (same closing sentence verbatim). `epic-orchestrator/lane-dispatch-prompt.md` is dead (its banner says do-not-dispatch) but `epic-orchestrator/SKILL.md:65` still instructs dispatching with it — an internal contradiction with that file's own contract table.

## C1 — Lane Flatten

### New file: `dodi-dev/skills/epic-orchestrator/execution-model.md`

The single canon of the execution contract, executor-neutral (written for "the executing session" — the epic driver or a manual lane session). Contents:

1. **Leaf rule (permanent):** every dispatched worker works directly, never dispatches sub-agents, and its final message is the deliverable returned as the Agent-tool result. Cite the harness limitation as the permanent ground.
2. **Tier pins:** every dispatch carries an explicit model-tier pin per the AGENTS.md tier table; `hook-require-model-pin.sh` enforces. The fable-policy lookup (C3) happens immediately before the pin is written.
3. **Dual-wake await:** native completion notification primary; `await-worker.sh` v2 background backstop; pinned fallback foreground chunked awaits. Wakes for already-reaped manifest entries are ignored (reap record = dedup marker). Silence is never success.
4. **STALLED handling:** stop the worker (agent-layer primitive), confirm it finished (terminal record, or stop-success + transcript quiescence), then RESUMABLE iff durable checkpoints are new since this dispatch, else one no-progress attempt toward the ceiling.
5. **Checkpoints:** the executing session posts each lane checkpoint comment itself as the boundary is crossed (`# Lane Checkpoint` species, unchanged).
6. **Manifest discipline:** append every dispatch to the session's manifest at the epic worktree's absolute path; reap at close-out (`reap-workers.sh`; stop stragglers; append reap records).
7. **Parallelism invariants (serial-now, seams-ready):** stated as invariants any future parallel mode must preserve, with one-lane-in-flight declared as *current policy, not architecture*:
   - (a) every lane's mutations are isolated in a per-lane ephemeral worktree; the epic worktree has exactly one writing session;
   - (b) the dispatch manifest is keyed by worker id and supports N live entries;
   - (c) wake attribution is by worker id, never by "the worker" definite article;
   - (d) merges, PM state advances, and register writes are serial in the driver by construction.

### New files: `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md`, `lanes/deliver-playbook.md`

Each playbook is the *only* statement of its lane's sequence. Content is moved (not rewritten) from the current lane skills, restructured as: phase table (phase → worker prompt → tier pin + fable-policy → checkpoint posted → exit/demotion edge), then per-phase notes. Sequences preserved exactly as shipped:

- **mature:** draft spec → spec review loop → apply `spec-ready` → write-plan → plan review loop → delivery-tier classification → apply `ready-to-implement` (+ `needs-capable-delivery` where classified).
- **deliver:** pickup-ticket → implement-ticket → review (pre-PR) → create-tests → verify → context-reset seam → submit-ticket-pr (Open) → review (child-PR) → report `ready-to-merge-child`. Checkpoint set unchanged: implementing / implementation-reviewing / testing / verifying / ready-for-child-pr / child-pr-reviewing.

Playbooks reference `execution-model.md` for all dispatch mechanics and never restate them.

### Rewrites

- **`drive-epic/SKILL.md` drive-loop step 3:** "Act" becomes *execute the selected lane's playbook natively per `execution-model.md`* — the "walk the selected skill's sequence" indirection and the "(0.14.1 interim)" framing are removed. Everything else in the loop (claim, close-out, re-scan) is untouched.
- **`deliver-ticket/SKILL.md`, `mature-ticket/SKILL.md`:** become thin manual wrappers: Contract table, claim/release discipline (per-ticket session claims, identical step-0 fence), a pointer to their playbook + `execution-model.md`, and exit states. Zero sequence prose. Their Contract tables keep the same trigger/inputs/outputs so manual invocation semantics are unchanged.
- **`epic-orchestrator/SKILL.md`:** line 65's stale "dispatch a deliver-ticket lane using lane-dispatch-prompt.md" is replaced with inline execution per the playbook; the contract-table row already says inline and stays.

### Deletions

- **`epic-orchestrator/lane-dispatch-prompt.md`** — deleted. Its design-input role is fulfilled by this spec; the leaf-rule prose it carried moves to `execution-model.md`.

### Promise strings

All four surfaces carrying "the 0.16.0 flatten redesign owns the durable architecture" (AGENTS.md:49, deliver-ticket:57, mature-ticket:28, lane-dispatch-prompt:3) are resolved: the first three replaced by pointers to `execution-model.md`; the fourth dies with its file.

## C2 — Workflow Modes

### Mode state

Enum: `sprint | waterfall | hotfix`. Sprint and waterfall are **scheduling policies over the same lane primitives** — same playbooks, different dispatch order. Storage (⚠ Gate 1):

- **Epic label** `mode-sprint` / `mode-waterfall` — the cheap re-readable cache the driver checks every loop pass (piggybacking the per-iteration re-scan; no extra API round-trip beyond the label read).
- **Decision-register entry** (`# Decision Register Entry` header, keyed by epic id + seam timestamp instead of a merge SHA) carrying the coupling rationale — the truth the label caches. Every mode *flip* lands a new register entry; the janitor (reconcile-tickets) flags label-vs-latest-entry mismatch.

No `mode-hotfix` label exists on epics: hotfix is a per-ticket filing-time declaration, not an epic scheduling policy (see below).

### assess-epic gains the scheduling-policy step

After building the dependency map, assess-epic decides sprint vs waterfall:

- **Gate 1 delegation wins:** if the delegation comment pre-declares or constrains the mode, apply it verbatim.
- **Otherwise decide autonomously** from the inter-child coupling graph (discriminator: file-overlap and blocked-by density — tightly coupled children favor waterfall's mature-all-first, independent children favor sprint's interleave), within the delegation, and write the register entry with rationale. **No third human gate.**
- Output feeds the Gate 1 package the same way the ready-work queue does today.
- **Re-assessment is a standard seam step:** the driver re-runs the mode evaluation at post-merge close-out and boot audit (mode flips mid-epic are expected — coupling that looked loose tightens once real diffs exist).

### Driver Select becomes mode-parameterized

The priority table's top slots are identical in both modes: merge → coherence review → epic PR → resume RESUMABLE. The lane slots reorder:

- **sprint:** … → deliver-ticket → mature-ticket (today's order; interleave per child).
- **waterfall:** … → mature-ticket → deliver-ticket, with deliver-ticket ineligible until every unblocked child carries `ready-to-implement` (mature-all-then-deliver-all).

`coherence-pending` blocking scope and demotion rules are mode-independent and unchanged.

### Hotfix (declared, never derived — reserved this release)

- **file-ticket** gains an explicit hotfix declaration slot (Type gains `hotfix`; the filed ticket carries a `hotfix` label). Declared only at filing time; nothing ever infers it.
- **0.16.0 behavior:** the driver and pickup treat a `hotfix`-labeled ticket as *outside the epic machinery* — it is never selected by the drive loop; encountering one inside an epic's child set is an escalation. The label routes to a documented manual path (operator-run, today's same-day point-release precedent).
- **Follow-up release (not 0.16.0):** entry criteria (prod-broken / time-critical), minimal gates (verify + one review + human deploy word — the Gate-2 equivalent survives), and the mandatory auto-filed debt ticket carrying hotfix context for the proper fix.

## C3 — Fable Availability Policy

**Never demotion — scarcity handling.** Fable tokens are scarce; every fable-seated gate pre-declares how scarcity is handled. Policy is **pre-declared per gate in the AGENTS.md tier table** (a new `fable-policy` column), never improvised mid-lane.

### Buckets and assignments

| Policy | Meaning | Gates |
| --- | --- | --- |
| **hard** | park-and-wait; no substitution ever | spec authoring; final spec-review round; coherence checks; capable-tier final pre-merge round (child-PR integration final on `needs-capable-delivery` tickets) — all four Mike-ruled 2026-07-07 |
| **deferred** | opus substitutes now; fable make-up queued as a durable obligation, batched at the integrated-head round | standard-tier child-PR final round; plan-review final round ⚠ |
| **soft** | opus substitutes; no make-up | post-clean-fable-pass confirmation sweeps (focused re-reviews); Gate 1 package drafting ⚠ (Mike reads the package at signoff — the human gate is the catch) |

⚠-marked assignments were proposed-not-ruled in the 2026-07-07 thread; Gate 1 signoff of this spec ratifies them.

### Mechanics

1. **Detection:** fable unavailability is detected at dispatch time — dispatch failure matching a capacity/tier-unavailable signature, then bounded retry (2 retries, spaced), then the policy applies. Never detected by guessing in advance.
2. **hard → `pending-capacity` park.** Same shape as pending-human: epic label `pending-capacity` + a register-style park entry (`# Decision Register Entry` variant recording gate, ticket, and the exact blocked dispatch), driver exits via the park protocol, reconcile-tickets surfaces it in the daily human-parked digest (age-tracked). **Unlike pending-human it has a wake edge:** the hourly guard, on seeing `pending-capacity`, runs a minimal one-shot fable probe dispatch (⚠ smallest possible prompt, e.g. "reply DONE"); probe success → clear the label, treat the epic as actionable, boot the driver, which retries the blocked dispatch first.
3. **deferred → substitute + queue make-up.** Dispatch the same worker prompt pinned opus. Record a durable obligation: a register entry (`FABLE_MAKEUP` kind) keyed by the gate + merge SHA (or ticket id pre-merge) naming what fable must re-review. **Consumption seam:** the integrated-head round (submit-epic-pr step 3) — its fable round's scope explicitly enumerates and covers all open `FABLE_MAKEUP` obligations for the epic; each is marked consumed by SHA-keyed reference in the round's output. An epic PR is not opened with unconsumed make-ups unexamined.
4. **soft → substitute, record only.** No obligation queued.
5. **Attribution (never silent):** every substitution extends the 0.15.0 catch-attribution line with a tier-degraded marker — format pinned as: `caught-by: <gate>/<round>/<tier> tier-degraded(fable→<tier>,<policy>)`. The dispatcher appends it exactly where it already appends `<round>/<tier>`; append-only, next-boundary rule unchanged. The marker feeds evidence-based reclassification of bucket assignments (the same attribution data 0.15.0 was built to collect).
6. **Hook interplay:** `hook-require-model-pin.sh` is unchanged — a substitution still carries an explicit pin (`model: opus`); the policy check happens in skill prose immediately before the pin is written.

## C4 — Planned Context Refresh

- **Budget:** 3 merged children per driver session (⚠ default; an invocation input may override).
- **Trigger point:** evaluated only at post-merge close-out (fence → release → evidence → reap all complete — everything durable, nothing in flight by construction). If merges-this-session ≥ budget → run the standard exit protocol (fence, continuation brief, claim release) with new exit state **`refresh-park`**.
- **Guard behavior:** `refresh-park` releases the claim like `parked`; the next guard tick sees actionable work and boots a fresh driver, which cold-boots from durable state + the brief (the proven path).
- **Emergency bloat-park:** unchanged, as backstop. Rationale: a degraded context is the worst judge of its own degradation — refresh is the rule, bloat the exception.
- **Enum sync (folds the §45 rider):** the driver-claim release exit-state enum becomes `parked | bloat-handoff | refresh-park | taken-over | ruled`, synchronized across `driver-claim.sh`, drive-epic prose, and the resident-orchestrator spec erratum.

## C5 — Deletions, Riders, Release

### pickup-next deletion

- Delete `dodi-dev/skills/pickup-next/` and any scheduled-task definition for `dodi-pickup-next`.
- Decouple the three referencing surfaces: `epic-orchestrator/SKILL.md` (rewritten in C1 anyway), `lane-dispatch-prompt.md` (deleted in C1), `reconcile-tickets/SKILL.md` (its pickup-next mentions replaced with drive-epic equivalents).
- Migration prose in `drive-epic/SKILL.md` §Scheduling migration is compressed to a completed-history note (the 0.14.0/0.14.1 dance is done).

### Riders

- **[C5-d] erratum:** the 0.15.0 spec Change 5 docs-only erratum — apply as specified in that spec's erratum note (docs surface only, no behavior change).
- **§45 enum sync:** folded into C4 above.

### Release

dodi-dev **0.16.0**: bump the three version-bearing metadata files in lockstep (`.claude-plugin/marketplace.json` `plugins[0].version`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`), run the validators green (`scripts/validate-plugin-metadata.sh` + the structural suite), fresh session to apply via `plugin update`.

## Decomposition Sketch (children filed after Gate 1)

Suggested child boundaries, dependency-ordered — final decomposition happens at filing:

1. **C1a** — `execution-model.md` + both lane playbooks (content move, single canon).
2. **C1b** — drive-epic step-3 rewrite + lane-skill thin-wrapping + lane-dispatch-prompt deletion + epic-orchestrator:65 fix + promise-string resolution. Blocked by C1a.
3. **C2** — mode state + assess-epic scheduling step + driver Select parameterization + hotfix declaration slot. Blocked by C1b (touches the same drive-epic Select prose).
4. **C3** — fable-policy column + pending-capacity park + make-up queue + tier-degraded marker + guard probe. Blocked by C1b (execution-model.md hosts the dispatch-time policy check).
5. **C4** — refresh budget + `refresh-park` exit state + enum sync. Blocked by C1b.
6. **C5** — pickup-next deletion + [C5-d] erratum + release bump. Blocked by all above.

## Verification Contract (epic-level)

- All three validators green; `bash -n` on every script; `comment-species.sh` classification table unchanged except any new species this spec adds (none — park entries reuse `# Decision Register Entry`).
- Grep-clean: no remaining `0.14.1 interim`, `lane-dispatch-prompt`, or `pickup-next` references outside historical docs (`docs/plans/`, `docs/specs/` are historical and exempt).
- The four promise-string surfaces verifiably resolved.
- Mode parameterization exercised by inspection against both orderings (sprint and waterfall) in the state-table; no automated harness exists for the driver loop — field validation is the next epic driven through it, per the 0.15.0 precedent.
