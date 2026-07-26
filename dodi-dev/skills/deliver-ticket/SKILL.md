---
name: deliver-ticket
description: Execute one ready child ticket end to end in a single lane session — pickup through open child PR and child-PR review — ending at ready-to-merge-child
model: sonnet
---

# Deliver Ticket

Manual entry point for one deliver lane — a single child ticket, run end to end in its own worktree, from pickup through open child PR and child-PR review, ending at `ready-to-merge-child`. The lane never merges and never touches the epic branch.

The lane's sequence, checkpoints, and context-hygiene seams live in **`epic-orchestrator/lanes/deliver-playbook.md`**; the dispatch mechanics (leaf rule, tier pins, dual-wake await, STALLED handling, the `RESUMABLE`/seam/continuation-brief mechanics, manifest discipline) live in **`epic-orchestrator/execution-model.md`**. This skill restates neither — it is the manual wrapper that names the contract and the claim discipline, then executes the playbook. In the autonomous epic, the resident driver (`drive-epic`) executes the same playbook inline; this skill is for a single ticket driven by hand.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child has `spec-ready` and `ready-to-implement` | ticket id, clean spec, clean plan (with Testing Contract), register canon summary, epic branch, repo path | `ready-to-merge-child` with full evidence trail, or an exit state | checkpoint comments per state boundary, child PR, notes entries | implementer workers, reviewers, test runners, fix workers, docs-sync worker | demotion surprise, concrete blocker, resumable context exit |

## Claim discipline

Manual invocation is a lane session under the same per-ticket claim discipline the driver applies: claim the ticket first (`${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> deliver-ticket <session-run-id>`), skipping any live claim from another session per the liveness hierarchy; fence and release the claim with its exit state (`${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> --session <session-run-id>`) at close-out. Claims serialize tickets; worktrees serialize files; nothing serializes runs.

## Exit states

- **ready-to-merge-child** — success; the orchestrator owns the merge.
- **demote-to-spec** — any product, architecture, scope, or spec/plan mismatch surprise: comment per the demotion rules in `epic-orchestrator/state-transitions.md` and exit. Never redesign mid-flight.
- **blocked** — concrete blocker (auth, tooling, a harness that cannot be set up): comment the blocker and exit.
- **RESUMABLE** — deliberate context exit (the verify→PR seam, or an emergency reset — capacity-park and refresh-park are driver-only exits, not reachable by a manual session, which stops and reports to the operator instead): commit on the child branch, write the continuation brief, and exit for re-dispatch.
