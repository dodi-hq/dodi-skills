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
   1. Merge a `ready-to-merge-child` (serial merge slot; evidence-checker verification per `epic-orchestrator/evidence-checker-prompt.md` before merging; postconditions via `${CLAUDE_PLUGIN_ROOT}/scripts/verify-merge.sh` and `${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-branch.sh`). **Merge-eligibility guard: no merge action is eligible while the epic holds `coherence-pending`** — this keeps reviews serial and the register append-ordered. **Fail-closed ordering: apply `coherence-pending` to the epic _before_ the merge command** (the irreversible write is the inlined `submit-ticket-pr` Merge, re-verified against the driver-claim status immediately before it), never after — a crash between merge and label under the old order left a merged child with no coherence review and, in gate-fail revert mode where no driver ever boots, no detector.
   2. **Run the epic-coherence review for a `coherence-pending` epic — full set-difference protocol.** Fetch all merged child PRs targeting the epic branch (`mergeCommit` oids) and all register-entry `Merge SHA:` keys (a **paged** read); the **target set** is every merged-but-unregistered SHA, reviewed **oldest `mergedAt` first, serially**, each dispatch noting that register entries newer than the SHA under review are **not precedent**. For each, the loop-side idempotence check first (an entry for this SHA ⇒ resume missing routing writes, do not re-dispatch); otherwise dispatch `epic-orchestrator/coherence-reviewer-prompt.md` (`model: fable`) and perform its verdict-routing writes, all keyed to the SHA. **Halt after the first pending-human verdict** (a GATE1_AMENDMENT/GATE1_REFRESH verdict) completes its own routing — review no further SHAs while it stands. The label clears **iff the set-difference is empty ∧ no register entry over the epic's merged SHAs is unresolved** (register-wide, never batch-scoped); zero merged child PRs clears vacuously. A pending-human entry is a **no-op park** — the human resolves it out-of-band via `rule-coherence <sha> approve|reject|redirect` (the `drive-epic` ruling mode), so the tick needs **no wake edge**: leave the label and move on. **Blocking scope:** `coherence-pending` blocks the merge slot and all canon-consuming dispatches (mature-ticket, deliver-ticket, epic-PR drafting); operator-ordered housekeeping that consumes no canon is exempt.
   3. Run `submit-epic-pr` when all children of an epic are done, the register-wide coherence clear predicate is satisfied (set-difference empty ∧ no unresolved pending-human entry), and no epic PR is open.
   4. Resume a lane that exited `RESUMABLE` — allowed even while `coherence-pending` (the lane predates the merge).
   5. Run `deliver-ticket` **inline** (0.14.1: never as a dispatched lane subagent — a nested dispatcher strands at its first own-worker dispatch; see `deliver-ticket` § Execution Model) for a child that passes `${CLAUDE_PLUGIN_ROOT}/scripts/dispatch-eligible.sh` (readiness labels ∧ no open blocking relations ∧ epic signed off and not `coherence-pending`). **Blocked for a `coherence-pending` epic.**
   6. Run `mature-ticket` for a child lacking `spec-ready` or `ready-to-implement`. **Blocked for a `coherence-pending` epic** (specs drafted against a register about to change are waste).
3. **Claim.** First **fence against a live driver**: resolve `<epic-id>` as the epic of the selected ticket by parent-traversal (hop `issue.parent` to the parentless root, exactly as `claim.sh` resolves the epic for tier-1), then run `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh status <epic-id>` — a fresh open driver claim means a resident driver owns this epic, so **exit no-op** (do not claim, do not merge). Otherwise mint a session run id and run `${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> <action> <session-run-id>` before acting. A live foreign claim (exit 3) means skip. Liveness is the **driver-claim-topped hierarchy** the script implements: a claim whose session matches a fresh open driver claim is alive; else a progress-species checkpoint within one lease window of now is alive; else the lease-age test. The tick never steals a live claim; `reconcile-tickets` expires dead ones. **Re-verify the driver-claim status immediately before the merge command itself** (the inlined `submit-ticket-pr` Merge sequence) — a driver booting minutes after this claim would otherwise merge concurrently; the re-verify closes the double-merge race.
4. **Act.** Run the selected lane skill to its natural exit. Lane-internal behavior is unchanged: checkpoint comments, worker dispatch discipline, tier pins, stop conditions all per the lane skill.
5. **Close out.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> <evidence> --session <session-run-id>` (the run id minted in the Step 3 claim is in scope), so the tick closes its own claim, never a foreign successor's. On a stop condition (`QUESTIONS_FOR_HUMAN`, demotion, blocker, retry ceiling), post the scannable escalation comment (TL;DR + Key Points) to the escalation channel and notify `humanContact` if set. Post the daily heartbeat if none exists for today (`${CLAUDE_PLUGIN_ROOT}/scripts/heartbeat.sh`). Exit.

Nothing actionable → log a one-line no-op and exit silently. A no-op is success, not an error.

## Retry Ceiling

The retry ceiling counts **stagnation, not resumes**. A `RESUMABLE` exit that added new durable checkpoint progress resets the attempt counter — a big ticket that legitimately needs several context resets is healthy. Only attempts that end with no new durable progress count toward the ceiling. When a run would be attempt `retryCeiling + 1` of no-progress attempts, do not attempt: mark the ticket `blocked`, post an escalation with the attempt trail, and leave it for a human or for `reconcile-tickets` to clear when the blocker is demonstrably resolved.

## Rules

- **One action per run.** Never chain a second selection after the first completes — the next tick picks it up. This bounds run length and keeps every run resumable.
- PM state is the only memory. Never rely on anything from a previous run's session.
- Claims are for crash visibility and multi-host coexistence, not locking — on one machine the scheduler's no-overlap guarantee already serializes ticks.
- Mechanics live in `dodi-dev/scripts/` — run the script and judge its result; never restate a script's mechanism in prose or improvise an alternative. A script failure with a clear cause is a result; a script that cannot run (missing env, missing binary) is a concrete blocker.
- All worker and lane dispatches carry explicit model tier pins per AGENTS.md dispatch discipline (a plugin hook also enforces this mechanically); the tick itself is Standard-tier routing.
- **Single active epic.** The priority order is defined for one epic; running concurrent epics requires round-robin selection, which this release does not implement. A second signed-off epic in scope is escalated, not silently interleaved.
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

Prerequisites before the first unattended run:

1. **Branch protection on main/master** requiring human review/merge — the structural Gate 2. The plugin's PreToolUse hook blocks merge attempts client-side; branch protection is the authoritative server-side enforcement.
2. **Escalation channel wired and tested** — send one synthetic escalation end-to-end and confirm it reaches a human surface (not just a PM comment).
3. `LINEAR_API_KEY` (or the PM equivalent) available to the session environment for the `dodi-dev/scripts/` PM scripts.

Machine-off operation (cloud-hosted routines with a fresh repo clone per run) is the upgrade path once the repo's test harness is proven to run in a fresh clone. On other harnesses, use the closest native scheduler with the same properties: fresh session, no overlapping runs, per-run permissions.

## Evidence

- Record per run: scope scanned, action selected (or no-op), ticket id, claim comment link, exit state, evidence links from the lane skill.
- Escalations carry the scannable header and the full attempt trail.

## Stop Conditions

- PM system unreachable or auth failure — escalate; do not retry within the run.
- Selected action's preconditions fail on claim (state moved since the scan) — release the claim, exit as a no-op; the next tick re-scans.
- Retry ceiling reached — mark `blocked`, escalate, exit.
- Any lane stop condition — record it, close out the claim, exit; the lane's own escalation stands.
