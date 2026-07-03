#!/usr/bin/env bash
# PreToolUse hook (matcher: Task|Agent) — dispatch-pin enforcement.
# Rejects any subagent dispatch without an explicit `model` parameter: an
# unpinned dispatch silently inherits the session model, which in spec/plan
# sessions is Frontier — a defect, not a default (AGENTS.md Dispatch Discipline).
# Escape hatch: DODI_ALLOW_UNPINNED=1.
set -uo pipefail

if [[ "${DODI_ALLOW_UNPINNED:-0}" == "1" ]]; then
  exit 0
fi

input="$(cat)"
model="$(HOOK_IN="$input" python3 -c 'import json,os; print(json.loads(os.environ["HOOK_IN"]).get("tool_input", {}).get("model", "") or "")' 2>/dev/null)" || exit 0

if [[ -z "$model" ]]; then
  echo "BLOCKED by dodi-dev dispatch-pin guard: this Agent dispatch has no explicit 'model' parameter. Every worker dispatch pins a model tier (fable/opus/sonnet/haiku) — an unpinned dispatch inherits the session model, which is a defect, not a default. Add the pin per AGENTS.md Model Tiers and retry. (Escape hatch for non-dodi work: DODI_ALLOW_UNPINNED=1.)" >&2
  exit 2
fi

exit 0
