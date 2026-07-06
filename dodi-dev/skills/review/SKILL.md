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
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | delta-scoped integration pair — one `opus` integration round + one `fable` integration final (child-pr-integration-prompt.md); Testing Contract coverage; branch currency with the epic branch; local CI runs in parallel |

## What to Check

| Category | What to Look For |
|----------|------------------|
| **Spec compliance** | Does the code implement what was specified? Nothing missing, nothing extra |
| **Code quality** | Clean, idiomatic, follows project conventions (CLAUDE.md / AGENTS.md, style guides) |
| **Security** | Injection, auth bypass, data leaks, OWASP top 10 |
| **Regression risk** | Does this change break assumptions in callers/consumers? |
| **Error handling** | Silent failures, swallowed exceptions, missing edge cases |
| **API contracts** | If touching APIs — are request/response shapes backwards-compatible? |
| **Documentation** | Docs, README, and config samples updated when behavior changes |
| **Operational concerns** | Logging, error surfacing, flags, rollout/rollback |

## Process — post-implementation and pre-PR (full gate)

1. Identify the spec/plan and the diff (`git diff <base>...HEAD`).
2. Dispatch the reviewer subagent (see review-prompt.md) with the context named.
3. **Review loop** — if the reviewer reports issues, dispatch fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a fresh reviewer. Cap at 5 rounds; if still not clean, stop and escalate with the unresolved findings.
4. **Final round at Frontier tier** — when a round comes back clean, dispatch one last fresh reviewer at `model: fable`. The gate is clean only when this round reports zero issues. If it finds issues, fix them and resume the loop at the per-round tier.
5. On clean:
   - post-implementation → proceed to `dodi-dev:submit`
   - pre-PR → proceed to tests and local readiness

## Process — child-PR (integration pair)

The pre-PR gate already ran the full checklist; the child-PR gate re-reviews the delta, not the checklist. One **integration round** at Capable tier (`model: opus` on Claude Code) plus one **integration final** at Frontier tier (`model: fable` on Claude Code), both delta-aimed at exactly what is new or changed since the pre-PR gate, both reading the whole PR diff (see child-pr-integration-prompt.md).

1. Identify the ticket, spec, plan (with its Testing Contract), and the PR diff.
2. Dispatch the **integration round** (child-pr-integration-prompt.md, `model: opus`). Dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent.
3. When the integration round is clean, dispatch the **integration final** — a fresh reviewer, same prompt, `model: fable`.
4. **Fix loop** — findings from either round route to fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a **focused `fable` re-round** aimed at the fix delta. Total child-PR rounds cap at 5; cap exhaustion escalates with the unresolved findings — it never merges.
5. The gate is clean only when a `fable` round reports zero issues. On clean, report `ready-to-merge-child`.

## Epic Lane Rules

- Reviewers start from fresh context; never rely on the implementation conversation.
- Classify every finding: spec mismatch, implementation issue, test issue, security issue, hygiene issue, or regression risk.
- Product, architecture, scope, or spec/plan mismatch findings demote the ticket per the orchestrator's demotion rules — do not fix them in-loop.
- **Focused re-review** is required when production code changes during verification: a fresh reviewer at Capable tier (`model: opus` on Claude Code) reads the fix delta plus its blast surface (callers/consumers), full checklist (review-prompt.md) scoped to that delta, before the reset seam — a scoped instance of the review fix loop (findings → fix worker → fresh focused round) under the pre-PR loop's cap.
- Child-PR rounds are delta-aimed — exactly what is new or changed since the pre-PR gate — and read the whole PR diff. Aim guides attention, not admissibility: any defect seen anywhere in the diff is a legal finding; the rounds simply do not re-execute the generic checklist the pre-PR gate owns.
- Child-PR context: if the epic branch moved, update the child branch from the epic branch and rerun relevant checks; stop on an unresolved merge conflict requiring judgment.
- Record reviewer status, findings, fixes, reviewed diff range, commands and exit codes, and the final clean-round evidence.

## Don't Skip This

"Tests pass" is not a review. Tests verify behavior; review verifies intent, quality, and risk.
