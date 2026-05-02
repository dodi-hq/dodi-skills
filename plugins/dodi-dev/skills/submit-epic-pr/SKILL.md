---
name: submit-epic-pr
description: Open an epic PR from the epic branch to main/master and leave it open for existing GitHub Actions and review
---

# Submit Epic PR

Use when all child tickets under an epic are done and merged into the epic branch.

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
3. Run epic-level `quality-gate`.
4. Prepare an epic readiness summary with child tickets, child PRs, test evidence, known risks, migrations, release notes, and coverage summary.
5. Push the epic branch.
6. Open a PR from epic branch to main/master.
7. Leave the PR open.
8. Update the epic ticket with the PR link and readiness summary.

## Commands

```bash
git checkout <epic-branch>
git fetch origin <base-branch>
git merge --no-ff origin/<base-branch>
git push -u origin <epic-branch>
gh pr create --base <base-branch> --head <epic-branch> --title "<epic-id>: <title>" --body-file <pr-body-file>
```

Expected evidence:

- latest base sync output
- epic quality-gate evidence
- push output or remote branch URL
- epic PR URL
- epic ticket comment with readiness summary

## Rules

- Never auto-merge epic PRs by default.
- Existing GitHub Actions and main-target review automation take over after PR creation.
- Stop if any child ticket is incomplete or reopened.
- Stop if epic-level `quality-gate` fails.
- Stop if syncing latest main/master introduces conflicts or required fixes; return the epic to `epic-active`.
- Stop if PR creation fails; report the blocker with command output.
