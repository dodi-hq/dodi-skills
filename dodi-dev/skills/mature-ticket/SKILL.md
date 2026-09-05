---
name: mature-ticket
description: Use when a child ticket lacks spec-ready or ready-to-implement and needs specification, plan, review, or human input
---

# Mature Ticket

Entry point for one mature lane — move a child ticket through spec and plan maturity gates under the two-gate model. Gate 1 epic signoff is the recorded delegation for every child, so routine per-child signoff is not required; the escape hatches preserve human input where it genuinely matters.

The lane's sequence, signoff model, per-gate push-back, durable seams, and stop conditions live in **`epic-orchestrator/lanes/mature-playbook.md`**; the dispatch mechanics (leaf rule, tier pins, dual-wake await, STALLED handling, the `RESUMABLE`/seam/continuation-brief mechanics, manifest discipline) live in **`epic-orchestrator/execution-model.md`**. This skill restates neither — it names the contract and the claim discipline, then executes the playbook. In the autonomous epic, the resident driver (`drive-epic`) executes the same playbook inline.

## Invocation modes

This skill has **two** modes, and the first thing it does is tell them apart:

| | **Manual** | **Autonomous (Florist)** |
| --- | --- | --- |
| Detected by | `FLORIST_UNIT` unset | `FLORIST_UNIT` set |
| Driven by | a present operator | the Florist kernel, one dispatch per lane |
| Scope | the whole lane, spec through plan | the phase range its `FLORIST_LANE` seats |
| Claim | `claim.sh` / `release-claim.sh` | the kernel's lease — **never** the claim scripts |
| Result | labels + gate comments | a stdout digest; the kernel moves the lane |
| Human stop | ask the operator | `declined` — there is nobody to ask |

**First step, both modes — run `"${CLAUDE_PLUGIN_ROOT}/scripts/florist-mode.sh"` before anything else.** It prints `mode=manual` or `mode=autonomous …` from the environment itself (`florist-worker-contract.md` § 1, DOD-1326). In autonomous mode, follow the three instructions it prints: read the contract now, run only § Florist seats below for your `FLORIST_LANE`, and close through `florist-digest.sh` — its output is the last thing you print. A session that skips this step and reaches a manual close-out has silently exited as far as the kernel is concerned.

**Autonomous mode is governed by `epic-orchestrator/florist-worker-contract.md`** — read it before anything else in that mode. It is the canon for the digest grammar, the decline vocabulary, the env contract, the artifact paths, and the writes a worker must never make. This file states only what is specific to the mature lane.

There is no frontmatter `model:` pin: the main loop runs at whatever tier its invoker seated it at — Florist seats the autonomous session per `worker-dispatch.json` (Standard, a router by design), and in manual mode the operator's own session pin applies. Worker dispatches are unaffected either way: every dispatch inside the playbook carries its own explicit pin and fable-policy (`execution-model.md` § 2), and a dispatch without a pin is a defect the tier-pin hook forbids.

## Gate tiers by epic tier (autonomous mode)

`FLORIST_EPIC_TIER` pins the lane's gate tiers before any dispatch is written. Unset is treated as `standard`.

| `FLORIST_EPIC_TIER` | Spec/plan gates | Research + read-and-digest | Fable |
| --- | --- | --- | --- |
| `standard` | Capable tier (`model: opus` on Claude Code) | Standard tier (`model: sonnet`) | nowhere — a smoke-sized epic never reaches for scarce capacity |
| `capable` | per the AGENTS.md § Fable Availability Policy gate table, unchanged | Standard tier (`model: sonnet`) | hard / deferred / soft per that table |

Under `standard` the fable-policy lookup still happens and still resolves — to a table with no fable seats in it, so no substitution is recorded and `fable-unavailable` cannot fire. Under `capable` the lookup is the existing one, and a **hard** gate that cannot dispatch declines rather than parks (`florist-worker-contract.md` § 6).

## Phase range by lane (autonomous mode)

Each dispatch runs the phases its lane seats, then emits one digest. The internal review loops run **inside** the dispatch — a review round is not a lane transition.

| `FLORIST_LANE` | Phases this dispatch runs | Digest on success |
| --- | --- | --- |
| `contract-drafting` | draft the contract, then the spec-review loop to a clean final round | `artifact-ready` + `FLORIST-EVIDENCE: kind=artifact ref=docs/specs/<unit>-contract.md sha=<pushed sha>` |
| `contract-review` | write the plan, then the plan-review loop to a clean final round | `clean-final delivery-tier=<standard\|capable>` + `FLORIST-EVIDENCE: kind=thread ref=<review record> sha=<contract sha>` |

This table is the lane's restatement of `florist-worker-contract.md` § 9, the per-seat canon. The evidence rows are **required**, not decoration: a drafting digest without an artifact row carrying a real SHA is not a submission, and a `clean-final` whose thread SHA is not the pinned contract SHA blocks the unit on `sha-mismatch`. The `delivery-tier` field is likewise required — it is the plan reviewer's classification, and a clean plan review without it is an incomplete result. Push before you read the SHA (`florist-worker-contract.md` § 7). Emit the digest through `"${CLAUDE_PLUGIN_ROOT}/scripts/florist-digest.sh"` (contract § 4) as the last output of the dispatch.

### The other edges

| Situation | Digest |
| --- | --- |
| Plan-writing or plan review exposes a contract defect (product, architecture, scope, or spec/plan mismatch) | `findings` + `kind=thread` evidence — the kernel returns the unit to `contract-drafting`. This is the demotion edge; never redesign the contract from the review lane |
| The drafter surfaces genuine product questions | `declined reason=questions-for-human`, the questions posted on the ticket |
| `FLORIST_NEEDS_HUMAN_SPEC=1` and the draft-signoff gate is unsatisfied (below) | `declined reason=needs-human-spec` |
| A **hard** fable gate cannot dispatch | `declined reason=fable-unavailable` |
| The admitted intent itself is invalidated | `blocked reason=spec-mismatch` |
| An operational wall — auth, tooling, an unbuildable harness | `blocked reason=worker-blocked` |

### The per-child draft-signoff gate

`FLORIST_NEEDS_HUMAN_SPEC=1` is **draft-then-review, never wait-then-draft**: the contract is drafted and reviewed autonomously in `contract-drafting` and pushed like any other, so the human reviews something real. The gate lands one phase later, at the top of `contract-review`, **before** plan-writing:

1. Compute the contract SHA (`florist-worker-contract.md` § 7).
2. Look for a ticket comment headed `# Spec Signoff` naming that SHA.
3. Absent ⇒ `declined reason=needs-human-spec`, with the SHA and the contract's path in the transcript so the raise carries them. Present ⇒ proceed to plan-writing; the signoff has been given against exactly this contract.

Keying the gate to the SHA is what makes it terminate: the unblock alone releases nothing, and a re-drafted contract needs a fresh signoff rather than inheriting an old one.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child lacks `spec-ready` or `ready-to-implement` | ticket id, current artifacts, dependency context, Gate 1 delegation record | clean spec, clean plan, readiness label decision | artifact links, reviewer evidence, assumptions, labels | spec drafter, spec reviewer, plan writer, plan reviewer | needs human spec input, unresolved dependency, review findings, spec/plan mismatch |

In autonomous mode the outputs and durable writes are the digest and the epic-branch push; the labels are the kernel's projection, never this session's to apply.

## Claim discipline (manual mode)

Manual invocation is a lane session under the same per-ticket claim discipline the driver applies: claim the ticket first (`${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> mature-ticket <session-run-id>`), skipping any live claim from another session per the liveness hierarchy; fence and release the claim with its exit state (`${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> --session <session-run-id>`) at close-out. Claims serialize tickets; worktrees serialize files; nothing serializes runs.

Autonomous mode runs **none** of this: the kernel's lease is the claim, and a claim comment written under a lease is a second lock with no arbiter.

## Session tier (manual mode)

Before claiming, confirm the main loop is running the tier the operator intends for spec and plan judgment. If it is not — or if fable capacity fails mid-lane — stop and put the choice to the operator per AGENTS.md § Fable Availability Policy's `operator-choice` row: **wait**, or **proceed at Capable tier (`model: opus` on Claude Code) at `max` effort**, with the substitution declared in that row's `session-tier:` grammar on each gate-transition comment. Autonomous mode never reaches this row (`florist-worker-contract.md` § 5).

## Exit states (manual mode)

- **Advance** — `spec-ready` applied (after clean spec review), then `ready-to-implement` (after clean plan review + dependency check, `needs-capable-delivery` where classified).
- **awaiting-epic-signoff** — neither `epic-signed-off` nor a per-child signoff present.
- **QUESTIONS_FOR_HUMAN** — the spec drafter returned open product questions; stop and ask regardless of delegation.
- **blocked-dependency** — an unresolved dependency.
- **demote-to-spec** — a product, architecture, scope, or spec/plan mismatch surprise: comment per the demotion rules in `epic-orchestrator/state-transitions.md` and exit.
- **RESUMABLE** — a deliberate context exit (an emergency reset — capacity-park and refresh-park are driver-only exits, not reachable by a manual session, which stops and reports to the operator instead): push to the epic branch, write the continuation brief, and exit for re-dispatch.
- **operator-wait** — fable unavailable at the session pin and the operator chose to wait: stop and report — never a park. At invocation this is a plain stop before any claim; mid-lane it is a `RESUMABLE` exit (push + continuation brief naming fable capacity as the resume condition). A **proceed** choice is not an exit — the lane continues at the declared substitution.

In autonomous mode these exit states are not reported anywhere: the digest is the only exit, and every one of them maps to a row in the tables above. `awaiting-epic-signoff` is structurally unreachable — an un-admitted unit never dispatches, and the admit attestation **is** the recorded Gate-1 delegation.
