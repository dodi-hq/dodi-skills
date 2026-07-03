---
name: reconcile-tickets
description: Use as the scheduled janitor that converges PM ticket state with GitHub/git reality — merge transitions, deploy transitions, branch/worktree cleanup, stale claims
model: sonnet
---

# Reconcile Tickets

The convergence janitor. One sweep per run: compare PM ticket state against GitHub/git reality and repair drift with evidence-cited writes. Event-side automation (the PM system's GitHub integration moving tickets on PR merge) is the fast path; this skill is the guaranteed backstop that makes state eventually consistent no matter what the event side missed.

The janitor **repairs state; it never advances work**. It does not dispatch lanes, write specs, or open PRs — that is `pickup-next`'s job. And it never guesses: when evidence conflicts or is missing, it posts an escalation comment describing the conflict instead of writing a state.

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
| Claim comment on any ticket | older than the lease window with no checkpoint progress since | clear the claim, restore the ticket to its pre-claim state, note the expiry on the ticket |
| Ticket `blocked` from the retry ceiling | the referenced blocker demonstrably resolved (e.g. the blocking dependency merged) | clear `blocked`, reset the attempt counter, comment the evidence |
| Anything ambiguous | evidence conflicts or is missing | post an escalation comment describing the conflict — never write a guessed state |

## Deploy Signal

Production deploys are recorded as GitHub deployments; the nightly deploy (one per night, when anything is pending) is the only path to production. A merged epic commit counts as deployed when a production deployment whose SHA reaches it reports `success`:

```bash
gh api "repos/<owner>/<repo>/deployments?environment=<production-env>&per_page=10" \
  --jq '.[] | {id, sha, created_at}'
gh api "repos/<owner>/<repo>/deployments/<deployment-id>/statuses" --jq '.[0].state'
git merge-base --is-ancestor <epic-merge-sha> <deployment-sha>   # exit 0 = deployed
```

## Cleanup (deploy-confirmed only)

- Delete the epic branch and any surviving child branches — only after verifying each is merged by SHA reachability from main/master (`git merge-base --is-ancestor`), never by branch name.
- Prune local worktrees for deleted branches on the machine this run executes on (`git worktree prune` after removing worktree directories).
- Post the deploy-confirmation comment on the epic: deployment id, SHA, environment, tickets transitioned, branches and worktrees cleaned.

## Rules

- Every write cites its evidence: PR link, merge SHA, deployment id, or command output. A transition comment without evidence is a defect.
- Destructive actions are limited to deleting merged branches and their worktrees, under the SHA-reachability check. Nothing else is ever deleted.
- Never merge anything, never dispatch work, never edit code.
- Read-only evidence gathering goes to workers (Fast tier — `model: haiku` on Claude Code) returning compact digests; the sweep loop stays lean.
- Gate 2 remains human-owned; observing a merge is not performing one.

## Scheduled Task Setup

Run as a harness-native scheduled task, **once daily, shortly after the nightly deploy window** (e.g. `23 6 * * *` for a deploy that completes by 06:00), plus manual invocation anytime. Daily is sufficient because deploys are nightly and merge transitions are primarily handled event-side by the PM system's GitHub integration. If that integration turns out not to be configured, raise the cadence so Gate 2 merges do not sit stale for a day.

Same runtime properties as `pickup-next`: fresh self-contained session per run, Auto permission mode against the settings allow-list, no-overlap scheduling.

## Evidence

- Record per run: checks performed, drift found and repaired (with citations), cleanup performed, claims expired, escalations posted, and a one-line no-drift note when the sweep is clean.

## Stop Conditions

- PM or GitHub unreachable / auth failure — escalate, exit; do not retry within the run.
- Any ambiguity per the sweep table — escalate that item, continue the rest of the sweep, exit normally.
