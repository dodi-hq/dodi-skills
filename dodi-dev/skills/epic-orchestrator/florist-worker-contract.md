# Florist Worker Contract

The single canon of what changes when a lane session is **spawned by the Florist kernel** instead of invoked by a human. Written for the executing session; referenced by every skill that holds a Florist seat — `mature-ticket` for the contract lanes, `implement-ticket` for `implementing`, `review` for `code-review` and `integrating`. § 9 is the per-seat table: which skill sits where, and the one digest each seat owes.

Florist is the durable orchestration kernel that replaces the prose state machine these skills carry between them: it owns unit state, leases, attempt accounting, escalation, and the tracker projection, and it dispatches a provider CLI per lane into a per-unit worktree. The session it spawns is a **worker**, not a driver. Everything below follows from that one fact.

## 1. Mode detection

`FLORIST_UNIT` is set in the environment ⇒ **autonomous mode**. Absent ⇒ manual mode, unchanged — a human invoked the skill and is present to answer it.

The check is the environment variable itself, never a heuristic about the harness, the model, or the presence of a tty. A skill that holds a Florist seat states both modes explicitly; a skill that holds none never reads this file.

**The check is a step, not a table row (DOD-1326).** The first Bash command of every seat-holding skill, in both modes, is:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/florist-mode.sh"
```

It prints `mode=manual` or `mode=autonomous unit=… lane=… …` and, in autonomous mode, the three instructions the session then follows: read this file now; only the skill's Florist seat section for `FLORIST_LANE` applies (the manual process tables, checkpoints, and close-out vocabulary do not); close through `florist-digest.sh` (§ 4). A session that reaches its close-out without having run this step has skipped the contract — that is how three of four review dispatches ended a lane with `ready-to-merge-child` and no digest on 2026-09-04, each costing a reap.

## 2. What the kernel tells the worker

| Variable | Meaning | Absent when |
| --- | --- | --- |
| `FLORIST_UNIT` | the unit id (`DOD-xxxx`), also the tracker identifier and the mode flag | not a Florist dispatch |
| `FLORIST_LANE` | the lane this dispatch is seated for — the phase range below | never |
| `FLORIST_ATTEMPT` | this lane's attempt counter, for the transcript | never |
| `FLORIST_TIER` | the session's own `<tier>@<effort>`, the seat's declared pairing | never |
| `FLORIST_FABLE_POLICY` | compatibility name for the seat's runtime-local Frontier availability bucket (`none` on a non-Frontier seat) | never |
| `FLORIST_EPIC_TIER` | the epic's design-phase capability assessment (`standard` \| `capable`) | the epic is unassessed |
| `FLORIST_DELIVERY_TIER` | the unit's plan-reviewer delivery classification (`standard` \| `capable`) | not yet classified |
| `FLORIST_PLANNER_ROUTING_CONTRACT` | `spec-review-planner-v1` when typed spec-to-planner transport is enforced | old kernel: contract seats block via `planner-routing.py require-kernel` |
| `FLORIST_PLANNER_ROUTING_PATH` | kernel-materialized JSON record for the approved spec, per `write-plan/planner-routing.md`; read before plan-writer dispatch | outside `contract-review`; absence there is missing transport, not legacy permission |
| `FLORIST_NEEDS_HUMAN_SPEC` | `1` iff the admit-time product snapshot carried the `needs-human-spec` label | the label was absent |
| `FLORIST_EPIC_BRANCH` | the epic branch unit branches fork from — the contract lanes' durable surface | never |
| `FLORIST_CHILD_REVIEW_CONTRACT` | `frontier-pre-pr-v1` only when the companion enforcement in `review/florist-companion.md` is deployed | older kernel: delivery seats block, never accept legacy success |
| `FLORIST_CHILD_REVIEW_INPUT_COMMAND` / `FLORIST_CHILD_REVIEW_INPUT_PATH` | JSON argv refresh command (invoke without shell), then path to `{identity, context}`; command-before-read at final/renewal/freshness checks per `review/child-review-contract.md` | outside enabled child-review seats; missing/failed refresh blocks those seats |
| `LINEAR_API_KEY` | the **worker-lane** tracker credential, read by `${CLAUDE_PLUGIN_ROOT}/scripts/linear-api.sh` — distinct from the kernel's own key, which the allowlist strips (DOD-1300) | the deployment issued no worker tracker credential: a concrete blocker (`blocked reason=worker-blocked`), never an improvised read path |

The worker's worktree is on `unit/<FLORIST_UNIT>`, forked from `FLORIST_EPIC_BRANCH`, and **persists across dispatches** for that unit: a later lane sees the earlier lane's files without fetching anything.

That worktree is a worktree of the **kernel's own clone**. The branch head the kernel fences a delivery digest against (§ 9) is the local `refs/heads/unit/<FLORIST_UNIT>` — the worktree's committed `HEAD` — and the kernel's irreversible actions (`pr-create`, `child-merge`) then check **origin** against the same SHA and refuse on any difference. So a delivery seat pushes `unit/<FLORIST_UNIT>` before it reads the SHA it cites, cites exactly `git rev-parse HEAD` after the push, and commits nothing after that read. Uncommitted work is invisible to the kernel; unpushed work fails the irreversible action.

The worker holds **none of the kernel's credentials** by design (the spawn-env allowlist strips them). It cannot read kernel state, cannot attest, and cannot advance itself. Everything it knows arrives in the table above, in its worktree, or on the ticket.

## 3. What the worker must not do

The kernel owns these; a worker that writes them is racing the component of record.

- **No claims.** The lease *is* the claim. Never run `claim.sh` / `release-claim.sh` — a lane claim comment under a lease is a second lock with no arbiter.
- **No readiness labels.** Never apply `spec-ready`, `ready-to-implement`, or `needs-capable-delivery`. Lane state is the unit doc; the tracker's labels are a **projection** of it, and a worker-written label is overwritten at the next projection pass — after having briefly lied to every human reading the board.
- **No tracker status writes** of any kind (lane, blocked reason, attempt, lease). Product fields and ordinary comments are fine; status fields are the kernel's output surface.
- **No self-advance.** The lane moves when the kernel accepts a digest (§4), never because the session decided it was done. Silence is never success; neither is a confident closing paragraph.

## 4. The digest — the only thing the kernel reads

The session's **stdout** is the return channel. Exactly two machine-readable line kinds; everything else on stdout is transcript prose.

```
FLORIST-STATUS: <outcome> [key=value ...]
FLORIST-EVIDENCE: kind=<pr|ci|artifact|thread|verdict> ref=<ref> sha=<sha|->
```

Rules the parser enforces, stated here so they are never discovered by accident:

- **Last `FLORIST-STATUS` wins**; evidence lines accumulate in order. Write the digest once, at the very end.
- An **unknown outcome, a malformed pair, or a missing required evidence row is not a submission** — the run is thrown away, the lease reaps, and the attempt settles against the unit. A typo costs a full attempt.
- Evidence `sha=-` means "no SHA"; a row that needs one must carry a real one.
- `ref=clean-final:…` is **manager-reserved** and silently dropped from worker evidence. Never emit it.

Outcomes and their required evidence are per lane; each seat-holding skill states its own table. A worker never invents an outcome its lane does not accept — the kernel rejects it, and the rejection is indistinguishable from a crash.

**Emit the digest through the helper, never by hand (DOD-1326):**

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/florist-digest.sh" <outcome> [key=value ...] [--evidence kind=<k> ref=<r> sha=<s|->]...
```

It validates the outcome, fields, and evidence rows against `FLORIST_LANE` per § 9 and prints exactly the two line kinds; it exits 2 with the reason when the digest would not be a submission (fix the input and run it again — that is a free retry; the kernel's rejection is not), and it refuses in manual mode. **Closing invariant:** an autonomous session's last stdout lines are the helper's output — for a success, a `blocked`, or a `declined` alike. The manual-mode close-out vocabulary (`ready-to-merge-child`, `Review Summary`, a checkpoint comment) is never the last thing an autonomous session prints.

**The final message *is* the stdout (DOD-1389).** The kernel spawns the provider CLI in print mode: its stdout is the session's **last assistant message** and nothing else. Running the helper is therefore not reporting — the helper's lines have to be *in* that closing message, flush left, unindented, outside any list item or quote. On 2026-09-08 two of three smoke-#3 dispatches ran the helper, read a valid digest back, and then closed with prose about it ("...emitted `clean-final delivery-tier=standard` as the last output"); the kernel saw silence and charged an attempt each time for work already pushed. On Claude Code the Stop hook `scripts/hook-florist-digest.sh` now refuses that exit — it re-checks the closing message with the kernel's own grammar and, when the session already produced a digest, hands those exact lines back to paste. It is bounded (three refusals, then the session may end) and harness-specific; the invariant above is the contract on every runtime.

## 5. Walls: `blocked` vs `declined`

Both park the unit on the same side-state and raise to a named human. They differ in one thing that matters:

- **`FLORIST-STATUS: blocked reason=<reasonId>`** — the worker hit a wall *while working*: an operational failure or a judgment call above its authority. A plain unblock re-dispatches the same lane to try again.
- **`FLORIST-STATUS: declined reason=<reasonId>`** — the worker refuses the dispatch on **policy**, deterministically: re-dispatching the identical configuration would decline identically, so an unblock that changes nothing the reason names re-declines at once. A decline is a submission, not an exit — emit it and stop; never exit silently and let the lease reap.

Neither charges an attempt (corrected in 0.19.0 — 0.18.0 said a block did): the kernel settles both in the same block CAS that clears the lease, so the reap — the only place an attempt is counted — never sees either. What costs an attempt is **silence**: an exit with no digest leaves a dead lease for the reap, and the § 8 predicate charges the unit when the branch head did not move and no evidence landed. What choosing the wrong one costs is the human's time: the raise carries the reason's unpark instructions, and a block's say what to restore or rule on while a decline's say what configuration to change.

`reason` must be a `reasonId` the kernel's registry knows; an unknown one fails closed and the run is thrown away. The registry (`schemas/reason-registry.json` in dodi-florist) is authoritative — these are the ones a lane worker emits:

| reasonId | Kind | Emit when |
| --- | --- | --- |
| `questions-for-human` | decline | genuine product questions the session cannot answer from the ticket, the register, or the code |
| `needs-human-spec` | decline | the per-child draft-signoff gate is armed and unsatisfied (§7) |
| `fable-unavailable` | decline | compatibility reason meaning a **hard**-policy runtime-local Frontier executor cannot dispatch and policy forbids substituting |
| `tier-mismatch` | decline | the unit's declared tier exceeds what this session is seated to run |
| `spec-mismatch` | blocked | an implementation or planning surprise invalidates the admitted intent itself |
| `worker-blocked` | blocked | a concrete operational wall: auth, missing tooling, a harness that cannot be set up |

**Every operator-choice stop becomes a decline.** There is no operator on the other end of an autonomous dispatch: a question asked into a closing transcript is a silent stall that costs an attempt and reaches nobody. The decline is what reaches a human — the kernel raises it, nudges it, and holds the unit until a named human resolves and unblocks.

## 6. Frontier policy without an operator

`FLORIST_EPIC_TIER` pins spec drafting/review, plan-review and docs-sync tiers as before. Plan writers and revisions use the validated spec-review planner-tier instead (`write-plan/planner-routing.md`); a Frontier writer retains deferred policy even if the epic/session field says `none`. Combined child final/renewal correctness and coherence are hard Frontier on every epic tier; no standard-epic downgrade applies. Where a gate is a Frontier seat, the AGENTS.md § Frontier Availability Policy buckets apply as written, with one invocation-mode route for the missing human. The retained env name `FLORIST_FABLE_POLICY` and decline reason `fable-unavailable` describe Frontier policy across runtimes; they are protocol tokens, not a requirement that Claude Fable execute the seat. Native executor selection is runtime-local per `execution-model.md` § 2.

- **`soft` / `deferred`** — substitute exactly as the policy says; record the `tier-degraded(...)` attribution in the gate comment.
- **`hard`** — the driver's `pending-capacity` park is not reachable from a worker (parking is a kernel act). Emit `declined reason=fable-unavailable` instead when the selected native Frontier executor is unavailable after the existing bounded retries: the kernel's block-and-raise **is** the park, and its unblock is the wake edge.
- **`operator-choice`** — unreachable in autonomous mode by construction (§5).

An epic with no `FLORIST_EPIC_TIER` is treated as `standard` — this default does not lower the hard Frontier child coherence requirement.

## 7. Durable surface and artifact paths

Contract artifacts push to **`FLORIST_EPIC_BRANCH`** at each gate transition, before the digest that cites them, so sibling drafters read canon rather than each other's dangling worktrees. Push, *then* read the SHA — a SHA cited before its push names a commit no successor can fetch.

Because each dispatch is a fresh process with no memory of the last one, autonomous-mode artifacts live at **unit-keyed paths**, not the dated manual ones:

- contract (spec): `docs/specs/<FLORIST_UNIT>-contract.md`
- plan: `docs/plans/<FLORIST_UNIT>-plan.md`

so a successor finds them by construction, and the contract's SHA is recoverable with `git log -1 --format=%H "$FLORIST_EPIC_BRANCH" -- docs/specs/$FLORIST_UNIT-contract.md` — which is the SHA the kernel pinned, provided **no later lane edits the contract artifact**. That is the rule, not a caution: a contract change is a demotion edge, never an edit in place.

Human signoff, where a gate requires it, is a ticket comment headed `# Spec Signoff` naming that contract SHA. Keying it to the SHA is what makes the gate self-invalidating: a re-drafted contract has a new SHA, so an old signoff cannot silently release a spec no human read.

## 8. What is unchanged

The mechanics in `execution-model.md` apply verbatim — the leaf rule (§1), explicit tier pins on every dispatch (§2), dual-wake await (§3), STALLED handling (§4), and manifest discipline (§6), with the manifest at the **unit worktree's** `.dodi/` since there is no epic worktree in a Florist dispatch. The lane's own playbook still declares its phase sequence, seams, and exit edges; this file changes only who is listening and how the session speaks to them.

A `RESUMABLE` exit has no counterpart here: the kernel's lease reap and attempt accounting are the resumption machinery, and a mid-lane context exit is simply a run that produced no digest. Push what is durable before it happens — the successor re-enters from the epic branch.

The deliver lane's `# Lane Checkpoint` comments are a driver-mode surface with no counterpart here: under Florist the checkpoints collapse into digest evidence, and a seat posts none. A delivery seat's durable progress is its commits on `unit/<FLORIST_UNIT>` plus its **Seat Record** (§ 9); a successor dispatch re-enters from those — implementation commits are never redone, and review reuse requires the complete child/base/decision-context identity plus verification evidence per `review/child-review-contract.md`, not HEAD alone.

## 9. Seats and digests

Every kernel lane with a seat, the skill that holds it, what one dispatch runs, and the digest that advances it. `pr-open` has **no seat**: the kernel opens the child PR itself (the `pr-create` irreversible action) once the `impl-ready` digest verifies, and the scheduler dispatches `code-review` when the PR exists. `soak-ready` and the terminals dispatch nothing. A seat-holding skill states its phases, gate tiers, and edges in its own words; it never emits a digest this section does not list.

| Lane | Seat | One dispatch runs | Advances on |
| --- | --- | --- | --- |
| `contract-drafting` | `mature-ticket` | draft the contract, spec-review loop to a clean final round, push to `FLORIST_EPIC_BRANCH` | `artifact-ready` |
| `contract-review` | `mature-ticket` | write the plan, plan-review loop to a clean final round, push | `clean-final delivery-tier=…` |
| `implementing` | `implement-ticket` | implement → Capable feedback → tests → docs-sync → verify → combined hard Frontier correctness/coherence final → push | `impl-ready head=…` |
| `pr-open` | — (kernel) | `pr-create` over the digest's head | scheduler dispatch |
| `code-review` | `review` | validate full coverage; reuse unchanged approval or verify/fix and renew at hard Frontier; push fixes | `clean-final` (in-lane: the scheduler upgrades to `integrating` when the epic's integration slot is free) |
| `integrating` | `review` | serialized currency/coverage check → sync, **or** renewed/reused staged coherence verdict | `synced head=…` (→ `code-review`) / `merge-ready head=…` (→ kernel `child-merge` → `soak-ready`) |

### Outcomes the kernel accepts, per lane

The kernel validates evidence presence and SHA identity before it commits anything; a row missing here is a rejected submission (thrown away, the attempt settles) and a SHA that does not match is `blocked:sha-mismatch`. `head=` is always the branch head **as the kernel observes it now** — the local `unit/<FLORIST_UNIT>` ref, which after the required push is also origin's.

| Outcome | Lane | Required fields | Required evidence | What the kernel does |
| --- | --- | --- | --- | --- |
| `artifact-ready` | contract-drafting | — | spec `artifact` first with a real `sha` (the pushed contract commit), plus `artifact ref=planner-routing:<locator>` at the same SHA | → `contract-review`; pins `contractSha` and preserves `plannerRouting` |
| `findings` | contract-review | — | `thread` | → `contract-drafting` (a new lane, a new attempt budget) |
| `clean-final` | contract-review | `delivery-tier=standard\|capable` | `thread` with `sha` = the pinned contract SHA | → `ready-to-implement`; stamps `deliveryTier` |
| `impl-ready` | implementing | `head=<sha>` | `artifact` `sha`=head; `thread` `sha`=head (the combined final); `ci` `sha`=head | branch head must equal `head`; then `pr-create` → `pr-open` |
| `demote` | implementing, code-review | — | `thread` (the demotion record) | → `contract-drafting` |
| `findings` | code-review | — | `thread` | **in-lane**: lease released, `attempt`+1, a fresh seat re-dispatches; the attempt ceiling is the escalation |
| `clean-final` | code-review | — | `thread` with `sha` = the branch head now | **in-lane**: pins `headSha`; the scheduler moves the unit to `integrating` when the slot is free |
| `synced` | integrating | `head=<sha>` | none required (record the sync as `artifact`) | → `code-review`; the merged delta re-passes review |
| `merge-ready` | integrating | `head=<sha>` | `verdict` with `ref=<OUTCOME>[:<sibling>,…]` and `sha`=head | records the verdict, then `child-merge` at exactly `head` → `soak-ready`; `GATE1_AMENDMENT`/`GATE1_REFRESH` park on `gate1-ruling` instead; `LEGITIMATE_DIVERGENCE` realigns the named siblings — the kernel's act, never the worker's |
| `blocked` | any | `reason=<reasonId>` | none required | side-state + raise; unblock re-enters the same lane at the same attempt |
| `declined` | any | `reason=<reasonId>` | none required | side-state + raise; deterministic — an unchanged re-dispatch re-declines; no attempt either way (§ 5) |

`verdict` outcomes are exactly `ALIGNED`, `MINOR`, `LEGITIMATE_DIVERGENCE`, `MATERIAL_DRIFT`, `GATE1_AMENDMENT`, `GATE1_REFRESH`; siblings are unit ids, comma-separated, no spaces, only on `LEGITIMATE_DIVERGENCE`. Anything else fails closed — no verdict, no merge.

### Evidence refs and the Seat Record

`ref` is a locator, never prose: a URL (a ticket comment, a PR), a repo path (`docs/specs/<unit>-contract.md`), or a `<kind>:<label>` token such as `sync:<epic sha>`. `sha` carries the commit the row attests to, and `-` only where the table above leaves the SHA free.

The existing successful spec review carries a separate typed planner-routing artifact, not a new digest field or child-review record. Read `write-plan/planner-routing.md` for the exact schema, content identity, capability guard, legacy handling and `UnitDoc.plannerRouting` preservation. The kernel must ingest it at drafting success and materialize it before planning; parser acceptance alone does not prove preservation. No extra reviewer/classifier stage is added, and `delivery-tier` remains the later plan reviewer's independent classification.

Every **delivery** seat closes with one ticket comment headed `# Seat Record`, posted before the digest, carrying: `unit`, `lane`, `attempt`, `head`; each gate's `gate-ledger:` line (`review` § Gate Ledger) with the SHA its clean closing round reviewed — the combined final's identity is the baseline the code-review seat checks for freshness; every completed review round's dispatcher-authored `review-executor:` line (`review` § Native Executor Evidence), including clean rounds; every runner digest's commands, exit codes, and the head SHA it ran against, the local-CI runner's named explicitly; the reviewed diff ranges; the epic head a sync merged; and the verdict where one was recorded. Its URL is the default `ref` for `thread` and `ci` rows. It is an ordinary comment — bookkeeping under the comment-species partition, never a status write — and it is what a successor dispatch reads to avoid redoing a clean gate at the same head (§ 8).

## 10. Child-review companion and proposal boundary

The companion may perform unchanged code-review/integrating coverage transitions without provider dispatch, using the same evidence/identity checks and existing lease/slot/pin rules with an explicit kernel reuse receipt. Such a transition does not emit a worker digest or count as a model review. The seat table describes provider work when needed for changed/unknown coverage; a dispatched seat still owes its existing digest. No success by silence.

Before implementing/code-review/integrating work, run `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/child-review-gate.py" require-kernel`; failure closes with `blocked reason=worker-blocked`. The helper is a compatibility signal check, not kernel attestation. Read `review/florist-companion.md` for deployment requirements and `review/child-review-contract.md` for the evidence schema/freshness rule.

Success in each delivery seat additionally carries `artifact ref=child-review:<record-locator> sha=<head>`. Existing outcome names, required thread/CI/verdict rows, reserved clean-final prefix, and final-message digest helper remain. The new companion validates the record and action pins; the current legacy parser's acceptance alone does not satisfy this contract. On reuse, the seat still posts its Seat Record and emits the normal success digest, preserving original Frontier provenance and recording live coverage checks.

Coherence proposals are staged on the child before PR opening and remain non-canonical through pre-merge review. The integrating worker never writes proposed canon or strips sibling readiness. The companion publishes staged decisions only after verified merge, under the real merge SHA, before releasing the integration barrier; existing drift/human routing and audit recovery remain. External tracker edits are not atomically frozen by this barrier: live revalidation detects changes, and any detected drift invalidates approval; document the residual check/action race rather than claiming an external lock.
