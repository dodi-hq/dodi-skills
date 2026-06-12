---
name: submit-epic-pr
description: Open an epic PR from the epic branch to main/master and leave it open for existing GitHub Actions and review
model: sonnet
---

# Submit Epic PR

Use when all child tickets under an epic are done and merged into the epic branch.

## Why a Full Regression Gate Before the PR

The epic PR must prove that all child commits work together, not just individually. Child PRs verify each ticket against the epic branch at its own merge time; they do not prove the final integrated head — including the latest main/master sync — is green. Only a full regression run on the integrated epic head proves that.

Treat GitHub Actions CI as the final safety gate before production, not the first line of defense. A full regression run can exceed an hour; it exists to catch true exceptions, not first-order breakage that a local run would surface. Do not throw a red or untested branch over the wall and leave downstream CI to discover what a local run would have caught. Open the epic PR only after the full regression suite passes locally on the integrated epic head.

## Inputs

- epic id
- epic branch
- base branch: main or master
- child ticket list
- child PR links
- epic readiness evidence

## Process

1. Confirm all child tickets are done.
2. Update the epic branch with the latest main/master.
3. Run `verify` as a full regression suite on the integrated epic head: all required unit, integration, and e2e groups across the merged children — the union of child Testing Contracts — must pass. Dispatch one test-runner worker per group (see `verify/test-runner-prompt.md`) and claim results only from the returned digests (commands + exit codes). This is a hard gate. Do not proceed if any required group fails or a required harness cannot be set up.
4. Run epic-level `quality-gate`.
5. Prepare an epic readiness summary with child tickets, child PRs, full-regression evidence (commands, exit codes, run on the post-sync epic head), known risks, migrations, release notes, and coverage summary.
6. Push the epic branch.
7. Open a PR from epic branch to main/master.
8. Leave the PR open.
9. Update the epic ticket with the PR link and readiness summary.

## Commands

```bash
git checkout <epic-branch>
git fetch origin <base-branch>
git merge --no-ff origin/<base-branch>

# Full regression on the integrated epic head, via `verify`, before pushing.
# Run the union of child Testing Contract commands; all required unit,
# integration, and e2e groups must pass (exit 0) on this post-sync head.

git push -u origin <epic-branch>
gh pr create --base <base-branch> --head <epic-branch> --title "<epic-id>: <title>" --body-file <pr-body-file>
```

Expected evidence:

- latest base sync output
- full regression evidence: commands, exit codes, and the epic head SHA the suite ran against (post-sync)
- epic quality-gate evidence
- push output or remote branch URL
- epic PR URL
- epic ticket comment with readiness summary

## Rules

- Never auto-merge epic PRs by default.
- Existing GitHub Actions and main-target review automation take over after PR creation.
- Stop if any child ticket is incomplete or reopened.
- Stop if the full regression suite has any failing required group. Classify the failure (test bug, integration bug, environment/harness, spec/plan mismatch), route the fix, and rerun. Do not open the epic PR on a red suite.
- Full-regression evidence must come from a run on the current epic head after the latest main/master sync. Aggregated per-child evidence does not satisfy this gate.
- Stop if epic-level `quality-gate` fails.
- Stop if syncing latest main/master introduces conflicts or required fixes; return the epic to `epic-active`.
- Stop if PR creation fails; report the blocker with command output.
