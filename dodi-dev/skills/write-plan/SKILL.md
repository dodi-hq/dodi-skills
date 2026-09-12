---
name: write-plan
description: Use when you have a spec or requirements and need to create a step-by-step implementation plan before coding
---

# Write Plan

Decompose an approved specification into ordered, bounded, verifiable implementation tasks. Define outcomes, dependencies, constraints, and completion criteria with enough context for an engineer new to the codebase. Do not write implementation code or pseudocode.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

**Before drafting or revising:** read [Planner routing](planner-routing.md), validate the successful spec review's typed planner-tier/identity/rationale, and preserve it with the planning evidence. It selects delegated plan writers and revisions only, not plan reviewers or delivery-tier. Missing legacy classification explicitly retains the prior writer policy; stale/invalid records never choose a tier by guess. Interactive model selection remains the operator's choice, not something loading this skill changes.

## Scope Check

If the spec covers multiple independent subsystems, break into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, identify the relevant components and known files, their responsibilities, and established patterns. Give verified paths where known; describe a new component's responsibility and placement without inventing speculative line numbers or prescribing local helpers and internal names.

- Each file: one clear responsibility, well-defined interface
- Files that change together should live together
- Follow established codebase patterns
- Prefer smaller focused files over large ones

## Plan Document Header

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** [One sentence]

**Implementation approach:** [Brief approach carrying forward approved product and architecture decisions; link the spec requirements]

**Dependency order:** [Ordered tasks and prerequisites; identify any dependency outside this plan]

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
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane. A mismatch here means the approved contract needs revision; routine coding choices within that contract are the implementer's responsibility, and implementation bugs are fixed in implementation.

---
```

## Task Structure

```markdown
### Task N: [Component Name]

**Outcome / spec coverage:** [Observable result and linked spec requirements]

**Components and known files:**
- [Component or verified file path]: [Responsibility and expected area of change]
- [Existing interface/pattern reference]: [What to reuse and which constraints apply]
- [Existing test location or harness]: [Relevant coverage]

**Dependencies:** [Earlier task outcomes or external prerequisites; none if independent]

**Interfaces, compatibility, and invariants:** [Approved shared contracts and observable behavior that must remain true, including across task boundaries]

**Acceptance criteria:** [Observable success conditions; link shared criteria where applicable]

**Verification:**
- Tests and critical failure cases: [Behaviors/assertions and regression surface, linked to the Testing Contract]
- Harness/environment: [Services, fixtures, setup prerequisites; none if not needed]
- Run: [Verified command, or where/how to discover it before verification]
- Expected: [Observable results that demonstrate acceptance and invariant preservation]

- [ ] Deliver [bounded outcome] using [established pattern] within the constraints above.
- [ ] Verify the acceptance criteria and critical failure cases; record command results.
- [ ] Commit the completed task.
```

For example, a task for an approved idempotent request contract can require repeated delivery of the same request to produce one persisted result, link the existing request handler and transaction pattern, and require tests for concurrent duplicates and retry after failure. The task states the approved invariant and how to observe it; function bodies and helper design are left to the implementer.

## Guidelines

- Make each task bounded, coherent, independently understandable, and detailed in proportion to risk. Reference shared plan sections explicitly instead of repeating them.
- Name known files/components and explain the relevant responsibilities and patterns. "Add validation" or "similar to X" alone is insufficient: identify the required behavior, constraints, and acceptance criteria.
- Do not prescribe implementation code, pseudocode, line-by-line edits, speculative line numbers, function bodies, local helpers, or internal naming. References to existing interfaces, schemas, and patterns, and verification commands with expected results, are useful and allowed.
- Use verified verification commands with observable expected results; when a command is not yet known, name its discovery location or step. Preserve the full Testing Contract.
- Carry forward approved decisions. Missing decisions that change product behavior, scope, architecture, or shared contracts return to specification; routine coding choices belong to the implementer within the plan's constraints.
- Write tests where they add value — skip tests for trivial getters/setters/CRUD
- DRY, YAGNI, frequent commits

## Epic Orchestration Planning Gates

- A ticket may enter planning only after human spec signoff or explicit delegation.
- Every implementation plan must include the full Testing Contract template with required test groups, critical flows, regression surface, commands, harness requirements, non-required rationale, and verification rules.
- The Testing Contract must state whether unit, integration, and e2e tests are required, their scope, why they are required or not required, minimum assertions, harness status, and commands or discovery requirements.
- Missing harness is not a skip reason; the plan must require setup or a concrete blocker.
- Apply `ready-to-implement` only after clean plan review and dependency check.
- Missing product behavior, architecture, shared-contract, or scope decisions return the ticket to the spec lane.

## Drafting Delegation

- **Interactive sessions:** draft the plan in the main loop — the dialogue context is the input. State the planner recommendation and actual operator-selected session separately; do not claim prose set the model or effort.
- **Mature lane** (manual, resident driver, or Florist): delegate drafting to a plan-writer subagent (see plan-writer-prompt.md), explicitly pinned from the validated planner-routing record; the main loop only runs the review loop on the returned draft. Validate and use the same choice for each fresh revision writer while the spec remains approved.
- **Research dispatches** (either mode): codebase exploration, test-harness orientation, and external/integration API research go to workers pinned at Standard tier (`model: sonnet` on Claude Code), returning ~20-line digests with source links. Never let a research dispatch inherit the session model.

## Plan Review Loop

After completing each chunk (≤1000 lines):

1. Dispatch plan-reviewer subagent (see plan-reviewer-prompt.md). Its tier/availability policy is unchanged; planner-tier never lowers a review seat. Its delivery-tier verdict remains an independent post-decomposition judgment.
2. Dispatch a **fresh plan-writer** in revision mode (plan path + findings + round — the Revision round block in plan-writer-prompt.md), then a **fresh reviewer** carrying the writer's Findings block as prior round; repeat until approved (max 5 iterations). Never re-enter the previous writer or reviewer (`execution-model.md` § 1, one-shot). Interactive sessions, which draft in the main loop, apply the fixes in the main loop and pass their own applied/declined list as the prior round.

## Execution Handoff

**"Plan saved to `docs/plans/<filename>.md`. Ready to execute?"**

When ready, invoke `dodi-dev:implement`.
