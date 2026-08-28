# Epic Integration Reviewer Dual-Tier Declaration (DOD-1217) Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** Make `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` declare both of its seats (Capable step-3 integrated-head rounds; Frontier step-4 fable make-up round) in all three tier-bearing lines, name the Frontier tier at the `SKILL.md:33` dispatch site, and turn the multi-tier half of the tier self-declaration invariant into code via a seat registry in `scripts/validate-phase-skills.sh` — per spec `docs/specs/2026-08-28-epic-integration-reviewer-dual-tier-design.md` and canon DR-004.

**Architecture:** Prose edits in two skill files (three lines in the prompt template, one phrase in the SKILL), one new self-contained bash block appended after the existing tier self-declaration loop in `scripts/validate-phase-skills.sh` (a case-statement seat registry whose default branch is the completeness assert — no associative arrays, macOS bash 3.2 safe), one new negative-case test at `dodi-dev/scripts/tests/test-validate-phase-skills.sh` (first test of a repo-root validator; copy-tree-and-mutate), and the five-file patch version bump.

**Tech Stack:** Markdown skill files, bash validator + bash test, JSON plugin metadata. No CI — every check is local (`bash <path>`).

**Worktree:** `/Users/may/github/dodi/dodi-skills/dodi-dev/worktrees/epic-dod-1213`, branch `epic/dod-1213-fable-scarcity-doctrine`. Run every command from this worktree root.

**Cross-ticket coordination (spec § Integration with DOD-1214 — read before Task 1 and Task 3):** DOD-1214 (`docs/plans/2026-08-28-effort-first-class-axis.md`, ready-to-implement, unmerged as of plan time) edits the same line-9 parenthetical (adds effort text) and the same validator file (extends the tier loop with an effort check), and bumps the version to 0.17.0. **This plan must not assume either merge order.** Every task whose anchor DOD-1214 can move starts with a state probe and gives both variants. This ticket adds **no effort text of its own** when it merges first, and **must not revert** DOD-1214's effort text when it merges second. Lines 3 and 6 of the template, `SKILL.md:33`, and the registry block's insertion anchor are untouched by DOD-1214.

## Testing Contract

### Required Test Groups

- Unit: `not-required`
  - Scope: n/a (prompt-template prose plus one validator block)
  - Reason: no unit-test harness for markdown content exists in this repo; the prompt file is a template, not executable code — the validator check is its test (ticket Testing contract).
  - Minimum assertions: none.

- Integration: `required`
  - Scope: repository validators over the full skill tree and plugin metadata, plus the new validator-behavior test.
  - Reason: `validate-phase-skills.sh` is the regression surface — the new seat-registry block must pass all 15 `*-prompt.md` templates on the fixed tree and fail a template that under-declares its seats; `validate-plugin-metadata.sh` enforces five-file version parity. Nothing tested the validators before; this ticket adds the first check that needs one.
  - Harness: `existing` — standalone bash scripts, no runner above them; the new test follows the `dodi-dev/scripts/tests/` conventions (`set -euo pipefail`, executable bit, final `<name> tests ok` line, invoked by path — no aggregate runner exists).
  - Minimum assertions:
    - `bash scripts/validate-phase-skills.sh` exits 0 and prints `phase skills ok` on the fixed tree (all 15 templates pass the existing tier check AND the new registry check).
    - `bash dodi-dev/scripts/tests/test-validate-phase-skills.sh` exits 0 and prints `validate-phase-skills tests ok`, asserting three cases: (a) unmutated copy → exit 0; (b) copy with every `Frontier tier` occurrence removed from `epic-integration-reviewer-prompt.md` → exit 1, stderr names the file and the missing seat (`Frontier`); (c) copy with a fake `*-prompt.md` entry appended to `prompt_files` (file created with a valid single-tier declaration) → exit 1 with the no-seat-registry-row message (the completeness assert's only test).
    - `bash scripts/validate-plugin-metadata.sh` exits 0 printing `plugin metadata ok: <resolved version>` after the five-file bump (Task 5 resolves the value).

- E2E: `not-required` (not-applicable)
  - Scope: n/a.
  - Reason: whether a live step-4 dispatch actually reads the corrected declaration is a runtime-transcript property with no test surface here; the fix is not retroactive to transcripts (spec § Edge cases). The declaration's shape is fully covered by the validator + test.
  - Harness: `not-applicable`
  - Minimum assertions: none.

### Critical Flows

- `bash scripts/validate-phase-skills.sh` passes on the full edited tree, and the new registry block fails naming the file and the missing tier when a registered seat's tier name is absent (test case b).
- The registry's completeness assert fires on any `*-prompt.md` entry in `prompt_files` without a registry row (test case c).
- The fixed template satisfies acceptance criteria 1-5 as amended by the spec (exactly 2 `Frontier tier` matches — header prose + in-block declaration; block header names both seats by model pin; pin-match instruction present; zero substitution-hedge phrases).

### Regression Surface

- The other 18 entries in the `prompt_files` array (19 total: 15 prompt files + 4 non-prompt entries the case filter skips) — the registry block must not fail any of them (criterion 7 covers this since the validator iterates the whole array; the registry rows in Task 3 were verified against every template's current declarations on this tree).
- `dodi-dev/skills/submit-epic-pr/SKILL.md` steps 2-4: step 3's Capable pin (`SKILL.md:32`) and step 4's hard fable policy, obligations preamble, keyed consumption, and restart-at-step-3 rule are unchanged in substance — only step 4's tier naming moves (confirm by reading the diff).
- If DOD-1214 merged first: no DOD-1214 text reverted — `git diff` on `epic-integration-reviewer-prompt.md` and `scripts/validate-phase-skills.sh` shows only additions/rewrites per this plan's variant-B forms, with all effort text preserved.
- The six existing scripts in `dodi-dev/scripts/tests/` still pass (they are cheap; run the whole directory).
- `dodi-dev/scripts/hook-require-model-pin.sh` is not touched (spec Non-Goals).

### Commands

- Unit: `not-required — none`
- Integration: `bash scripts/validate-phase-skills.sh` ; `bash dodi-dev/scripts/tests/test-validate-phase-skills.sh` ; `bash scripts/validate-plugin-metadata.sh`
- E2E: `not-applicable — none`
- Broader regression: `bash scripts/validate-ticket-comment-templates.sh` ; `for t in dodi-dev/scripts/tests/test-*.sh; do echo "== $t"; bash "$t" || exit 1; done`

### Harness Requirements

- `bash`, `python3` (used inside the validators), `git`, `mktemp`, `awk`, `sed` — all present locally; no services, env vars, seeds, browsers, mocks, or accounts. Run everything from the worktree root (the validators use repo-relative paths; the new test resolves the repo root from its own location).

### Non-Required Rationale

- Unit: prompt prose plus one bash block; no markdown unit harness exists and inventing one is out of scope.
- Integration: (required — n/a)
- E2E: runtime dispatch behavior has no test surface in this repo; the declaration's shape is the testable artifact and is covered.

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## File Structure

One file created; eight modified.

| File | Responsibility of the change |
|------|------------------------------|
| `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` | lines 3, 6, 9 rewritten to declare both seats (exemplar: `review/child-pr-integration-prompt.md:3,6,9-11`) |
| `dodi-dev/skills/submit-epic-pr/SKILL.md` | one phrase in step 4 (:33): tier name added beside the `fable` alias |
| `scripts/validate-phase-skills.sh` | new seat-registry block **after** the existing tier self-declaration loop (existing loop untouched — it is DOD-1214's surface) |
| `dodi-dev/scripts/tests/test-validate-phase-skills.sh` (create) | negative-case test: copy-tree-and-mutate, three cases |
| `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json` | one patch-level version bump relative to the epic-branch value at implementation time (Task 5 resolves it) |

**Never modified:** the template's Output section (`epic-integration-reviewer-prompt.md:67-80` — the `caught-by: epic-integration/<round>/<tier>` line already fits both seats), the six aim classes, mechanical/judgment classification, head-freeze semantics, `SKILL.md:32` (step 3's Capable pin), the hard-policy sentence and obligations mechanics in `SKILL.md:33`, the existing tier loop at `scripts/validate-phase-skills.sh:60-70` (or its DOD-1214-extended form), `dodi-dev/scripts/hook-require-model-pin.sh`, `.agents/plugins/marketplace.json` (no version key), any effort text anywhere (DOD-1214's axis).

---

### Task 1: Template fix — three tier-bearing lines

**Files:**
- Modify: `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md:3,6,9-10`

- [ ] **Step 1:** Probe DOD-1214's state at this anchor (decides Step 4's variant)

Run: `grep -n 'You are an epic integration reviewer' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md`

- If the line reads `You are an epic integration reviewer (Capable tier). You are reviewing the` → DOD-1214 has **not** landed here; use **Variant A** in Step 4.
- If it reads `You are an epic integration reviewer (Capable tier, high effort). You are reviewing the` → DOD-1214 landed first; use **Variant B** in Step 4.
- Anything else (e.g. an already-dual-tier declaration): stop — the fix may already be merged; re-read the file and the ticket before editing.

- [ ] **Step 2:** Line 3 — header prose names both seats. Replace (this anchor is identical in both DOD-1214 states):

```text
Dispatch as a fresh-context subagent per round of the **integrated-head review loop** in `submit-epic-pr`, at Capable tier (`model: opus` on Claude Code) — a fresh reviewer every round, never a reused one.
```

with:

```text
Dispatch as a fresh-context subagent per round of the **integrated-head review loop** in `submit-epic-pr`: the step-3 integrated-head rounds at Capable tier (`model: opus` on Claude Code), and the conditional step-4 fable make-up round at Frontier tier (`model: fable` on Claude Code) — a fresh reviewer every round, never a reused one.
```

(The remainder of the paragraph — per-child gates context, mechanical/judgment routing — is byte-unchanged.)

- [ ] **Step 3:** Line 6 — Agent-tool block header names both pins (exemplar form: `review/child-pr-integration-prompt.md:6`; identical in both DOD-1214 states). Replace:

```text
Agent tool (general-purpose, model: opus):
```

with:

```text
Agent tool (general-purpose, model: opus for the integrated-head rounds; model: fable for the make-up round):
```

- [ ] **Step 4:** Line 9 — in-block self-declaration names both tiers plus the pin instruction, each seat's declaration unit on one physical line (matching DOD-1214's reflow convention so its flattened effort grep and any single-line grep both pass). Apply the variant chosen in Step 1. **No substitution hedge in either variant** — the make-up seat's fable-policy is hard (`SKILL.md:33`; AGENTS.md § Fable Availability Policy): never write "or the tier this dispatch pins" or any substitution language.

**Variant A (DOD-1214 not landed — no effort text; adding any would duplicate DOD-1214's edit):** replace:

```text
    You are an epic integration reviewer (Capable tier). You are reviewing the
    integrated head of an epic branch before its epic PR opens. Every merged
```

with:

```text
    You are an epic integration reviewer (Capable tier for the integrated-head rounds;
    Frontier tier for the fable make-up round — match this dispatch's pin).
    You are reviewing the integrated head of an epic branch before its epic PR
    opens. Every merged
```

**Variant B (DOD-1214 landed first — carry its effort text forward, per spec § Integration rule 1; never revert it):** replace:

```text
    You are an epic integration reviewer (Capable tier, high effort). You are reviewing the
    integrated head of an epic branch before its epic PR opens. Every merged
```

with:

```text
    You are an epic integration reviewer (Capable tier, high effort for the integrated-head rounds;
    Frontier tier, xhigh effort for the fable make-up round — match this dispatch's pin).
    You are reviewing the integrated head of an epic branch before its epic PR
    opens. Every merged
```

(In both variants the following lines — `child PR already passed its own review gates; your aim` onward — are byte-unchanged.)

- [ ] **Step 5:** Verify (amended acceptance criteria 1-5)

Run: `grep -n 'Frontier tier' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md`
Expected: exactly **2** matches — line 3 (header prose, `at Frontier tier (\`model: fable\` on Claude Code)`) and line 10 (the in-block declaration's second physical line). Not 3: the block header (line 6) names both seats by model pin per the exemplar, not by tier name (criterion 1 as amended by the spec — the original criterion's "at least three" was mechanically wrong).

Run: `grep -n 'model: opus for the integrated-head rounds; model: fable for the make-up round' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md`
Expected: 1 match at line 6 (criterion 3).

Run: `grep -cF "match this dispatch's pin" dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md`
Expected: `1` (criterion 4).

Run: `grep -c 'or the tier this dispatch pins' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md || true`
Expected: `0` (the grep itself exits 1 on zero matches — the `|| true` absorbs that; the count `0` is the assertion) (criterion 5).

Run: `bash scripts/validate-phase-skills.sh >/dev/null; echo "exit: $?"`
Expected: `exit: 0` (the existing tier loop — and DOD-1214's effort check if present — still passes on the reflowed declaration).

If Variant B was applied, additionally run: `grep -n 'high effort\|xhigh effort' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md`
Expected: both effort units present on lines 9-10 — DOD-1214's text carried forward, not reverted (additional acceptance criterion).

### Task 2: Dispatch-site phrase — `SKILL.md:33`

**Files:**
- Modify: `dodi-dev/skills/submit-epic-pr/SKILL.md:33`

- [ ] **Step 1:** One phrase in step 4 (DOD-1214 does not touch this file; the anchor is stable). Replace:

```text
dispatch **one batched fable round** using `epic-integration-reviewer-prompt.md` with a dispatcher-supplied obligations preamble enumerating them (no new prompt file).
```

with:

```text
dispatch **one batched Frontier-tier round** (`model: fable` on Claude Code) using `epic-integration-reviewer-prompt.md` with a dispatcher-supplied obligations preamble enumerating them (no new prompt file).
```

Nothing else in step 4 changes — the hard-policy sentence, the obligations preamble, keyed consumption, the restart-at-step-3 rule, and the `caught-by: epic-integration/<round>/fable` tagging are byte-unchanged. `SKILL.md:32` (step 3's Capable pin) is untouched.

- [ ] **Step 2:** Verify

Run: `grep -n 'batched' dodi-dev/skills/submit-epic-pr/SKILL.md`
Expected: exactly one match, line 33, showing `dispatch **one batched Frontier-tier round** (\`model: fable\` on Claude Code) using` — the tier name alongside the alias per AGENTS.md § Editing Rules (criterion 6).

Run: `grep -c 'fable-policy is hard' dodi-dev/skills/submit-epic-pr/SKILL.md`
Expected: `1` — the hard-policy sentence is intact.

Run: `ls dodi-dev/skills/submit-epic-pr/`
Expected: exactly `SKILL.md` and `epic-integration-reviewer-prompt.md` — no new prompt file (criterion 11).

- [ ] **Step 3:** Commit

```bash
git add dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md dodi-dev/skills/submit-epic-pr/SKILL.md
git commit -m "DOD-1217: declare both tiers in epic-integration-reviewer-prompt

The template serves two seats — step-3 integrated-head rounds at Capable
tier and the conditional step-4 fable make-up round at Frontier tier —
but named only Capable in all three tier-bearing lines. Fix lines 3, 6,
and 9 against the review/child-pr-integration-prompt.md exemplar (no
substitution hedge: the make-up seat's fable-policy is hard), and name
the Frontier tier beside the fable alias at the SKILL.md:33 dispatch
site.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 3: Validator seat registry

**Files:**
- Modify: `scripts/validate-phase-skills.sh` (new block after the existing tier self-declaration loop)

- [ ] **Step 1:** Probe DOD-1214's state at this anchor (informational — the insertion point is the same either way)

Run: `grep -c 'does not name its effort' scripts/validate-phase-skills.sh || true`

- `0` → DOD-1214's effort check not landed; the tier loop is the original :60-70 form.
- `1` → DOD-1214 landed first; the tier loop carries its effort check.

Either way: **do not modify the loop** — it is DOD-1214's surface (spec § Integration rule 3; keeping the surfaces disjoint minimizes the merge conflict). The new block goes **after** the loop's closing `done`, **before** the `# Deterministic skeleton:` comment. That seam (`done`, blank line, `# Deterministic skeleton: plugin scripts exist, are executable, and parse.`) is identical in both DOD-1214 states and unique in the file.

- [ ] **Step 2:** Insert the registry block. Replace:

```bash
done

# Deterministic skeleton: plugin scripts exist, are executable, and parse.
```

with:

```bash
done

# Multi-tier seat registry: every worker prompt template must name every tier
# it is dispatched at (AGENTS.md Dispatch Discipline — the second half of the
# tier self-declaration invariant; the loop above checks only the first half).
# A prompt file with no row here fails: registering the seats is part of
# adding or re-seating a template.
required_tiers_for() {
  case "$1" in
    brainstorm/spec-reviewer-prompt.md)                  echo "Frontier" ;;
    implement/implementer-prompt.md)                     echo "Standard Capable" ;;
    review/review-prompt.md)                             echo "Capable Frontier" ;;
    review/child-pr-integration-prompt.md)               echo "Capable Frontier" ;;
    write-plan/plan-reviewer-prompt.md)                  echo "Frontier" ;;
    write-plan/plan-writer-prompt.md)                    echo "Frontier" ;;
    epic-orchestrator/state-reader-prompt.md)            echo "Fast" ;;
    epic-orchestrator/evidence-checker-prompt.md)        echo "Fast" ;;
    epic-orchestrator/gate1-package-prompt.md)           echo "Frontier" ;;
    epic-orchestrator/coherence-reviewer-prompt.md)      echo "Frontier" ;;
    mature-ticket/spec-drafter-prompt.md)                echo "Frontier" ;;
    verify/test-runner-prompt.md)                        echo "Fast" ;;
    submit-ticket-pr/local-ci-runner-prompt.md)          echo "Fast" ;;
    submit-ticket-pr/docs-sync-prompt.md)                echo "Frontier" ;;
    submit-epic-pr/epic-integration-reviewer-prompt.md)  echo "Capable Frontier" ;;
    *)                                                   echo "" ;;
  esac
}

for prompt in "${prompt_files[@]}"; do
  case "$prompt" in
    *-prompt.md) ;;
    *) continue ;;
  esac
  path="dodi-dev/skills/${prompt}"
  tiers="$(required_tiers_for "$prompt")"
  if [[ -z "$tiers" ]]; then
    echo "worker prompt has no seat-registry row: ${prompt}" >&2
    exit 1
  fi
  for tier in $tiers; do
    if ! grep -q "${tier} tier" "$path"; then
      echo "worker prompt does not name a tier it is dispatched at (${tier}): ${prompt}" >&2
      exit 1
    fi
  done
  if [[ "$tiers" == *" "* ]] && ! grep -qF "match this dispatch's pin" "$path"; then
    echo "multi-tier worker prompt missing 'match this dispatch's pin': ${prompt}" >&2
    exit 1
  fi
done

# Deterministic skeleton: plugin scripts exist, are executable, and parse.
```

Registry semantics (spec § 3): a row lists the tiers a template is *dispatched at by design* — the seats, not the substitution outcomes. `submit-ticket-pr/docs-sync-prompt.md` is deliberately single-tier (`Frontier`): both its modes are designed-Frontier seats; the `opus` outcome under the child mode's soft policy is a policy event attributed by the `tier-degraded(...)` marker, not a seat. All rows were verified against the templates' current declarations and dispatch sites on this tree; the registry checks tiers only — effort coverage is DOD-1214's check.

- [ ] **Step 3:** Verify positive case

Run: `bash -n scripts/validate-phase-skills.sh; echo "syntax: $?"`
Expected: `syntax: 0`.

Run: `bash scripts/validate-phase-skills.sh; echo "exit: $?"`
Expected: file listing, then `phase skills ok`, `exit: 0` — all 15 `*-prompt.md` entries pass both the existing loop and the registry (the four non-prompt entries — `state-transitions.md`, `execution-model.md`, the two playbooks — are skipped by the `*-prompt.md` case guard) (criterion 7).

- [ ] **Step 4:** Hand-run the registry's negative case once, in a scratch copy (never mutate the working tree; the durable version of this check is Task 4's test)

```bash
tmp="$(mktemp -d)" && mkdir -p "$tmp/dodi-dev" \
  && cp -R dodi-dev/skills dodi-dev/scripts dodi-dev/hooks "$tmp/dodi-dev/" \
  && cp -R scripts "$tmp/" \
  && sed 's/Frontier tier/Redacted tier/g' "$tmp/dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md" > "$tmp/f" \
  && mv "$tmp/f" "$tmp/dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md" \
  && (cd "$tmp" && bash scripts/validate-phase-skills.sh >/dev/null); echo "exit: $?"; rm -rf "$tmp"
```
Expected: stderr line `worker prompt does not name a tier it is dispatched at (Frontier): submit-epic-pr/epic-integration-reviewer-prompt.md`, then `exit: 1` (criterion 12).

### Task 4: Negative-case test — `dodi-dev/scripts/tests/test-validate-phase-skills.sh`

First test of a repo-root validator. The existing `dodi-dev/scripts/tests/` source-and-assert pattern does not transfer (`validate-phase-skills.sh` is a non-sourceable top-to-bottom script), so the shape is copy-tree-and-mutate per the ticket's Testing contract. Two deliberate refinements of the contract's sketch, both required for correctness:

- **Copy enumerated subtrees, not `cp -R dodi-dev scripts`:** the main checkout hosts git worktrees under `dodi-dev/worktrees/` (untracked), so a bare `cp -R dodi-dev` run from the main checkout would recursively copy every worktree — each containing its own `dodi-dev` — into the temp dir. The validator reads only `dodi-dev/skills/**`, `dodi-dev/scripts/**`, `dodi-dev/hooks/hooks.json`, and `scripts/` (verified by reading all of it: no `templates/`, no git state), so the test copies exactly those.
- **Case (b) removes *every* `Frontier tier` occurrence** (not just line 9): the registry check is file-scope, so a partial removal leaving line 3's `Frontier tier (\`model: fable\` on Claude Code)` intact would let the check pass wrongly. Case (c)'s fake file carries a valid single-tier declaration (not `touch` — an empty file would fail the existing tier-presence loop first, with the wrong error message), so the failure is isolated to the registry's completeness assert. The fake declaration uses `(Fast tier, no effort axis)` so the same test passes unchanged after DOD-1214's effort check lands.

**Files:**
- Create: `dodi-dev/scripts/tests/test-validate-phase-skills.sh` (executable)

- [ ] **Step 1:** Create the file with this exact content:

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"

# Copy-tree-and-mutate: the validator reads only dodi-dev/skills, dodi-dev/scripts,
# dodi-dev/hooks, and its own repo-relative paths — no templates/, no git state.
# Enumerated subtrees, not `cp -R dodi-dev`: the main checkout hosts worktrees
# under dodi-dev/worktrees/, which a bare recursive copy would drag along.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/dodi-dev"
cp -R "$REPO_ROOT/dodi-dev/skills" "$REPO_ROOT/dodi-dev/scripts" "$REPO_ROOT/dodi-dev/hooks" "$tmp/dodi-dev/"
cp -R "$REPO_ROOT/scripts" "$tmp/"

fail=0
# The validator's error messages name prompts skill-relative (the ${prompt}
# array value), not repo-relative — assert on that form.
prompt_rel="submit-epic-pr/epic-integration-reviewer-prompt.md"
target_rel="dodi-dev/skills/$prompt_rel"
target="$tmp/$target_rel"

run_validator() { # sets rc and err
  rc=0
  err="$( (cd "$tmp" && bash scripts/validate-phase-skills.sh 2>&1 >/dev/null) )" || rc=$?
}

# Case (a): unmutated copy passes.
run_validator
if [[ "$rc" -ne 0 ]]; then
  echo "FAIL case-a: validator failed on unmutated copy: $err" >&2
  fail=1
fi

# Case (b): remove EVERY 'Frontier tier' occurrence from the dual-tier template
# (the registry check is file-scope — a partial removal would pass wrongly).
sed 's/Frontier tier/Redacted tier/g' "$target" > "$target.new" && mv "$target.new" "$target"
if grep -q 'Frontier tier' "$target"; then
  echo "FAIL case-b: mutation did not apply" >&2
  fail=1
fi
run_validator
if [[ "$rc" -eq 0 ]]; then
  echo "FAIL case-b: validator passed with the Frontier seat undeclared" >&2
  fail=1
fi
case "$err" in
  *"$prompt_rel"*) ;;
  *) echo "FAIL case-b: stderr does not name the offending file: $err" >&2; fail=1 ;;
esac
case "$err" in
  *Frontier*) ;;
  *) echo "FAIL case-b: stderr does not name the missing seat (Frontier): $err" >&2; fail=1 ;;
esac

# Restore for case (c).
cp "$REPO_ROOT/$target_rel" "$target"

# Case (c): a prompt_files entry with no registry row fails the completeness
# assert. The fake file carries a valid single-tier declaration so the failure
# is the registry's, not the tier-presence loop's.
vt="$tmp/scripts/validate-phase-skills.sh"
awk '{print} $0 == "  submit-epic-pr/epic-integration-reviewer-prompt.md" {print "  submit-epic-pr/fake-seat-prompt.md"}' "$vt" > "$vt.new" && mv "$vt.new" "$vt"
if ! grep -q 'fake-seat-prompt.md' "$vt"; then
  echo "FAIL case-c: prompt_files mutation did not apply" >&2
  fail=1
fi
printf 'You are a fake seat (Fast tier, no effort axis). Registry completeness-assert fixture.\n' \
  > "$tmp/dodi-dev/skills/submit-epic-pr/fake-seat-prompt.md"
run_validator
if [[ "$rc" -eq 0 ]]; then
  echo "FAIL case-c: validator passed with an unregistered prompt file" >&2
  fail=1
fi
case "$err" in
  *"no seat-registry row"*"fake-seat-prompt.md"*) ;;
  *) echo "FAIL case-c: expected the no-seat-registry-row message naming fake-seat-prompt.md, got: $err" >&2; fail=1 ;;
esac

if (( fail )); then echo "validate-phase-skills tests FAILED" >&2; exit 1; fi
echo "validate-phase-skills tests ok"
```

- [ ] **Step 2:** Set the executable bit

Run: `chmod +x dodi-dev/scripts/tests/test-validate-phase-skills.sh && ls -l dodi-dev/scripts/tests/test-validate-phase-skills.sh`
Expected: mode `-rwxr-xr-x`.

- [ ] **Step 3:** Verify

Run: `bash dodi-dev/scripts/tests/test-validate-phase-skills.sh; echo "exit: $?"`
Expected: `validate-phase-skills tests ok`, `exit: 0` (criterion 13).

Run: `bash scripts/validate-phase-skills.sh >/dev/null; echo "exit: $?"`
Expected: `exit: 0` — the new test file lives under `dodi-dev/scripts/tests/`, which the validator's `plugin_scripts` list does not enumerate; nothing in the validator regresses. (Note: the validator's final `find dodi-dev/skills` listing is unaffected — the test is under `dodi-dev/scripts/`.)

- [ ] **Step 4:** Commit

```bash
git add scripts/validate-phase-skills.sh dodi-dev/scripts/tests/test-validate-phase-skills.sh
git commit -m "DOD-1217: seat registry in validate-phase-skills + negative-case test

Every *-prompt.md entry in prompt_files maps to the tier names it must
declare (case statement, bash-3.2 safe); the default case is the
completeness assert. Multi-tier rows additionally require the literal
'match this dispatch's pin'. The existing tier loop is untouched (it
guards declaration shape; the registry guards seat coverage). New test
covers pass, missing-seat, and unregistered-entry cases via
copy-tree-and-mutate.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 5: Version bump — one patch level, five files

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `dodi-dev/.claude-plugin/plugin.json`
- Modify: `dodi-dev/.codex-plugin/plugin.json`
- Modify: `.grok-plugin/marketplace.json`
- Modify: `dodi-dev/.grok-plugin/plugin.json`

(`.agents/plugins/marketplace.json` carries no version key — do not touch it.)

- [ ] **Step 1:** Resolve the current epic-branch version (never hardcode — DOD-1214 bumps to 0.17.0 if it merged first)

Run: `grep -ho '"version": "[^"]*"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json | sort -u`
Expected: exactly **one** line (the five files agree). Call its value `<CUR>`. The target `<NEXT>` is one patch level up:
- `<CUR>` = `0.16.4` → `<NEXT>` = `0.16.5` (this ticket merges before DOD-1214)
- `<CUR>` = `0.17.0` → `<NEXT>` = `0.17.1` (DOD-1214 merged first)
- any other value → `<NEXT>` = `<CUR>` with the last component incremented by 1.

If the grep prints more than one line, the five files disagree — stop and escalate; do not bump over a parity defect.

- [ ] **Step 2:** In each of the five files, replace:

```text
"version": "<CUR>",
```

with:

```text
"version": "<NEXT>",
```

(One occurrence per file; leading indentation differs between the marketplace files and the plugin files — preserve each file's own indentation, which an exact-substring edit of just the key:value text does automatically.)

- [ ] **Step 3:** Verify (criteria 8 and 10, with the spec's whitespace-normalized parity check — a plain `grep -h '"version"' | sort -u | wc -l` returns 2 even on identical versions because the five files indent differently)

Run: `bash scripts/validate-plugin-metadata.sh; echo "exit: $?"`
Expected: `plugin metadata ok: <NEXT>`, `exit: 0`.

Run: `grep -ho '"version": "[^"]*"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json | sort -u | wc -l`
Expected: `1`, and the single value is `"version": "<NEXT>"` (re-run without `| wc -l` to see it).

- [ ] **Step 4:** Commit (bare version string in the message per AGENTS.md § Editing Rules; the `v<NEXT>` tag is applied at release time by the epic PR process, not by this lane). Substitute the resolved `<NEXT>`:

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json
git commit -m "DOD-1217: <NEXT> — dual-tier declaration in epic-integration-reviewer-prompt

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

Then run: `git log -1 --format=%s`
Expected: the subject contains the bare string `<NEXT>` (criterion 14).

### Task 6: Full acceptance + regression sweep (no code changes)

- [ ] **Step 1:** Run the acceptance-criteria greps (annotations state the expected result; `|| true` absorbs grep's exit-1-on-zero-matches where a zero count is the assertion)

```bash
grep -c 'Frontier tier' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md               # 2 (amended criterion 1)
grep -n 'model: opus for the integrated-head rounds; model: fable for the make-up round' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md   # 1 hit, line 6 (criterion 3)
grep -cF "match this dispatch's pin" dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md  # 1 (criterion 4)
grep -c 'or the tier this dispatch pins' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md || true   # 0 (criterion 5)
grep -n 'batched' dodi-dev/skills/submit-epic-pr/SKILL.md                                                # line 33 names Frontier-tier + fable alias (criterion 6)
ls dodi-dev/skills/submit-epic-pr/                                                                       # exactly SKILL.md + epic-integration-reviewer-prompt.md (criterion 11)
```

Additionally read `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md:3` and the in-block declaration to confirm criteria 2 and 4's prose reads per spec § 1, and read the `git diff` of `SKILL.md` to confirm only the one phrase moved.

- [ ] **Step 2:** If DOD-1214 merged first (Variant B was applied anywhere), confirm no DOD-1214 text was reverted

```bash
git diff main -- dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md scripts/validate-phase-skills.sh
```
(Diffed against `main`, not a fixed commit-count offset like `HEAD~3` — robust to however many commits this task's own work took, or to unrelated commits landing on the epic branch in the meantime.)
Expected: the template diff shows the dual-tier declaration carrying both effort units (`high effort` / `xhigh effort`); the validator diff shows only the appended registry block — DOD-1214's effort check inside the tier loop is untouched (additional acceptance criterion; spec § Integration rules 1 and 3).

- [ ] **Step 3:** Run the validators, the new test, and the full regression suite

```bash
bash scripts/validate-phase-skills.sh                      # exit 0, "phase skills ok" (criterion 7)
bash scripts/validate-plugin-metadata.sh                   # exit 0, "plugin metadata ok: <NEXT>" (criterion 8)
bash scripts/validate-ticket-comment-templates.sh          # exit 0 (criterion 9)
bash dodi-dev/scripts/tests/test-validate-phase-skills.sh  # exit 0, "validate-phase-skills tests ok" (criterion 13)
for t in dodi-dev/scripts/tests/test-*.sh; do echo "== $t"; bash "$t" || exit 1; done   # all seven pass
```
Expected: every command exits 0; the loop now runs seven test scripts (the six pre-existing plus the new one).

- [ ] **Step 4:** Confirm the working tree is clean

Run: `git status --porcelain`
Expected: empty — all changes committed across Tasks 2, 4, and 5. If a scratch temp dir leaked into the tree (it should not — Task 3 Step 4 and the test both work in `mktemp -d`), remove it before finishing.
