# C5: Catch-Attribution Rider + Doctrine + 0.15.0 Release — Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute tasks in order (1→4). Each task ends with its own Verify (all commands must exit 0) and its own local commit; the phase-skills validator is green at every task boundary, and Task 4 — the metadata bump, deliberately last — closes with all three repo validators (the metadata validator then asserting `plugin metadata ok: 0.15.0`) plus the full grep battery. All Old-text anchors below are byte-exact from the epic branch @ `3bfbf29` (C1+C2+C3+C4 merged; both new prompts exist, born untagged per [S1]); **anchor by the quoted text, never by line number** (line numbers in this plan are hints). If an Old anchor does not match exactly, STOP and re-read the file — never fuzzy-match or approximate.

**Goal:** Land Change 5 — the fully wired catch-attribution rider: one per-finding `caught-by: <gate>/<round>/<tier>` output-format line in each of the SIX reviewer prompts, the catch-tag rule (grammar + tagging surfaces + dispatcher duties) in `review/SKILL.md`, and the AGENTS.md sweep (Frontier row + review-pipeline doctrine sentence + catch-tag one-liner) — then bump the version to **0.15.0** in exactly the three metadata files, closing the epic (spec § Change 5 + its sweep rows; scope = GitHub issue #7 as amended; canon [S1] completes here — C5 owns ALL caught-by lines, and the two prompts born untagged by C1/C4 receive theirs in this one reviewable diff).

**Architecture:** Emitters and dispatcher split per the spec: the six reviewer prompts each gain exactly one output-format line instructing the reviewer to tag each finding with its gate token — five gates hard-coded (`child-pr`, `spec-review`, `plan-review`, `coherence`, `epic-integration`), while `review/review-prompt.md` serves two epic-lane gates plus the interactive context, so its line carries a dispatcher-filled `[GATE_TOKEN]` placeholder (`pre-pr` | `focused-re-review`; interactive post-implementation carries `pre-pr`-equivalent attribution or none). Round and tier are appended by the dispatcher when posting; the dispatcher itself tags `verify`/local-CI **failures** (runners stay pure — no runner prompt gains a tag line). The doctrine home is a new `## Catch Attribution` section in `review/SKILL.md` (round grammar: integers per gate, a `fable` final is its integer, single-shot gates verify/local-ci/coherence use `1` per attempt, epic-integration counts rounds within its per-attempt loop; tagging surfaces: the NEXT boundary's evidence, append-only — verify-stage failures in the `ready-for-child-pr` checkpoint evidence, child-PR-stage local-CI failures in the lane's `ready-to-merge-child` exit report). AGENTS.md gets the Frontier-row extension (line 27) and, at the line-35 adjacency the spec flags, the two-fable-rounds doctrine folded INTO the existing tier-diversity bullet plus the catch-tag one-liner as its own adjacent bullet — extend-not-duplicate. The 0.15.0 bump is the last task, so every earlier boundary still validates as 0.14.2 and the final battery asserts the release lockstep.

**Tech Stack:** Markdown skills (harness-neutral per AGENTS.md Editing Rules), JSON plugin metadata, Bash validator scripts. The three repo validators are the regression suite.

**Source of truth:** `docs/specs/2026-07-06-review-pipeline-consolidation-design.md` § Change 5 (the binding paragraph: emitters cover the whole enum; gate-token composition; round grammar pinned incl. epic-integration counting its per-attempt loop; tagging surfaces append-only) + the C5 reference-sweep rows (review/SKILL.md "catch-tag rule"; review-prompt.md dispatcher-supplied gate; the three "+1 output-format line" rows; AGENTS.md row; metadata row). GitHub issue #7 body **as amended** ([S1]: C5 owns ALL caught-by lines; both new prompts born untagged receive theirs here). Epic canon (#3 § Decision Register — Canon): [S1], [C4-c] (the epic-integration prompt's fifth input is registered — this plan only appends its tag line), [G1]/[C3-c] (this lane runs under installed 0.14.2; the tag goes live when the release applies).

**File surface (eleven files — all modify, no creates):** `dodi-dev/skills/review/SKILL.md` (+ § Catch Attribution), `dodi-dev/skills/review/review-prompt.md`, `dodi-dev/skills/review/child-pr-integration-prompt.md`, `dodi-dev/skills/brainstorm/spec-reviewer-prompt.md`, `dodi-dev/skills/write-plan/plan-reviewer-prompt.md`, `dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md`, `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` (one output line each), `AGENTS.md` (2 hunks), `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json` (version → 0.15.0).

**Boundary discipline — do NOT touch (out of scope or deliberately tag-free):**

- **Runner prompts stay pure:** `verify/test-runner-prompt.md` and `submit-ticket-pr/local-ci-runner-prompt.md` get NO tag line — the dispatcher tags verify/local-CI failures. The Task 4 file-set equality asserts this positively.
- Every other prompt and skill: `implement/implementer-prompt.md`, `write-plan/plan-writer-prompt.md`, `mature-ticket/spec-drafter-prompt.md`, `epic-orchestrator/` state/reader/checker/dispatch files (incl. the dead `lane-dispatch-prompt.md`), `deliver-ticket/`, `verify/`, `submit-ticket-pr/`, `submit-epic-pr/SKILL.md`, `drive-epic/` — zero diff vs `3bfbf29`.
- `epic-orchestrator/state-transitions.md` and `templates/ticket-comments/*` — zero diff: the tag rides INSIDE evidence bodies; no checkpoint column, template line, or validator assertion changes (the tagging-surface rule is prose in `review/SKILL.md`).
- `scripts/*` — zero diff (no validator changes in C5).
- `.agents/plugins/marketplace.json` — **has NO version field; not a bump target** (the metadata validator asserts only its source path). The bump is exactly three files.
- `review/SKILL.md` outside the one inserted section; each prompt outside its one inserted line; AGENTS.md outside the two hunks (lines 27 and 35-area) — byte-identical. In particular the Capable/Standard/Fast rows and the `needs-capable-delivery` bullet stay untouched.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `functions/components/modules` — the eleven modified files, exercised by the three repo validators (metadata lockstep + JSON parse, skill/prompt existence + repo-only-reference hygiene, template heading integrity).
  - Reason: `<why>` — this is a docs/prose/validator repository; the validators are the executable unit surface, and this child moves the version the metadata validator asserts in lockstep across three files — the bump task's battery expects `plugin metadata ok: 0.15.0`.
  - Minimum assertions: `<specific behaviors>` — `validate-phase-skills.sh` exits 0 after every task (1–4); `validate-plugin-metadata.sh` exits 0 in Task 4 printing `plugin metadata ok: 0.15.0`; all three validators exit 0 in Task 4.

- Integration: `not-required`
  - Scope: `module boundaries/APIs/db/jobs/etc` — n/a.
  - Reason: `<why>` — no executable pipeline exists in this repository; the validators ARE the integration surface (cross-file existence, reference, and lockstep checks). Same rationale class as C1/C2/C3/C4.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a; see the Broader-regression battery (Task 4 Step 5) for cross-file text assertions.

- E2E: `not-required`
  - Scope: `user/business-critical flows` — n/a.
  - Reason: `<why>` — prose-skill behavior has no desk harness, and the tag's live data path (PM evidence comments) cannot be exercised at desk; the live exercise arrives with the 0.15.0 release itself — this epic is walked under installed 0.14.2 per canon [G1]/[C3-c], and DOD-650 is the first measured caught-by sample. Same rationale class as C1/C2/C3/C4. (Field precedent for the tag format already exists in this epic's own PM trail — e.g. `spec-review/1/fable`, `pre-pr/2/fable` — applied manually.)
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a.

### Critical Flows

- `Reviewer emits the tag per finding (gate token hard-coded, or [GATE_TOKEN] dispatcher-filled for review-prompt.md) → dispatcher appends round and tier when posting → posted evidence is grep-aggregatable by gate`
- `Dispatcher-only tagging for verify/local-CI failures at the NEXT boundary's evidence (append-only): verify-stage → ready-for-child-pr checkpoint evidence; child-PR-stage local CI → ready-to-merge-child exit report; runner prompts never carry the tag`
- `Round grammar composes for DOD-650: integers per gate; fable final = its integer; verify/local-ci/coherence = 1 per attempt; epic-integration counts rounds within its per-attempt loop`
- `Release lockstep: the three metadata files move to 0.15.0 together and the metadata validator asserts equality`

### Regression Surface

- `Runner prompts (verify/test-runner-prompt.md, submit-ticket-pr/local-ci-runner-prompt.md) and every non-emitter prompt/skill — byte-identical to 3bfbf29 (file-set equality, Task 4)`
- `Each emitting prompt outside its one added line — byte-identical (numstat 1/0 per prompt); leaf-discipline lines untouched`
- `review/SKILL.md outside § Catch Attribution — byte-identical (numstat 8/0, one hunk; heading sequence pinned)`
- `AGENTS.md rows 28–30 (Capable/Standard/Fast), the needs-capable-delivery bullet, and everything outside the two hunks — byte-identical (numstat 3/2, 2 hunks; survivor greps)`
- `state-transitions.md, templates/, scripts/ — zero diff (the sole permanent quality-gating resume token area is not entered at all)`
- `.agents/plugins/marketplace.json — zero diff (no version field)`

### Commands

- Unit: `bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh && bash scripts/validate-ticket-comment-templates.sh` (from the repo root; Tasks 1–3 run phase-skills at each boundary, Task 4 runs all three — metadata then prints `plugin metadata ok: 0.15.0`)
- Integration: `not-applicable — no executable pipeline; the validators are the integration surface`
- E2E: `not-applicable — live exercise arrives with the 0.15.0 release; this epic runs under installed 0.14.2 per canon [G1]/[C3-c]; DOD-650 is the first measured sample`
- Broader regression: the Task 4 Step 5 battery — caught-by file-set equality on ship surfaces (exactly 8 files), per-file count exactly 1, per-prompt gate-token pins, changed-file-set equality vs `3bfbf29` (exactly the 11 C5 files, docs/ excluded), per-file hunk/numstat precision, version pins + old-version negations; every command exits 0 on success.

### Harness Requirements

- `bash, python3, grep, git, awk — repo checkout only; no network, no PM access, no env vars`

### Non-Required Rationale

- Unit: n/a (required).
- Integration: `no executable pipeline exists; the three validators are the only cross-file integration surface and run as the Unit group (same rationale class as C1/C2/C3/C4)`
- E2E: `no desk e2e of prose skills or PM comment flows exists; live behavior lands at the 0.15.0 release — this epic dogfoods 0.14.2 per canon [G1]/[C3-c] (same rationale class as C1/C2/C3/C4)`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

**Caught-by end state (asserted in Task 4): exactly 8 ship-surface files, exactly 1 line each**

| File | caught-by lines @ 3bfbf29 | after C5 | gate token on the line |
| --- | --- | --- | --- |
| `AGENTS.md` | 0 | **1** | `<gate>` (generic one-liner) |
| `dodi-dev/skills/review/SKILL.md` | 0 | **1** | `<gate>` (rule; full enum) |
| `dodi-dev/skills/review/review-prompt.md` | 0 | **1** | `[GATE_TOKEN]` (dispatcher-supplied: `pre-pr` \| `focused-re-review`) |
| `dodi-dev/skills/review/child-pr-integration-prompt.md` | 0 | **1** | `child-pr` |
| `dodi-dev/skills/brainstorm/spec-reviewer-prompt.md` | 0 | **1** | `spec-review` |
| `dodi-dev/skills/write-plan/plan-reviewer-prompt.md` | 0 | **1** | `plan-review` |
| `dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md` | 0 | **1** | `coherence` |
| `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` | 0 | **1** | `epic-integration` |

---

## Tasks

### Task 1: `review/` home surfaces — § Catch Attribution rule + the two review-gate prompt lines

**Files:**
- Modify: `dodi-dev/skills/review/SKILL.md` (one inserted section between Epic Lane Rules and Don't Skip This, line ~59)
- Modify: `dodi-dev/skills/review/review-prompt.md` (one line added to the Output section, line ~64)
- Modify: `dodi-dev/skills/review/child-pr-integration-prompt.md` (one line added to the Output section, line ~59)

- [ ] **Step 1:** Insert the `## Catch Attribution` section into `review/SKILL.md`. The Old block is the last Epic Lane Rules bullet plus the next heading (consecutive, unique).

Old:

```markdown
- Record reviewer status, findings, fixes, reviewed diff range, commands and exit codes, and the final clean-round evidence.

## Don't Skip This
```

New:

```markdown
- Record reviewer status, findings, fixes, reviewed diff range, commands and exit codes, and the final clean-round evidence.

## Catch Attribution

Every posted review-evidence finding — lane checkpoint evidence, review comments, escalations, demotion comments — carries a per-finding tag `caught-by: <gate>/<round>/<tier>`, gate ∈ {spec-review, plan-review, pre-pr, focused-re-review, verify, local-ci, child-pr, epic-integration, coherence}. Reviewer prompts emit the tag per finding — single-gate prompts hard-code their gate token; review-prompt.md serves two epic-lane gates plus the interactive context, so its gate token is supplied by the dispatcher from the invoking context (`pre-pr` | `focused-re-review`; interactive post-implementation runs carry `pre-pr`-equivalent attribution or none). The dispatcher appends round and tier when posting, and itself tags `verify`/local-CI **failures** (runners stay pure — the tag never enters a runner prompt).

- **Round grammar:** `<round>` is an integer counting rounds within that gate's loop for this ticket — a `fable` final is its integer, never "final"; single-shot gates (verify, local-ci, coherence) use `1` per attempt; epic-integration counts rounds within its per-attempt loop like the review gates. `<tier>` is the catching round's model tier alias (e.g. `opus`, `fable`).
- **Tagging surfaces (append-only — never edit a posted checkpoint):** tags land in the next boundary's evidence — a verify-stage failure tags in the `ready-for-child-pr` checkpoint evidence; a child-PR-stage local-CI failure (when the conditional dispatches it) tags in the lane's `ready-to-merge-child` exit report.
- No new artifact, no script: the tag is grep-aggregatable from PM comments.

## Don't Skip This
```

- [ ] **Step 2:** Add the tag line to `review-prompt.md`'s Output Issues block (the dispatcher supplies the gate token — this prompt serves `pre-pr` and `focused-re-review`).

Old:

```markdown
    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]
    - classify each: spec mismatch | implementation | test | security | hygiene | regression risk
```

New:

```markdown
    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]
    - classify each: spec mismatch | implementation | test | security | hygiene | regression risk
    - tag each: `caught-by: [GATE_TOKEN]/<round>/<tier>` — the dispatcher supplies [GATE_TOKEN] from the invoking context (`pre-pr` | `focused-re-review`; interactive post-implementation carries `pre-pr`-equivalent attribution or none) and appends round and tier when posting
```

- [ ] **Step 3:** Add the tag line to `child-pr-integration-prompt.md`'s Output Issues block (hard-coded gate).

Old:

```markdown
    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]
    - classify each: spec mismatch | implementation | test | security | hygiene | regression risk
```

New:

```markdown
    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]
    - classify each: spec mismatch | implementation | test | security | hygiene | regression risk
    - tag each: `caught-by: child-pr/<round>/<tier>` — round and tier appended by the dispatcher when posting
```

- [ ] **Step 4:** Verify

Run (from the repo root):

```bash
# Full-block pin for the multi-line New section (literal <<'PATN' — no backtick/$ expansion; -x = whole-line match; each of the 5 pattern lines matches exactly its own file line).
PATN1="$(mktemp)"; cat > "$PATN1" <<'PATN'
## Catch Attribution
Every posted review-evidence finding — lane checkpoint evidence, review comments, escalations, demotion comments — carries a per-finding tag `caught-by: <gate>/<round>/<tier>`, gate ∈ {spec-review, plan-review, pre-pr, focused-re-review, verify, local-ci, child-pr, epic-integration, coherence}. Reviewer prompts emit the tag per finding — single-gate prompts hard-code their gate token; review-prompt.md serves two epic-lane gates plus the interactive context, so its gate token is supplied by the dispatcher from the invoking context (`pre-pr` | `focused-re-review`; interactive post-implementation runs carry `pre-pr`-equivalent attribution or none). The dispatcher appends round and tier when posting, and itself tags `verify`/local-CI **failures** (runners stay pure — the tag never enters a runner prompt).
- **Round grammar:** `<round>` is an integer counting rounds within that gate's loop for this ticket — a `fable` final is its integer, never "final"; single-shot gates (verify, local-ci, coherence) use `1` per attempt; epic-integration counts rounds within its per-attempt loop like the review gates. `<tier>` is the catching round's model tier alias (e.g. `opus`, `fable`).
- **Tagging surfaces (append-only — never edit a posted checkpoint):** tags land in the next boundary's evidence — a verify-stage failure tags in the `ready-for-child-pr` checkpoint evidence; a child-PR-stage local-CI failure (when the conditional dispatches it) tags in the lane's `ready-to-merge-child` exit report.
- No new artifact, no script: the tag is grep-aggregatable from PM comments.
PATN
grep -cxFf "$PATN1" dodi-dev/skills/review/SKILL.md | grep -qx -- 5 && echo T1_A_OK; rm -f "$PATN1"
test "$(grep -n -- '^## ' dodi-dev/skills/review/SKILL.md | cut -d: -f2- | paste -sd'|' -)" = "## What to Check|## Process — post-implementation and pre-PR (full gate)|## Process — child-PR (integration pair)|## Epic Lane Rules|## Catch Attribution|## Don't Skip This" && echo T1_B_OK
grep -qF -- '- tag each: `caught-by: [GATE_TOKEN]/<round>/<tier>` — the dispatcher supplies [GATE_TOKEN] from the invoking context (`pre-pr` | `focused-re-review`; interactive post-implementation carries `pre-pr`-equivalent attribution or none) and appends round and tier when posting' dodi-dev/skills/review/review-prompt.md && echo T1_C_OK
grep -qF -- '- tag each: `caught-by: child-pr/<round>/<tier>` — round and tier appended by the dispatcher when posting' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_D_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/review/SKILL.md)" = "1" && echo T1_E_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/review/review-prompt.md)" = "1" && echo T1_F_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/review/child-pr-integration-prompt.md)" = "1" && echo T1_G_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/skills/review/SKILL.md | awk '{print $1"/"$2}')" = "8/0" && echo T1_H_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/skills/review/review-prompt.md | awk '{print $1"/"$2}')" = "1/0" && echo T1_I_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/skills/review/child-pr-integration-prompt.md | awk '{print $1"/"$2}')" = "1/0" && echo T1_J_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T1_K_OK
```

Expected: the eleven lines `T1_A_OK` … `T1_K_OK`, in order, every command exit 0. (`T1_A_OK` is the byte pin for the whole new section — 5 whole-line matches; `T1_B_OK` pins the heading sequence, proving the section sits between Epic Lane Rules and Don't Skip This; `T1_E_OK`–`T1_G_OK` prove exactly ONE caught-by line per file; `T1_H_OK`–`T1_J_OK` prove pure insertions — 8/1/1 lines added, zero deleted, so everything else is byte-identical.)

- [ ] **Step 5:** Commit

```bash
git add dodi-dev/skills/review/SKILL.md dodi-dev/skills/review/review-prompt.md dodi-dev/skills/review/child-pr-integration-prompt.md
git commit -m "feat: C5 — review skill Catch Attribution rule (enum, round grammar, append-only tagging surfaces, dispatcher duties); caught-by output lines in review-prompt ([GATE_TOKEN] dispatcher-supplied) and child-pr-integration-prompt (child-pr)"
```

### Task 2: the four sibling reviewer prompts — one tag line each

**Files:**
- Modify: `dodi-dev/skills/brainstorm/spec-reviewer-prompt.md` (Output Issues block, line ~31)
- Modify: `dodi-dev/skills/write-plan/plan-reviewer-prompt.md` (Output Issues block, line ~52)
- Modify: `dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md` (Output list, after the canon-summary item, line ~36)
- Modify: `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` (Output Issues block, after the mechanical/judgment line, line ~73)

- [ ] **Step 1:** `spec-reviewer-prompt.md` — hard-coded `spec-review`.

Old:

```markdown
    **Issues (if any):**
    - [Section X]: [specific issue] - [why it matters]
```

New:

```markdown
    **Issues (if any):**
    - [Section X]: [specific issue] - [why it matters]
    - tag each: `caught-by: spec-review/<round>/<tier>` — round and tier appended by the dispatcher when posting
```

- [ ] **Step 2:** `plan-reviewer-prompt.md` — hard-coded `plan-review`.

Old:

```markdown
    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] - [why it matters]
```

New:

```markdown
    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] - [why it matters]
    - tag each: `caught-by: plan-review/<round>/<tier>` — round and tier appended by the dispatcher when posting
```

- [ ] **Step 3:** `coherence-reviewer-prompt.md` — hard-coded `coherence`, appended as the last Output list item (this prompt's output is a bold-labeled bullet list, not a fenced Issues block; the tag format stays identical).

Old:

```markdown
- **Canon summary update:** the revised current-canon text (supersede chains collapsed, one line per decision), destined for the `## Decision Register — Canon` section of the epic description — the one register surface maintained in place (PM comments cannot be pinned; the description always renders at the top)
```

New:

```markdown
- **Canon summary update:** the revised current-canon text (supersede chains collapsed, one line per decision), destined for the `## Decision Register — Canon` section of the epic description — the one register surface maintained in place (PM comments cannot be pinned; the description always renders at the top)
- **Catch tag:** each reported finding carries `caught-by: coherence/<round>/<tier>` — round and tier appended by the dispatcher when posting (single-shot gate: round is `1` per attempt)
```

- [ ] **Step 4:** `epic-integration-reviewer-prompt.md` — hard-coded `epic-integration` ([S1]: born untagged at C4, receives its line here).

Old:

```markdown
    - **also classify each finding `mechanical` or `judgment` (required):** mechanical ≡ **no runtime-behavior effect** (docs, config samples, comments, formatting/hygiene); anything touching **runtime behavior** — flags, contracts, data shapes — is **judgment**; **when in doubt ⇒ judgment**
```

New:

```markdown
    - **also classify each finding `mechanical` or `judgment` (required):** mechanical ≡ **no runtime-behavior effect** (docs, config samples, comments, formatting/hygiene); anything touching **runtime behavior** — flags, contracts, data shapes — is **judgment**; **when in doubt ⇒ judgment**
    - tag each: `caught-by: epic-integration/<round>/<tier>` — round and tier appended by the dispatcher when posting (rounds count within this epic-PR attempt)
```

- [ ] **Step 5:** Verify

Run (from the repo root):

```bash
grep -qF -- '- tag each: `caught-by: spec-review/<round>/<tier>` — round and tier appended by the dispatcher when posting' dodi-dev/skills/brainstorm/spec-reviewer-prompt.md && echo T2_A_OK
grep -qF -- '- tag each: `caught-by: plan-review/<round>/<tier>` — round and tier appended by the dispatcher when posting' dodi-dev/skills/write-plan/plan-reviewer-prompt.md && echo T2_B_OK
grep -qF -- '- **Catch tag:** each reported finding carries `caught-by: coherence/<round>/<tier>` — round and tier appended by the dispatcher when posting (single-shot gate: round is `1` per attempt)' dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md && echo T2_C_OK
grep -qF -- '- tag each: `caught-by: epic-integration/<round>/<tier>` — round and tier appended by the dispatcher when posting (rounds count within this epic-PR attempt)' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T2_D_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/brainstorm/spec-reviewer-prompt.md)" = "1" && echo T2_E_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/write-plan/plan-reviewer-prompt.md)" = "1" && echo T2_F_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md)" = "1" && echo T2_G_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md)" = "1" && echo T2_H_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/skills/brainstorm/spec-reviewer-prompt.md | awk '{print $1"/"$2}')" = "1/0" && echo T2_I_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/skills/write-plan/plan-reviewer-prompt.md | awk '{print $1"/"$2}')" = "1/0" && echo T2_J_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md | awk '{print $1"/"$2}')" = "1/0" && echo T2_K_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md | awk '{print $1"/"$2}')" = "1/0" && echo T2_L_OK
grep -qF -- '**Round:** [N — rounds count within this epic-PR attempt]' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T2_M_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T2_N_OK
```

Expected: the fourteen lines `T2_A_OK` … `T2_N_OK`, in order, every command exit 0. (`T2_E_OK`–`T2_H_OK` prove exactly ONE caught-by line per prompt; `T2_I_OK`–`T2_L_OK` prove pure one-line insertions — everything else in each prompt, incl. the leaf-discipline lines, is byte-identical; `T2_M_OK` proves the tag line's round parenthetical matches the prompt's existing per-attempt Round input — same grammar, no drift.)

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills/brainstorm/spec-reviewer-prompt.md dodi-dev/skills/write-plan/plan-reviewer-prompt.md dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md
git commit -m "feat: C5 — caught-by output lines in spec-review, plan-review, coherence (single-shot: 1/attempt), and epic-integration (per-attempt loop) reviewer prompts"
```

### Task 3: AGENTS.md — Frontier row, two-fable-rounds doctrine at the line-35 adjacency, catch-tag one-liner

**Files:**
- Modify: `AGENTS.md` (exactly 2 hunks: the Frontier tier row, line ~27; the tier-diversity bullet, line ~35 — extended in place, with the catch-tag one-liner as a new bullet directly after it. Lines 28–30, the `needs-capable-delivery` bullet, and everything else stay byte-identical)

- [ ] **Step 1:** Extend the Frontier row (the child-PR integration final is `fable`, alongside the pre-PR final).

Old:

```markdown
| Frontier | `fable` | Spec drafting/review, plan writing/review, the final pre-PR review round |
```

New:

```markdown
| Frontier | `fable` | Spec drafting/review, plan writing/review, the final pre-PR review round, the child-PR integration final |
```

- [ ] **Step 2:** Fold the review-pipeline doctrine sentence INTO the existing tier-diversity bullet (extend, not duplicate — the spec-flagged line-35 adjacency), and add the catch-tag one-liner as its own bullet immediately after.

Old:

```markdown
- The review pipeline intentionally mixes tiers for reviewer diversity, not thrift: `opus` per-round and a fresh `fable` final gate have different failure modes, so the final round is a genuinely independent check rather than one more identical pass. When a task smells like judgment, escalate the tier — never economize on it.
```

New:

```markdown
- The review pipeline intentionally mixes tiers for reviewer diversity, not thrift: `opus` per-round and a fresh `fable` final gate have different failure modes, so the final round is a genuinely independent check rather than one more identical pass. The delivery lane runs two `fable` rounds per ticket with deliberately diverse aims — the pre-PR final judges the full gate, the child-PR integration final judges the integration delta — and seam-only material still sees both tiers (`opus` integration round + `fable` integration final). When a task smells like judgment, escalate the tier — never economize on it.
- Every posted review-evidence finding carries `caught-by: <gate>/<round>/<tier>` — grammar and tagging surfaces are pinned in the `review` skill (§ Catch Attribution); per-gate catch rates are grep-aggregatable from PM comments.
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
# Full-block pin for the three New lines (literal <<'PATN'; -x whole-line matches).
PATN3="$(mktemp)"; cat > "$PATN3" <<'PATN'
| Frontier | `fable` | Spec drafting/review, plan writing/review, the final pre-PR review round, the child-PR integration final |
- The review pipeline intentionally mixes tiers for reviewer diversity, not thrift: `opus` per-round and a fresh `fable` final gate have different failure modes, so the final round is a genuinely independent check rather than one more identical pass. The delivery lane runs two `fable` rounds per ticket with deliberately diverse aims — the pre-PR final judges the full gate, the child-PR integration final judges the integration delta — and seam-only material still sees both tiers (`opus` integration round + `fable` integration final). When a task smells like judgment, escalate the tier — never economize on it.
- Every posted review-evidence finding carries `caught-by: <gate>/<round>/<tier>` — grammar and tagging surfaces are pinned in the `review` skill (§ Catch Attribution); per-gate catch rates are grep-aggregatable from PM comments.
PATN
grep -cxFf "$PATN3" AGENTS.md | grep -qx -- 3 && echo T3_A_OK; rm -f "$PATN3"
test "$(grep -c -- 'caught-by' AGENTS.md)" = "1" && echo T3_B_OK
grep -qF -- '| Capable | `opus` | Per-round code review, PR review, integrated-head epic review, delivery (implementers + fix workers) on `needs-capable-delivery` tickets |' AGENTS.md && echo T3_C_OK
grep -qF -- '**Per-ticket delivery-tier routing (`needs-capable-delivery`):**' AGENTS.md && echo T3_D_OK
test "$(git diff --unified=0 3bfbf29 -- AGENTS.md | grep -c -- '^@@')" = "2" && echo T3_E_OK
test "$(git diff --numstat 3bfbf29 -- AGENTS.md | awk '{print $1"/"$2}')" = "3/2" && echo T3_F_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T3_G_OK
```

Expected: the seven lines `T3_A_OK` … `T3_G_OK`, in order, every command exit 0. (`T3_A_OK` is the byte pin for all three New lines; `T3_B_OK` proves exactly ONE caught-by line in AGENTS.md; `T3_C_OK`/`T3_D_OK` prove the Capable row (C4's) and the `needs-capable-delivery` bullet survive byte-exact — the doctrine extension neither duplicates nor contradicts them; `T3_E_OK`/`T3_F_OK` prove exactly two hunks, +3/−2 lines — nothing else in AGENTS.md moved.)

- [ ] **Step 4:** Commit

```bash
git add AGENTS.md
git commit -m "docs: C5 — AGENTS.md Frontier row adds the child-PR integration final; two-fable-rounds diverse-aims doctrine folded into the tier-diversity bullet; catch-tag one-liner"
```

### Task 4: 0.15.0 metadata bump (exactly three files, lockstep) — then the full battery

**Files:**
- Modify: `dodi-dev/.claude-plugin/plugin.json` (version line, line ~4)
- Modify: `dodi-dev/.codex-plugin/plugin.json` (version line, line ~3)
- Modify: `.claude-plugin/marketplace.json` (plugins[0] version line, line ~12)

(`.agents/plugins/marketplace.json` has NO version field — do not touch it.)

- [ ] **Step 1:** Bump `dodi-dev/.claude-plugin/plugin.json`.

Old:

```json
  "version": "0.14.2",
```

New:

```json
  "version": "0.15.0",
```

- [ ] **Step 2:** Bump `dodi-dev/.codex-plugin/plugin.json`.

Old:

```json
  "version": "0.14.2",
```

New:

```json
  "version": "0.15.0",
```

- [ ] **Step 3:** Bump `.claude-plugin/marketplace.json` (6-space indent — inside the `plugins` array entry).

Old:

```json
      "version": "0.14.2",
```

New:

```json
      "version": "0.15.0",
```

- [ ] **Step 4:** Verify — release lockstep

Run (from the repo root):

```bash
bash scripts/validate-plugin-metadata.sh
test "$(grep -c -- '"version": "0.15.0"' dodi-dev/.claude-plugin/plugin.json)" = "1" && echo T4_A_OK
test "$(grep -c -- '"version": "0.15.0"' dodi-dev/.codex-plugin/plugin.json)" = "1" && echo T4_B_OK
test "$(grep -c -- '"version": "0.15.0"' .claude-plugin/marketplace.json)" = "1" && echo T4_C_OK
! grep -qF -- '0.14.2' dodi-dev/.claude-plugin/plugin.json && echo T4_D_OK
! grep -qF -- '0.14.2' dodi-dev/.codex-plugin/plugin.json && echo T4_E_OK
! grep -qF -- '0.14.2' .claude-plugin/marketplace.json && echo T4_F_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/.claude-plugin/plugin.json | awk '{print $1"/"$2}')" = "1/1" && echo T4_G_OK
test "$(git diff --numstat 3bfbf29 -- dodi-dev/.codex-plugin/plugin.json | awk '{print $1"/"$2}')" = "1/1" && echo T4_H_OK
test "$(git diff --numstat 3bfbf29 -- .claude-plugin/marketplace.json | awk '{print $1"/"$2}')" = "1/1" && echo T4_I_OK
git diff --quiet 3bfbf29 -- .agents/plugins/marketplace.json && echo T4_J_OK
```

Expected, in order, every command exit 0: `plugin metadata ok: 0.15.0` (the bump task's battery expectation — the validator asserts the three files in lockstep), then `T4_A_OK` … `T4_J_OK`. (`T4_D_OK`–`T4_F_OK` prove the old version string is gone from each bumped file; `T4_J_OK` proves the codex marketplace file — no version field — is untouched.)

- [ ] **Step 5:** Verify — full Testing Contract battery (Unit group + Broader regression)

Run (from the repo root):

```bash
bash scripts/validate-plugin-metadata.sh
bash scripts/validate-phase-skills.sh > /dev/null && echo T4_K_OK
bash scripts/validate-ticket-comment-templates.sh
test "$(grep -rlF -- 'caught-by' AGENTS.md .claude-plugin .agents dodi-dev scripts templates | LC_ALL=C sort | paste -sd' ' -)" = "AGENTS.md dodi-dev/skills/brainstorm/spec-reviewer-prompt.md dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md dodi-dev/skills/review/SKILL.md dodi-dev/skills/review/child-pr-integration-prompt.md dodi-dev/skills/review/review-prompt.md dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md dodi-dev/skills/write-plan/plan-reviewer-prompt.md" && echo T4_L_OK
test "$(grep -c -- 'caught-by' AGENTS.md)" = "1" && echo T4_M_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/review/SKILL.md)" = "1" && echo T4_N_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/review/review-prompt.md)" = "1" && echo T4_O_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/review/child-pr-integration-prompt.md)" = "1" && echo T4_P_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/brainstorm/spec-reviewer-prompt.md)" = "1" && echo T4_Q_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/write-plan/plan-reviewer-prompt.md)" = "1" && echo T4_R_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md)" = "1" && echo T4_S_OK
test "$(grep -c -- 'caught-by' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md)" = "1" && echo T4_T_OK
grep -qF -- 'caught-by: [GATE_TOKEN]/<round>/<tier>' dodi-dev/skills/review/review-prompt.md && echo T4_U_OK
grep -qF -- 'caught-by: child-pr/<round>/<tier>' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T4_V_OK
grep -qF -- 'caught-by: spec-review/<round>/<tier>' dodi-dev/skills/brainstorm/spec-reviewer-prompt.md && echo T4_W_OK
grep -qF -- 'caught-by: plan-review/<round>/<tier>' dodi-dev/skills/write-plan/plan-reviewer-prompt.md && echo T4_X_OK
grep -qF -- 'caught-by: coherence/<round>/<tier>' dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md && echo T4_Y_OK
grep -qF -- 'caught-by: epic-integration/<round>/<tier>' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T4_Z_OK
grep -qF -- 'caught-by: <gate>/<round>/<tier>' dodi-dev/skills/review/SKILL.md && echo T4_AA_OK
grep -qF -- 'caught-by: <gate>/<round>/<tier>' AGENTS.md && echo T4_AB_OK
test "$(git diff --name-only 3bfbf29 -- . ':(exclude)docs' | LC_ALL=C sort | paste -sd' ' -)" = ".claude-plugin/marketplace.json AGENTS.md dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json dodi-dev/skills/brainstorm/spec-reviewer-prompt.md dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md dodi-dev/skills/review/SKILL.md dodi-dev/skills/review/child-pr-integration-prompt.md dodi-dev/skills/review/review-prompt.md dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md dodi-dev/skills/write-plan/plan-reviewer-prompt.md" && echo T4_AC_OK
test "$(git diff --unified=0 3bfbf29 -- AGENTS.md | grep -c -- '^@@')" = "2" && echo T4_AD_OK
test "$(git diff --unified=0 3bfbf29 -- dodi-dev/skills/review/SKILL.md | grep -c -- '^@@')" = "1" && echo T4_AE_OK
```

Expected, in order, every command exit 0:

```
plugin metadata ok: 0.15.0
T4_K_OK
ticket comment templates ok
T4_L_OK
T4_M_OK
T4_N_OK
T4_O_OK
T4_P_OK
T4_Q_OK
T4_R_OK
T4_S_OK
T4_T_OK
T4_U_OK
T4_V_OK
T4_W_OK
T4_X_OK
T4_Y_OK
T4_Z_OK
T4_AA_OK
T4_AB_OK
T4_AC_OK
T4_AD_OK
T4_AE_OK
```

(`T4_L_OK` is the rider's end-state assertion: exactly the 8 ship-surface files carry the tag — which positively proves the runner prompts (`verify/test-runner-prompt.md`, `submit-ticket-pr/local-ci-runner-prompt.md`) and every other prompt/skill/template/script carry NONE; `T4_M_OK`–`T4_T_OK` pin exactly one line per file; `T4_U_OK`–`T4_AB_OK` pin the right gate token in each emitter; `T4_AC_OK` asserts the complete changed-file set vs `3bfbf29` is exactly C5's eleven files, docs/ excluded — the plan file lands there; `T4_AD_OK`/`T4_AE_OK` re-assert hunk precision on the two multi-hunk-risk files. The load-bearing assertion is exit 0.)

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "release: dodi-dev 0.15.0 — review-pipeline consolidation metadata bump (three files, lockstep) — C5 complete, epic release-ready"
```

---

## Notes for the executor

- **Verify-command hygiene:** every command exits 0 on success; every grep pattern argument is preceded by `--`. The only negations are the three `! grep -qF -- '0.14.2' <file>` checks in Task 4 Step 4, each scoped to a single bumped file — the string `0.14.2` appears in NO New text in this plan (all New version text is `0.15.0`), so no negation collision is possible. `caught-by` is never used as a negation pattern: absence-elsewhere is asserted positively by the `T4_L_OK` file-set equality. Sorted list comparisons pin `LC_ALL=C sort` (`.claude-plugin` must sort before `AGENTS.md`; `review/SKILL.md` before `review/child-pr-…`).
- **Heredoc pins:** both multi-line New blocks (the § Catch Attribution section, the AGENTS.md three-line block) are pinned byte-exact via literal `<<'PATN'` pattern files with `grep -cxFf` (whole-line `-x` matches — no substring credit; no pattern line is empty; each pattern line matches exactly one file line). Apostrophes and backticks inside those blocks never enter shell quoting. Single-line New additions are pinned with single-quoted `grep -qF --` (they contain backticks but no apostrophes — verified per line).
- **One-line-per-prompt invariant:** each of the six emitters gains exactly ONE line containing `caught-by` (counts pinned per file), placed in the prompt's existing Output section; the tag core `caught-by: <token>/<round>/<tier>` plus "round and tier appended by the dispatcher when posting" is the consistent format, with the line adapted to each prompt's output idiom (fenced `- tag each:` lines; the coherence prompt's bold-labeled list item).
- **AGENTS.md:35 adjacency (spec plan-phase pin):** handled by EXTENDING the existing tier-diversity bullet — the new sentence adds the two-fable-rounds diverse-aims claim (pre-PR final = full gate; child-PR integration final = integration delta; seam-only material sees `opus` + `fable`, mirroring the spec's invariants line) without restating the bullet's existing opus-vs-fable failure-mode claim — and placing the catch-tag one-liner as its own bullet directly after. `T3_C_OK`/`T3_D_OK` prove the neighboring Capable row and `needs-capable-delivery` bullet are untouched.
- **Disclosed micro-pins (format clarifications, not behavior):** (1) `<tier>` is pinned as the catching round's model tier alias — matching this epic's own field usage (`pre-pr/2/fable` in [C2-d], `spec-review/1/fable`–`/2/fable` on issue #7); the spec leaves the tier vocabulary implicit. (2) The coherence and epic-integration tag lines carry a short round parenthetical (`1` per attempt; rounds count within this epic-PR attempt) restating the pinned grammar at the point of use — `T2_M_OK` proves the epic-integration wording matches the prompt's existing Round input verbatim.
- **Runners stay pure:** no tag line enters `verify/test-runner-prompt.md` or `submit-ticket-pr/local-ci-runner-prompt.md` — the dispatcher tags verify/local-CI failures at the NEXT boundary's evidence per § Catch Attribution. No state-transitions, template, or validator edits exist in C5: the tag rides inside evidence bodies, changing no durable-state shape.
- **Ordering:** the doctrine home lands first (Task 1) so the sibling prompt lines (Task 2) and the AGENTS.md pointer to § Catch Attribution (Task 3) reference an existing section; the metadata bump is deliberately LAST (Task 4) — at the Task 1–3 boundaries the metadata validator (if run) still prints `plugin metadata ok: 0.14.2`; after Task 4 it asserts 0.15.0. Phase-skills and templates validators are unaffected by every C5 edit and stay green at all boundaries.
- **[C3-c]/[G1] context:** this lane itself runs under installed 0.14.2 — the walked pipeline does not emit tags yet; these edits are branch-text law from this child forward and go live at the release (per the release process: merge, then a fresh session applies `plugin update` — never `install`). DOD-650 is the first measured caught-by sample. **This child closes the epic:** after its merge the epic branch is release-ready.
- If any Old anchor fails to match byte-exactly, stop and re-read the target file — never adapt the edit; report the mismatch.
