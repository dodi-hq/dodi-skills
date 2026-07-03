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

| Tier | Alias | Used for |
|------|-------|----------|
| Capable | `opus` | Spec drafting/review, plan writing/review, code review, PR review |
| Standard | `sonnet` | Writing code, writing tests, fixing findings, PR bodies, failure triage |
| Fast | `haiku` | Orchestration next-step decisions, git mechanics, state classification, command runners |

- Aliases only — never full model IDs; aliases track model upgrades.
- Interactive-facing skills (brainstorm, write-plan, pickup, submit, file-ticket) omit `model:` and inherit the session model. In the autonomous epic lane, `mature-ticket`'s `opus` pin persists for the rest of the turn into the spec/plan work it chains into.
- Never set `CLAUDE_CODE_SUBAGENT_MODEL` on hive machines — it outranks every per-dispatch pin.

## Dispatch Discipline

The main loop is a router and conversation surface. Bulk reads, test runs, and evidence checks go to workers that return compact digests — for responsiveness in interactive skills, and for context longevity in autonomous epic runs (an orchestrator that reads raw diffs/logs/PM dumps compacts and loses state).

- Delegate any step that pulls more than ~200 lines of file/log/PM content into the main loop, or runs longer than ~1 minute.
- Worker return contract: `STATUS` (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED, or Approved / Issues Found for reviewers) + `EVIDENCE` (commit ids, file paths, command + exit code, log path) + details capped at ~20 lines. No transcripts, no pasted logs.
- Parallel dispatch for read-only workers only (explorers, reviewers, evidence checkers). Implementers never run in parallel. State-advancing orchestration actions stay one at a time.

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
