---
name: reconcile-tickets
description: Use as the scheduled janitor that converges PM ticket state with GitHub/git reality — merge transitions, deploy transitions, branch/worktree cleanup, stale claims
model: sonnet
---

# Reconcile Tickets

The convergence janitor. One sweep per run: compare PM ticket state against GitHub/git reality and repair drift with evidence-cited writes. Event-side automation (the PM system's GitHub integration moving tickets on PR merge) is the fast path; this skill is the guaranteed backstop that makes state eventually consistent no matter what the event side missed.

The janitor **repairs state; it never advances work**. It does not dispatch lanes, write specs, or open PRs — that is the resident driver's job (`drive-epic`; the `pickup-next` tick is the paused 0.14.0 fallback). And it never guesses: when evidence conflicts or is missing, it posts an escalation comment describing the conflict instead of writing a state.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| scheduled daily run or manual invocation | PM scope, repo path(s), production environment name, claim lease window (default 2h) | drift repaired or escalated, cleanup performed | ticket state transitions with evidence, deploy-confirmation comment, claim expiries, branch/worktree deletions | read-only state-reader and evidence-checker workers | PM or GitHub unreachable, ambiguous evidence (escalated, not guessed) |

## Sweep Checks

| Check | Drift detected | Action |
| --- | --- | --- |
| Ticket in `delivering`/`ready-to-merge-child` | its child PR merged or closed | advance or flag per the `epic-orchestrator/state-transitions.md` tables, citing PR link and merge commit |
| Epic at `epic-pr-open` | epic PR merged into main/master (Gate 2 happened) | move epic and all children to Merged (or the team's Done state), citing the merge commit |
| Epic in Merged state | production deploy confirmed for a SHA reaching the epic merge commit | move epic and children to Deployed/Released (or apply a `deployed` label if the workflow has no such state); post the deploy-confirmation comment; run cleanup |
| Claim comment on any ticket | dead per the liveness hierarchy (no matching fresh driver claim, no progress-species checkpoint within a lease window of now, over lease age) | clear the claim via `release-claim.sh` (re-reading staleness immediately before the close; foreign claims released by id, never most-recent-open), restore the ticket to its pre-claim state, note the expiry |
| Unreaped worker in an over-lease dispatch manifest | non-terminal worker in a manifest older than the lease | classify via `${CLAUDE_PLUGIN_ROOT}/scripts/reap-workers.sh <manifest>`, stop what its layer can stop, digest note; crashed lanes leave worktree + manifest for this sweep |
| Stray open driver claim | a `# Driver Claim` older than its staleness window (default 45m) | expire via `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh release <epic-id> <claim-id> taken-over` only (species separation — never `release-claim.sh`), re-reading staleness immediately before the close; `taken-over` is the correct exit-state for a janitor reaping a dead driver claim (matching Task B's `acquire` stale-close semantics), so Task B's release enum and this caller agree by text, not executor judgment |
| Fresh driver claim + no progress-species writes > 8h (wedged driver) | the wedged-driver backstop — a driver claim staying fresh via its refresher while posting no progress-species work | escalate; this probe lives HERE in the daily sweep (honest latency ~a day), not the hourly guard, which under same-task no-overlap cannot fire against the live driver it would probe |
| Ticket `blocked` from the retry ceiling | the referenced blocker demonstrably resolved (e.g. the blocking dependency merged) | clear `blocked`, reset the attempt counter, comment the evidence |
| Child parked as dependency-blocked | all its blocking relations are terminal (per the relation graph) | advance per the transition tables, citing the relation state |
| Open epic PR | conflicted against its base, or failing required checks | escalate — Gate 2 notifications fire at PR-open; a later red X has no other watcher |
| Production deployment | latest deployment reports failure/error (`${CLAUDE_PLUGIN_ROOT}/scripts/check-deploy.sh` exit 4) | escalate immediately; affected epics stay Merged with a deploy-failed note. Detection only — triage is the future devops leg |
| Any active epic | no durable progress (checkpoint, merge, label transition, register entry) within the watchdog window (default 3 days) and not parked on an explicit human-wait state | escalate with a diagnosis from `${CLAUDE_PLUGIN_ROOT}/scripts/watchdog-scan.sh`: dispatchable children or why none (including relation cycles), live claims, `coherence-pending` age, open PR state |
| Anything ambiguous | evidence conflicts or is missing | post an escalation comment describing the conflict — never write a guessed state |

## Waiting-On-You Digest

Every run produces the daily digest of human-parked items across all epics: each Gate 1 request, `QUESTIONS_FOR_HUMAN`, `needs-human-spec` wait, demotion awaiting a ruling, unresolved pending-human coherence-ruling register entry (a `coherence-pending` epic with a GATE1_AMENDMENT/GATE1_REFRESH entry and no later `RULING` for its SHA — awaited via `rule-coherence`; the reminder loop the park depends on, since the 3-day watchdog exempts explicit human-wait states), `blocked` ticket, and open Gate 2 PR — with age, the one-line ask, and the link. Deliver it to the escalation channel. **Re-escalation:** any item older than the staleness window (default 3 days) is flagged with its age — escalations are not fire-and-forget. An empty digest is one line: "nothing waiting on you."

## Deploy Signal

Production deploys are recorded as GitHub deployments; the nightly deploy (one per night, when anything is pending) is the only path to production. A merged epic commit counts as deployed when a production deployment whose SHA reaches it reports `success`. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-deploy.sh <epic-merge-sha> <environment>`: exit 0 = deployed (proceed to cleanup), exit 1 = not yet, exit 4 = latest deployment failed (escalate). Do not restate or improvise the deployment-API mechanics — the script owns them.

## Cleanup (deploy-confirmed only)

- Delete the epic branch and any surviving child branches via `${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-branch.sh <branch> <base> [worktree] [repo-dir] [verified-merge-sha]` — pass the merge SHA (from `verify-merge.sh` or the PR's merge commit) for squash-merged branches; the script verifies reachability plus content match and refuses otherwise. Never delete by name or bypass it.
- Expire dead claims via `${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh` after the **liveness hierarchy** (a claim whose session matches a fresh open driver claim is alive; else a progress-species checkpoint within one lease window of **now** is alive; else the lease-age test) — never the old age-blind "fresh checkpoints ⇒ alive" rule, which immortalized a crashed session's claim. Foreign claims are released **by claim id** with an explicit flag, with a pre-close staleness re-read.
- Post the deploy-confirmation comment on the epic: deployment id, SHA, environment, tickets transitioned, branches and worktrees cleaned.

## Rules

- Every write cites its evidence: PR link, merge SHA, deployment id, or command output. A transition comment without evidence is a defect.
- Destructive actions are limited to deleting merged branches and their worktrees, under the SHA-reachability check. Nothing else is ever deleted.
- Never merge anything, never dispatch work, never edit code.
- Read-only evidence gathering goes to workers (Fast tier — `model: haiku` on Claude Code) returning compact digests; the sweep loop stays lean.
- Gate 2 remains human-owned; observing a merge is not performing one.

## Scheduled Task Setup

Run as a harness-native scheduled task, **once daily, shortly after the nightly deploy window** (e.g. `23 6 * * *` for a deploy that completes by 06:00), plus manual invocation anytime. Daily is sufficient because deploys are nightly and merge transitions are primarily handled event-side by the PM system's GitHub integration. If that integration turns out not to be configured, raise the cadence so Gate 2 merges do not sit stale for a day.

Same runtime properties as the resident driver's guard: fresh self-contained session per run, Auto permission mode against the settings allow-list, no-overlap scheduling.

## Evidence

- Record per run: checks performed, drift found and repaired (with citations), cleanup performed, claims expired, escalations posted, and a one-line no-drift note when the sweep is clean.

## Stop Conditions

- PM or GitHub unreachable / auth failure — escalate, exit; do not retry within the run.
- Any ambiguity per the sweep table — escalate that item, continue the rest of the sweep, exit normally.
