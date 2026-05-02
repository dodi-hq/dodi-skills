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
