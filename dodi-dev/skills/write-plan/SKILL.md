---
name: write-plan
description: Use when you have a spec or requirements and need to create a step-by-step implementation plan before coding
---

# Write Plan

Create implementation plans with enough detail that an engineer with zero codebase context can execute them. Exact file paths, complete code, exact commands, bite-sized steps.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Scope Check

If the spec covers multiple independent subsystems, break into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each is responsible for.

- Each file: one clear responsibility, well-defined interface
- Files that change together should live together
- Follow established codebase patterns
- Prefer smaller focused files over large ones

## Plan Document Header

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** [One sentence]

**Architecture:** [2-3 sentences]

**Tech Stack:** [Key technologies]

## Testing Contract

### Required Test Groups

- Unit: `<required|not-required>`
  - Scope: `<functions/components/modules>`
  - Reason: `<why>`
  - Minimum assertions: `<specific behaviors>`

- Integration: `<required|not-required>`
  - Scope: `<module boundaries/APIs/db/jobs/etc>`
  - Reason: `<why>`
  - Harness: `<existing|setup-required|not-applicable>`
  - Minimum assertions: `<specific flows>`

- E2E: `<required|not-required>`
  - Scope: `<user/business-critical flows>`
  - Reason: `<why>`
  - Harness: `<existing|setup-required|not-applicable>`
  - Minimum assertions: `<specific flows>`

### Critical Flows

- `<flow 1>`
- `<flow 2>`

### Regression Surface

- `<adjacent module or behavior that must not break>`

### Commands

- Unit: `<command or to-be-discovered>`
- Integration: `<command or to-be-discovered>`
- E2E: `<command or to-be-discovered>`
- Broader regression: `<command or to-be-discovered>`

### Harness Requirements

- `<required setup, service, fixture, seed data, browser, env var, mock, account, etc>`

### Non-Required Rationale

- Unit: `<only if not-required>`
- Integration: `<only if not-required>`
- E2E: `<only if not-required>`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts:123-145`
- Test: `tests/exact/path/to/test.ts`

- [ ] **Step 1:** [Specific action]

```typescript
// Complete code, not "add validation"
```

- [ ] **Step 2:** Verify

Run: `exact command`
Expected: [exact output]

- [ ] **Step 3:** Commit

```bash
git add [files]
git commit -m "feat: specific change"
```
````

## Guidelines

- Exact file paths always
- Complete code in plan (not "add validation" or "similar to X")
- Exact commands with expected output
- Write tests where they add value — skip tests for trivial getters/setters/CRUD
- DRY, YAGNI, frequent commits

## Epic Orchestration Planning Gates

- A ticket may enter planning only after human spec signoff or explicit delegation.
- Every implementation plan must include the full Testing Contract template with required test groups, critical flows, regression surface, commands, harness requirements, non-required rationale, and verification rules.
- The Testing Contract must state whether unit, integration, and e2e tests are required, their scope, why they are required or not required, minimum assertions, harness status, and commands or discovery requirements.
- Missing harness is not a skip reason; the plan must require setup or a concrete blocker.
- Apply `ready-to-implement` only after clean plan review and dependency check.
- Product or architecture ambiguity returns the ticket to the spec lane.

## Drafting Delegation

- **Interactive sessions:** draft the plan in the main loop — the dialogue context is the input.
- **Autonomous epic lane** (entered via `mature-ticket`): delegate drafting to a plan-writer subagent (see plan-writer-prompt.md); the main loop only runs the review loop on the returned draft.
- **Research dispatches** (either mode): codebase exploration, test-harness orientation, and external/integration API research go to workers pinned at Standard tier (`model: sonnet` on Claude Code), returning ~20-line digests with source links. Never let a research dispatch inherit the session model — plan sessions run Frontier, and read-and-digest work gains nothing from it.

## Plan Review Loop

After completing each chunk (≤1000 lines):

1. Dispatch plan-reviewer subagent (see plan-reviewer-prompt.md)
2. Dispatch a **fresh plan-writer** in revision mode (plan path + findings + round — the Revision round block in plan-writer-prompt.md), then a **fresh reviewer** carrying the writer's Findings block as prior round; repeat until approved (max 5 iterations). Never re-enter the previous writer or reviewer (`execution-model.md` § 1, one-shot). Interactive sessions, which draft in the main loop, apply the fixes in the main loop and pass their own applied/declined list as the prior round.

## Execution Handoff

**"Plan saved to `docs/plans/<filename>.md`. Ready to execute?"**

When ready, invoke `dodi-dev:implement`.
