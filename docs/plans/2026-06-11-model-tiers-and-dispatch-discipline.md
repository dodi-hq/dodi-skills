# Model Tiers & Dispatch Discipline Implementation Plan

> **For agentic workers:** Execute tasks in order. The Claude tree (`dodi-dev/skills/`) is authoritative; mirror to the Codex tree (`plugins/dodi-dev/skills/`) at the end.

**Goal:** Stop running mundane orchestration work on flagship models and stop bulk reads/runs from bloating the main loop — pin a model tier per skill and per worker dispatch, and delegate read-heavy/run-heavy steps to subagents.

**Architecture:** Two levers. (1) `model:` frontmatter in SKILL.md switches the main-loop model for the rest of the turn when a skill is invoked. (2) The Agent tool's `model` parameter pins each worker dispatch; it is written directly into the worker prompt templates so it is mechanical, not advisory. Delegation discipline keeps the main loop as a router/conversation surface: bulk reads, test runs, and evidence checks go to workers that return compact digests.

**Why both motivations matter:**
- *Responsiveness* — interactive skills keep talking to the human instead of reading 40 files.
- *Context longevity* — autonomous epic runs survive without compaction because the orchestrator's context holds state maps and digests, never raw diffs/logs/PM dumps.

## Model Tier Convention

| Tier | Alias | Used for |
|------|-------|----------|
| Capable | `opus` | Spec drafting/review, plan writing/review, code review, PR review |
| Standard | `sonnet` | Writing code, writing tests, fixing findings, PR bodies, failure triage |
| Fast | `haiku` | Orchestration next-step decisions, git mechanics, state classification, command runners |

Rules:
- Aliases only — never full model IDs (aliases track model upgrades).
- Interactive-facing skills omit `model:` (= inherit the session model). In the autonomous lane, `mature-ticket`'s `opus` pin persists for the rest of the turn into `write-plan`/`brainstorm`-style work it chains into.
- `CLAUDE_CODE_SUBAGENT_MODEL` env var outranks everything — never set it on hive machines.

## Dispatch Discipline Convention

- **Delegation heuristic:** if a step pulls more than ~200 lines of file/log/PM content into the main loop, or runs longer than ~1 minute, dispatch a worker.
- **Worker return contract:** `STATUS` (existing DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED vocabulary, or Approved / Issues Found for reviewers) + `EVIDENCE` (commit ids, file paths, command + exit code, log path) + details capped at ~20 lines. No transcripts, no pasted logs.
- **Parallel dispatch for read-only workers only.** Explorers, reviewers, evidence checkers fan out freely. Implementers never run in parallel. The orchestrator's one-state-advancing-action-at-a-time invariant holds; parallelism lives inside a phase.

---

### Task 1: SKILL.md frontmatter — add `model:` per tier

**Files (Claude tree, all `dodi-dev/skills/<name>/SKILL.md`):**

| Skill | model |
|---|---|
| epic-orchestrator, assess-epic, pickup-epic, pickup-ticket, quality-gate | `haiku` |
| implement, implement-ticket, create-tests, verify, review, review-implementation, review-child-pr, submit-ticket-pr, submit-epic-pr | `sonnet` |
| mature-ticket | `opus` |
| brainstorm, write-plan, file-ticket, pickup, submit | *(no field — inherit)* |

Frontmatter gains one line after `description`, e.g.:

```yaml
---
name: epic-orchestrator
description: ...
model: haiku
---
```

### Task 2: Pin models in existing worker prompt templates

- `brainstorm/spec-reviewer-prompt.md`: `Agent tool (general-purpose):` → `Agent tool (general-purpose, model: opus):`
- `write-plan/plan-reviewer-prompt.md`: same → `model: opus`
- `review/review-prompt.md`: same → `model: opus`
- `implement/implementer-prompt.md`: `Agent tool (general-purpose or implementation-engineer):` → `Agent tool (general-purpose or implementation-engineer, model: sonnet):`
- `review-child-pr/pr-reviewer-prompt.md` (bare-prompt format): add dispatch line under the title: `Dispatch with the Agent tool, model: opus.`
- `submit-ticket-pr/local-ci-runner-prompt.md` (bare-prompt format): add dispatch line: `Dispatch with the Agent tool, model: haiku.` Plus return-contract line: report commands, exit codes, failing test names, and log paths — never paste raw logs.

### Task 3: New worker prompt templates

1. `epic-orchestrator/state-reader-prompt.md` — haiku, read-only. Reads epic + child tickets from PM, branch/worktree state, optional ledger. Returns a compact state map (per child: state, labels, artifact links, branch, blockers) ≤ 40 lines. Never returns raw ticket bodies.
2. `epic-orchestrator/evidence-checker-prompt.md` — haiku, read-only. Given an advancement claim and expected evidence, verifies durable evidence (label present, comment posted, commit exists, command exit code) and returns citations. Fresh-context verification independent of the claiming worker.
3. `mature-ticket/spec-drafter-prompt.md` — opus. Drafts spec questions or a proposed spec from ticket + dependency context; returns the spec draft path and open questions.
4. `write-plan/plan-writer-prompt.md` — opus, autonomous lane only. Given spec path + exploration digest, drafts the plan doc per the write-plan template (incl. Testing Contract); main loop runs the review loop.
5. `verify/test-runner-prompt.md` — haiku. Runs one test group's commands; returns digest: command, exit code, failing test names, log file path. Shared by verify, submit-epic-pr regression, and review-child-pr local CI.

### Task 4: Skill body edits (delegation discipline)

- `epic-orchestrator/SKILL.md`: add **Delegation** section — state reconstruction via state-reader worker, evidence verification via evidence-checker worker; the main loop only routes, dispatches, and advances on citations.
- `brainstorm/SKILL.md`: step 1 becomes — dispatch parallel background Explore subagents for context, ask the first clarifying question while they run. Keep dialogue and spec writing in the main loop.
- `write-plan/SKILL.md`: add note — in the autonomous epic lane (entered via mature-ticket), delegate plan drafting to plan-writer worker; interactive use keeps drafting in-loop.
- `mature-ticket/SKILL.md`: reference spec-drafter prompt in Process.
- `verify/SKILL.md`: add **Runner Delegation** section — test groups run via test-runner workers returning digests; the gate semantics are preserved (claims only from evidence in digests: command + exit code). Read-only inspection stays in-loop.
- `submit-epic-pr/SKILL.md`: note that the full regression run dispatches verify's test-runner workers per group.
- `review-child-pr/SKILL.md`: steps 2–3 — dispatch the PR reviewer and the local CI runner **in parallel** (one message, two Agent calls); they are independent.
- `implement/SKILL.md`: tighten Model Selection with explicit aliases (haiku / sonnet / opus) matching the tier table.
- `quality-gate/SKILL.md`: add the five new prompt templates to the step-3 expected-file list (both trees).

### Task 5: AGENTS.md contributor conventions

Add a **Model Tiers** section (tier table + aliases-only + inherit rule) and a **Dispatch Discipline** section (delegation heuristic, worker return contract, parallel-read-only rule) so future skills follow the convention.

### Task 6: Metadata bump + validation fix

- Bump `0.8.3` → `0.9.0` in: `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `plugins/dodi-dev/.codex-plugin/plugin.json`.
- Fix `scripts/validate-plugin-metadata.sh`: drop the stale hard-coded `assert claude['version'] == '0.8.2'` (rotted at 0.8.3; the cross-file equality asserts are the real check).

### Task 7: Mirror to Codex tree + validate

```bash
rsync -a --delete dodi-dev/skills/ plugins/dodi-dev/skills/
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
find plugins/dodi-dev/skills -type l -print   # expect empty
```

Expected: all pass; version reported `0.9.0`.

### Task 8: Commit

One commit for the plan, one for the implementation (`feat: model tiers + dispatch discipline across dodi-dev skills`).

## Out of Scope

- Background/parallel cross-phase orchestration (one-action invariant stays).
- `fable` as the capable tier (revisit after observing opus behavior).
- Runtime-specific Codex wording divergence (trees stay exact mirrors for now).
