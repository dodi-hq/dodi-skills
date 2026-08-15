#!/usr/bin/env bash
# Dual-payload contract: Claude Code uses tool_input; Grok Build uses toolInput.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PIN="$HERE/../hook-require-model-pin.sh"
GATE="$HERE/../hook-gate2-guard.sh"
bash -n "$PIN"
bash -n "$GATE"

run_hook() {
  local script="$1"
  local payload="$2"
  printf '%s' "$payload" | bash "$script"
  return $?
}

expect_exit() {
  local want="$1"
  local script="$2"
  local payload="$3"
  local label="$4"
  set +e
  run_hook "$script" "$payload"
  local got=$?
  set -e
  [[ "$got" -eq "$want" ]] || {
    echo "FAIL $label: expected exit $want, got $got" >&2
    exit 1
  }
}

# Pin hook: missing model is blocked on both payload shapes.
expect_exit 2 "$PIN" '{"tool_input":{"description":"x","prompt":"y"}}' "claude-unpinned"
expect_exit 2 "$PIN" '{"toolInput":{"description":"x","prompt":"y"}}' "grok-unpinned"

# Pin hook: explicit model is allowed on both payload shapes.
expect_exit 0 "$PIN" '{"tool_input":{"model":"sonnet","prompt":"y"}}' "claude-pinned"
expect_exit 0 "$PIN" '{"toolInput":{"model":"grok-4.6","prompt":"y"}}' "grok-pinned"

# Gate 2: non-merge commands are allowed on both payload shapes.
expect_exit 0 "$GATE" '{"tool_input":{"command":"git status"}}' "claude-non-merge"
expect_exit 0 "$GATE" '{"toolInput":{"command":"git status"}}' "grok-non-merge"

# Gate 2: a merge whose base cannot be resolved fails closed (both shapes).
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 1"},"cwd":"/tmp"}' "claude-merge-failclosed"
expect_exit 2 "$GATE" '{"toolInput":{"command":"gh pr merge 1"},"cwd":"/tmp"}' "grok-merge-failclosed"

echo "hook payload tests ok"
