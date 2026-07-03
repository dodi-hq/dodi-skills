---
name: pickup-next
description: Use as the scheduled tick that scans the PM system for signed-off epics and advances exactly one actionable ticket per run, then exits
model: sonnet
---

# Pickup Next

The stateless heartbeat of autonomous delivery. Each run: scan the PM system, pick the single highest-priority actionable item, run the corresponding lane skill to its natural exit, checkpoint, and exit. Nothing survives between runs except durable PM/git state — a run that crashes loses nothing a later run cannot reconstruct.

This skill replaces the resident orchestrator loop. It only acts **after Gate 1**: epics without `epic-signed-off` are human territory (interactive `epic-orchestrator` sessions at the monitor) and are skipped entirely. Gate 2 is procedural and absolute: no tick ever merges, auto-merges, or enables auto-merge on an epic PR.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| scheduled tick or manual run | PM team/project scope, repo path(s), retry ceiling (default 3) | one advanced ticket or a clean no-op | claim comment, lane checkpoint comments (via lane skills), escalation comments | `mature-ticket`, `deliver-ticket`, `submit-ticket-pr` (Merge), `submit-epic-pr`, state-reader and evidence-checker workers | PM unreachable, retry ceiling hit, claim conflict, tool/auth failure |

## Inputs

- PM system scope (team or project)
- repo path(s)
- optional `retryCeiling` (default `3`)
- optional `humanContact`

## Process — One Pass

1. **Scan.** Dispatch a state-reader worker (see `epic-orchestrator/state-reader-prompt.md`, Fast tier — `model: haiku` on Claude Code) for epics carrying `epic-signed-off` that are not parked at `epic-pr-open`. Skip every epic without the label. Consume the state map; do not read raw PM dumps in the main loop.
2. **Select one action**, highest priority first, honoring the routing tables and demotion rules in `epic-orchestrator/state-transitions.md`:
   1. Merge a `ready-to-merge-child` (serial merge slot; evidence-checker verification per `epic-orchestrator/evidence-checker-prompt.md` before merging).
   2. Run `submit-epic-pr` when all children of an epic are done and no epic PR is open.
   3. Resume a lane that exited `RESUMABLE` (attempt counter below the retry ceiling).
   4. Dispatch `deliver-ticket` for a `ready-to-implement` child with dependencies clear.
   5. Run `mature-ticket` for a child lacking `spec-ready` or `ready-to-implement`.
3. **Claim.** Before acting, post the claim comment on the chosen ticket: host, timestamp, intended action, consecutive-attempt counter for that ticket+action. Skip any ticket carrying a live claim from another host that is younger than the lease window (2 hours) — `reconcile-tickets` expires stale claims; the tick never steals one.
4. **Act.** Run the selected lane skill to its natural exit. Lane-internal behavior is unchanged: checkpoint comments, worker dispatch discipline, tier pins, stop conditions all per the lane skill.
5. **Close out.** Update the claim comment with the exit state and evidence links. On a stop condition (`QUESTIONS_FOR_HUMAN`, demotion, blocker, retry ceiling), post the scannable escalation comment (TL;DR + Key Points) and notify `humanContact` if set. Exit.

Nothing actionable → log a one-line no-op and exit silently. A no-op is success, not an error.

## Retry Ceiling

The claim comment carries a consecutive-attempt counter per ticket+action. When a run would be attempt `retryCeiling + 1` after consecutive `RESUMABLE`/failed exits, do not attempt: mark the ticket `blocked`, post an escalation comment with the attempt trail, and leave it for a human or for `reconcile-tickets` to clear when the blocker is demonstrably resolved. A successful exit resets the counter.

## Rules

- **One action per run.** Never chain a second selection after the first completes — the next tick picks it up. This bounds run length and keeps every run resumable.
- PM state is the only memory. Never rely on anything from a previous run's session.
- Claims are for crash visibility and multi-host coexistence, not locking — on one machine the scheduler's no-overlap guarantee already serializes ticks.
- All worker and lane dispatches carry explicit model tier pins per AGENTS.md dispatch discipline; the tick itself is Standard-tier routing.
- Never touch epics lacking `epic-signed-off`; never merge an epic PR; never advance state without evidence-checker verification (evidence rule unchanged from `epic-orchestrator`).

## Scheduled Task Setup

Run this skill as a **harness-native scheduled task** — never a hand-rolled cron/daemon around a headless CLI.

On Claude Code desktop (Scheduled Tasks):

- Prompt: invoke `dodi-dev:pickup-next` with the PM scope and repo path(s); the prompt must be self-contained (fresh session per run, no memory of prior runs).
- Schedule: every ~15 minutes on an off-peak minute (e.g. `4,19,34,49 * * * *`).
- Permission mode: Auto, respecting the settings allow-list. Merging the epic PR must not be in any allow-list, but the real guard is procedural: this skill never does it.
- Isolation: worktree-per-run for the tick session; lane skills manage their own child worktrees.
- The scheduler's no-overlap guarantee means a long lane run simply delays the next tick — that is correct behavior, not a fault.
- Runs require the app open and the machine awake; suits a dedicated hive machine.

Machine-off operation (cloud-hosted routines with a fresh repo clone per run) is the upgrade path once the repo's test harness is proven to run in a fresh clone. On other harnesses, use the closest native scheduler with the same properties: fresh session, no overlapping runs, per-run permissions.

## Evidence

- Record per run: scope scanned, action selected (or no-op), ticket id, claim comment link, exit state, evidence links from the lane skill.
- Escalations carry the scannable header and the full attempt trail.

## Stop Conditions

- PM system unreachable or auth failure — escalate; do not retry within the run.
- Selected action's preconditions fail on claim (state moved since the scan) — release the claim, exit as a no-op; the next tick re-scans.
- Retry ceiling reached — mark `blocked`, escalate, exit.
- Any lane stop condition — record it, close out the claim, exit; the lane's own escalation stands.
