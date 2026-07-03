# dodi-skills - Codex Instructions

## Project Shape

- This repository publishes Dodi developer workflow skills.
- There is one canonical skill tree, `dodi-dev/skills/*/SKILL.md`, served to both runtimes.
- The plugin directory `dodi-dev/` carries two metadata envelopes: `.claude-plugin/plugin.json` (Claude Code) and `.codex-plugin/plugin.json` (Codex).
- Marketplace entries point at the same directory: `.claude-plugin/marketplace.json` (Claude) and `.agents/plugins/marketplace.json` (Codex), both with source `./dodi-dev`.
- There is no mirror tree. Never reintroduce a copied skill tree; drift is a release bug.

## Editing Rules

- Skills are harness-neutral: one SKILL.md must read correctly on both Claude Code and Codex.
- Write harness-specific mechanics (model aliases, Agent tool) as the Claude form plus the tier name, e.g. "Capable tier (`model: opus` on Claude Code)". Codex maps tiers per the table below.
- If a released skill changes, bump the version in all three metadata files in the same change.
- Preserve each skill's frontmatter with `name` and `description`.
- Keep workflow instructions concrete and command-oriented.
- Prefer adding supporting prompt files beside the owning skill when the prompt is too long for `SKILL.md`.
- Skills must never reference files that exist only in this repository (e.g. `docs/specs/...`); policy a skill needs at runtime ships inside the skill's own directory.

## Model Tiers

Every skill and worker dispatch declares a model tier. Two levers: `model:` in SKILL.md frontmatter (switches the main-loop model for the rest of the turn when the skill is invoked) and the Agent tool's `model` parameter (pinned directly in worker prompt templates so it is mechanical, not advisory).

| Tier | Claude alias | Used for |
|------|--------------|----------|
| Frontier | `fable` | Spec drafting/review, plan writing/review, the final pre-PR review round |
| Capable | `opus` | Per-round code review, PR review |
| Standard | `sonnet` | Orchestration routing, writing code, writing tests, fixing findings, PR bodies, failure triage, quality gate |
| Fast | `haiku` | Git mechanics, state classification, command/test runners, read-only state digests |

- Aliases only — never full model IDs; aliases track model upgrades.
- Aliases are Claude Code vocabulary. On Codex, map tiers to the closest local equivalents (Frontier/Capable → highest-reasoning configuration, Standard → default coding model, Fast → small fast model); a skill that names a Claude alias means that tier.
- Pick tiers by capability match, never by cost — the goal is intelligence-effectiveness; dollars and token counts fall where they fall. Use Frontier wherever judgment quality compounds downstream (specs, plans, review gates). Use lower tiers only where frontier intelligence adds nothing to the output (git mechanics, test execution, state digests) — they are faster and lower-latency, which is itself effectiveness.
- The review pipeline intentionally mixes tiers for reviewer diversity, not thrift: `opus` per-round and a fresh `fable` final gate have different failure modes, so the final round is a genuinely independent check rather than one more identical pass. When a task smells like judgment, escalate the tier — never economize on it.
- Judgment-heavy interactive skills (brainstorm, write-plan) omit `model:` and inherit the session model — run those sessions on the Frontier model. Mechanical interactive skills (pickup, file-ticket, submit) pin `sonnet`. In the autonomous epic lane, `mature-ticket`'s `fable` pin persists for the rest of the turn into the spec/plan work it chains into.
- Never set `CLAUDE_CODE_SUBAGENT_MODEL` on hive machines — it outranks every per-dispatch pin.

## Dispatch Discipline

The main loop is a router and conversation surface. Bulk reads, test runs, and evidence checks go to workers that return compact digests — for responsiveness in interactive skills, and for context longevity in autonomous epic runs (an orchestrator that reads raw diffs/logs/PM dumps compacts and loses state).

- Delegate any step that pulls more than ~200 lines of file/log/PM content into the main loop, or runs longer than ~1 minute.
- Worker return contract: `STATUS` (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED, or Approved / Issues Found for reviewers) + `EVIDENCE` (commit ids, file paths, command + exit code, log path) + details capped at ~20 lines. No transcripts, no pasted logs.
- Parallel dispatch for read-only workers (explorers, reviewers, evidence checkers) is always allowed. `deliver-ticket` lanes may run in parallel across independent children (no dependency edge, disjoint predicted file surfaces; when in doubt, serialize). Within a lane, implementers never run in parallel. Merges into the epic branch and PM state advances stay one at a time.

## Scannable Artifacts

Every human-facing artifact — specs, the Gate 1 signoff package, the epic readiness summary, notifications — leads with:

- `## TL;DR` — 2-3 sentences.
- `## Key Points` — 5-9 bullets: decisions, tradeoffs, in/out scope, risks; prefix delegated assumptions with ⚠.

The header must be self-sufficient: a human who reads nothing else can approve or redirect. Everything below is written for agents. Notifications carry only the header plus links. Spec reviewers treat a missing or stale header as a blocking finding.

## Context Hygiene

Long-running sessions compact deliberately — a deliberate compaction is a voluntary crash + resume against durable state, never a harness-forced mid-thought summary.

- A legal reset point passes the Resumability Test: a fresh session, given only durable state, would choose the same next action.
- Mandatory anchors: orchestrator after Gate 1 approval and after every child merge; lanes at the quality-gate→PR seam.
- Never reset mid-step; finish the step, write the continuation brief (state + evidence links, next action + why, live concerns, in-flight work that must not be redone), then reset.
- Soft observations (flaky tests, retried workers, fragile modules) are appended to notes as they occur — when unsure, write it down.

## Verification

- Run repository validation scripts:

  ```bash
  scripts/validate-plugin-metadata.sh
  scripts/validate-phase-skills.sh
  scripts/validate-ticket-comment-templates.sh
  ```

- Validate runtime templates when they change:

  ```bash
  python3 - <<'PY'
  import json
  from pathlib import Path
  for line in Path('templates/run-ledger/record.jsonl').read_text().splitlines():
      json.loads(line)
  print('jsonl ok')
  PY
  ```
