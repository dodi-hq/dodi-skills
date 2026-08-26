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

# Tier fit: mechanical shapes pinned above Standard are blocked (both shapes).
# The regression case (2026-08-26): a delivery lane blanket-pinned opus and ran
# its test runner at review tier.
expect_exit 2 "$PIN" '{"tool_input":{"model":"opus","description":"Run DOD-1143 replica-set contract suite","prompt":"y"}}' "misfit-test-suite-opus"
expect_exit 2 "$PIN" '{"toolInput":{"model":"claude-fable-5","description":"Run the designer unit-test suite","prompt":"y"}}' "misfit-test-suite-fable"
expect_exit 2 "$PIN" '{"tool_input":{"model":"opus","description":"State-reader for epic DOD-1140","prompt":"y"}}' "misfit-state-reader"
expect_exit 2 "$PIN" '{"tool_input":{"model":"opus","description":"Create the child branch and worktree","prompt":"y"}}' "misfit-worktree"

# Tier fit: mechanics at or below Standard are fine.
expect_exit 0 "$PIN" '{"tool_input":{"model":"haiku","description":"Run DOD-1143 replica-set contract suite","prompt":"y"}}' "fit-test-suite-haiku"
expect_exit 0 "$PIN" '{"tool_input":{"model":"sonnet","description":"Run the designer unit-test suite","prompt":"y"}}' "fit-test-suite-sonnet"

# Tier fit: judgment shapes are never mechanical, even at Frontier.
expect_exit 0 "$PIN" '{"tool_input":{"model":"fable","description":"Pre-PR fable final DOD-1197","prompt":"y"}}' "fit-review-fable"
expect_exit 0 "$PIN" '{"tool_input":{"model":"opus","description":"Pre-PR round-2 review: test infra","prompt":"y"}}' "fit-review-testinfra"

# Tier fit: matching reads the description only — a reviewer prompt that mentions
# running the suite must not trip the guard.
expect_exit 0 "$PIN" '{"tool_input":{"model":"opus","description":"Integrated-head epic review r1","prompt":"Read the diff and run the full test suite before judging."}}' "fit-desc-only"

# Tier fit: a declared escalation is allowed — never silent.
expect_exit 0 "$PIN" '{"tool_input":{"model":"opus","description":"Run the flaky replica-set suite","prompt":"tier-justified: needs judgment to classify nondeterministic failures"}}' "fit-tier-justified"

# Tier fit: unknown slugs (Grok maps every tier to one model) skip the fit check.
expect_exit 0 "$PIN" '{"toolInput":{"model":"grok-4.6","description":"Run the designer unit-test suite","prompt":"y"}}' "fit-grok-slug-skips"

# Gate 2: non-merge commands are allowed on both payload shapes.
expect_exit 0 "$GATE" '{"tool_input":{"command":"git status"}}' "claude-non-merge"
expect_exit 0 "$GATE" '{"toolInput":{"command":"git status"}}' "grok-non-merge"

# Gate 2: a merge whose base cannot be resolved fails closed (both shapes).
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 1"},"cwd":"/tmp"}' "claude-merge-failclosed"
expect_exit 2 "$GATE" '{"toolInput":{"command":"gh pr merge 1"},"cwd":"/tmp"}' "grok-merge-failclosed"

echo "hook payload tests ok"
