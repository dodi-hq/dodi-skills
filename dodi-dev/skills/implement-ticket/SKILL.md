---
name: implement-ticket
description: Use when a ready child ticket has a child worktree and implementation must follow the reviewed plan exactly
---

# Implement Ticket

Dispatch implementation workers against the clean plan. The implementation must follow the plan exactly; surprises that require judgment return the ticket to the spec lane.

## Invocation modes

This skill has **two** modes, and the first thing it does is tell them apart:

| | **Manual** | **Autonomous (Florist)** |
| --- | --- | --- |
| Detected by | `FLORIST_UNIT` unset | `FLORIST_UNIT` set |
| Driven by | the deliver lane's executing session (the resident driver, or a `deliver-ticket` session), which runs this skill as one phase of `epic-orchestrator/lanes/deliver-playbook.md` | the Florist kernel: one dispatch seats `FLORIST_LANE=implementing` |
| Scope | the implementation phase only — review, tests, verify, and the PR are the lane's later phases | the whole implementing seat: implement through a verified, pushed head |
| The PR | never — `submit-ticket-pr` opens it after the verify→PR seam | never — the kernel opens it (`pr-create`) once the digest verifies |
| Result | the `implementation-reviewing` checkpoint + evidence | a stdout digest; the kernel moves the lane |
| Human stop | stop and report to the lane | `declined` / `blocked` — there is nobody to ask |

**First step, both modes — run `"${CLAUDE_PLUGIN_ROOT}/scripts/florist-mode.sh"` before anything else.** It prints `mode=manual` or `mode=autonomous …` from the environment itself (`florist-worker-contract.md` § 1, DOD-1326). In autonomous mode, follow the three instructions it prints: read the contract now, run only § Florist seats below for your `FLORIST_LANE`, and close through `florist-digest.sh` — its output is the last thing you print. A session that skips this step and reaches a manual close-out has silently exited as far as the kernel is concerned.

**Autonomous mode is governed by `epic-orchestrator/florist-worker-contract.md`** — read it before anything else in that mode. It is the canon for the digest grammar, the decline vocabulary, the env contract, the push rule, the Seat Record, and the writes a worker must never make. This file states only what is specific to the implementing seat.

There is no frontmatter `model:` pin (retired in 0.19.0): the kernel seats this session at the unit's delivery tier — the Standard base seat, or the Capable variant when `FLORIST_DELIVERY_TIER=capable` — and a frontmatter pin would override that seat at skill load. In manual mode the lane session's own tier applies (Standard: the lane's main loop is a router). Worker dispatches are unaffected either way: every dispatch below carries its own explicit pin, and a dispatch without one is a defect the tier-pin hook forbids.

## Phase sequence (autonomous mode)

The implementing seat runs the deliver playbook's phases 2–5 plus the docs-sync step, in this order, inside one dispatch, then pushes and emits one digest. Internal review loops run **inside** the dispatch — a round is not a lane transition.

1. **Implement** — `implement/implementer-prompt.md` per task, serially, exact plan adherence (§ Process below).
2. **Pre-PR review** — `review` (pre-PR context), the full gate: rounds plus the final round, capped at 5 rounds plus the final. Its clean closing round is the `thread` evidence the kernel requires.
3. **Tests** — `create-tests` against the plan's Testing Contract.
4. **Docs-sync** — `submit-ticket-pr/docs-sync-prompt.md` in child mode; commit any edit on the unit branch. This step moves here from `submit-ticket-pr` Open (which does not run under Florist) so the edits sit on the head that verification covers and the PR opens over.
5. **Verify** — `verify`: one runner per Testing Contract group plus the local-CI runner, every digest recording the head SHA it ran against. A product-code fix here triggers the focused re-review (`review` § Epic Lane Rules) and re-runs the affected groups and the local-CI runner at the new head.
6. **Push, record, digest** — `git push -u origin unit/$FLORIST_UNIT`, then `head=$(git rev-parse HEAD)`, post the Seat Record, emit the digest through `"${CLAUDE_PLUGIN_ROOT}/scripts/florist-digest.sh" impl-ready head=$head --evidence …` (§ Digest below) as the last output of the session. Nothing is committed after `head` is read.

Inputs arrive on the worktree and the ticket: the contract at `docs/specs/<FLORIST_UNIT>-contract.md` and the plan (with its Testing Contract) at `docs/plans/<FLORIST_UNIT>-plan.md` — both on the unit branch, which forked from `FLORIST_EPIC_BRANCH` after the contract lanes pushed them; the ticket via `${CLAUDE_PLUGIN_ROOT}/scripts/linear-api.sh`; the decision-register canon in the epic ticket's description.

**Resume** (`FLORIST_ATTEMPT` > 0, or a worktree with commits already on it): the worktree persists across dispatches. Read the Seat Record(s) and the branch log first. Implementation commits are never redone; a gate is re-run at the current head unless a Seat Record for exactly that head already records it clean.

## Tiers (autonomous mode)

Writers follow `FLORIST_DELIVERY_TIER` — the kernel's truth behind the `needs-capable-delivery` label, which is a projection this session never applies:

| `FLORIST_DELIVERY_TIER` | Implementers and fix workers |
| --- | --- |
| `capable` | every one at Capable tier (`model: opus` on Claude Code), no per-task demotion |
| `standard` / unset | `implement/SKILL.md` § Model Selection's per-task defaults |

Gates follow `FLORIST_EPIC_TIER` (unset is treated as `standard`):

| `FLORIST_EPIC_TIER` | Pre-PR rounds | Pre-PR final round | Focused re-review | Docs-sync | Runners |
| --- | --- | --- | --- | --- | --- |
| `standard` | Capable (`opus`) | Capable — fable nowhere; no substitution recorded, because no fable seat exists at this tier | Capable | Capable (the soft seat resolves the same way) | Fast (`haiku`) |
| `capable` | Capable | Frontier (`fable`), policy **deferred**: `opus` substitutes with the `tier-degraded(...)` marker and a `Kind: FABLE_MAKEUP` register entry on the epic ticket | Capable | Frontier, policy **soft** | Fast |

Under `capable` the AGENTS.md § Fable Availability Policy table applies as written, with the contract's § 6 substitution: no gate in this seat is **hard**, so `fable-unavailable` cannot fire here.

## Digest (autonomous mode)

On success:

```
FLORIST-STATUS: impl-ready head=<sha>
FLORIST-EVIDENCE: kind=artifact ref=unit/<FLORIST_UNIT> sha=<head>
FLORIST-EVIDENCE: kind=thread ref=<Seat Record URL> sha=<sha the clean closing pre-PR round reviewed>
FLORIST-EVIDENCE: kind=ci ref=<Seat Record URL> sha=<head>
```

- `head` is the pushed head. The kernel blocks the unit on `sha-mismatch` if the branch head differs, and `pr-create` refuses if origin differs — push, then read (`florist-worker-contract.md` § 2).
- The `artifact` and `ci` rows are **SHA-matched to `head`** or the digest is not a submission. Any commit after the last local-CI run — a fix, a docs-sync edit — means the runners run again at the new head before the push.
- The `thread` row's SHA is the one the closing pre-PR round reviewed. It may precede `head`: tests and docs-sync commits follow the pre-PR gate by design, and the child-PR gate reviews them as the delta.

### The other edges

| Situation | Digest |
| --- | --- |
| A product, architecture, scope, or plan mismatch surprise — from an implementer, the pre-PR gate, tests, or verification | `demote` + `FLORIST-EVIDENCE: kind=thread ref=<demotion comment URL> sha=-`. Post the comment per `epic-orchestrator/state-transitions.md` § Demotion Rules (with its `rework-origin:` line) — never redesign in-lane; the kernel returns the unit to `contract-drafting` |
| The pre-PR loop cap is exhausted with findings still open | `blocked reason=spec-mismatch`, the unresolved findings and their `gate-ledger:` line in the Seat Record. A gate that cannot converge is the strongest evidence the admitted intent is unsound, and this reason's unpark is exactly the ruling that fits (unblock if the spec holds, or preempt and refile) |
| The admitted intent itself is invalidated | `blocked reason=spec-mismatch` |
| An operational wall — auth, tooling, a required harness that cannot be set up, no `LINEAR_API_KEY` | `blocked reason=worker-blocked` |
| `FLORIST_DELIVERY_TIER=capable` but `FLORIST_TIER` seats a Standard session | `declined reason=tier-mismatch` — before any dispatch |

An implementer's `NEEDS_CONTEXT` that the ticket, the register canon, and the code cannot answer is a plan-mismatch surprise: demote. There is no operator to supply context mid-lane.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child worktree exists | ticket id, clean spec, clean plan, child worktree | implementation commits or explicit escalation | ticket comment with commit ids, worker evidence, surprise notes | implementation workers only | product decision needed, architecture decision needed, scope surprise, plan mismatch, worker blocked |

In autonomous mode the durable writes are the commits on `unit/<FLORIST_UNIT>`, the push, and the Seat Record; the allowed delegation widens to the seat's whole phase sequence (reviewers, test workers, runners, the docs-sync worker), each a leaf.

## Inputs

- ticket id
- clean spec
- clean plan
- child branch and worktree
- repo instructions
- Testing Contract from the plan

## Process

- Read the clean plan and dispatch bounded implementation workers.
- Require exact plan adherence.
- Demote to the spec lane on product, architecture, scope, or plan mismatch surprises.
- Keep implementation workers scoped to the plan and child worktree.
- Record commits and commands as implementation evidence.
- Do not create PRs or merge branches from this step; the deliver-ticket lane owns the PR stage and the orchestrator owns merges — and under Florist the kernel owns both.

## Evidence

- Record worker status, commit ids, files changed, commands run, and surprise notes.
- Record any demotion reason and the artifact that must be revised.

## Stop Conditions (manual mode)

- Stop on product decision, architecture decision, scope surprise, plan mismatch, or worker blocker.
- Stop if implementation cannot follow the plan without new judgment.
- Stop if required dependencies are unavailable.
- Stop at `ready-for-child-pr` only after review, tests, and verification (incl. repo-local checks) are clean.

In autonomous mode none of these is reported anywhere: the digest is the only exit, and every one of them maps to a row in the tables above.
