# dodi-dev 0.16.0 — Execution-Model Flatten Redesign

**Date:** 2026-07-07
**Epic:** DOD-796
**Type:** Refactor (architecture)
**Target repo:** dodi-hq/dodi-skills (plugin), ships as dodi-dev 0.16.0

## TL;DR

Dissolve the 0.14.1 interim lane abstraction: lane sequences become single-canon playbook docs under `epic-orchestrator/` that drive-epic executes natively, with `deliver-ticket`/`mature-ticket` reduced to thin manual wrappers. Add two riders the driver's dispatch ownership makes possible: workflow modes (sprint/waterfall as an assess-epic-chosen epic scheduling policy over the same lane primitives; hotfix as a per-ticket filing-time declaration, reserved this release) and the fable availability policy (per-gate `fable-policy: hard | deferred | soft` with a `pending-capacity` park and a batched make-up round — never a silent downgrade). pickup-next is finally deleted; the driver gains a planned context refresh every 3 merged children.

## Key Points

- **Flatten (C1):** the "inline, leaf-dispatch, dual-wake" execution contract is stated **once** in a new `epic-orchestrator/execution-model.md`; lane sequences move to `epic-orchestrator/lanes/{mature,deliver}-playbook.md`. The three duplicated copies (drive-epic + both lane skills) collapse to pointers. `lane-dispatch-prompt.md` is deleted; the leaf rule is reframed from "0.14.1 interim" to the permanent architecture.
- **Serial now, seams ready:** 0.16.0 stays one-lane-in-flight, but `execution-model.md` pins the four isolation invariants (per-lane worktrees, worker-id-keyed manifest, worker-id wake attribution, serial merges/PM writes) so a later release can enable N parallel leaf implementers without re-architecture.
- **Workflow modes (C2):** the epic mode enum is two-valued — `sprint | waterfall` — durable per-epic state (epic label + decision-register entry) re-read every driver loop pass; assess-epic decides it from inter-child coupling unless the Gate 1 delegation pre-declares it; mid-epic flips are first-class, each landing a register entry. Hotfix is *not* an epic mode: it is a per-ticket filing-time declaration (*declared, never derived*) — 0.16.0 ships the declaration slot and routes hotfix work around the epic machinery via escalation; the full minimal-gate hotfix path is a follow-up standalone release.
- **Fable policy (C3):** every fable-seated gate declares `fable-policy` in a new AGENTS.md **gate-policy table** (the tier table is tier-keyed; policy is per-gate) — the assignment table in C3 covers every fable seat, and focused re-rounds inherit their gate's policy. **Hard** (park-and-wait via `pending-capacity`, guard probes for capacity return): spec authoring, final spec-review round, coherence checks (Mike-ruled), capable-tier child-PR final round ⚠ (proposed as a 4th, not yet ruled) — plus the make-up round itself (hard by construction). **Deferred** (opus substitutes now, fable make-up batched at a dedicated fable round in submit-epic-pr): standard-tier child-PR final, pre-PR final, plan writing, plan-review final ⚠. **Soft** (substitute, no make-up): non-final spec/plan review rounds, post-clean-pass confirmation sweeps, Gate 1 package drafting ⚠. Every substitution stamps `tier-degraded` on the catch-attribution tag; `review/SKILL.md`'s gate-clean invariants and pinned catch-tag grammar are amended policy-aware.
- **Planned refresh (C4):** the driver parks deliberately at the first post-merge close-out after 3 merged children (⚠ default, invocation-overridable), posting the continuation brief and releasing with new exit state `refresh-park`; the guard boots the successor. Emergency bloat-park is unchanged as backstop. The shipped "only two exits" doctrine is amended across every surface stating or assuming the two-exit binary (enumerated in C4 below, not just the doctrine statement itself) to park / refresh-park / bloat, with its real prohibition kept verbatim: no time- or silence-based trigger.
- **Deletions & riders (C5):** pickup-next skill + scheduled task deleted, with a full reference sweep (six surfaces enumerated in C5 — including AGENTS.md:85, drive-epic's overview line, and epic-orchestrator's frontmatter, all missed by earlier counts); resident-orchestrator spec §45 release-enum sync (currently five states, missing `taken-over`; brought to the full seven with `refresh-park`); 0.15.0 spec [C5-d] erratum fixed inline (the contradictory `verifying`-checkpoint tagging phrase); the four 0.16.0 promise strings (AGENTS.md:49, deliver-ticket:57, mature-ticket:28, lane-dispatch-prompt:3) resolved.
- **⚠ Assumptions for Gate 1:** playbook home under `epic-orchestrator/` (not drive-epic); mode stored as label-plus-register-entry (label is the cheap cache, register is truth); capable-tier child-PR final round as a 4th hard entry (the other three hard entries — spec authoring, final spec-review, coherence checks — are Mike-ruled); the deferred/soft bucket assignments; refresh budget default of 3; the guard's fable probe as a minimal one-shot dispatch.
- **Out of scope:** actual parallel lane dispatch; full hotfix machinery (entry criteria, minimal gates, auto-filed debt ticket); machine-off/cloud operation; any change to claim discipline, Gate 2, or the coherence-ruling route.
- **Risk:** wrapper/playbook drift is designed out (wrappers carry no sequence prose — pointers only); mode label drift vs register is janitor-checked (reconcile-tickets); deleting pickup-next removes the manual fallback tick, covered by manual drive-epic invocation running the identical guard.

---

*Everything below is written for agents planning and implementing the change.*

## Background and Verified Constraints

The 0.14.1 stopgap exists because of a verified harness limitation (2026-07-05, two controlled tests, 5/5 field hangs on DOD-650): **a subagent that dispatches its own worker and yields is never re-woken** — completion notifications route to the top-level session only, and no blocking dispatch mode exists at depth ≥ 1. The consequence is durable, not interim: the top-level session must own every dispatch, and every worker must be a leaf. 0.15.0 was delivered through the inline model (epic #3, 5/5 ALIGNED coherence), proving it in the field. 0.16.0 makes the inline model the *stated architecture* and deletes the machinery that pretended otherwise.

Current duplication (research-verified): the procedural contract (leaf-worker dispatch, checkpoint-posting-as-you-go, tier pins, dual-wake await) appears three times — `drive-epic/SKILL.md` drive-loop step 3, `deliver-ticket/SKILL.md` §Execution Model, `mature-ticket/SKILL.md` (same closing sentence verbatim). `epic-orchestrator/lane-dispatch-prompt.md` is dead (its banner says do-not-dispatch) but `epic-orchestrator/SKILL.md:65` still instructs dispatching with it — an internal contradiction with that file's own contract table.

## C1 — Lane Flatten

⚠ Everything below assumes the playbook/execution-model home is `epic-orchestrator/` (not `drive-epic/`) — a Gate-1 assumption (see TL;DR); stated as settled prose here only because Gate 1 signoff of this spec is what ratifies it.

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
- **`epic-orchestrator/SKILL.md`:** line 65's stale "dispatch a deliver-ticket lane using lane-dispatch-prompt.md" is replaced with inline execution per the playbook; the contract-table row already says inline and stays. **Also in scope:** the § Parallel Lanes section (lines 71–76, "dispatch up to `maxParallelLanes` … `deliver-ticket` lanes concurrently") and the `maxParallelLanes` input (line 32) are deleted — they instruct exactly what `execution-model.md` forbids (concurrent nested lane subagents); one-lane-in-flight is the shipped policy, and the parallelism invariants live in `execution-model.md` §7 for the future flip.
- **`scripts/validate-phase-skills.sh`:** the structural validator's arrays are updated in lockstep with the file moves — `pickup-next` leaves `skills=(...)` (line 23), `epic-orchestrator/lane-dispatch-prompt.md` leaves `prompt_files=(...)` (line 43), and the three new canon files (`execution-model.md`, `lanes/mature-playbook.md`, `lanes/deliver-playbook.md`) enter the structural checks per the existing convention. Without this the C1/C5 deletions fail the Verification Contract's own "validators green" gate.

### Deletions

- **`epic-orchestrator/lane-dispatch-prompt.md`** — deleted. Its design-input role is fulfilled by this spec; the leaf-rule prose it carried moves to `execution-model.md`.

### Promise strings

All four surfaces carrying a 0.16.0 promise are resolved, but not uniformly. Three carry "the 0.16.0 flatten redesign owns the durable architecture" (`deliver-ticket:57`, `mature-ticket:28`, `lane-dispatch-prompt:3`) — the first two replaced by pointers to `execution-model.md`, the third dies with its file. **`AGENTS.md:49` carries a different promise** ("parallel lanes return with the 0.16.0 flatten redesign") that this spec does *not* fulfill — parallel dispatch is explicitly out of scope (§ Out of scope) — so its fix is a reword deferring the promise, not a bare pointer: e.g. "parallel lane dispatch remains a future release; `execution-model.md` §7 pins the isolation invariants it must preserve."

## C2 — Workflow Modes

### Mode state

The epic mode enum is **two-valued**: `sprint | waterfall` — scheduling policies over the same lane primitives (same playbooks, different dispatch order). Hotfix is deliberately *not* an epic mode: it is a per-ticket filing-time declaration that routes around the epic machinery entirely (see below). Storage (⚠ Gate 1):

- **Epic label** `mode-sprint` / `mode-waterfall` — the cheap re-readable cache the driver checks every loop pass (piggybacking the per-iteration re-scan; no extra API round-trip beyond the label read).
- **Decision-register entry** (`# Decision Register Entry` header, `Kind: MODE`, keyed by epic id + seam timestamp instead of a merge SHA) carrying the coupling rationale — the truth the label caches. Every mode *flip* lands a new register entry; the janitor (reconcile-tickets) gains a row flagging label-vs-latest-MODE-entry mismatch.

**Register-entry kinds and the coherence audit.** This spec introduces register entries that are not coherence verdicts (`Kind: MODE` here; `Kind: CAPACITY_PARK` and `Kind: FABLE_MAKEUP` in C3). Two consequences, both explicit change items:

1. **Set-difference filter:** the boot coherence audit ("every merged child PR holds a register entry") and the `coherence-pending` clear predicate count only coherence-verdict entries, never MODE/CAPACITY_PARK/FABLE_MAKEUP entries — otherwise a make-up entry keyed to a merge SHA could satisfy the audit for a child that never got its coherence review. **Normative discriminator (the one authoritative grep): the `Kind:` field — an entry with no `Kind:` field is a coherence-verdict entry; an entry with any `Kind:` value is not.** (Backward compatible: every entry already posted lacks `Kind:` and is a verdict.) The audit prose in drive-epic, the state tables, **and `epic-orchestrator/SKILL.md:87`** (the Merging-step clear predicate — a third surface stating the same register-wide audit, easy to miss since it reads as orchestrator-only prose) states this filter.
2. **Template/validator surface:** the register-entry comment template and `validate-ticket-comment-templates.sh` currently assume the `Merge SHA:` key; they gain the `Kind:` field with the per-kind key variants (MODE: epic id + seam timestamp; CAPACITY_PARK: gate + ticket; FABLE_MAKEUP: gate + merge SHA or ticket id pre-merge). Coherence-verdict entries are unchanged and need no `Kind:` field (absence ⇒ verdict — backward compatible with every entry already posted).

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

`coherence-pending` blocking scope and demotion rules are mode-independent and unchanged. **Table home:** the mode-parameterized priority table lands in `epic-orchestrator/state-transitions.md` as single canon (today the ordering lives as drive-epic step-1 prose with a pickup-next mirror — the mirror dies in C5); drive-epic step 1 references it.

### Hotfix (declared, never derived — reserved this release)

- **file-ticket** gains an explicit hotfix declaration slot (Type gains `hotfix`; the filed ticket carries a `hotfix` label). Declared only at filing time; nothing ever infers it.
- **0.16.0 behavior:** the driver and pickup treat a `hotfix`-labeled ticket as *outside the epic machinery* — it is never selected by the drive loop; encountering one inside an epic's child set is an escalation. The label routes to a documented manual path (operator-run, today's same-day point-release precedent — "documented" means the maintainer-thread precedent already narrated, not a new doc this release authors; the standalone hotfix-machinery release below is what turns it into a first-class written path).
- **Follow-up release (not 0.16.0):** entry criteria (prod-broken / time-critical), minimal gates (verify + one review + human deploy word — the Gate-2 equivalent survives), and the mandatory auto-filed debt ticket carrying hotfix context for the proper fix.

## C3 — Fable Availability Policy

**Never demotion — scarcity handling.** Fable tokens are scarce; every fable-seated gate pre-declares how scarcity is handled. Policy is **pre-declared per gate in a dedicated AGENTS.md gate-policy table** (see § Policy home below — it does not fit as a column in the existing tier-keyed table), never improvised mid-lane.

### Buckets and assignments

The table covers **every** fable seat in the shipped tier table (AGENTS.md + the per-skill pins research-verified: review/SKILL.md pre-PR and child-PR finals, mature-ticket's spec drafter / spec & plan reviewers / plan writer, brainstorm and write-plan reviewer prompts, coherence-reviewer, Gate 1 package worker). A fable seat without a row is a spec bug. **`mature-ticket/SKILL.md`'s own frontmatter `model: fable` main-loop pin** (persists for the skill's whole turn per AGENTS.md:38, carried unchanged by the C1 thin-wrapper) is a session-level default, not a discrete gate dispatch — it needs no row of its own because execution-model.md §2 and Mechanics §7 (Hook interplay) already require every individual dispatch inside the skill to carry its own explicit per-gate policy pin immediately before dispatch, which overrides the frontmatter default; the frontmatter pin only matters as the fallback if a dispatch prompt is ever left unpinned, which the tier-pin hook already forbids.

| Policy | Meaning | Gates |
| --- | --- | --- |
| **hard** | park-and-wait; no substitution ever | spec authoring (drafter); **final** spec-review round; coherence checks — **these three Mike-ruled 2026-07-07**; capable-tier child-PR final round (`needs-capable-delivery` tickets) ⚠ (proposed as a 4th hard entry in the same thread, not yet ruled — else opus reviews opus on invariant-dense work; Gate 1 signoff of this spec ratifies it, same as the other ⚠ entries below) — plus the **fable make-up round** (hard by construction: the debt collector cannot itself be substituted, else deferred collapses to soft) |
| **deferred** | opus substitutes now; fable make-up queued as a durable obligation, batched at the dedicated make-up round in submit-epic-pr | standard-tier child-PR final round; pre-PR final round (all tiers — the child-PR gate still guards the merge, hard on capable tier) ⚠; plan writing ⚠; **final** plan-review round ⚠ |
| **soft** | opus substitutes; no make-up | **non-final** spec-review and plan-review rounds (the final round of each loop is the gate; a make-up of a superseded intermediate round has no value) ⚠; post-clean-pass confirmation sweeps (any optional confirmation dispatch added after a clean hard round — no shipped mandatory seat matches this today; the row exists so a future one has a declared home) ⚠; Gate 1 package drafting ⚠ (Mike reads the package at signoff — the human gate is the catch) |

**Focused re-rounds inherit their gate's policy.** The child-PR post-fix focused re-round (`review/SKILL.md:47`, a fresh `model: fable` dispatch) is not a confirmation sweep — it is the round that *establishes* gate-clean after fixes, so it carries its gate's policy: **hard** on capable-tier tickets, **deferred** on standard-tier, exactly like the child-PR final it re-establishes. (The pre-PR focused re-review is an opus seat and needs no row.) Under a deferred substitution, gate-clean semantics follow the effective-tier rule in Mechanics §6.

⚠-marked assignments were proposed-not-ruled in the 2026-07-07 thread (or are this spec's completions of the coverage requirement); Gate 1 signoff of this spec ratifies them. Note the deliberate asymmetry: spec-review final is hard while plan-review final is deferred — the spec is the canon everything downstream consumes, while plan defects still face the pre-PR/child-PR review chain, and the make-up round's scope covers their consequence surface.

**Policy home (structural):** the AGENTS.md tier table is keyed by tier, not by gate, so the policy does not fit as a column there. AGENTS.md gains a compact **gate-policy table** (this section's table, transplanted) adjacent to the tier table; skills reference it the way they reference tier pins today.

### Mechanics

1. **Detection:** fable unavailability is detected at dispatch time — dispatch failure matching a capacity/tier-unavailable signature, then bounded retry (2 retries, spaced), then the policy applies. Never detected by guessing in advance.
2. **hard → `pending-capacity` park.** Same shape as pending-human: epic label `pending-capacity` + a register entry (`Kind: CAPACITY_PARK`, recording gate, ticket, and the exact blocked dispatch), driver exits via the park protocol, reconcile-tickets gains a digest row surfacing it (age-tracked). **Unlike pending-human it has a wake edge:** the hourly guard, on seeing `pending-capacity`, runs a minimal one-shot fable probe dispatch (⚠ smallest possible prompt, e.g. "reply DONE"); probe success → clear the label, treat the epic as actionable, boot the driver, which retries the blocked dispatch first. **Mid-lane parks are expected:** the blocked dispatch is usually a phase worker inside an inline-walked lane, so the successor resumes the lane from its durable checkpoints (the existing RESUMABLE machinery — the CAPACITY_PARK entry's recorded dispatch is the resume key) and the retried dispatch is its first action. **Manual sessions:** a manual lane session (thin-wrapper invocation) hitting a hard gate under scarcity does not park — it stops and reports to the operator, who is present by definition; the park machinery is driver-only.
3. **deferred → substitute + queue make-up.** Dispatch the same worker prompt pinned opus. Record a durable obligation: a register entry (`Kind: FABLE_MAKEUP`) keyed by the gate + merge SHA (or ticket id pre-merge) naming what fable must re-review — for review gates the original scope; for plan writing / plan review, the consequence surface (the affected child's merged diff), since re-reviewing a consumed plan post-implementation has no value.
   **Consumption seam — a dedicated fable make-up round in submit-epic-pr**, pinned precisely: it runs **after the integrated-head round reports clean for the attempt and before the head freeze / epic-PR open**. If any `FABLE_MAKEUP` obligations are open, dispatch **one batched fable round** using `epic-integration-reviewer-prompt.md` with a dispatcher-supplied obligations preamble enumerating them (no new prompt file); findings carry `caught-by: epic-integration/<round>/fable` per the existing grammar and route through the same mechanical/judgment classification as integration findings; a make-up-driven fix moves the head and **restarts the attempt loop per the existing rules** (the make-up round re-runs with the remaining obligations). Each obligation is marked consumed by keyed reference in the round's output. This round's fable-policy is **hard** (see table) — fable still unavailable at epic-PR time ⇒ `pending-capacity` park, the epic PR does not open with unconsumed make-ups. The existing opus integrated-head round is unchanged (it is Capable-tier per AGENTS.md, not a fable seat — the make-up round is a distinct, conditional round beside it). Zero open obligations ⇒ the round is skipped entirely.
4. **soft → substitute, record only.** No obligation queued.
5. **Attribution (never silent):** every substitution extends the 0.15.0 catch-attribution line with a tier-degraded marker — format pinned as: `caught-by: <gate>/<round>/<tier> tier-degraded(fable→<tier>,<policy>)`. The dispatcher appends it exactly where it already appends `<round>/<tier>`; append-only, next-boundary rule unchanged. The marker feeds evidence-based reclassification of bucket assignments (the same attribution data 0.15.0 was built to collect).
6. **`review/SKILL.md` edits (explicit change items):** (a) the pinned catch-tag grammar (§ Catch Attribution) gains the optional `tier-degraded(...)` suffix exactly as formatted above; (b) the gate-clean invariants at the pre-PR and child-PR finals ("the gate is clean only when a `fable` round reports zero issues") become policy-aware: for **hard** gates the wording stands unchanged; for **deferred/soft** gates, clean = zero issues from the final round at the gate's *effective* tier (the pin the policy produced), with the obligation queued / marker recorded as applicable. No gate is ever clean by silence.
7. **Hook interplay:** `hook-require-model-pin.sh` is unchanged — a substitution still carries an explicit pin (`model: opus`); the policy check happens in skill prose immediately before the pin is written.

## C4 — Planned Context Refresh

- **Budget:** 3 merged children per driver session (⚠ default; an invocation input may override).
- **Trigger point:** evaluated only at post-merge close-out (fence → release → evidence → reap all complete — everything durable, nothing in flight by construction). If merges-this-session ≥ budget → run the standard exit protocol (fence, continuation brief, claim release) with new exit state **`refresh-park`**.
- **Guard behavior:** `refresh-park` releases the claim like `parked`; the next guard tick sees actionable work and boots a fresh driver, which cold-boots from durable state + the brief (the proven path).
- **Emergency bloat-park:** unchanged, as backstop. Rationale: a degraded context is the worst judge of its own degradation — refresh is the rule, bloat the exception.
- **Doctrine amendment (explicit change items — full surface sweep, not three).** `refresh-park` is a **distinct third exit**, not a park subspecies — pinned consistently everywhere it's named. The shipped "park and bloat — the **only two exits** / no third exit trigger" doctrine becomes **park** (no automated action possible — including the pending-human and new pending-capacity species), **refresh-park** (planned, count-based, only at a post-merge durable seam), and **bloat** (emergency). The original prohibition's substance is retargeted to what it always meant and keeps verbatim: **no time- or silence-based exit or succession trigger** — refresh-park is count-based at a durable boundary, not a clock rule. Every surface stating or assuming the two-exit binary is swept, not just the doctrine statement: `drive-epic/SKILL.md:81-83` (the doctrine header itself), `:3` (frontmatter description), `:9` (overview: "until park or bloat"), `:17` (Contract table Outputs cell), `:69` (drive-loop repeat condition), `:88` (release-command exit-state value list, folding the enum-sync below), `:127` (session-evidence exit enum, also folding the enum-sync below), `:135` (Stop Conditions closing line); `AGENTS.md:85` and `:96`; `epic-orchestrator/SKILL.md:97`. **Cross-child seam:** `AGENTS.md:85` and `drive-epic:9` are *also* touched by C5's pickup-next sweep, for an unrelated reason (stripping the 0.14.1/pickup-next mention on the same lines) — C4 lands first per the decomposition order, so C5's editor must preserve C4's park/refresh-park/bloat wording on those lines rather than reintroducing the two-exit phrasing while removing the pickup-next text. **`AGENTS.md:96` / `epic-orchestrator/SKILL.md:97` need a reworded carve-out, not a bare enum append:** that sentence's whole point is *close-out ≠ reset*, but refresh-park **is** a reset triggered at a close-out — appending it to the enum as written ("a reset happens only at park, refresh-park, or bloat") contradicts the sentence it's amending. Reword to: "the child-merge close-out is a durable-brief anchor point (register + continuation brief kept current), not an *unplanned* reset — an actual context reset happens only at park, the *planned* refresh-park (itself a close-out, by deliberate design — the one exception this rule carves out), or bloat." (At `epic-orchestrator/SKILL.md:97`, whose trailing "(a mandatory reset per merge …)" clause already follows the target span, the same replacement lands as an adjacent parenthetical — grammatically valid but denser than at `AGENTS.md:96`; the implementing editor may split it into two sentences there if it reads awkwardly, without changing the substance.)
- **Enum sync (folds the §45 rider):** the driver-claim release exit-state enum is the shipped six **plus** `refresh-park`: `parked | bloat-handoff | no-op | ruled | taken-over | error | refresh-park` (`no-op` and `error` are load-bearing for guard exits and must survive), synchronized across `driver-claim.sh:245`, drive-epic prose (the `:88` release-command value list and the `:127` session-evidence enum above), and the resident-orchestrator spec's §45 line — **currently five states** (`parked | bloat-handoff | no-op | ruled | error`, missing `taken-over` — a pre-existing sync debt from 0.14.0's own §45 rider, independent of this change), brought to the full seven by this child.

## C5 — Deletions, Riders, Release

### pickup-next deletion and the reference sweep

- Delete `dodi-dev/skills/pickup-next/`. Scheduled-task definitions are harness/operator-managed, not in-repo artifacts (there is none to delete in this repo) — disabling/removing the `dodi-pickup-next` task is an operator action alongside this repo change, not a repo-scoped deliverable.
- **Full reference sweep — six surfaces** (the epic's "three references" undercounted; these are the grep-verified set):
  1. `epic-orchestrator/SKILL.md` (body + frontmatter) — **not fully covered by C1** (C1 only touches `:65`, `:71-76`, `:32`): `:62`'s "normally executed by the pickup-next tick" parenthetical needs its own pickup-next-reference fix here, **and its frontmatter description** (line 3 names the pickup-next tick). (`:87`'s coherence-audit clear predicate is a *third* audit surface needing C2's `Kind:`-field set-difference filter, per C2 § Register-entry kinds — cross-referenced here, not re-stated.)
  2. `lane-dispatch-prompt.md` (deleted in C1);
  3. `reconcile-tickets/SKILL.md` (pickup-next mentions replaced with drive-epic equivalents);
  4. `drive-epic/SKILL.md:9` overview sentence (names pickup-next and the 0.14.1 contract — outside the step-3 rewrite, so called out separately);
  5. `drive-epic/SKILL.md` §Scheduling migration — compressed to a completed-history note (the 0.14.0/0.14.1 dance is done);
  6. `AGENTS.md:85` — carries both a literal `0.14.1 interim` marker and a pickup-next mention; not covered by the AGENTS.md:49 promise-string fix and swept here.
- The C1 scope note "everything else in the loop is untouched" applies to the drive-*loop* steps only; the overview and migration prose above are explicitly in scope.

### Riders

- **[C5-d] erratum (docs-only, inlined here from epic #3's register):** in `docs/specs/2026-07-06-review-pipeline-consolidation-design.md` § Change 5, the phrase "verify/local-CI **failures** are tagged by the dispatcher in the `verifying` checkpoint evidence" contradicts the append-only tagging-surfaces rule pinned later in the same paragraph (tags land in the **next boundary's** evidence — verify-stage failures in the `ready-for-child-pr` checkpoint). Correct the phrase to "tagged by the dispatcher in the next boundary's checkpoint evidence (`ready-for-child-pr`)". No ship-surface change; the shipped `review/SKILL.md` already states the correct rule.
- **§45 enum sync:** folded into C4 above.

### Release

dodi-dev **0.16.0**: bump the three version-bearing metadata files in lockstep (`.claude-plugin/marketplace.json` `plugins[0].version`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`), run the validators green (`scripts/validate-plugin-metadata.sh` + the structural suite), fresh session to apply via `plugin update`.

## Decomposition Sketch (children filed after Gate 1)

Suggested child boundaries, dependency-ordered — final decomposition happens at filing:

1. **C1a** — `execution-model.md` + both lane playbooks (content move, single canon).
2. **C1b** — drive-epic step-3 rewrite + lane-skill thin-wrapping + lane-dispatch-prompt deletion + epic-orchestrator:65 fix + §Parallel-Lanes/`maxParallelLanes` deletion + promise-string resolution. Blocked by C1a. (Both C1 children keep `validate-phase-skills.sh` arrays in lockstep with every file add/delete.)
3. **C2** — mode state (label + MODE register entries + template/validator `Kind:` field) + assess-epic scheduling step + driver Select parameterization + coherence-audit kind filter + hotfix declaration slot in file-ticket + `pickup`/driver hotfix-label routing + reconcile-tickets mode-mismatch row. Blocked by C1b (touches the same drive-epic Select prose).
4. **C3** — the AGENTS.md gate-policy table (all seats) + pending-capacity park + guard probe + FABLE_MAKEUP queue + submit-epic-pr make-up round + `review/SKILL.md` grammar/gate-clean amendments + tier-degraded marker + reconcile-tickets pending-capacity digest row. Blocked by C1b (execution-model.md hosts the dispatch-time policy check) and C2 (shares the register-entry `Kind:` machinery).
5. **C4** — refresh budget + `refresh-park` exit state + seven-state enum sync + the full exit-doctrine surface sweep. Blocked by C1b.
6. **C5** — pickup-next deletion (incl. `validate-phase-skills.sh` skills-array update) + six-surface reference sweep + [C5-d] erratum + release bump. Blocked by all above.

## Verification Contract (epic-level)

- All three validators green; `bash -n` on every script; `comment-species.sh` classification table unchanged except any new species this spec adds (none — park entries reuse `# Decision Register Entry`).
- Grep-clean: no remaining bare `0.14.1`, `lane-dispatch-prompt`, `pickup-next`, or `maxParallelLanes` references outside historical docs (`docs/plans/`, `docs/specs/` are historical and exempt; the bare-`0.14.1` pattern deliberately catches phrasings like "0.14.1 leaf-worker contract" that the narrower `0.14.1 interim` misses, e.g. `epic-orchestrator/SKILL.md:21`).
- The four promise-string surfaces verifiably resolved.
- Mode parameterization exercised by inspection against both orderings (sprint and waterfall) in the state-table; no automated harness exists for the driver loop — field validation is the next epic driven through it, per the 0.15.0 precedent.
