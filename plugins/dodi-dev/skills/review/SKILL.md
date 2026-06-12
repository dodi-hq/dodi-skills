---
name: review
description: Use after implementation is complete and before creating a PR — agent-driven code review checking spec compliance, code quality, security, and regression risk
model: sonnet
---

# Review

Comprehensive agent-driven code review. Run after implementation, before PR.

## What to Check

| Category | What to Look For |
|----------|------------------|
| **Spec compliance** | Does the code implement what was specified? Nothing missing, nothing extra |
| **Code quality** | Clean, idiomatic, follows project conventions (CLAUDE.md, style guides) |
| **Security** | Injection, auth bypass, data leaks, OWASP top 10 |
| **Regression risk** | Does this change break assumptions in callers/consumers? |
| **Error handling** | Silent failures, swallowed exceptions, missing edge cases |
| **API contracts** | If touching APIs — are request/response shapes backwards-compatible? |

## Process

1. Identify the spec/plan and the diff (`git diff <base>...HEAD`)
2. Dispatch review subagent (see review-prompt.md) with:
   - The spec/plan path
   - The diff or list of changed files
   - Project conventions (CLAUDE.md path)
3. **Review loop** — if the subagent reports any issues, fix them and dispatch a fresh review subagent again. Repeat until a review round comes back clean with zero issues. Do not exit the loop on a round that still has findings — the final round must be clean.
4. When the final round is clean: proceed to `dodi-dev:submit`

## Epic Orchestration Review Rules

- Read the spec, plan, and diff directly.
- Treat this as fresh-context review.
- Focused re-review is required when production code changes during verification.
- Classify findings as spec mismatch, implementation issue, test issue, security issue, hygiene issue, or regression risk.

## Don't Skip This

"Tests pass" is not a review. Tests verify behavior; review verifies intent, quality, and risk.
