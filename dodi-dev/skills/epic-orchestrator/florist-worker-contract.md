# Florist Worker Contract

The single canon of what changes when a lane session is **spawned by the Florist kernel** instead of invoked by a human. Written for the executing session; referenced by every skill that holds a Florist seat — `mature-ticket` for the contract lanes, `implement-ticket` for `implementing`, `review` for `code-review` and `integrating`. § 9 is the per-seat table: which skill sits where, and the one digest each seat owes.

Florist is the durable orchestration kernel that replaces the prose state machine these skills carry between them: it owns unit state, leases, attempt accounting, escalation, and the tracker projection, and it dispatches a provider CLI per lane into a per-unit worktree. The session it spawns is a **worker**, not a driver. Everything below follows from that one fact.

## 1. Mode detection

`FLORIST_UNIT` is set in the environment ⇒ **autonomous mode**. Absent ⇒ manual mode, unchanged — a human invoked the skill and is present to answer it.

The check is the environment variable itself, never a heuristic about the harness, the model, or the presence of a tty. A skill that holds a Florist seat states both modes explicitly; a skill that holds none never reads this file.

## 2. What the kernel tells the worker

| Variable | Meaning | Absent when |
| --- | --- | --- |
| `FLORIST_UNIT` | the unit id (`DOD-xxxx`), also the tracker identifier and the mode flag | not a Florist dispatch |
| `FLORIST_LANE` | the lane this dispatch is seated for — the phase range below | never |
| `FLORIST_ATTEMPT` | this lane's attempt counter, for the transcript | never |
| `FLORIST_TIER` | the session's own `<tier>@<effort>`, the seat's declared pairing | never |
| `FLORIST_FABLE_POLICY` | the seat's fable-availability bucket (`none` on a non-fable seat) | never |
| `FLORIST_EPIC_TIER` | the epic's design-phase capability assessment (`standard` \| `capable`) | the epic is unassessed |
| `FLORIST_DELIVERY_TIER` | the unit's plan-reviewer delivery classification (`standard` \| `capable`) | not yet classified |
| `FLORIST_NEEDS_HUMAN_SPEC` | `1` iff the admit-time product snapshot carried the `needs-human-spec` label | the label was absent |
| `FLORIST_EPIC_BRANCH` | the epic branch unit branches fork from — the contract lanes' durable surface | never |
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
| `fable-unavailable` | decline | a **hard**-policy fable gate cannot dispatch and policy forbids substituting |
| `tier-mismatch` | decline | the unit's declared tier exceeds what this session is seated to run |
| `spec-mismatch` | blocked | an implementation or planning surprise invalidates the admitted intent itself |
| `worker-blocked` | blocked | a concrete operational wall: auth, missing tooling, a harness that cannot be set up |

**Every operator-choice stop becomes a decline.** There is no operator on the other end of an autonomous dispatch: a question asked into a closing transcript is a silent stall that costs an attempt and reaches nobody. The decline is what reaches a human — the kernel raises it, nudges it, and holds the unit until a named human resolves and unblocks.

## 6. Fable policy without an operator

`FLORIST_EPIC_TIER` pins the lane's gate tiers (the seat-holding skill states its own mapping). Where a gate is a fable seat, the AGENTS.md § Fable Availability Policy buckets apply as written, with one substitution for the missing human:

- **`soft` / `deferred`** — substitute exactly as the policy says; record the `tier-degraded(...)` attribution in the gate comment.
- **`hard`** — the driver's `pending-capacity` park is not reachable from a worker (parking is a kernel act). Emit `declined reason=fable-unavailable` instead: the kernel's block-and-raise **is** the park, and its unblock is the wake edge.
- **`operator-choice`** — unreachable in autonomous mode by construction (§5).

An epic with no `FLORIST_EPIC_TIER` is treated as `standard` — an unassessed epic never reaches for scarce capacity.

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

The deliver lane's `# Lane Checkpoint` comments are a driver-mode surface with no counterpart here: under Florist the checkpoints collapse into digest evidence, and a seat posts none. A delivery seat's durable progress is its commits on `unit/<FLORIST_UNIT>` plus its **Seat Record** (§ 9); a successor dispatch re-enters from those — implementation commits are never redone, and a gate is re-run at the current head unless a Seat Record for exactly that head already records it clean.

## 9. Seats and digests

Every kernel lane with a seat, the skill that holds it, what one dispatch runs, and the digest that advances it. `pr-open` has **no seat**: the kernel opens the child PR itself (the `pr-create` irreversible action) once the `impl-ready` digest verifies, and the scheduler dispatches `code-review` when the PR exists. `soak-ready` and the terminals dispatch nothing. A seat-holding skill states its phases, gate tiers, and edges in its own words; it never emits a digest this section does not list.

| Lane | Seat | One dispatch runs | Advances on |
| --- | --- | --- | --- |
| `contract-drafting` | `mature-ticket` | draft the contract, spec-review loop to a clean final round, push to `FLORIST_EPIC_BRANCH` | `artifact-ready` |
| `contract-review` | `mature-ticket` | write the plan, plan-review loop to a clean final round, push | `clean-final delivery-tier=…` |
| `implementing` | `implement-ticket` | implement → pre-PR review loop → tests → docs-sync → verify → push | `impl-ready head=…` |
| `pr-open` | — (kernel) | `pr-create` over the digest's head | scheduler dispatch |
| `code-review` | `review` | the child-PR integration pair + fix loop + conditional local CI, on the kernel-opened PR; push fixes | `clean-final` (in-lane: the scheduler upgrades to `integrating` when the epic's integration slot is free) |
| `integrating` | `review` | currency check → sync, **or** the coherence verdict | `synced head=…` (→ `code-review`) / `merge-ready head=…` (→ kernel `child-merge` → `soak-ready`) |

### Outcomes the kernel accepts, per lane

The kernel validates evidence presence and SHA identity before it commits anything; a row missing here is a rejected submission (thrown away, the attempt settles) and a SHA that does not match is `blocked:sha-mismatch`. `head=` is always the branch head **as the kernel observes it now** — the local `unit/<FLORIST_UNIT>` ref, which after the required push is also origin's.

| Outcome | Lane | Required fields | Required evidence | What the kernel does |
| --- | --- | --- | --- | --- |
| `artifact-ready` | contract-drafting | — | `artifact` with a real `sha` (the pushed contract commit) | → `contract-review`; pins `contractSha` |
| `findings` | contract-review | — | `thread` | → `contract-drafting` (a new lane, a new attempt budget) |
| `clean-final` | contract-review | `delivery-tier=standard\|capable` | `thread` with `sha` = the pinned contract SHA | → `ready-to-implement`; stamps `deliveryTier` |
| `impl-ready` | implementing | `head=<sha>` | `artifact` `sha`=head; `thread` (the clean closing pre-PR round, its own reviewed SHA); `ci` `sha`=head | branch head must equal `head`; then `pr-create` → `pr-open` |
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

Every **delivery** seat closes with one ticket comment headed `# Seat Record`, posted before the digest, carrying: `unit`, `lane`, `attempt`, `head`; each gate's `gate-ledger:` line (`review` § Gate Ledger) with the SHA its clean closing round reviewed — the pre-PR gate's is the baseline the code-review seat aims its delta at; every runner digest's commands, exit codes, and the head SHA it ran against, the local-CI runner's named explicitly; the reviewed diff ranges; the epic head a sync merged; and the verdict where one was recorded. Its URL is the default `ref` for `thread` and `ci` rows. It is an ordinary comment — bookkeeping under the comment-species partition, never a status write — and it is what a successor dispatch reads to avoid redoing a clean gate at the same head (§ 8).
