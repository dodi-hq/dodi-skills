# Deliver-Ticket Lanes & Two-Gate Autonomy Implementation Plan

> **For agentic workers:** Execute tasks in order. Single tree — all skill edits under `dodi-dev/skills/`.

**Goal:** Ship the 0.11.0 workflow: `deliver-ticket` lanes (2 in parallel), two human gates (epic intent, production entry), scannable artifacts, and deliberate context resets.

**Spec:** `docs/specs/2026-07-02-deliver-ticket-lanes-and-two-gate-autonomy-design.md`

**Testing Contract (repo-native):** the three validation scripts are the regression suite — `scripts/validate-plugin-metadata.sh`, `scripts/validate-phase-skills.sh`, `scripts/validate-ticket-comment-templates.sh` — all must exit 0 after every task. No code harness applies to a markdown policy package.

## Tasks

1. **New skill `deliver-ticket`** (`dodi-dev/skills/deliver-ticket/SKILL.md`, `model: sonnet`): lane contract, internal sequence (pickup-ticket → implement-ticket → review pre-PR → create-tests → verify → quality-gate → open child PR → review child-PR), checkpoint comments, exit states (`ready-to-merge-child` / demote / blocked / `RESUMABLE`), resume contract, context reset at the quality-gate→PR seam. The lane never merges.
2. **Orchestrator** (`epic-orchestrator/SKILL.md`): `maxParallelLanes` input (default 2), Gate 1 and Gate 2 in Hard Gates, rewritten Allowed Next Actions (gate-1 signoff request, deliver-ticket dispatch, serial merge-child), Parallel Lanes policy, Context Hygiene (mandatory reset anchors, continuation brief, notes discipline). New worker prompt `gate1-package-prompt.md` (fable).
3. **State tables** (`epic-orchestrator/state-transitions.md`): external child states collapse to spec lane → ready-to-implement → delivering → ready-to-merge-child → done; inner table retained as the lane checkpoint contract; epic level gains `awaiting-epic-signoff`.
4. **Gate 1 delegation** (`mature-ticket/SKILL.md`, `assess-epic/SKILL.md`): epic-level signoff is the recorded delegation for all children; `needs-human-spec` label restores the per-child gate; `QUESTIONS_FOR_HUMAN` unchanged; assess-epic outputs feed the Gate 1 package and the parallelism check.
5. **Scannable artifacts** (`brainstorm/SKILL.md`, `mature-ticket/spec-drafter-prompt.md`, `brainstorm/spec-reviewer-prompt.md`, `submit-epic-pr/SKILL.md`, `quality-gate/SKILL.md`): specs and the readiness summary lead with `## TL;DR` + `## Key Points`; spec reviewers fail a missing or stale header; AGENTS.md gains the convention.
6. **submit-ticket-pr split**: "Open" (lane-invoked: push, PR, body) and "Merge" (orchestrator-invoked, serial, currency check). Child-PR review moves into the lane.
7. **Templates + validation**: new `templates/ticket-comments/epic-signoff-request.md` (Gate 1 package); `epic-pr-ready.md` gains the TL;DR/Key Points header; both wired into `validate-ticket-comment-templates.sh`; `validate-phase-skills.sh` gains `deliver-ticket` and `gate1-package-prompt.md`.
8. **AGENTS.md conventions**: Scannable Artifacts section; Context Hygiene section; dispatch-discipline note that delivery lanes may run in parallel across independent children while merges stay serial.
9. **Metadata bump** to `0.11.0` (three files) + full validation run.
