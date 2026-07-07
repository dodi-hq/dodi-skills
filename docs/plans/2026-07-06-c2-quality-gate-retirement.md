# C2: Quality-Gate Retirement + Verify Absorption (Change 2 child-level) — Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute tasks in order (1→8). Each task ends with its own Verify (all commands must exit 0) and its own local commit; every task leaves the three repo validators green — the quality-gate skill directory and its validator skills-array entry are removed **together in Task 8**, so the phase-skills validator never sees one without the other. All Old-text anchors below are byte-exact from the epic branch @ `f7449db` (C1 merged); **anchor by the quoted text, never by step or line number** (C1 renumbered nothing here, but siblings renumber later). If an Old anchor does not match exactly, STOP and re-read the file — never fuzzy-match or approximate.

**Goal:** Retire `quality-gate` as a skill and as a child-lane phase — every child-level check re-homed by scope — with `verify` absorbing the local-CI runner dispatch (discovery mandate intact, `groups-covered-elsewhere` scope note) and all runner digests recording the head SHA they ran against (spec § Change 2 child-level + § Change 3 SHA-recording prerequisites; scope = GitHub issue #8 as amended, incl. the lane-dispatch-prompt clause).

**Architecture:** The lane's horizontal-gate phase disappears: `verify` becomes the last pre-seam stage (per-group Contract runners + the local-CI runner, repo-local gates + broader checks), the mandatory reset seam renames quality-gate→PR to **verify→PR**, and the checkpoint enum drops `quality-gating` everywhere it appears (deliver-ticket, state-transitions, the lane-checkpoint template, the dead lane-dispatch prompt). The `ready-for-child-pr` checkpoint becomes the durable home of each runner digest's recorded head SHA (the local-CI runner's named explicitly) — the input surface C3's conditional-CI predicate will read from the far side of the reset. The interactive track (`submit`) replaces its `/quality-gate` pre-flight with review-evidence + create-tests-if-missing + verify. Epic-level quality-gate surfaces (`submit-epic-pr`, the epic-pr-ready template + its validator heading assertion, state-transitions epic row) are **C4's** and survive this child untouched.

**Tech Stack:** Markdown skills/prompts/templates (harness-neutral per AGENTS.md Editing Rules), Bash validator scripts. The three repo validators are the regression suite.

**Source of truth:** `docs/specs/2026-07-06-review-pipeline-consolidation-design.md` § Change 2 (child-level) + § Change 3 SHA-recording bullets + the C2 reference-sweep rows; GitHub issue #8 body (amended: + `epic-orchestrator/lane-dispatch-prompt.md` enum/seam, banner intact); epic canon (#3 § Decision Register — Canon): [C1-a] re-home before retire, [C1-d] C3 anchors quoted-text in `review/SKILL.md`, preserved byte-exact.

**Boundary discipline — do NOT touch (sibling-owned):**

- `dodi-dev/skills/review/SKILL.md` and both review prompts — entirely. C3's anchors live there ("the local CI runner (" and "local CI runs in parallel", canon [C1-d]); Task 8's battery asserts both survive byte-exact.
- The child-PR local-CI dispatch stays **unconditional** everywhere C2 touches — the deliver-ticket child-PR review step is renumbered with its text otherwise byte-identical. The conditional predicate is C3's.
- `submit-ticket-pr/SKILL.md` § Merge (incl. line 34 "verified by an evidence checker") — C3/C4 consumers. Only lines 9/17/24 change here.
- `epic-orchestrator/state-transitions.md`: the Child-Ticket `ready-to-merge-child` row, the lane-exit `(exit) ready-to-merge-child` row, and the epic-table `epic-ready-for-pr` row ("epic quality gate evidence") — C3's/C4's. Only the Lane Checkpoint Contract's `quality-gating` + `ready-for-child-pr` rows and a new resume-mapping paragraph change here.
- `submit-epic-pr/` (all three quality-gate mentions), `templates/ticket-comments/epic-pr-ready.md`, and `scripts/validate-ticket-comment-templates.sh:100` (the "Quality Gate Evidence" heading assertion) — C4's epic-level re-home.
- `caught-by` lines anywhere — C5's.
- Plugin metadata (three files) — no version bump in C2; the 0.15.0 bump lands with the epic's release close-out.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `functions/components/modules` — the fifteen touched files (fourteen content files plus the edited validator) + one deleted directory, exercised by the three repo validators (skill/prompt file existence, skills-array integrity, repo-only-reference hygiene, template integrity) plus `bash -n` on the edited validator.
  - Reason: `<why>` — this is a docs/prose/validator repository; the validators are the executable unit surface and they assert exactly the invariants C2 can break (deleting a skill still named in the skills array, template heading damage, script syntax).
  - Minimum assertions: `<specific behaviors>` — all three validators exit 0 after every task (Tasks 1–7 with `quality-gate` still present in both the tree and the array; Task 8 with both removed); `bash -n scripts/validate-phase-skills.sh` exits 0 after Task 8.

- Integration: `not-required`
  - Scope: `module boundaries/APIs/db/jobs/etc` — n/a.
  - Reason: `<why>` — no executable pipeline exists in this repository; the validators ARE the integration surface (cross-file existence and reference checks across skills, prompts, scripts, and templates). Same rationale as C1.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a; see the Broader-regression grep battery (Task 8 Step 3) for cross-file text assertions.

- E2E: `not-required`
  - Scope: `user/business-critical flows` — n/a.
  - Reason: `<why>` — live pipeline behavior is exercised by the epic's own delivery: this ticket's lane is itself the first walk of the retired-phase sequence. Same rationale as C1.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a.

### Critical Flows

- `Lane sequence reads coherently end to end in deliver-ticket: pickup → implement → review (pre-PR) → create-tests → verify (per-group runners + local-CI runner, digests record head SHAs, focused re-review on product fixes) → reset seam (verify→PR) → submit-ticket-pr Open → review (child-PR pair ∥ local CI) → ready-to-merge-child`
- `Checkpoint enum is identical across its four surfaces (deliver-ticket, state-transitions table, lane-checkpoint template, lane-dispatch prompt): implementing | implementation-reviewing | testing | verifying | ready-for-child-pr | child-pr-reviewing`
- `ready-for-child-pr row carries the verification-green trigger and the recorded-head-SHA evidence descriptor (the durable input C3's predicate reads)`
- `Resume mapping: a posted quality-gating checkpoint reads as verifying complete; pre-0.15.0 lanes past verifying run the local-CI runner before posting ready-for-child-pr or note its absence`

### Regression Surface

- `C3's anchors in review/SKILL.md ("the local CI runner (" dispatch clause and the "local CI runs in parallel" table cell) — byte-exact, file untouched`
- `C4's epic-level quality-gate surfaces: submit-epic-pr (3 mentions), state-transitions epic-ready-for-pr row, epic-pr-ready.md heading, validate-ticket-comment-templates.sh:100 assertion`
- `submit-ticket-pr § Merge step 1 "verified by an evidence checker" (C3/C4 consumer) and the (exit)/ready-to-merge-child rows in state-transitions`
- `lane-dispatch-prompt.md do-not-dispatch banner (line 3) — intact`
- `verify's epic full-regression rule (last Epic Orchestration bullet) — unchanged`

### Commands

- Unit: `bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh && bash scripts/validate-ticket-comment-templates.sh` (run from the repo root; each task's Verify runs the relevant subset, Task 8 runs all three)
- Integration: `not-applicable — no executable pipeline; the validators are the integration surface`
- E2E: `not-applicable — exercised live by this epic's own delivery`
- Broader regression: `bash -n scripts/validate-phase-skills.sh` plus the grep battery in Task 8 Step 3 — the operative tree (`AGENTS.md`, `.claude-plugin`, `.agents`, `dodi-dev`, `scripts`, `templates`; `docs/` excluded by design) contains the string `quality`-`gat` (case-insensitive) in **exactly four files, seven lines**, all enumerated below; every command exits 0 on success.

### Harness Requirements

- `bash, python3, grep, git — repo checkout only; no network, no PM access, no env vars`

### Non-Required Rationale

- Unit: n/a (required).
- Integration: `no executable pipeline exists; the three validators are the only cross-file integration surface and run as the Unit group`
- E2E: `the epic's own delivery is the live exercise of the retired phase and the new seam; a desk e2e of prose skills does not exist`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

**Expected grep-battery survivor set (determined by grepping the C1-merged tree, asserted precisely in Task 8):**

| File | Lines with `quality`-`gat` | Owner |
| --- | --- | --- |
| `dodi-dev/skills/submit-epic-pr/SKILL.md` | 3 — "Run epic-level `quality-gate`." / "epic quality-gate evidence" / "Stop if epic-level `quality-gate` fails." | C4 |
| `dodi-dev/skills/epic-orchestrator/state-transitions.md` | 2 — the epic row's "epic quality gate evidence" (C4) + **C2's own new resume-mapping line naming the legacy `quality-gating` token** (intentional: the mapping must name the literal boundary value old checkpoints carry) | C4 / C2 |
| `scripts/validate-ticket-comment-templates.sh` | 1 — the "Quality Gate Evidence" heading assertion | C4 |
| `templates/ticket-comments/epic-pr-ready.md` | 1 — "## Quality Gate Evidence" | C4 |

---

## Tasks

### Task 1: `verify` absorbs the local-CI runner + digest head-SHA rules

**Files:**
- Modify: `dodi-dev/skills/verify/SKILL.md` (§ Runner Delegation gains two paragraphs; frontmatter, The Gate, and the Epic Orchestration rules — incl. the epic full-regression bullet — stay byte-identical)
- Modify: `dodi-dev/skills/verify/test-runner-prompt.md` (one line added inside the existing Output-digest field list)
- Modify: `dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md` (one input added; head SHA added inside the existing return-digest sentence; role, responsibilities, and leaf block otherwise byte-identical)

- [ ] **Step 1:** Append the local-CI dispatch mandate and the digest head-SHA rule to `dodi-dev/skills/verify/SKILL.md` § Runner Delegation (two new paragraphs after the existing one).

Old:

```markdown
Dispatch test execution to test-runner workers (see test-runner-prompt.md), one per test group, instead of running suites in the main loop — suite output floods context and blocks everything else. The gate is preserved: each runner returns a digest with commands, exit codes, failing test names, and a log path, and you claim results only from that evidence. A runner's "passed" without commands + exit codes is a worker success claim — reject it. Quick read-only checks (`git diff`, single-file inspection) stay in the main loop.
```

New:

```markdown
Dispatch test execution to test-runner workers (see test-runner-prompt.md), one per test group, instead of running suites in the main loop — suite output floods context and blocks everything else. The gate is preserved: each runner returns a digest with commands, exit codes, failing test names, and a log path, and you claim results only from that evidence. A runner's "passed" without commands + exit codes is a worker success claim — reject it. Quick read-only checks (`git diff`, single-file inspection) stay in the main loop.

**Local-CI runner — required stage element:** alongside the per-group runners, dispatch the **local-CI runner** (`submit-ticket-pr/local-ci-runner-prompt.md`): repo-local gates (lint, typecheck, validation scripts named in the repo instructions) plus broader cross-area regression checks, with its discover-and-run mandate intact — where the Testing Contract's Broader-regression line is `to-be-discovered` or narrow, the runner's discovery obligation governs. Pass it a `groups-covered-elsewhere` scope note naming the test groups the per-group runners already cover, so the same suites are not run twice in one stage.

**Digest head-SHA rule:** every runner digest — per-group and local-CI alike — records the head SHA its commands ran against, so downstream gates can tie each green result to the exact tree state that produced it. A digest without its head SHA is incomplete evidence — reject it the same way as a missing exit code.
```

- [ ] **Step 2:** Add the head-SHA field inside the Output-digest list of `dodi-dev/skills/verify/test-runner-prompt.md` (directly after the Commands field; the "digest only / never paste logs" closing text is untouched).

Old:

```markdown
- **Commands:** each command with its exit code
```

New:

```markdown
- **Commands:** each command with its exit code
- **Head SHA:** the worktree commit the commands ran against (`git rev-parse HEAD`)
```

- [ ] **Step 3:** Add the optional scope input to `dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md` (last item of the Inputs list).

Old:

```markdown
- repo instructions from AGENTS.md or CLAUDE.md
```

New:

```markdown
- repo instructions from AGENTS.md or CLAUDE.md
- optional `groups-covered-elsewhere`: test groups sibling per-group runners already cover in this verify stage — do not re-run those groups; run everything else your discovery finds (verify-stage dispatches pass this; child-PR dispatches omit it and run un-scoped)
```

- [ ] **Step 4:** Add the head SHA inside the same file's return-digest sentence (the "never paste" sentence is untouched).

Old:

```markdown
Return a digest only: commands, exit codes, failing test names, and log file paths. Never paste raw logs or full test output into your report.
```

New:

```markdown
Return a digest only: commands, exit codes, failing test names, the head SHA the checks ran against (`git rev-parse HEAD` in the worktree), and log file paths. Never paste raw logs or full test output into your report.
```

- [ ] **Step 5:** Verify

Run (from the repo root):

```bash
grep -qF 'dispatch the **local-CI runner** (`submit-ticket-pr/local-ci-runner-prompt.md`)' dodi-dev/skills/verify/SKILL.md && echo T1_A_OK
grep -qF '`groups-covered-elsewhere`' dodi-dev/skills/verify/SKILL.md && echo T1_B_OK
grep -qF '**Digest head-SHA rule:**' dodi-dev/skills/verify/SKILL.md && echo T1_C_OK
grep -qF 'discover-and-run mandate intact' dodi-dev/skills/verify/SKILL.md && echo T1_D_OK
grep -qF 'For an epic full regression run before the epic PR' dodi-dev/skills/verify/SKILL.md && echo T1_E_OK
grep -qF -- '- **Head SHA:** the worktree commit the commands ran against (`git rev-parse HEAD`)' dodi-dev/skills/verify/test-runner-prompt.md && echo T1_F_OK
grep -qF 'Never paste raw logs or full test output' dodi-dev/skills/verify/test-runner-prompt.md && echo T1_G_OK
grep -qF -- '- optional `groups-covered-elsewhere`' dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md && echo T1_H_OK
grep -qF 'the head SHA the checks ran against (`git rev-parse HEAD` in the worktree)' dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md && echo T1_I_OK
grep -qF 'Never paste raw logs or full test output into your report.' dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md && echo T1_J_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T1_K_OK
```

Expected: the eleven lines `T1_A_OK` … `T1_K_OK`, in order, every command exit 0. (`T1_E_OK` proves the epic full-regression rule is unchanged; `T1_G_OK`/`T1_J_OK` prove both runner prompts keep the digest-only discipline.)

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills/verify/SKILL.md dodi-dev/skills/verify/test-runner-prompt.md dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
git commit -m "feat: verify absorbs the local-CI runner (discovery mandate, groups-covered-elsewhere scope); all runner digests record head SHA"
```

### Task 2: `deliver-ticket` — drop the quality-gate phase, renumber, verify→PR seam

**Files:**
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md` (Internal Sequence steps 5–10 → 5–9; checkpoint enum; Context Hygiene seam bullet. The Contract table, tier parenthetical (C1's), Exit States, Resume, Execution Model, and Rules stay byte-identical)

- [ ] **Step 1:** Replace Internal Sequence steps 5–10 with the five-step tail: verify expands (local-CI runner + head SHAs + focused re-review pointer), quality-gate drops, the seam is named verify→PR, and the child-PR review step keeps its text byte-identical apart from the number (its unconditional parallel local-CI wording is C3 material).

Old:

```markdown
5. `verify` — one test-runner worker per group; claim results only from digests.
6. `quality-gate` — horizontal checks with command evidence.
7. **Context reset seam** — see Context Hygiene below.
8. `submit-ticket-pr` (Open only) — push the child branch, open the PR against the epic branch, write the PR body.
9. `review` (child-PR context) — the delta-scoped integration pair (one `opus` integration round + a `fable` integration final per `review/child-pr-integration-prompt.md`) and the local CI runner in parallel.
10. Report `ready-to-merge-child` with the evidence trail. Do not merge.
```

New:

```markdown
5. `verify` — one test-runner worker per group plus the local-CI runner dispatch (repo-local gates + broader checks, discovery mandate intact); claim results only from digests; every runner digest records the head SHA it ran against; a product-code fix here triggers the focused re-review (`review` § Epic Lane Rules) before the seam.
6. **Context reset seam (verify→PR)** — see Context Hygiene below.
7. `submit-ticket-pr` (Open only) — push the child branch, open the PR against the epic branch, write the PR body.
8. `review` (child-PR context) — the delta-scoped integration pair (one `opus` integration round + a `fable` integration final per `review/child-pr-integration-prompt.md`) and the local CI runner in parallel.
9. Report `ready-to-merge-child` with the evidence trail. Do not merge.
```

- [ ] **Step 2:** Drop `quality-gating` from the checkpoint enum (Checkpoints section).

Old:

```markdown
`verifying`, `quality-gating`, `ready-for-child-pr`
```

New:

```markdown
`verifying`, `ready-for-child-pr`
```

- [ ] **Step 3:** Rename the seam in the Context Hygiene bullet and restate its trigger as verification green.

Old:

```markdown
- **Mandatory reset at the quality-gate→PR seam:** after `quality-gate` passes, write the continuation brief and exit `RESUMABLE`. The orchestrator re-dispatches a fresh lane that opens the PR and runs child-PR review. This is the lane's biggest natural boundary; a fresh context reviews the PR without implementation bias.
```

New:

```markdown
- **Mandatory reset at the verify→PR seam:** after `verify` is green (Contract groups + the local-CI runner scope; focused re-review clean if fixes occurred), write the continuation brief and exit `RESUMABLE`. The orchestrator re-dispatches a fresh lane that opens the PR and runs child-PR review. This is the lane's biggest natural boundary; a fresh context reviews the PR without implementation bias.
```

- [ ] **Step 4:** Verify

Run (from the repo root):

```bash
grep -qF '5. `verify` — one test-runner worker per group plus the local-CI runner dispatch' dodi-dev/skills/deliver-ticket/SKILL.md && echo T2_A_OK
grep -qF '6. **Context reset seam (verify→PR)** — see Context Hygiene below.' dodi-dev/skills/deliver-ticket/SKILL.md && echo T2_B_OK
grep -qF '9. Report `ready-to-merge-child` with the evidence trail. Do not merge.' dodi-dev/skills/deliver-ticket/SKILL.md && echo T2_C_OK
grep -qF '`verifying`, `ready-for-child-pr`, `child-pr-reviewing`' dodi-dev/skills/deliver-ticket/SKILL.md && echo T2_D_OK
grep -qF '**Mandatory reset at the verify→PR seam:** after `verify` is green' dodi-dev/skills/deliver-ticket/SKILL.md && echo T2_E_OK
grep -qF 'and the local CI runner in parallel.' dodi-dev/skills/deliver-ticket/SKILL.md && echo T2_F_OK
! grep -qi 'quality.gat' dodi-dev/skills/deliver-ticket/SKILL.md && echo T2_G_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T2_H_OK
```

Expected: the eight lines `T2_A_OK` … `T2_H_OK`, in order, every command exit 0. (`T2_F_OK` proves the child-PR step's unconditional parallel local-CI wording survived the renumber for C3.)

- [ ] **Step 5:** Commit

```bash
git add dodi-dev/skills/deliver-ticket/SKILL.md
git commit -m "feat: deliver-ticket drops the quality-gate phase — verify expands, seam renamed verify→PR, checkpoint enum shrinks"
```

### Task 3: `state-transitions.md` — Lane Checkpoint Contract row retirement + resume mapping

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/state-transitions.md` (Lane Checkpoint Contract only: the `quality-gating` + `ready-for-child-pr` rows collapse to one, and a resume-mapping paragraph is appended after the failure-routing paragraph. The Child-Ticket `ready-to-merge-child` row, the `(exit) ready-to-merge-child` lane-exit row, and the epic-table `epic-ready-for-pr` row stay byte-identical — C3's/C4's)

- [ ] **Step 1:** Replace the two adjacent rows with the single `ready-for-child-pr` row carrying the verification-green trigger and the recorded-head-SHA evidence descriptor.

Old:

```markdown
| quality-gating | verification green | commands, exit codes, per-group digests |
| ready-for-child-pr | quality gate passed — mandatory lane context reset here | gate evidence; continuation brief |
```

New:

```markdown
| ready-for-child-pr | verification green (Contract groups + local-CI runner scope; focused re-review clean if fixes occurred) — mandatory lane context reset here | verification evidence, including each runner digest's recorded head SHA with the local-CI runner's named explicitly; continuation brief |
```

- [ ] **Step 2:** Append the resume-mapping paragraph after the failure-routing paragraph.

Old:

```markdown
Failure routing inside the lane mirrors the previous per-skill rules: implementation bug → back to implementing; test bug or harness work → back to testing; judgment surprise at any checkpoint → demote-to-spec and exit.
```

New:

```markdown
Failure routing inside the lane mirrors the previous per-skill rules: implementation bug → back to implementing; test bug or harness work → back to testing; judgment surprise at any checkpoint → demote-to-spec and exit.

**Resume mapping (pre-0.15.0 checkpoints):** a previously posted `quality-gating` checkpoint reads as `verifying` complete; the next boundary is `ready-for-child-pr`. A pre-0.15.0 lane resuming past `verifying` never ran the verify-stage local-CI runner: run it before posting `ready-for-child-pr`, or post that boundary noting the runner's absence.
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
grep -qF '| ready-for-child-pr | verification green (Contract groups + local-CI runner scope; focused re-review clean if fixes occurred) — mandatory lane context reset here |' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T3_A_OK
grep -qF "verification evidence, including each runner digest's recorded head SHA with the local-CI runner's named explicitly; continuation brief |" dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T3_B_OK
! grep -q '| quality-gating |' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T3_C_OK
grep -qF 'a previously posted `quality-gating` checkpoint reads as `verifying` complete; the next boundary is `ready-for-child-pr`' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T3_D_OK
grep -qF '| (exit) ready-to-merge-child | child-PR review + local CI clean | reviewer status, CI digests |' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T3_E_OK
grep -qF '| ready-to-merge-child | orchestrator takes the serial merge slot | evidence-checker citations; child branch current with epic head |' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T3_F_OK
grep -qF 'epic quality gate evidence' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T3_G_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/epic-orchestrator/state-transitions.md)" = "2" && echo T3_H_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T3_I_OK
```

Expected: the nine lines `T3_A_OK` … `T3_I_OK`, in order, every command exit 0. (`T3_E_OK`/`T3_F_OK`/`T3_G_OK` prove the C3/C4-owned rows survive byte-exact; `T3_H_OK` pins this file's two intentional survivors: the resume-mapping token + the epic row.)

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/epic-orchestrator/state-transitions.md
git commit -m "feat: lane checkpoint contract — quality-gating row retired into ready-for-child-pr (verification green + recorded head SHAs); resume mapping added"
```

### Task 4: Ticket-comment templates — boundary enum + evidence descriptors

**Files:**
- Modify: `templates/ticket-comments/lane-checkpoint.md` (boundary enum + evidence placeholder; validator-asserted headings and `Run id:` untouched)
- Modify: `templates/ticket-comments/child-pr-ready.md` (one evidence line; validator-asserted headings untouched)

- [ ] **Step 1:** Drop `quality-gating` from the lane-checkpoint boundary enum.

Old:

```markdown
Ticket: `<child-ticket-id>` · Boundary: `<implementing | implementation-reviewing | testing | verifying | quality-gating | ready-for-child-pr | child-pr-reviewing>`
```

New:

```markdown
Ticket: `<child-ticket-id>` · Boundary: `<implementing | implementation-reviewing | testing | verifying | ready-for-child-pr | child-pr-reviewing>`
```

- [ ] **Step 2:** Rename the evidence descriptor. (Note: `ready-for-child-pr` appears without backticks here because the whole placeholder is already one code span — inner backticks would terminate it.)

Old:

```markdown
- `<branch / worktree / plan link / commit ids / review evidence / test files / harness evidence / gate evidence — per the boundary's row in state-transitions.md>`
```

New:

```markdown
- `<branch / worktree / plan link / commit ids / review evidence / test files / harness evidence / verification evidence (incl. recorded runner head SHAs at the ready-for-child-pr boundary) — per the boundary's row in state-transitions.md>`
```

- [ ] **Step 3:** Rename the child-pr-ready evidence line.

Old:

```markdown
- Quality gate: `<pass evidence>`
```

New:

```markdown
- Repo-local + broader checks: `<pass evidence>`
```

- [ ] **Step 4:** Verify

Run (from the repo root):

```bash
grep -qF '<implementing | implementation-reviewing | testing | verifying | ready-for-child-pr | child-pr-reviewing>' templates/ticket-comments/lane-checkpoint.md && echo T4_A_OK
grep -qF 'verification evidence (incl. recorded runner head SHAs at the ready-for-child-pr boundary)' templates/ticket-comments/lane-checkpoint.md && echo T4_B_OK
grep -qF -- '- Repo-local + broader checks: `<pass evidence>`' templates/ticket-comments/child-pr-ready.md && echo T4_C_OK
! grep -qi 'quality.gat' templates/ticket-comments/lane-checkpoint.md templates/ticket-comments/child-pr-ready.md && echo T4_D_OK
bash scripts/validate-ticket-comment-templates.sh > /dev/null && echo T4_E_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T4_F_OK
```

Expected: the six lines `T4_A_OK` … `T4_F_OK`, in order, every command exit 0.

- [ ] **Step 5:** Commit

```bash
git add templates/ticket-comments/lane-checkpoint.md templates/ticket-comments/child-pr-ready.md
git commit -m "feat: lane-checkpoint + child-pr-ready templates — quality-gating boundary and gate-evidence wording retired"
```

### Task 5: Phase-skill stop conditions — three distinct anchors

**Files:**
- Modify: `dodi-dev/skills/pickup-ticket/SKILL.md` (one Stop Conditions line)
- Modify: `dodi-dev/skills/implement-ticket/SKILL.md` (one Stop Conditions line)
- Modify: `dodi-dev/skills/create-tests/SKILL.md` (one Stop Conditions line)

- [ ] **Step 1:** Reword the pickup-ticket stop condition.

Old:

```markdown
- Stop at `ready-for-child-pr` only after local implementation, review, tests, verify, and quality-gate complete.
```

New:

```markdown
- Stop at `ready-for-child-pr` only after local implementation, review, tests, and verification (incl. repo-local checks) complete.
```

- [ ] **Step 2:** Reword the implement-ticket stop condition.

Old:

```markdown
- Stop at `ready-for-child-pr` only after review, tests, verification, and quality gate are clean.
```

New:

```markdown
- Stop at `ready-for-child-pr` only after review, tests, and verification (incl. repo-local checks) are clean.
```

- [ ] **Step 3:** Reword the create-tests stop condition.

Old:

```markdown
- Stop at `ready-for-child-pr` only after verification and quality gate are clean.
```

New:

```markdown
- Stop at `ready-for-child-pr` only after verification (incl. repo-local checks) is clean.
```

- [ ] **Step 4:** Verify

Run (from the repo root):

```bash
grep -qF -- '- Stop at `ready-for-child-pr` only after local implementation, review, tests, and verification (incl. repo-local checks) complete.' dodi-dev/skills/pickup-ticket/SKILL.md && echo T5_A_OK
grep -qF -- '- Stop at `ready-for-child-pr` only after review, tests, and verification (incl. repo-local checks) are clean.' dodi-dev/skills/implement-ticket/SKILL.md && echo T5_B_OK
grep -qF -- '- Stop at `ready-for-child-pr` only after verification (incl. repo-local checks) is clean.' dodi-dev/skills/create-tests/SKILL.md && echo T5_C_OK
! grep -qi 'quality.gat' dodi-dev/skills/pickup-ticket/SKILL.md dodi-dev/skills/implement-ticket/SKILL.md dodi-dev/skills/create-tests/SKILL.md && echo T5_D_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T5_E_OK
```

Expected: the five lines `T5_A_OK` … `T5_E_OK`, in order, every command exit 0.

- [ ] **Step 5:** Commit

```bash
git add dodi-dev/skills/pickup-ticket/SKILL.md dodi-dev/skills/implement-ticket/SKILL.md dodi-dev/skills/create-tests/SKILL.md
git commit -m "feat: stop conditions reworded — verification (incl. repo-local checks) replaces quality gate across pickup/implement/create-tests"
```

### Task 6: `submit` — interactive pre-flight replaces `/quality-gate`

**Files:**
- Modify: `dodi-dev/skills/submit/SKILL.md` (pre-flight bullet + report line; Key Rules and Epic Workflow Submit Policy stay byte-identical)

- [ ] **Step 1:** Replace the `/quality-gate` pre-flight bullet (3-space indent preserved).

Old:

```markdown
   - **Run `/quality-gate`** — this is mandatory. Invoke the quality-gate skill to run compliance checks, create tests, and run the test suite. Do NOT skip this step.
```

New:

```markdown
   - **Pre-PR verification** — this is mandatory. Confirm clean post-implementation `review` evidence exists; run `create-tests` if the Testing Contract requires test groups not yet present; then run `verify` — all Testing Contract command lines plus the local-CI runner scope (repo-local gates + broader checks). Do NOT skip this step.
```

- [ ] **Step 2:** Update the report line.

Old:

```markdown
3. Report the branch, commit range, review evidence, verification evidence, and quality-gate evidence.
```

New:

```markdown
3. Report the branch, commit range, review evidence, and verification evidence (incl. repo-local + broader checks).
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
grep -qF '**Pre-PR verification** — this is mandatory.' dodi-dev/skills/submit/SKILL.md && echo T6_A_OK
grep -qF 'Confirm clean post-implementation `review` evidence exists' dodi-dev/skills/submit/SKILL.md && echo T6_B_OK
grep -qF 'run `create-tests` if the Testing Contract requires test groups not yet present' dodi-dev/skills/submit/SKILL.md && echo T6_C_OK
grep -qF '3. Report the branch, commit range, review evidence, and verification evidence (incl. repo-local + broader checks).' dodi-dev/skills/submit/SKILL.md && echo T6_D_OK
! grep -qi 'quality.gat' dodi-dev/skills/submit/SKILL.md && echo T6_E_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T6_F_OK
```

Expected: the six lines `T6_A_OK` … `T6_F_OK`, in order, every command exit 0.

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/submit/SKILL.md
git commit -m "feat: submit pre-flight = review evidence + create-tests-if-missing + verify (Contract commands + local-CI scope)"
```

### Task 7: Reference sweep — lane-dispatch prompt, AGENTS.md, submit-ticket-pr

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md` (boundary enum + seam line; the do-not-dispatch banner and everything else stay byte-identical — the file is dead, retained as 0.16.0 flatten input)
- Modify: `AGENTS.md` (Standard-tier Used-for list; Context Hygiene anchors line)
- Modify: `dodi-dev/skills/submit-ticket-pr/SKILL.md` (lines 9/17/24 only; § Merge — incl. "verified by an evidence checker" — stays byte-identical)

- [ ] **Step 1:** Drop `quality-gating` from the lane-dispatch prompt's boundary enum (same anchor form as Task 2 Step 2, different file).

Old:

```markdown
`verifying`, `quality-gating`, `ready-for-child-pr`
```

New:

```markdown
`verifying`, `ready-for-child-pr`
```

- [ ] **Step 2:** Rename the seam in the lane-dispatch prompt.

Old:

```markdown
- Mandatory context reset at the quality-gate→PR seam: write the continuation brief, exit `RESUMABLE`.
```

New:

```markdown
- Mandatory context reset at the verify→PR seam: write the continuation brief, exit `RESUMABLE`.
```

- [ ] **Step 3:** Drop "quality gate" from the AGENTS.md Standard-tier Used-for list.

Old:

```markdown
failure triage, quality gate, research digests
```

New:

```markdown
failure triage, research digests
```

- [ ] **Step 4:** Rename the seam in the AGENTS.md mandatory-anchors line.

Old:

```markdown
lanes at the quality-gate→PR seam
```

New:

```markdown
lanes at the verify→PR seam
```

- [ ] **Step 5:** Update submit-ticket-pr's Open-half framing (line 9).

Old:

```markdown
lane after the quality gate; **Merge**
```

New:

```markdown
lane after verify; **Merge**
```

- [ ] **Step 6:** Drop quality gate from submit-ticket-pr's inputs list (line 17).

Old:

```markdown
- evidence summary from implementation, review, tests, verification, and quality gate
```

New:

```markdown
- evidence summary from implementation, review, tests, and verification
```

- [ ] **Step 7:** Rename the PR-body evidence item (line 24).

Old:

```markdown
test evidence, quality-gate evidence, and ticket link
```

New:

```markdown
test evidence, verification evidence (incl. repo-local + broader checks), and ticket link
```

- [ ] **Step 8:** Verify

Run (from the repo root):

```bash
grep -qF '(`implementing`, `implementation-reviewing`, `testing`, `verifying`, `ready-for-child-pr`, `child-pr-reviewing`)' dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md && echo T7_A_OK
grep -qF -- '- Mandatory context reset at the verify→PR seam: write the continuation brief, exit `RESUMABLE`.' dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md && echo T7_B_OK
grep -qF 'Do not dispatch this prompt (0.14.1 interim).' dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md && echo T7_C_OK
grep -qF 'failure triage, research digests (API docs, harness/codebase orientation)' AGENTS.md && echo T7_D_OK
grep -qF 'lanes at the verify→PR seam' AGENTS.md && echo T7_E_OK
grep -qF 'lane after verify; **Merge** runs' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T7_F_OK
grep -qF -- '- evidence summary from implementation, review, tests, and verification' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T7_G_OK
grep -qF 'test evidence, verification evidence (incl. repo-local + broader checks), and ticket link' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T7_H_OK
grep -qF 'verified by an evidence checker' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T7_I_OK
! grep -qi 'quality.gat' AGENTS.md dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T7_J_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T7_K_OK
```

Expected: the eleven lines `T7_A_OK` … `T7_K_OK`, in order, every command exit 0. (`T7_C_OK` proves the do-not-dispatch banner is intact; `T7_I_OK` proves § Merge step 1 — the C3/C4 consumer — is untouched.)

- [ ] **Step 9:** Commit

```bash
git add dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md AGENTS.md dodi-dev/skills/submit-ticket-pr/SKILL.md
git commit -m "feat: sweep quality-gate wording — lane-dispatch enum/seam, AGENTS.md tier row + anchors line, submit-ticket-pr evidence lines"
```

### Task 8: Retire the quality-gate skill (directory + validator array, atomic) + full battery

**Files:**
- Delete: `dodi-dev/skills/quality-gate/` (the whole directory — one file, `SKILL.md`)
- Modify: `scripts/validate-phase-skills.sh` (only the `skills` array — the `prompt_files` list and every assertion stay byte-identical)

- [ ] **Step 1:** Delete the skill directory (staged in the same commit as the array edit — the validator asserts `dodi-dev/skills/quality-gate/SKILL.md` exists for as long as the array names it).

```bash
git rm -r dodi-dev/skills/quality-gate
```

- [ ] **Step 2:** Remove `quality-gate` from the skills array (two-space indent preserved).

Old:

```bash
  pickup
  quality-gate
  review
```

New:

```bash
  pickup
  review
```

- [ ] **Step 3:** Verify — full Testing Contract (Unit group + Broader-regression grep battery)

Run (from the repo root):

```bash
test ! -e dodi-dev/skills/quality-gate && echo T8_A_OK
! grep -q 'quality-gate' scripts/validate-phase-skills.sh && echo T8_B_OK
bash -n scripts/validate-phase-skills.sh && echo T8_C_OK
bash scripts/validate-plugin-metadata.sh
bash scripts/validate-phase-skills.sh > /dev/null && echo T8_D_OK
bash scripts/validate-ticket-comment-templates.sh
test "$(grep -ril 'quality.gat' AGENTS.md .claude-plugin .agents dodi-dev scripts templates | sort | paste -sd' ' -)" = "dodi-dev/skills/epic-orchestrator/state-transitions.md dodi-dev/skills/submit-epic-pr/SKILL.md scripts/validate-ticket-comment-templates.sh templates/ticket-comments/epic-pr-ready.md" && echo T8_E_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/submit-epic-pr/SKILL.md)" = "3" && echo T8_F_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/epic-orchestrator/state-transitions.md)" = "2" && echo T8_G_OK
test "$(grep -ci 'quality.gat' scripts/validate-ticket-comment-templates.sh)" = "1" && echo T8_H_OK
test "$(grep -ci 'quality.gat' templates/ticket-comments/epic-pr-ready.md)" = "1" && echo T8_I_OK
grep -qF 'local CI runs in parallel' dodi-dev/skills/review/SKILL.md && echo T8_J_OK
grep -qF 'the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel**' dodi-dev/skills/review/SKILL.md && echo T8_K_OK
git status --porcelain dodi-dev/skills/review/ | { ! grep -q .; } && echo T8_L_OK
```

Expected, in order, every command exit 0:

```
T8_A_OK
T8_B_OK
T8_C_OK
plugin metadata ok: 0.14.2
T8_D_OK
ticket comment templates ok
T8_E_OK
T8_F_OK
T8_G_OK
T8_H_OK
T8_I_OK
T8_J_OK
T8_K_OK
T8_L_OK
```

(`T8_E_OK`–`T8_I_OK` assert the exact seven-line survivor set from the Testing Contract table: three C4 lines in submit-epic-pr, the C4 epic row plus C2's own resume-mapping token in state-transitions, the C4 validator heading assertion, and the C4 template heading. `T8_J_OK`/`T8_K_OK` assert C3's two review/SKILL.md anchors byte-exact; `T8_L_OK` asserts `review/` has no local modifications at all. The metadata version prints 0.14.2 — C2 does not bump; the load-bearing assertion is exit 0.)

- [ ] **Step 4:** Commit

```bash
git add scripts/validate-phase-skills.sh
git commit -m "feat: retire the quality-gate skill — directory deleted with its validator skills-array entry (C2 child-level complete)"
```

---

## Notes for the executor

- Verify-command hygiene: every command above exits 0 on success (negations use `! grep -q`; the survivor battery uses `test`-wrapped counts, never bare `grep -c` as a pass signal). No negation pattern in this plan matches any New-text block it is scoped against — the two intentional `quality-gating`/`quality gate` survivors (state-transitions resume-mapping line, epic row) are covered by positive assertions plus an exact per-file count of 2, never by a bare negation on that file.
- Ordering is re-home-before-retire (canon [C1-a]): verify absorbs the runner and the SHAs first (Task 1), the lane and every consumer stop naming quality-gate next (Tasks 2–7, during which the skill still exists — harmless double coverage), and the skill + its validator array entry vanish together last (Task 8). Validators are green at every one of the eight boundaries.
- `dodi-dev/skills/review/` (SKILL.md and both prompts) must show zero diff in `git status` when this plan is done — C3's quoted-text anchors live there. Task 8's `T8_J`–`T8_L` enforce this.
- The lane-checkpoint template's evidence placeholder cannot carry inner backticks around `ready-for-child-pr` (the placeholder is one Markdown code span); the plain-text form there is intentional, not drift.
- If any Old anchor fails to match byte-exactly, stop and re-read the target file — a sibling child may have landed out of order; report the mismatch instead of adapting the edit.
