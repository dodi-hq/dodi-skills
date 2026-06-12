---
name: review-child-pr
description: Run fresh-context review and local CI-equivalent checks for a child PR targeting an epic branch
model: sonnet
---

# Review Child PR

Use after `submit-ticket-pr` opens a child PR against the epic branch. This is a fresh-context gate. Do not rely on the implementation conversation.

## Inputs

- child PR id or URL
- child ticket id
- epic branch
- child branch
- spec path
- plan path
- local child worktree

## Process

1. Read the ticket, spec, plan, and PR diff.
2. Dispatch the fresh-context PR reviewer (`pr-reviewer-prompt.md`) and the local CI-equivalent test runner **in parallel** — one message, two Agent calls. They are independent; do not sequence them.
3. Collect both results.
4. If review or tests find issues, dispatch fix workers.
5. If production code changes, rerun focused review and affected tests.
6. If the epic branch moved, update the child branch from the epic branch and rerun relevant checks.
7. When clean, report `ready-to-merge-child`.

## Stop Conditions

- Stop on product, architecture, scope, or spec/plan mismatch and demote according to the spec.
- Stop on unresolved merge conflict requiring judgment.
- Stop on auth/tool failure and report the blocker.

## Evidence

Record PR comments, commands run, exit codes, reviewer status, test evidence, and final next action.

## Local CI Runner

Use `submit-ticket-pr/local-ci-runner-prompt.md` when dispatching the local CI-equivalent runner.
