# Epic Coherence Gate & Decision Register Design

## TL;DR

Add a Frontier-tier **epic-coherence review** at the post-merge seam: after each child merges into the epic branch and before any new work is dispatched for that epic, a fable reviewer checks the merged result against the epic's design intent — because every existing review is ticket-local, and small judgment calls compound as later children conform to earlier ones. The **epic ticket itself becomes the master decision register**; legitimate divergence is a first-class outcome that updates the canon and re-matures affected children automatically. The child dependency graph moves to **native PM blocked-by relations**, and a **lights-out hardening** package (stalled-epic watchdog, dedicated escalation channel + daily digest, heartbeat, deploy/CI failure detection, structural Gate 2 via branch protection) guarantees that healthy-quiet and stalled never look the same, and that failure-to-self-correct always becomes a human ping. Architecturally, this release gives the framework its **deterministic skeleton**: every mechanical invariant ships as a script or hook inside the plugin — code enforces what code can enforce — while SKILL.md files remain the judgment contracts.

## Key Points

- **The gap: all current reviews are ticket-local.** Pre-PR review, child-PR review, and quality gate ask "does this child match its own spec/plan?" Nothing asks "does the merged result still match the epic's design?" until the epic PR's full regression — which is functional, not architectural, and arrives after drift has compounded.
- **Drift compounds by construction.** Children build on the merged epic branch and every skill says "follow existing patterns," so child 1's slightly-off judgment call becomes child 3's local convention. Correction cost grows with every merge; the gate runs where it is cheapest — immediately after each merge.
- **New seam in the tick:** after `pickup-next`'s merge action completes, the epic enters `coherence-pending`, which blocks new `deliver-ticket` dispatches and `mature-ticket` planning for that epic until the review clears. Running the review is a tick action, priority just below merges. Serial lanes (the 0.12.0 default) get the full benefit — the gate protects dispatches, not work already in flight.
- **Frontier tier, alignment only.** The coherence reviewer (`model: fable`) reviews the merged diff + child spec against the epic design / Gate 1 package, the decision register, and sibling specs. It does not re-review correctness — that already passed opus rounds. Design-intent alignment is judgment whose quality compounds downstream: the definition of Frontier work.
- **The epic ticket is the master decision register.** Every coherence review appends a register entry comment to the epic: the child's notable judgment calls, the verdict, and any newly canonical decisions. Spec drafters, plan writers, and lanes receive the register as required input — the preventive half that stops the *next* child from drifting the same way.
- **Four verdicts, four routes.** ALIGNED → register entry only. MINOR_DRIFT → register entry + downstream notes; no rework. MATERIAL_DRIFT (child wandered, design right) → corrective ticket sequenced before dependent children; epic holds for dependents until corrected. LEGITIMATE_DIVERGENCE (child right, design stale) → the new decision becomes canonical in the register and affected children are realigned.
- **Realignment is label hygiene, not new machinery.** For each affected child the reviewer names: strip `ready-to-implement` (and `spec-ready` only when the spec itself is invalidated); the tick then routes the child back through `mature-ticket`, whose drafter consumes the updated register. Divergence is judged once, at the seam — never re-derived inside lanes, which stay forbidden from redesigning mid-flight.
- **Gate 1 amendment escape hatch.** A divergence that contradicts what the human explicitly approved at Gate 1 is never canonized by automation: escalate with the scannable header, hold dependent dispatches, and wait. Delegation covers routine choices, not silent rewrites of approved intent.
- **The child dependency graph moves to native PM relations.** Hard sequencing edges are registered as blocked-by relations at planning time (today they live as prose in the epic assessment comment). Dispatch eligibility becomes a structural query — readiness labels ∧ no open blocking issues ∧ epic not `coherence-pending` — and the MATERIAL_DRIFT corrective ticket holds its dependents by relation, not by procedure. Soft parallelism signals (file-surface overlap) stay in the assessment; relations carry hard sequencing only.
- **Watch the verdict distribution.** On a well-specified epic most verdicts should be ALIGNED. If the gate never fires beyond that across a few epics, the register alone may be doing the work — revisit whether the review can drop to sampling. The bet is the usual one: a bounded Frontier check per merge against unbounded compounded rework.
- **Lights-out hardening (this release, not later).** A stalled-epic watchdog and a daily "waiting on you" digest in the janitor, a dedicated needs-human escalation channel with re-escalation on staleness, a tick heartbeat as dead-man's switch, janitor escalation on failed production deploys and red/conflicted epic PRs, a progress-based retry ceiling and claim test, idempotent verdict writes, and a curated register canon. Healthy-quiet and stalled must never look the same, and failure-to-self-correct must always become a human ping.
- **Gate 2 becomes structural, not procedural.** Setup prerequisite: branch protection on main/master requiring human review/merge, so automation *cannot* merge the epic PR even if misrouted. The markdown rule stays; GitHub enforces it.
- **Invariants become code; judgment stays prose.** Every field bug to date (lane stalls, silent merges, tier inheritance) lived in the mechanical layer, where prose is a probabilistic interpreter for what should be deterministic. This release ships the mechanical layer as plugin-bundled scripts (`dodi-dev/scripts/`) and hooks; skills shrink to "run the script, judge the result." Prose is never asked to be persuasive about a postcondition again.

---

## Gate Placement in the Tick Model

`pickup-next`'s action priorities gain one slot and one precondition:

1. Merge a `ready-to-merge-child` — unchanged, but its close-out now marks the epic `coherence-pending` instead of leaving it free.
2. **Run the epic-coherence review for a `coherence-pending` epic** (new; outranks everything below so the epic is never blocked longer than one tick).
3. Run `submit-epic-pr` when all children are done — requires the last merge's coherence review clean.
4. Resume a RESUMABLE lane — allowed while `coherence-pending` (the lane predates the merge; stopping it mid-flight loses more than it protects).
5. Dispatch `deliver-ticket` — **blocked for a `coherence-pending` epic.**
6. Run `mature-ticket` — **blocked for a `coherence-pending` epic** (specs drafted against a register about to change are waste).

`coherence-pending` is a label on the epic, applied by the merge close-out and removed by the review's close-out. A crashed review run leaves the label; the next tick re-runs the review (it is read-only until its verdict writes, so re-running is safe). Manual `epic-orchestrator` sessions honor the same label.

With `maxParallelLanes` > 1 a sibling lane may already be in flight when the gate fires; the gate cannot protect it. That lane's own merge gets its own coherence review, which catches conflicts one seam later. This is accepted for now and is one more reason the 0.12.0 serial default should hold until coherence verdicts prove boring.

## Coherence Reviewer

New worker prompt `epic-orchestrator/coherence-reviewer-prompt.md`, dispatched with `model: fable` (Frontier tier) by the tick (or a manual orchestrator session).

Inputs:

- the merged child's diff (merge commit against the pre-merge epic head), spec, and plan
- the epic design artifact and the Gate 1 signoff package (what the human actually approved)
- the current decision register (all register entries on the epic ticket)
- sibling child specs (pending and delivered)

Responsibilities:

- judge **alignment only** — architecture, abstractions, data shapes, responsibility placement, naming conventions, integration-point contracts — against the epic design and register; correctness is already reviewed
- extract the child's notable judgment calls (made silently or explicitly) into register entries, whatever the verdict
- for divergence, decide which side is right: the implementation or the design
- name the affected children explicitly for any verdict that propagates
- flag any divergence that touches Gate-1-approved intent as `GATE1_AMENDMENT` — never canonize it
- judge **cumulative** drift, not just this merge: weigh the register as a whole against the Gate 1 package, and when accumulated superseded points have materially moved the epic from what was approved — even though each step was individually routine — escalate a **Gate 1 refresh** (scannable delta summary, human re-approves or redirects)
- adversarial framing: the prompt instructs the reviewer to argue that the merge diverges and let the evidence defeat the argument, countering the correlated-blind-spot risk of Frontier reviewing Frontier-drafted designs

Output:

- **Verdict:** ALIGNED | MINOR_DRIFT | MATERIAL_DRIFT | LEGITIMATE_DIVERGENCE (+ optional GATE1_AMENDMENT flag)
- **Register entries:** each a one-paragraph decision statement with evidence links
- **Affected children:** ticket ids + which label(s) to strip + one line why, per child
- **Corrective ticket draft** (MATERIAL_DRIFT only): scope, why it must precede dependents

## Verdict Routing

| Verdict | Register write | Child tickets | Epic |
| --- | --- | --- | --- |
| ALIGNED | entries for notable judgment calls | none | clear `coherence-pending` |
| MINOR_DRIFT | entries + drift note naming the convention downstream children must not copy (or must copy — whichever the reviewer rules) | none reworked; affected pending children get a spec-lane note, labels intact | clear `coherence-pending` |
| MATERIAL_DRIFT | entries + the drift ruling | corrective ticket filed (via `file-ticket`) and sequenced before dependent children; dependents' dispatch blocked until it merges | clear `coherence-pending`; dependency map updated |
| LEGITIMATE_DIVERGENCE | the new decision recorded as canonical, superseding the design point (design artifact gets a superseded-by note, never silently edited) | affected children: strip `ready-to-implement`; strip `spec-ready` only if the spec itself is invalidated → tick re-routes through `mature-ticket` with the updated register | clear `coherence-pending` |
| any + GATE1_AMENDMENT | entry marked ⚠ pending human ruling | dependent dispatches held | escalate with scannable header; `coherence-pending` stays until the human rules |

**Verdict writes are idempotent.** The close-out is multi-step (register entry, label strips, corrective ticket, clearing `coherence-pending`), and a crashed run may have completed some steps. Every write is keyed to the merge SHA under review: before writing, check for an existing register entry / corrective ticket / label state for that SHA and skip what already exists. Re-running a coherence review after a crash must never double-file.

Realignment is deliberately label-driven: no lane ever "checks and repairs" its own instructions. A lane whose plan predates a register change either was named as affected (and lost its labels before dispatch) or was not (and proceeds). Divergence is judged exactly once, at the seam, by the Frontier reviewer with the full picture.

## Decision Register (on the epic ticket)

The epic ticket is the master register. Mechanics:

- Each coherence review appends one **register entry comment** (template: `decision-register-entry`): child id, verdict, decisions recorded (one paragraph each, evidence-linked), affected children, superseded design points.
- Entries are append-only; a later entry may supersede an earlier one by reference, never by editing history.
- The epic description gains a one-line pointer to the register convention so humans and agents know where to look.

**Curation — the canon summary.** Registers grow with every merge, and an uncurated register recreates the context-bloat problem for every consumer. The coherence reviewer maintains the **canon summary** as a `## Decision Register — Canon` section of the **epic description**: current canonical decisions only, supersede chains collapsed, one line each. (Amended post-ship: originally spec'd as a "pinned comment" — Linear has no comment pinning, GUI or API; the description is always rendered at the top and API-writable.) Consumers read the canon section; the full entry-comment history remains for audit. The reviewer updates the section as part of every verdict close-out (idempotent, keyed like all verdict writes).

Consumers (all gain the register as required input — the canon summary, not the raw history):

- `mature-ticket` spec drafter and `write-plan` plan writer: draft against the register; contradicting a canonical register decision is a review finding.
- `deliver-ticket` lanes: receive the register at pickup as context; still forbidden from redesigning — a perceived register conflict mid-lane is a demote-to-spec surprise, as today.
- The coherence reviewer itself: prior entries are precedent.
- The Gate 1 package and epic readiness summary: link the register so both human gates see the accumulated decisions. The Gate 2 readiness summary gains a mandatory **"what changed since you signed off"** section — every canonized divergence from the Gate 1 package, one line each — so the merge decision sees the delta, not just the outcome.

## Native Dependency Relations

The dependency graph becomes structural PM state instead of comment prose:

- **Registration at planning time.** `file-ticket` sets blocked-by relations implied by the decomposition when it creates the children; `assess-epic` verifies and repairs the relations against its dependency analysis, and the Gate 1 package presents the graph (now also human-visible in the PM UI). Gate 1 approval canonizes it.
- **Dispatch eligibility is a query, not a parse.** `pickup-next` dispatches `deliver-ticket` for a child only when: readiness labels present ∧ no open blocking issues on the child ∧ the epic is not `coherence-pending`. "B waits for A done *and* coherence-checked" needs no per-edge encoding — the relation covers "A done"; the epic-level label covers "coherence-checked" for every edge at once.
- **`blocked-dependency` resolves natively.** The state-transition table's dependency check reads live relations; a child unblocks the moment its blocker reaches its terminal state, with no comment archaeology.
- **Verdict routing uses relations.** MATERIAL_DRIFT: the corrective ticket is created with blocked-by relations from each dependent child — the "sequenced before dependents" hold is structural. LEGITIMATE_DIVERGENCE: relations are untouched unless the reviewer explicitly re-sequences; realignment is label-driven as above.
- **Hard sequencing only.** Predicted file-surface overlap and other parallelism signals remain advisory data in the assessment and plans — they inform lane concurrency, and encoding them as blocked-by would create false blocks.
- **Janitor hygiene.** `reconcile-tickets` adds one check: a child whose blocking issues are all terminal but which still sits in a blocked state gets advanced (or escalated if evidence is ambiguous), citing the relation state.

## Deterministic Skeleton: Scripts and Hooks

The dividing rule: **anything with an invariant becomes code; anything with a judgment stays prose.** Scripts ship inside the plugin (`dodi-dev/scripts/`), so they version, validate, and install with the skills that call them.

### Script inventory

| Script | Owns | Replaces prose in |
| --- | --- | --- |
| `await-worker.sh` | poll a dispatched worker's `output_file` until mtime stable >60s; print only the final JSONL entries | AGENTS.md await contract, `deliver-ticket`, `mature-ticket`, lane-dispatch prompt |
| `claim.sh` / `release-claim.sh` | claim comment create/update with the progress-based liveness test | `pickup-next` claim step, orchestrator claim discipline |
| `dispatch-eligible.sh` | the eligibility query: readiness labels ∧ no open blocking issues ∧ epic not `coherence-pending` | `pickup-next` selection step |
| `verify-merge.sh` | post-merge postcondition: PR state MERGED + merge commit reachable on the target branch | `submit-ticket-pr` merge verification |
| `cleanup-branch.sh` | merged-by-SHA-reachability check, then remote delete → worktree remove → local delete | `submit-ticket-pr`, janitor cleanup |
| `check-deploy.sh` | production deployment status + SHA reachability for a given epic merge commit | janitor deploy transition |
| `watchdog-scan.sh` | per-epic durable-progress staleness scan, relation-cycle detection | janitor watchdog |
| `heartbeat.sh` | post the daily heartbeat line | tick close-out |

Scripts are plain bash + `gh` + the PM API — portable to any runtime that can run a shell. A script also outranks a Fast-tier worker for pure mechanics: where the tier table said "haiku for git mechanics," prefer the script — zero-variance beats low-latency.

### Hooks (Claude Code)

- **Gate 2, client-side:** a PreToolUse hook blocks any `gh pr merge` (and equivalent) whose target branch is main/master. Branch protection remains the server-side enforcement; the hook makes the attempt fail fast and loudly inside the session.
- **Dispatch pins, enforced:** a PreToolUse hook rejects any Agent dispatch without an explicit `model` parameter. The 0.11.1 rule ("an unpinned dispatch is a defect") stops being a sentence agents must remember and becomes a wall they cannot walk through.

Hooks are Claude-Code-specific. On Codex, the prose rules and server-side branch protection carry the same invariants; hooks are defense-in-depth, not the sole enforcement.

### Drift protection

- When a mechanic exists as a script, skills must **reference the script, never restate the mechanism** — a skill re-describing `await-worker.sh`'s polling loop in prose is a review finding (restated mechanics are how the two layers diverge).
- Validation grows accordingly: scripts exist and are executable; hook configuration parses; every script named in a skill exists in `dodi-dev/scripts/`.

## Lights-Out Hardening

The failure mode that breaks unattended operation is not a wrong action — the gates catch those — it is **silence**: an epic that sits still while every tick exits as a successful no-op, or an escalation that reaches no one. Two invariants: *healthy-quiet and stalled must never look the same*, and *failure-to-self-correct must always become a human ping*.

### Stalled-epic watchdog (janitor check)

`reconcile-tickets` gains: for every active epic (`epic-signed-off`, not done), if no durable progress (new checkpoint, merge, label transition, register entry) has occurred within the watchdog window (default 3 days) **and** the epic is not parked on an explicit human-wait state, escalate with a diagnosis: dispatchable children (or why none — including relation cycles: if no child is dispatchable and none is human-parked, say which blocked-by edges form the knot), live claims, `coherence-pending` age, open PR state. This converts every unknown-unknown stall — deadlocked relations, a stuck label, a routing bug — into a known escalation.

### Escalation channel and the "waiting on you" digest

- Needs-human events (Gate 1 refresh, `QUESTIONS_FOR_HUMAN`, demotions, blockers, retry ceiling, watchdog, deploy/CI failures) go to a **dedicated escalation channel** (Slack ping or equivalent) — never mixed into routine run-completion notifications, which are noise at tick cadence and must be mutable without losing escalations.
- The janitor produces a daily **"waiting on you" digest**: every human-parked item across all epics — what it is, how long parked, the one-line ask, the link. Aggregation is the guard against human attention becoming the silent bottleneck.
- **Re-escalation:** a human-parked item older than the staleness window (default 3 days) is re-pinged in the next digest with its age flagged. Escalations are not fire-and-forget.

### Dead-man's switch

The tick posts a daily heartbeat (one line, fixed location — a designated PM ticket or channel). The absence of the heartbeat is the signal that the substrate itself died (app closed, machine down) — the one failure the janitor cannot report because it dies with the same substrate. Interim measure until scheduling moves to managed infrastructure.

### Deploy and epic-PR failure detection (janitor checks)

- A production deployment reporting `failure`/`error` → escalate immediately; affected epics stay in Merged with a deploy-failed note. Detection only — triage remains the future devops leg.
- An open epic PR that is conflicted against its base or has failing checks → escalate. Gate 2 notifications fire at PR-open; without this check, a later red X has no watcher.

### Progress-based retry and claim semantics

- **Retry ceiling counts stagnation, not resumes.** A `RESUMABLE` exit that added new durable checkpoint progress resets the counter; only attempts that end with no new progress count toward the ceiling. A big ticket that legitimately needs several context resets is healthy; three attempts that go nowhere are not.
- **Claim liveness is progress-tested, not age-tested.** Before skipping (or expiring) a claim, check for durable progress since the claim's last update; a 3-hour-old claim with fresh checkpoints is alive regardless of lease age. The lease window is the fallback when there is no progress signal at all.

### Multi-epic fairness

Default posture: **one active epic at a time** — the tick's global priority order is defined for a single epic and will starve a second one behind long lanes. Running multiple concurrent epics requires round-robin by epic in the tick's selection step; until that is implemented, starting a second epic while one is active is a deliberate human choice, not a supported default.

### Setup prerequisites (alongside the scheduled tasks)

1. **Branch protection on main/master** requiring human review/merge — the structural enforcement of Gate 2. The procedural rule stays; GitHub makes it impossible rather than forbidden.
2. The escalation channel wired and tested (one synthetic escalation end-to-end) before the first unattended epic.

## Out of Scope

- Sampling or skipping coherence reviews on "small" children — run it every merge first; earn the optimization with verdict data.
- Automated triage of failed deploys or red epic-PR CI — detection and escalation ship here; diagnosis/repair is the future devops leg (`babysit-epic-pr`, post-merge verification).
- Round-robin multi-epic scheduling — single active epic is the supported posture this release.
- Reverting merged children — correction is always forward (corrective ticket), never a revert by automation.
- Coherence checks between concurrent in-flight lanes — covered indirectly at each lane's own merge seam; revisit with `maxParallelLanes` > 1.
- Cross-epic coherence.

## Versioning

Ships as `0.13.0`: the deterministic skeleton (`dodi-dev/scripts/` — await-worker, claim/release-claim, dispatch-eligible, verify-merge, cleanup-branch, check-deploy, watchdog-scan, heartbeat — plus the two PreToolUse hooks and validator coverage); new `epic-orchestrator/coherence-reviewer-prompt.md` (fable, adversarial framing, cumulative-drift check, idempotent writes); `pickup-next` gains the `coherence-pending` action, dispatch blocks, relation-based dispatch eligibility, progress-based retry/claim semantics, and the daily heartbeat; `epic-orchestrator` merge step and state tables gain the seam; `file-ticket` and `assess-epic` gain native dependency-relation registration/repair; `mature-ticket`/spec-drafter, `write-plan`/plan-writer, and `deliver-ticket` consume the register canon summary; `submit-epic-pr` gains the "what changed since you signed off" section; `reconcile-tickets` gains relation hygiene, the stalled-epic watchdog, the "waiting on you" digest with re-escalation, and deploy/epic-PR failure detection; new `templates/ticket-comments/decision-register-entry.md` wired into validation; AGENTS.md records the register convention and the two lights-out invariants; setup prerequisites documented: branch protection on main/master and the escalation channel test.
