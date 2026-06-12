# dodi-skills - Codex Instructions

## Project Shape

- This repository publishes Dodi developer workflow skills.
- The Claude plugin marketplace entry is `.claude-plugin/marketplace.json`.
- The Claude plugin metadata is `dodi-dev/.claude-plugin/plugin.json`.
- Claude skills live under `dodi-dev/skills/*/SKILL.md`.
- Codex plugin metadata and skills should live in a separate Codex plugin tree.
- New workflow skills must be added to both Claude and Codex skill trees.

## Editing Rules

- Keep Claude and Codex skills functionally equivalent, but allow runtime-native wording and mechanics.
- Do not use symlinks or generated exposure as the long-term distribution model.
- If a released skill changes, update the relevant plugin versions for every affected runtime.
- Preserve each skill's frontmatter with `name` and `description`.
- Keep workflow instructions concrete and command-oriented.
- Prefer adding supporting prompt files beside the owning skill when the prompt is too long for `SKILL.md`.

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
