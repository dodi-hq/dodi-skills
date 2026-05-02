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

- Validate JSON metadata after edits:

  ```bash
  python -m json.tool .claude-plugin/marketplace.json
  python -m json.tool dodi-dev/.claude-plugin/plugin.json
  python -m json.tool .agents/plugins/marketplace.json
  python -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json
  ```

- Check the published file set before release:

  ```bash
  find dodi-dev/skills plugins/dodi-dev/skills -maxdepth 2 -type f | sort
  ```
