---
name: review
description: Fresh-context code review for any completed change — post-implementation, pre-PR in the epic lane, or child PR — with a fix loop and a Frontier-tier final round
model: sonnet
---

# Review

Comprehensive fresh-context, agent-driven code review with a fix loop. One skill, three contexts:

| Context | When | Reviewer reads | Context-specific checks |
| --- | --- | --- | --- |
| **post-implementation** | interactive: after `implement`, before `submit` | spec/plan, diff, project conventions | — |
| **pre-PR** | epic lane: implementation complete, before tests and local readiness | spec, plan, diff in the child worktree | classify findings; demotion rules apply |
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | Testing Contract coverage; branch currency with the epic branch; local CI runs in parallel |

## What to Check

| Category | What to Look For |
|----------|------------------|
| **Spec compliance** | Does the code implement what was specified? Nothing missing, nothing extra |
| **Code quality** | Clean, idiomatic, follows project conventions (CLAUDE.md / AGENTS.md, style guides) |
| **Security** | Injection, auth bypass, data leaks, OWASP top 10 |
| **Regression risk** | Does this change break assumptions in callers/consumers? |
| **Error handling** | Silent failures, swallowed exceptions, missing edge cases |
| **API contracts** | If touching APIs — are request/response shapes backwards-compatible? |

## Process

1. Identify the spec/plan and the diff (`git diff <base>...HEAD`, or the PR diff in the child-PR context).
2. Dispatch the reviewer subagent (see review-prompt.md) with the context named. In the **child-PR context**, dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent.
3. **Review loop** — if the reviewer reports issues, dispatch fix workers, then a fresh reviewer. Cap at 5 rounds; if still not clean, stop and escalate with the unresolved findings.
4. **Final round at Frontier tier** — when a round comes back clean, dispatch one last fresh reviewer at `model: fable`. The gate is clean only when this round reports zero issues. If it finds issues, fix them and resume the loop at the per-round tier.
5. On clean:
   - post-implementation → proceed to `dodi-dev:submit`
   - pre-PR → proceed to tests and local readiness
   - child-PR → report `ready-to-merge-child`

## Epic Lane Rules

- Reviewers start from fresh context; never rely on the implementation conversation.
- Classify every finding: spec mismatch, implementation issue, test issue, security issue, hygiene issue, or regression risk.
- Product, architecture, scope, or spec/plan mismatch findings demote the ticket per the orchestrator's demotion rules — do not fix them in-loop.
- Focused re-review is required when production code changes during verification.
- Child-PR context: if the epic branch moved, update the child branch from the epic branch and rerun relevant checks; stop on an unresolved merge conflict requiring judgment.
- Record reviewer status, findings, fixes, reviewed diff range, commands and exit codes, and the final clean-round evidence.

## Don't Skip This

"Tests pass" is not a review. Tests verify behavior; review verifies intent, quality, and risk.
