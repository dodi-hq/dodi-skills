# C3: Conditional Local CI + Evidence-Checker Scoping (Changes 3+4) — Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute tasks in order (1→5). Each task ends with its own Verify (all commands must exit 0) and its own local commit; every task leaves the phase-skills validator green, and Task 5 closes with all three repo validators plus the full grep battery. All Old-text anchors below are byte-exact from the epic branch @ `469c8f4` (C1+C2 merged); **anchor by the quoted text, never by step or line number** (line numbers in this plan are hints — sibling children renumber). If an Old anchor does not match exactly, STOP and re-read the file — never fuzzy-match or approximate.

**Goal:** Make the child-PR local CI dispatch conditional on a durable checkpoint-recorded head-SHA predicate (fails closed), and scope the merge-slot evidence-checker to adoption boundaries (fails closed) — the single sources plus all four consumer surfaces, ending the double-CI window canon [C2-a] opened (spec §§ Change 3 + Change 4; scope = GitHub issue #5 as amended, incl. the [C2-b] resume-mapping backstop parenthetical).

**Architecture:** Change 3's predicate lives where the dispatch happens — `review` (child-PR context) — and reads its inputs from the `ready-for-child-pr` checkpoint, the durable home of the recorded runner head SHAs C2 landed (the evaluator runs on the far side of the lane's mandatory reset, so session-ephemeral digests cannot reach it). Skip iff (a) no commits after the checkpoint's **local-CI-runner** SHA (absent ⇒ dispatch; a newer test-runner SHA never substitutes), (b) that SHA is an ancestor of the current child HEAD (`git merge-base --is-ancestor`), and (c) the epic branch has not moved (any sync forces dispatch); undecidable ⇒ dispatch. Change 4's rule is stated once in `epic-orchestrator` (Merging step 2 + § Evidence Rule, jointly the single source): the checker dispatches iff the session is adopting (foreign/missing run id, or own checkpoints predating the last compaction); own-session in-context walks skip it, keeping `verify-merge.sh` and branch currency. `submit-ticket-pr` § Merge becomes the single source of merge eligibility and both state-transition cells, `pickup-next` (behavior unchanged — a tick always adopts), and `drive-epic`'s contract row are swept to the conditional forms. The janitor (`reconcile-tickets`) is out of scope by spec.

**Tech Stack:** Markdown skills (harness-neutral per AGENTS.md Editing Rules), Bash validator scripts. The three repo validators are the regression suite.

**Source of truth:** `docs/specs/2026-07-06-review-pipeline-consolidation-design.md` § Change 3 + § Change 4 + the C3 reference-sweep rows; GitHub issue #5 body **as amended** ([C2-b]: re-add the v7 backstop parenthetical to the resume-mapping line); epic canon (#3 § Decision Register — Canon): [C1-d] quoted-text anchors in `review/SKILL.md`, [C2-a] this child ends the double-CI window, [C2-b] backstop re-add, [C2-c] survivor set preserved.

**File surface (modify-only, seven files):** `dodi-dev/skills/review/SKILL.md` (contexts cell + child-PR dispatch clause), `dodi-dev/skills/epic-orchestrator/SKILL.md` (Merging step 2 + § Evidence Rule), `dodi-dev/skills/submit-ticket-pr/SKILL.md` (§ Merge intro + step 1 + evidence item), `dodi-dev/skills/epic-orchestrator/state-transitions.md` (two cells + resume-mapping parenthetical), `dodi-dev/skills/pickup-next/SKILL.md` (two lines), `dodi-dev/skills/drive-epic/SKILL.md` (one contract cell), `dodi-dev/skills/deliver-ticket/SKILL.md` (step-8 lane-sequence clause — one hunk; scope amendment per issue #5 [C2-b] plan-review ruling). No files created or deleted; no template, script, or metadata changes.

**Boundary discipline — do NOT touch (sibling-owned or out of scope):**

- `dodi-dev/skills/review/review-prompt.md` and `dodi-dev/skills/review/child-pr-integration-prompt.md` — zero diff; only `review/SKILL.md` changes in that directory (Task 5 battery asserts it against base `469c8f4`).
- The [C2-c] survivor set — exactly 4 files / 7 lines of quality-gate wording: `submit-epic-pr/SKILL.md` (3), state-transitions epic row + resume-mapping legacy `quality-gating` token (2), `validate-ticket-comment-templates.sh` heading assertion (1), `epic-pr-ready.md` heading (1). Six lines are C4's; the resume-mapping token is C2's, permanent — Task 4 appends the backstop parenthetical WITHOUT stripping it (issue #5 amendment: "no label strip").
- `dodi-dev/skills/deliver-ticket/SKILL.md` — only step 8's lane-sequence clause changes (Task 5 Step 4; the scope amendment [C2-b] plan-review ruling on issue #5 adopts this one-clause edit into C3 to avoid a post-C3 two-competing-texts seed). The rest of the file — every other step, the worker-dispatch discipline, Context Hygiene, Exit States — stays byte-identical; Task 5's `T5_W1`/`T5_W2` assert exactly that ONE hunk and nothing else in the file.
- `dodi-dev/skills/reconcile-tickets/SKILL.md` — the janitor's read-only reconciliation checkers are explicitly out of Change 4's scope.
- `caught-by` lines anywhere — C5's ([S1]); none of this plan's New text carries the tag.
- Plugin metadata (three files) — no version bump in C3; the 0.15.0 bump lands with the epic's release close-out.
- Epic-level surfaces (`submit-epic-pr/`, epic-pr-ready template, validator heading assertion, state-transitions epic row) — C4's.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `functions/components/modules` — the six modified skill/table files, exercised by the three repo validators (skill/prompt file existence, skills-array integrity, repo-only-reference hygiene, template integrity).
  - Reason: `<why>` — this is a docs/prose/validator repository; the validators are the executable unit surface and they assert the invariants prose edits can break (file existence, repo-only references, template headings).
  - Minimum assertions: `<specific behaviors>` — `validate-phase-skills.sh` exits 0 after every task (1–5); all three validators exit 0 in Task 5.

- Integration: `not-required`
  - Scope: `module boundaries/APIs/db/jobs/etc` — n/a.
  - Reason: `<why>` — no executable pipeline exists in this repository; the validators ARE the integration surface (cross-file existence and reference checks). Same rationale class as C1/C2.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a; see the Broader-regression grep battery (Task 5 Step 5) for cross-file text assertions.

- E2E: `not-required`
  - Scope: `user/business-critical flows` — n/a.
  - Reason: `<why>` — prose-skill behavior has no desk harness; the live exercise arrives with the 0.15.0 release (this epic itself dogfoods the 0.14.2 pipeline per canon [G1]). Same rationale class as C1/C2.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a.

### Critical Flows

- `Child-PR stage: evaluator reads the ready-for-child-pr checkpoint → skip local CI iff (a) no commits after the recorded local-CI-runner SHA (absent ⇒ dispatch; test-runner SHA never substitutes) ∧ (b) recorded SHA is an ancestor of child HEAD ∧ (c) epic branch has not moved (any sync forces dispatch) → otherwise dispatch in parallel as today; not decidable ⇒ dispatch`
- `Merge slot: adopting (foreign/missing run id, or own checkpoints predating the last compaction) ⇒ evidence-checker; own-session in-context walk ⇒ skip checker, keep verify-merge.sh postcondition + branch-currency check; when in doubt ⇒ dispatch`
- `Lane exit evidence: child-PR review clean + local CI clean OR the checkpoint-recorded verify-stage local-CI digest under the conditional-CI predicate, per submit-ticket-pr § Merge (the single source of merge eligibility)`
- `Resume mapping: a pre-0.15.0 lane past verifying that posts ready-for-child-pr noting the runner's absence hits the no-digest⇒dispatch backstop — the child-PR CI run is forced ([C2-b])`
- `Tick behavior unchanged: pickup-next always adopts (fresh session per run), so its checker verification always fires — lines 30 and 54 say so without changing what a tick does`

### Regression Surface

- `[C2-c] survivor set: exactly 4 files / 7 lines of quality-gate wording, byte-identical counts (submit-epic-pr 3, state-transitions 2, validator 1, epic-pr-ready 1)`
- `review/review-prompt.md and review/child-pr-integration-prompt.md — zero diff vs 469c8f4`
- `deliver-ticket — exactly one hunk (step-8 lane-sequence clause); every other line byte-identical. verify/*, submit-ticket-pr/local-ci-runner-prompt.md, templates/* — untouched by C3`
- `epic-orchestrator Merging steps 1 and 3–6 (coherence machinery, label-before-merge ordering) and "Durable PM state is the source of truth." — byte-identical`
- `submit-ticket-pr Open half, merge commands block, and Rules section — byte-identical`

### Commands

- Unit: `bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh && bash scripts/validate-ticket-comment-templates.sh` (from the repo root; Tasks 1–4 run phase-skills, Task 5 runs all three)
- Integration: `not-applicable — no executable pipeline; the validators are the integration surface`
- E2E: `not-applicable — live exercise arrives with the 0.15.0 release; this epic runs the 0.14.2 pipeline per canon [G1]`
- Broader regression: the Task 5 Step 5 grep battery — new predicate text present at every surface (review, epic-orchestrator, submit-ticket-pr, state-transitions ×3, pickup-next ×2, drive-epic), the [C2-c] survivor set unchanged, `review/` prompts untouched; every command exits 0 on success.

### Harness Requirements

- `bash, python3, grep, git — repo checkout only; no network, no PM access, no env vars`

### Non-Required Rationale

- Unit: n/a (required).
- Integration: `no executable pipeline exists; the three validators are the only cross-file integration surface and run as the Unit group (same rationale class as C1/C2)`
- E2E: `no desk e2e of prose skills exists; live behavior lands at the 0.15.0 release — this epic dogfoods 0.14.2 per canon [G1] (same rationale class as C1/C2)`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

**Expected [C2-c] survivor set (unchanged by C3 — asserted in Task 5):**

| File | Lines with `quality`-`gat` | Owner |
| --- | --- | --- |
| `dodi-dev/skills/submit-epic-pr/SKILL.md` | 3 | C4 |
| `dodi-dev/skills/epic-orchestrator/state-transitions.md` | 2 — the epic row (C4) + the resume-mapping legacy `quality-gating` token (C2's, permanent; Task 4 appends after it, never strips it) | C4 / C2 |
| `scripts/validate-ticket-comment-templates.sh` | 1 | C4 |
| `templates/ticket-comments/epic-pr-ready.md` | 1 | C4 |

---

## Tasks

### Task 1: `review` (child-PR context) — the conditional local-CI predicate (Change 3)

**Files:**
- Modify: `dodi-dev/skills/review/SKILL.md` (contexts-table child-PR cell, line ~15; child-PR Process step 2 dispatch clause, line ~45 — the two surfaces canon [C1-d] anchors by quoted text. Everything else — both Process sections' other steps, What to Check, Epic Lane Rules, both prompt files — stays byte-identical)

- [ ] **Step 1:** Replace the contexts-table cell's unconditional tail (anchor: "local CI runs in parallel").

Old:

```markdown
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | delta-scoped integration pair — one `opus` integration round + one `fable` integration final (child-pr-integration-prompt.md); Testing Contract coverage; branch currency with the epic branch; local CI runs in parallel |
```

New:

```markdown
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | delta-scoped integration pair — one `opus` integration round + one `fable` integration final (child-pr-integration-prompt.md); Testing Contract coverage; branch currency with the epic branch; local CI conditional — dispatched in parallel unless the `ready-for-child-pr` checkpoint's recorded local-CI head SHA still covers the branch (skip predicate in Process — child-PR) |
```

- [ ] **Step 2:** Replace the Process step-2 dispatch clause (anchor: "the local CI runner (") with the full skip predicate.

Old:

```markdown
2. Dispatch the **integration round** (child-pr-integration-prompt.md, `model: opus`). Dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent.
```

New:

```markdown
2. Dispatch the **integration round** (child-pr-integration-prompt.md, `model: opus`). **Conditional local CI:** evaluate the skip predicate from the `ready-for-child-pr` checkpoint — the durable home of the recorded runner head SHAs (this evaluator runs on the far side of the lane's mandatory reset, so session-ephemeral digests cannot reach it). Skip the local CI dispatch **iff all three hold**: **(a)** the checkpoint records a head SHA for the **local-CI runner specifically** and no commits exist on the child branch after it — a newer test-runner SHA never substitutes (a verify-stage fix re-runs affected groups, not necessarily the local-CI runner); no recorded local-CI SHA ⇒ dispatch; **(b)** that recorded SHA is an ancestor of the current child HEAD (`git merge-base --is-ancestor <recorded-sha> HEAD`; a rebase-style rewrite orphans it — dispatch); **(c)** the epic branch has not moved — any epic-branch sync (merge or rebase) forces the dispatch: the sync-then-rerun rule (Epic Lane Rules) explicitly includes the CI runner. The predicate fails closed: not decidable ⇒ dispatch. On dispatch, dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent. On skip, record the predicate evaluation (recorded local-CI SHA, ancestry result, epic-head check) in the exit evidence; the checkpoint-recorded verify-stage local-CI digest is then the CI-equivalent evidence (`submit-ticket-pr` § Merge).
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
grep -qF 'local CI conditional — dispatched in parallel unless' dodi-dev/skills/review/SKILL.md && echo T1_A_OK
! grep -qF 'local CI runs in parallel' dodi-dev/skills/review/SKILL.md && echo T1_B_OK
grep -qF '**Conditional local CI:** evaluate the skip predicate from the `ready-for-child-pr` checkpoint' dodi-dev/skills/review/SKILL.md && echo T1_C_OK
grep -qF 'a newer test-runner SHA never substitutes' dodi-dev/skills/review/SKILL.md && echo T1_D_OK
grep -qF 'no recorded local-CI SHA ⇒ dispatch' dodi-dev/skills/review/SKILL.md && echo T1_E_OK
grep -qF 'git merge-base --is-ancestor' dodi-dev/skills/review/SKILL.md && echo T1_F_OK
grep -qF 'any epic-branch sync (merge or rebase) forces the dispatch' dodi-dev/skills/review/SKILL.md && echo T1_G_OK
grep -qF 'The predicate fails closed: not decidable ⇒ dispatch.' dodi-dev/skills/review/SKILL.md && echo T1_H_OK
grep -qF 'dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent' dodi-dev/skills/review/SKILL.md && echo T1_I_OK
grep -qF 'Child-PR context: if the epic branch moved, update the child branch from the epic branch and rerun relevant checks' dodi-dev/skills/review/SKILL.md && echo T1_J_OK
git status --porcelain dodi-dev/skills/review/review-prompt.md dodi-dev/skills/review/child-pr-integration-prompt.md | { ! grep -q .; } && echo T1_K_OK
# Full-paragraph pin (advisory a): the entire New Process step-2 paragraph must be present byte-exact (closes the retype-corruption gap the token greps above cannot). Heredoc is literal (`<<'PATN'` — no backtick/`$` expansion); grep -Ff matches the whole line as one fixed string.
PATN1="$(mktemp)"; cat > "$PATN1" <<'PATN'
2. Dispatch the **integration round** (child-pr-integration-prompt.md, `model: opus`). **Conditional local CI:** evaluate the skip predicate from the `ready-for-child-pr` checkpoint — the durable home of the recorded runner head SHAs (this evaluator runs on the far side of the lane's mandatory reset, so session-ephemeral digests cannot reach it). Skip the local CI dispatch **iff all three hold**: **(a)** the checkpoint records a head SHA for the **local-CI runner specifically** and no commits exist on the child branch after it — a newer test-runner SHA never substitutes (a verify-stage fix re-runs affected groups, not necessarily the local-CI runner); no recorded local-CI SHA ⇒ dispatch; **(b)** that recorded SHA is an ancestor of the current child HEAD (`git merge-base --is-ancestor <recorded-sha> HEAD`; a rebase-style rewrite orphans it — dispatch); **(c)** the epic branch has not moved — any epic-branch sync (merge or rebase) forces the dispatch: the sync-then-rerun rule (Epic Lane Rules) explicitly includes the CI runner. The predicate fails closed: not decidable ⇒ dispatch. On dispatch, dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent. On skip, record the predicate evaluation (recorded local-CI SHA, ancestry result, epic-head check) in the exit evidence; the checkpoint-recorded verify-stage local-CI digest is then the CI-equivalent evidence (`submit-ticket-pr` § Merge).
PATN
grep -cFf "$PATN1" dodi-dev/skills/review/SKILL.md | grep -qx 1 && echo T1_M_OK; rm -f "$PATN1"
bash scripts/validate-phase-skills.sh > /dev/null && echo T1_L_OK
```

Expected: the thirteen lines `T1_A_OK` … `T1_K_OK`, then `T1_M_OK`, then `T1_L_OK` (validator last), every command exit 0. (`T1_B_OK` proves the unconditional cell wording is gone — the New texts nowhere contain that exact string; `T1_J_OK` proves the Epic Lane Rules sync-then-rerun line is untouched — clause (c) carries the explicit CI-runner inclusion; `T1_K_OK` proves both prompt files are untouched; `T1_M_OK` is the full-paragraph pin — the entire New Process step-2 predicate byte-exact via `grep -Ff`, closing the retype-corruption gap.)

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/review/SKILL.md
git commit -m "feat: child-PR local CI becomes conditional — skip predicate reads the ready-for-child-pr checkpoint's recorded local-CI head SHA, fails closed"
```

### Task 2: `epic-orchestrator` — evidence-checker scoped to adoption boundaries (Change 4 single source)

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/SKILL.md` (Merging step 2, line ~83; § Evidence Rule first paragraph, line ~104. Merging steps 1 and 3–6, "Durable PM state is the source of truth.", and every other section stay byte-identical)

- [ ] **Step 1:** Replace Merging step 2 with the scoped checker rule (the single source, with § Evidence Rule).

Old:

```markdown
2. Verify its evidence via an evidence-checker worker (`evidence-checker-prompt.md`).
```

New:

```markdown
2. **Scoped evidence-checker rule (the single source, with § Evidence Rule):** dispatch the evidence-checker worker (`evidence-checker-prompt.md`) **iff this session is adopting work it did not execute and directly observe** — any Lane Checkpoint in the trail carries a foreign or missing session run id, **or** any own-run-id checkpoint predates this session's last compaction (a deliberate compaction is a voluntary crash + resume: post-compaction knowledge of prior steps is reconstructed from durable state, not observed — treat those checkpoints as adopted). When every checkpoint was written by this session in its current context window, skip the checker: results were claimed only from leaf digests as the lane was walked, and the merge retains its script-owned postcondition (step 5, `verify-merge.sh`) and the branch-currency check (step 3). **When in doubt, dispatch — the predicate fails closed.** (Scope: the merge-slot adoption gate; the janitor's read-only reconciliation checkers in `reconcile-tickets` are a different context, untouched.)
```

- [ ] **Step 2:** Scope the § Evidence Rule paragraph to the same adoption test (non-merge advances included).

Old:

```markdown
The orchestrator may not advance state from a lane or worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing — via the evidence-checker worker.
```

New:

```markdown
The orchestrator may not advance state from a lane or worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing. The evidence-checker worker is the **adoption** instrument — Merging step 2 states the single test with this section: own-session work walked in the current context window advances on its leaf digests and the durable writes made as each boundary was crossed; adopted work (a foreign or missing run id, or own checkpoints predating the last compaction) takes the checker. Non-merge state advances follow the same adoption test. When in doubt, dispatch — the predicate fails closed.
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
grep -qF 'iff this session is adopting work it did not execute and directly observe' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_A_OK
grep -qF 'foreign or missing session run id' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_B_OK
grep -qF "predates this session's last compaction" dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_C_OK
grep -qF 'skip the checker: results were claimed only from leaf digests as the lane was walked' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_D_OK
grep -qF '(step 5, `verify-merge.sh`) and the branch-currency check (step 3)' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_E_OK
grep -qF '**When in doubt, dispatch — the predicate fails closed.**' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_F_OK
grep -qF 'read-only reconciliation checkers in `reconcile-tickets` are a different context, untouched.)' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_G_OK
grep -qF 'The evidence-checker worker is the **adoption** instrument' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_H_OK
grep -qF 'Non-merge state advances follow the same adoption test.' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_I_OK
! grep -qF 'Verify its evidence via an evidence-checker worker' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_J_OK
! grep -qF -- '— via the evidence-checker worker.' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_K_OK
grep -qF 'Durable PM state is the source of truth.' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_L_OK
grep -qF '4. **Merge-eligibility guard: no merge is eligible while the epic holds `coherence-pending`**' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T2_M_OK
# Full-paragraph pin (advisory a): the entire New Merging step-2 adoption predicate must be present byte-exact. Literal heredoc; grep -Ff matches the whole line as one fixed string.
PATN2="$(mktemp)"; cat > "$PATN2" <<'PATN'
2. **Scoped evidence-checker rule (the single source, with § Evidence Rule):** dispatch the evidence-checker worker (`evidence-checker-prompt.md`) **iff this session is adopting work it did not execute and directly observe** — any Lane Checkpoint in the trail carries a foreign or missing session run id, **or** any own-run-id checkpoint predates this session's last compaction (a deliberate compaction is a voluntary crash + resume: post-compaction knowledge of prior steps is reconstructed from durable state, not observed — treat those checkpoints as adopted). When every checkpoint was written by this session in its current context window, skip the checker: results were claimed only from leaf digests as the lane was walked, and the merge retains its script-owned postcondition (step 5, `verify-merge.sh`) and the branch-currency check (step 3). **When in doubt, dispatch — the predicate fails closed.** (Scope: the merge-slot adoption gate; the janitor's read-only reconciliation checkers in `reconcile-tickets` are a different context, untouched.)
PATN
grep -cFf "$PATN2" dodi-dev/skills/epic-orchestrator/SKILL.md | grep -qx 1 && echo T2_O_OK; rm -f "$PATN2"
bash scripts/validate-phase-skills.sh > /dev/null && echo T2_N_OK
```

Expected: the fifteen lines `T2_A_OK` … `T2_M_OK`, then `T2_O_OK`, then `T2_N_OK` (validator last), every command exit 0. (`T2_J_OK`/`T2_K_OK` prove both unconditional phrasings are gone — neither is a substring of any New text in this plan; `T2_L_OK`/`T2_M_OK` prove the source-of-truth line and the coherence machinery survive byte-exact; `T2_O_OK` is the full-paragraph pin — the entire New Merging step-2 adoption predicate byte-exact via `grep -Ff`.)

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/epic-orchestrator/SKILL.md
git commit -m "feat: evidence-checker scoped to adoption boundaries — Merging step 2 + Evidence Rule are the single source, fail closed; janitor out of scope"
```

### Task 3: `submit-ticket-pr` § Merge — single source of merge eligibility + conditional evidence forms

**Files:**
- Modify: `dodi-dev/skills/submit-ticket-pr/SKILL.md` (§ Merge intro sentence + step 1, lines ~32–34; one Expected-evidence item, line ~55. The Open half, the command blocks, the other evidence items, and Rules stay byte-identical)

- [ ] **Step 1:** Mark § Merge the single source and make step 1's checker citation conditional (spec's exact conditional form).

Old:

```markdown
## Merge (orchestrator-invoked, strictly serial)

1. Require the lane's `ready-to-merge-child` report with clean child-PR review and local CI-equivalent evidence, verified by an evidence checker.
```

New:

```markdown
## Merge (orchestrator-invoked, strictly serial)

This section is the **single source of merge eligibility** — consumers reference it, never restate it.

1. Require the lane's `ready-to-merge-child` report with clean child-PR review and local CI-equivalent evidence — evidence-checker citations when adopting (per the epic-orchestrator Evidence Rule); own-session evidence trail otherwise.
```

- [ ] **Step 2:** Extend the CI-equivalent evidence item with the checkpoint-recorded conditional form.

Old:

```markdown
- local CI-equivalent command evidence
```

New:

```markdown
- local CI-equivalent command evidence — a child-PR-stage local CI digest, or the **checkpoint-recorded** verify-stage local-CI digest when the conditional-CI predicate held (`review`, child-PR context; the durable record, not session memory)
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
grep -qF 'This section is the **single source of merge eligibility** — consumers reference it, never restate it.' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T3_A_OK
grep -qF 'evidence-checker citations when adopting (per the epic-orchestrator Evidence Rule); own-session evidence trail otherwise' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T3_B_OK
! grep -qF 'verified by an evidence checker' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T3_C_OK
grep -qF 'the **checkpoint-recorded** verify-stage local-CI digest when the conditional-CI predicate held' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T3_D_OK
grep -qF 'the durable record, not session memory' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T3_E_OK
grep -qF 'Do not merge if review or local CI-equivalent checks are not clean.' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T3_F_OK
grep -qF '5. Return to the lane — the lane runs `review` (child-PR context) next. Do not merge from this half.' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T3_G_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T3_H_OK
```

Expected: the eight lines `T3_A_OK` … `T3_H_OK`, in order, every command exit 0. (`T3_C_OK` proves the unconditional step-1 phrasing is gone — not a substring of any New text; `T3_F_OK`/`T3_G_OK` prove the Rules section and the Open half survive byte-exact.)

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/submit-ticket-pr/SKILL.md
git commit -m "feat: submit-ticket-pr § Merge marked single source of merge eligibility — conditional checker citation + checkpoint-recorded verify-stage CI digests"
```

### Task 4: `state-transitions.md` — conditional evidence cells + the [C2-b] backstop parenthetical

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/state-transitions.md` (Child-Ticket `ready-to-merge-child` row's Required-evidence cell; the lane-exit `(exit) ready-to-merge-child` row's Reached-when cell; the resume-mapping line's tail. Anchor by row NAME and quoted text — line numbers drifted after C2. The epic-table row, the `ready-for-child-pr` row, and everything else stay byte-identical)

- [ ] **Step 1:** Make the Child-Ticket `ready-to-merge-child` Required-evidence cell conditional (edit the cell fragment — it is unique in the file; the row's other five columns are untouched).

Old:

```markdown
evidence-checker citations; child branch current with epic head
```

New:

```markdown
own-session evidence trail (all checkpoints this run id, written this context window) or evidence-checker citations (adoption); child branch current with epic head
```

- [ ] **Step 2:** Make the lane-exit row's Reached-when cell conditional (find the row by its content "child-PR review + local CI clean"; the evidence cell "reviewer status, CI digests" stands — in the skip case the digest cited is the checkpoint-recorded verify-stage one).

Old:

```markdown
| (exit) ready-to-merge-child | child-PR review + local CI clean | reviewer status, CI digests |
```

New:

```markdown
| (exit) ready-to-merge-child | child-PR review clean + local CI clean *or* verify-stage local-CI digest under the conditional-CI predicate (per `submit-ticket-pr` § Merge) | reviewer status, CI digests |
```

- [ ] **Step 3:** Re-add the v7 backstop parenthetical to the resume-mapping line ([C2-b] — verbatim v7 text, appended after "absence"; the legacy `quality-gating` token earlier in the same line is NOT stripped).

Old:

```markdown
**Resume mapping (pre-0.15.0 checkpoints):** a previously posted `quality-gating` checkpoint reads as `verifying` complete; the next boundary is `ready-for-child-pr`. A pre-0.15.0 lane resuming past `verifying` never ran the verify-stage local-CI runner: run it before posting `ready-for-child-pr`, or post that boundary noting the runner's absence.
```

New:

```markdown
**Resume mapping (pre-0.15.0 checkpoints):** a previously posted `quality-gating` checkpoint reads as `verifying` complete; the next boundary is `ready-for-child-pr`. A pre-0.15.0 lane resuming past `verifying` never ran the verify-stage local-CI runner: run it before posting `ready-for-child-pr`, or post that boundary noting the runner's absence (the no-digest⇒dispatch backstop then forces the child-PR CI run).
```

- [ ] **Step 4:** Verify

Run (from the repo root):

```bash
grep -qF 'own-session evidence trail (all checkpoints this run id, written this context window) or evidence-checker citations (adoption); child branch current with epic head' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_A_OK
grep -qF '| (exit) ready-to-merge-child | child-PR review clean + local CI clean *or* verify-stage local-CI digest under the conditional-CI predicate (per `submit-ticket-pr` § Merge) | reviewer status, CI digests |' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_B_OK
! grep -qF '| child-PR review + local CI clean |' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_C_OK
grep -qF '(the no-digest⇒dispatch backstop then forces the child-PR CI run)' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_D_OK
grep -qF 'a previously posted `quality-gating` checkpoint reads as `verifying` complete' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_E_OK
grep -qF 'epic quality gate evidence' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_F_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/epic-orchestrator/state-transitions.md)" = "2" && echo T4_G_OK
grep -qF "verification evidence, including each runner digest's recorded head SHA with the local-CI runner's named explicitly; continuation brief |" dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_H_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T4_I_OK
```

Expected: the nine lines `T4_A_OK` … `T4_I_OK`, in order, every command exit 0. (`T4_C_OK` proves the old unconditional cell is gone — the New cell reads "review clean + local CI clean", so the old string is not a substring of it; `T4_E_OK`–`T4_G_OK` prove the two [C2-c] survivor lines in this file are intact at exactly two `quality`-`gat` lines; `T4_H_OK` proves the `ready-for-child-pr` row — the predicate's durable input — is untouched.)

- [ ] **Step 5:** Commit

```bash
git add dodi-dev/skills/epic-orchestrator/state-transitions.md
git commit -m "feat: state-transitions — conditional evidence cells (ready-to-merge-child + lane exit); resume-mapping no-digest backstop re-added per [C2-b]"
```

### Task 5: `pickup-next` + `drive-epic` + `deliver-ticket` consumer sweep — then the full battery

**Files:**
- Modify: `dodi-dev/skills/pickup-next/SKILL.md` (step 2.1's merge clause, line ~30; the Rules absolute, line ~54 — behavior unchanged, a tick always adopts)
- Modify: `dodi-dev/skills/drive-epic/SKILL.md` (contract-row delegation cell, line ~17 — one parenthetical; nothing else)
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md` (step-8 lane-sequence clause — one hunk; the rest of the file stays byte-identical)

- [ ] **Step 1:** Add the always-fires note to pickup-next's merge clause (edit the fragment — it is unique in the file; the rest of the step-2.1 line is untouched).

Old:

```markdown
before merging; postconditions via
```

New:

```markdown
before merging (a tick is always an adopting session, so this always fires); postconditions via
```

- [ ] **Step 2:** Scope pickup-next's Rules absolute (behavior unchanged: every tick is a fresh session, so every advance is adopted work and the checker still always fires).

Old:

```markdown
- Never touch epics lacking `epic-signed-off`; never merge an epic PR; never advance state without evidence-checker verification (evidence rule unchanged from `epic-orchestrator`).
```

New:

```markdown
- Never touch epics lacking `epic-signed-off`; never merge an epic PR; never advance state on adopted work without evidence-checker verification, per the `epic-orchestrator` Evidence Rule adoption test — a fresh tick is always adopting, so for the tick this always fires.
```

- [ ] **Step 3:** Note the checker conditional in drive-epic's contract delegation cell (edit the fragment — it is unique in the file; the rest of the row is untouched).

Old:

```markdown
state-reader / evidence-checker leaf workers
```

New:

```markdown
state-reader / evidence-checker leaf workers (checker conditional per the `epic-orchestrator` Evidence Rule — the driver's inline-walked lanes are the primary skip case)
```

- [ ] **Step 4:** Rewrite `deliver-ticket` step 8's lane-sequence clause to the conditional form (BLOCKING fold, scope amendment per issue #5 [C2-b] plan-review ruling). The clause is a one-line lane summary; it must name the pair the spec's § Change 2 end-state uses (`∥ conditional local CI`) and reference `review` (child-PR context) as the predicate home — **no mechanism restatement** (the (a)/(b)/(c) predicate lives in `review/SKILL.md`; drift rule). Anchor by the quoted tail — it is unique in the file (`∥` appears nowhere in `deliver-ticket` today). Only the tail after the integration-pair parenthetical changes; the rest of the line and the leading `8. ` are byte-identical.

Old:

```markdown
 and the local CI runner in parallel.
```

New:

```markdown
 ∥ conditional local CI (dispatched in parallel unless the skip predicate holds — per `review`, child-PR context).
```

- [ ] **Step 5:** Verify (task-local)

Run (from the repo root):

```bash
grep -qF 'before merging (a tick is always an adopting session, so this always fires); postconditions via' dodi-dev/skills/pickup-next/SKILL.md && echo T5_A_OK
grep -qF -- '- Never touch epics lacking `epic-signed-off`; never merge an epic PR; never advance state on adopted work without evidence-checker verification, per the `epic-orchestrator` Evidence Rule adoption test — a fresh tick is always adopting, so for the tick this always fires.' dodi-dev/skills/pickup-next/SKILL.md && echo T5_B_OK
! grep -qF 'evidence rule unchanged from' dodi-dev/skills/pickup-next/SKILL.md && echo T5_C_OK
grep -qF 'checker conditional per the `epic-orchestrator` Evidence Rule' dodi-dev/skills/drive-epic/SKILL.md && echo T5_D_OK
grep -qF 'the primary skip case)' dodi-dev/skills/drive-epic/SKILL.md && echo T5_E_OK
grep -qF '∥ conditional local CI (dispatched in parallel unless the skip predicate holds — per `review`, child-PR context).' dodi-dev/skills/deliver-ticket/SKILL.md && echo T5_D2_OK
! grep -qF 'and the local CI runner in parallel.' dodi-dev/skills/deliver-ticket/SKILL.md && echo T5_E2_OK
```

Expected: the seven lines `T5_A_OK` … `T5_E_OK`, then `T5_D2_OK`, `T5_E2_OK`, in order, every command exit 0. (`T5_C_OK` proves the old absolute's parenthetical is gone — not a substring of any New text; `T5_D2_OK` is the positive pin for the new `deliver-ticket` step-8 conditional clause; `T5_E2_OK` proves the old unconditional tail is gone — the New clause nowhere contains that string, so the negation is a clean single-file check.)

- [ ] **Step 6:** Verify — full Testing Contract battery (Unit group + Broader regression)

Run (from the repo root):

```bash
bash scripts/validate-plugin-metadata.sh
bash scripts/validate-phase-skills.sh > /dev/null && echo T5_F_OK
bash scripts/validate-ticket-comment-templates.sh
grep -qF 'git merge-base --is-ancestor' dodi-dev/skills/review/SKILL.md && echo T5_G_OK
grep -qF 'The predicate fails closed: not decidable ⇒ dispatch.' dodi-dev/skills/review/SKILL.md && echo T5_H_OK
grep -qF 'iff this session is adopting work it did not execute and directly observe' dodi-dev/skills/epic-orchestrator/SKILL.md && echo T5_I_OK
grep -qF 'single source of merge eligibility' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T5_J_OK
grep -qF 'evidence-checker citations when adopting (per the epic-orchestrator Evidence Rule); own-session evidence trail otherwise' dodi-dev/skills/submit-ticket-pr/SKILL.md && echo T5_K_OK
grep -qF 'or evidence-checker citations (adoption); child branch current with epic head' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T5_L_OK
grep -qF 'verify-stage local-CI digest under the conditional-CI predicate (per `submit-ticket-pr` § Merge)' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T5_M_OK
grep -qF '(the no-digest⇒dispatch backstop then forces the child-PR CI run)' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T5_N_OK
grep -qF '(a tick is always an adopting session, so this always fires)' dodi-dev/skills/pickup-next/SKILL.md && echo T5_O_OK
grep -qF 'the primary skip case' dodi-dev/skills/drive-epic/SKILL.md && echo T5_P_OK
test "$(grep -ril 'quality.gat' AGENTS.md .claude-plugin .agents dodi-dev scripts templates | sort | paste -sd' ' -)" = "dodi-dev/skills/epic-orchestrator/state-transitions.md dodi-dev/skills/submit-epic-pr/SKILL.md scripts/validate-ticket-comment-templates.sh templates/ticket-comments/epic-pr-ready.md" && echo T5_Q_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/submit-epic-pr/SKILL.md)" = "3" && echo T5_R_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/epic-orchestrator/state-transitions.md)" = "2" && echo T5_S_OK
test "$(grep -ci 'quality.gat' scripts/validate-ticket-comment-templates.sh)" = "1" && echo T5_T_OK
test "$(grep -ci 'quality.gat' templates/ticket-comments/epic-pr-ready.md)" = "1" && echo T5_U_OK
test "$(git diff --name-only 469c8f4 -- dodi-dev/skills/review/ | sort | paste -sd' ' -)" = "dodi-dev/skills/review/SKILL.md" && echo T5_V_OK
test "$(git diff --name-only 469c8f4 -- dodi-dev/skills/deliver-ticket/ | sort | paste -sd' ' -)" = "dodi-dev/skills/deliver-ticket/SKILL.md" && echo T5_W1_OK
test "$(git diff --unified=0 469c8f4 -- dodi-dev/skills/deliver-ticket/SKILL.md | grep -c '^@@')" = "1" && echo T5_W2_OK
git diff --quiet 469c8f4 -- dodi-dev/skills/verify/ dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md dodi-dev/skills/reconcile-tickets/ templates/ scripts/ && echo T5_W_OK
```

Expected, in order, every command exit 0:

```
plugin metadata ok: 0.14.2
T5_F_OK
ticket comment templates ok
T5_G_OK
T5_H_OK
T5_I_OK
T5_J_OK
T5_K_OK
T5_L_OK
T5_M_OK
T5_N_OK
T5_O_OK
T5_P_OK
T5_Q_OK
T5_R_OK
T5_S_OK
T5_T_OK
T5_U_OK
T5_V_OK
T5_W1_OK
T5_W2_OK
T5_W_OK
```

(`T5_G_OK`–`T5_P_OK` assert the new predicate text landed at every surface; `T5_Q_OK`–`T5_U_OK` assert the exact [C2-c] survivor set — 4 files, counts 3/2/1/1; `T5_V_OK` asserts only `review/SKILL.md` changed under `review/` since base `469c8f4` — both prompts byte-identical across all commits; `T5_W1_OK`/`T5_W2_OK` assert C3's ONE `deliver-ticket` hunk and nothing else in that file — only `deliver-ticket/SKILL.md` changed under the dir, and exactly one `@@` hunk in it (the step-8 clause); `T5_W_OK` asserts C3 left verify, the local-CI runner prompt, the janitor, templates, and scripts untouched since base. The metadata version prints 0.14.2 — C3 does not bump; the load-bearing assertion is exit 0.)

- [ ] **Step 7:** Commit

```bash
git add dodi-dev/skills/pickup-next/SKILL.md dodi-dev/skills/drive-epic/SKILL.md dodi-dev/skills/deliver-ticket/SKILL.md
git commit -m "feat: pickup-next + drive-epic checker rule scoped by reference; deliver-ticket step-8 lane clause made conditional (tick always adopts; driver inline walks are the skip case) — C3 complete"
```

---

## Notes for the executor

- Task 1's exit-evidence recording of the predicate evaluation is a disclosed spec-plus (operational visibility; no behavior change).
- Verify-command hygiene: every command above exits 0 on success; negations use `! grep -qF` scoped to a single file, and no negation pattern is a substring of any New text in this plan (checked per task in the Expected notes). Dash-leading patterns carry `--` before the pattern (`T5_B_OK`); patterns containing an apostrophe use double quotes only when they contain no backticks (`T2_C_OK`, `T4_H_OK`). The two full-paragraph pins (`T1_M_OK`, `T2_O_OK`) hold text with BOTH apostrophes and backticks — inline single-quote or double-quote `grep -F` is impossible, so each writes the exact New paragraph to a temp file via a literal `<<'PATN'` heredoc (no backtick/`$` expansion) and asserts `grep -cFf "$PATN" <file> | grep -qx 1` (exactly one line matches the whole fixed string); the temp file is removed after.
- Ordering: single sources first — the Change 3 predicate (Task 1, `review`) and the Change 4 rule (Task 2, `epic-orchestrator`) — then the consumers (`submit-ticket-pr`, `state-transitions`, `pickup-next`/`drive-epic`). Mid-sequence a consumer may briefly reference wording that lands one task later; all five tasks ship in one child PR, and the phase-skills validator is green at every boundary.
- Task 4's three edits together must leave `state-transitions.md` at exactly two `quality`-`gat` lines (`T4_G_OK`): the C4-owned epic row and C2's permanent resume-mapping `quality-gating` token — the [C2-b] parenthetical appends after that token, never strips it (issue #5 amendment: "no label strip").
- `469c8f4` in `T5_V_OK`/`T5_W1_OK`/`T5_W2_OK`/`T5_W_OK` is the C1+C2-merged epic head this plan's anchors were taken from; commits after it on the child branch are exactly this plan's five task commits plus the plan file itself (the `deliver-ticket` step-8 clause rides in Task 5's commit — no sixth commit), so the path-scoped diffs prove sibling surfaces untouched. `T5_W1`/`T5_W2` narrow the `deliver-ticket` claim from "untouched" to "exactly one hunk in SKILL.md, nothing else in the directory".
- Behavior notes for review context (not edits): `pickup-next`'s two rewordings change no tick behavior — a tick is a fresh session, always adopting, so the checker fires on every tick advance exactly as before; `deliver-ticket` step 8's lane-sequence clause is reworded to the conditional form (Task 5 Step 4) so the lane summary no longer promises unconditional parallel CI — it references `review` (child-PR context), which that step invokes and which owns the predicate (mechanism not restated — drift rule).
- If any Old anchor fails to match byte-exactly, stop and re-read the target file — a sibling child may have landed out of order; report the mismatch instead of adapting the edit.
