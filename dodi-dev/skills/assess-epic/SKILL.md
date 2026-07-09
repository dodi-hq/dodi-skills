---
name: assess-epic
description: Use when an epic worktree exists and orchestration needs to classify child tickets, dependencies, readiness, and blockers
model: haiku
---

# Assess Epic

Classify the epic and child tickets from durable PM and repository state. This skill decides queues; it does not write specs, implement code, create PRs, or merge branches.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| epic worktree exists or orchestration resumes | epic id, child ticket list, repo state, artifact links | ticket maturity map, dependency map, ready work queue, maturity work queue | epic assessment comment or run ledger entry | explorer/reviewer workers for dependency checks only | ticket access failure, inconsistent child hierarchy, missing repo |

## Inputs

- epic id
- child ticket list
- repo state
- artifact links
- existing labels and comments
- optional run ledger records

## Process

- Read the epic and child tickets from the PM system.
- Inspect labels, comments, artifact links, branches, and worktrees.
- Classify each child using the orchestrator-tracked table in `epic-orchestrator/state-transitions.md`.
- Build ready work and maturity work queues.
- Build the dependency map: it feeds the sprint/waterfall mode decision (§ Scheduling Policy) — the inter-child coupling graph is the discriminator — so record file-surface overlap signals (shared modules, config, schema) alongside ticket dependencies.
- **Verify and repair the native relation graph:** hard sequencing edges must exist as blocked-by relations on the tickets themselves (dispatch eligibility queries them — `${CLAUDE_PLUGIN_ROOT}/scripts/dispatch-eligible.sh`). Add missing relations your analysis implies, flag relations that contradict it, and detect cycles (a cycle is a blocker, not a judgment call). After Gate 1 signoff the relation graph is canonical. Soft parallelism signals stay in the assessment comment — never encode them as blocked-by.
- Treat `spec-ready` and `ready-to-implement` as hard gates.
- The outputs feed the Gate 1 signoff package: state map, dependency map, and any child that should carry `needs-human-spec`.
- Do not create PRs or dispatch lanes from this skill.

## Scheduling Policy (Mode)

After the dependency map is built, decide the epic's workflow mode — `sprint` or `waterfall`, two scheduling policies over the same lane primitives (sprint interleaves mature/deliver per child; waterfall matures all children, then delivers all):

- **Gate 1 delegation wins:** if the delegation comment pre-declares or constrains the mode, apply it verbatim.
- **Otherwise decide autonomously** from the inter-child coupling graph — the discriminator is file-overlap and blocked-by density: tightly coupled children favor waterfall's mature-all-first, independent children favor sprint's interleave. Stay within the delegation. **No third human gate.**
- **Escalated tier:** the mode decision is a judgment over the coupling graph binding epic-wide scheduling, not state classification, so it is **not** taken at this skill's `model: haiku` main-loop tier. Dispatch a mode-decision worker pinned **Capable tier** (`model: opus` on Claude Code; `${CLAUDE_PLUGIN_ROOT}/scripts/hook-require-model-pin.sh` enforces the explicit pin) with the coupling graph and delegation as input; it returns the mode plus a one-line coupling rationale.
- **Record it:** write a `# Decision Register Entry` with `Kind: MODE` (keyed by epic id + seam timestamp) carrying the rationale, and apply the `mode-sprint`/`mode-waterfall` epic label (the cache; the register entry is truth). See `epic-orchestrator/state-transitions.md` § Workflow Mode and Driver Priority Table.
- **Re-assessment is a standard step, not one-shot:** the driver re-runs the mode evaluation at each lane close-out and the boot audit (coupling that looked loose tightens once real diffs exist); mid-epic flips are first-class, each landing a new `MODE` entry. Those mid-epic re-evaluations are the **driver's own inline judgment** over the map it already holds — no separate dispatch, since re-reading its own held map at its own session tier is not a fresh gate.
- The chosen mode feeds the Gate 1 package the same way the ready-work queue does.

## Evidence

- Record child state map, dependency map, ready work queue, maturity work queue, and blockers.
- Record source links for labels, comments, specs, plans, branches, and worktrees.

## Stop Conditions

- Stop on ticket access failure, inconsistent child hierarchy, or missing repository context.
- Stop when a child ticket needs human spec input.
- Stop when dependencies are unclear enough to affect sequencing — an unclear dependency also affects the mode decision (§ Scheduling Policy).
