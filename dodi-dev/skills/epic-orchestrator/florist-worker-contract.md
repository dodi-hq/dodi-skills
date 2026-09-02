# Florist Worker Contract

The single canon of what changes when a lane session is **spawned by the Florist kernel** instead of invoked by a human. Written for the executing session; referenced by every skill that holds a Florist seat (today `mature-ticket`; the delivery-lane skills as their seats land).

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

The worker's worktree is on `unit/<FLORIST_UNIT>`, forked from `FLORIST_EPIC_BRANCH`, and **persists across dispatches** for that unit: a later lane sees the earlier lane's files without fetching anything.

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

- **`FLORIST-STATUS: blocked reason=<reasonId>`** — the worker hit a wall *while working*: an operational failure or a judgment call above its authority. The attempt is spent.
- **`FLORIST-STATUS: declined reason=<reasonId>`** — the worker refuses the dispatch on **policy**, deterministically: re-dispatching the identical configuration would decline identically, so **no attempt is burned**. A decline is a submission, not an exit — emit it and stop; never exit silently and let the lease reap.

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
