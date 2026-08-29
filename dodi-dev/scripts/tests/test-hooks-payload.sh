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

# Gate 2: a merge whose target repo cannot be determined fails closed (both shapes).
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 1"},"cwd":"/tmp"}' "claude-merge-failclosed"
expect_exit 2 "$GATE" '{"toolInput":{"command":"gh pr merge 1"},"cwd":"/tmp"}' "grok-merge-failclosed"

# Gate 2: an unparseable payload that appears to carry a merge fails closed;
# one that does not is allowed. (Regression: the extractor's failure path used
# to exit 0 for every command, merges included.)
expect_exit 2 "$GATE" 'not-json gh pr merge 5' "unparseable-merge-failclosed"
expect_exit 0 "$GATE" 'not-json git status' "unparseable-non-merge"

# --- Gate 2 scoping + wrong-repo-resolution regressions ---------------------
# Fixture repos (never touch the network: out-of-scope exits before gh, and
# in-scope tests run against the stub gh below).
FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT
git init -q "$FIX/florist" && git -C "$FIX/florist" remote add origin git@github.com:dodi-hq/dodi-florist.git
git init -q "$FIX/v2" && git -C "$FIX/v2" remote add origin https://github.com/dodi-hq/dodi_v2.git

# Stub gh: emits GH_STUB_JSON, or fails when GH_STUB_FAIL=1.
mkdir "$FIX/bin"
cat >"$FIX/bin/gh" <<'STUB'
#!/usr/bin/env bash
[[ "${GH_STUB_FAIL:-0}" == "1" ]] && { echo "stub gh failure" >&2; exit 1; }
printf '%s' "${GH_STUB_JSON:-}"
STUB
chmod +x "$FIX/bin/gh"

# Scope (2026-08-29 regression): a merge in an unprotected repo is out of
# scope and allowed — the guard used to block `gh pr merge` in any repository.
expect_exit 0 "$GATE" '{"tool_input":{"command":"gh pr merge 7 --squash"},"cwd":"'"$FIX/florist"'"}' "out-of-scope-repo-allowed"
expect_exit 0 "$GATE" '{"toolInput":{"command":"gh pr merge 7 --squash"},"cwd":"'"$FIX/florist"'"}' "out-of-scope-repo-allowed-grok"
expect_exit 0 "$GATE" '{"tool_input":{"command":"gh pr merge https://github.com/acme/widgets/pull/3"},"cwd":"/tmp"}' "out-of-scope-url-allowed"

# Scope: DODI_GATE2_REPOS overrides the default (dodi_v2); bare-name and
# owner-qualified entries both match, case-insensitively.
export PATH="$FIX/bin:$PATH" GH_STUB_FAIL=1
export DODI_GATE2_REPOS="dodi-florist"
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 7"},"cwd":"'"$FIX/florist"'"}' "allowlist-override-guards"
export DODI_GATE2_REPOS="Dodi-HQ/DODI_V2"
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 9"},"cwd":"'"$FIX/v2"'"}' "allowlist-owner-qualified"
expect_exit 0 "$GATE" '{"tool_input":{"command":"gh pr merge 7"},"cwd":"'"$FIX/florist"'"}' "allowlist-owner-qualified-excludes-others"
unset DODI_GATE2_REPOS GH_STUB_FAIL

# In scope (default allowlist = dodi_v2): base resolution via the stub.
export GH_STUB_JSON='{"baseRefName":"epic/dod-1200","url":"https://github.com/dodi-hq/dodi_v2/pull/9"}'
expect_exit 0 "$GATE" '{"tool_input":{"command":"gh pr merge 9"},"cwd":"'"$FIX/v2"'"}' "in-scope-epic-base-allowed"
export GH_STUB_JSON='{"baseRefName":"main","url":"https://github.com/dodi-hq/dodi_v2/pull/9"}'
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 9"},"cwd":"'"$FIX/v2"'"}' "in-scope-main-base-blocked"

# Fail-open regression (2026-08-29): gh resolving the ref against a different
# repo or PR (seen under gh account ambiguity) must read as unknown → blocked,
# even when the foreign PR's base is not main/master.
export GH_STUB_JSON='{"baseRefName":"epic/other","url":"https://github.com/other-org/other-repo/pull/9"}'
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 9"},"cwd":"'"$FIX/v2"'"}' "wrong-repo-resolution-blocked"
export GH_STUB_JSON='{"baseRefName":"epic/dod-1200","url":"https://github.com/dodi-hq/dodi_v2/pull/8"}'
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 9"},"cwd":"'"$FIX/v2"'"}' "wrong-pr-resolution-blocked"

# In scope: gh failing outright still fails closed.
unset GH_STUB_JSON
export GH_STUB_FAIL=1
expect_exit 2 "$GATE" '{"tool_input":{"command":"gh pr merge 9"},"cwd":"'"$FIX/v2"'"}' "in-scope-gh-failure-blocked"
unset GH_STUB_FAIL

echo "hook payload tests ok"
