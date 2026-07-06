# C1: Child-PR Integration Pair (Change 1) — Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute tasks in order (1→5). Each task ends with its own Verify (all commands must exit 0) and its own local commit; every task leaves the three repo validators green. All Old-text anchors below are byte-exact from the epic branch @ `e4c9fe7`; **anchor by the quoted text, never by step or line number** (sibling children renumber later). If an Old anchor does not match exactly, STOP and re-read the file — never fuzzy-match or approximate.

**Goal:** Re-aim the child-PR review gate from a second full-checklist loop to a delta-scoped integration pair — one `opus` integration round + one `fable` integration final — keeping the pre-PR full gate unchanged, pinning the focused re-review rule in place, and adding the Documentation and Operational-concerns checklist rows (spec § Change 1 + the C1-owned reference-sweep rows; scope = GitHub issue #4).

**Architecture:** `review/SKILL.md` splits its single Process into two per-context processes: post-implementation + pre-PR keep the existing full loop (opus rounds cap 5 + fable final) on `review-prompt.md`; the child-PR context becomes an integration pair on a **new** sibling prompt `child-pr-integration-prompt.md` carrying the delta aims and the admissibility sentence. `review-prompt.md` narrows to the full-gate contexts (post-implementation, pre-PR, focused re-review) and drops its child-PR-only section. `deliver-ticket/SKILL.md` names the pair; `scripts/validate-phase-skills.sh` asserts the new prompt file exists.

**Tech Stack:** Markdown skills/prompts (harness-neutral per AGENTS.md Editing Rules — Claude alias + tier name where new prose names tiers), Bash validator scripts. The three repo validators are the regression suite.

**Source of truth:** `docs/specs/2026-07-06-review-pipeline-consolidation-design.md` § Change 1 + its C1 sweep rows. Spec-review notes carried in: anchors are quoted text (pre-C2 numbering is not load-bearing); the unconditional parallel local-CI dispatch wording is preserved for C3.

**Boundary discipline — do NOT touch (sibling-owned):**

- `quality-gate` skill, deliver-ticket's `quality-gate` step, and the `quality-gating` checkpoint — C2 retires them; in this child they stay intact.
- Deliver-ticket step renumbering and the quality-gate→PR seam rename — C2.
- The conditional local-CI predicate — C3. The child-PR local CI runner stays **dispatched in parallel, unconditional**, with the dispatch clause preserved byte-for-byte as C3's anchor.
- `caught-by` output lines in any prompt (including the new one) — C5.
- AGENTS.md tier-table rows and every file not listed in a Task below.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `functions/components/modules` — the five touched files, exercised by the three repo validators (file existence, prompt registration, repo-only-reference hygiene, template integrity) plus `bash -n` on the edited validator.
  - Reason: `<why>` — this is a docs/prose/validator repository; the validators are the executable unit surface and they assert exactly the invariants C1 can break (prompt-file existence, no repo-only references inside `dodi-dev/skills`, script syntax).
  - Minimum assertions: `<specific behaviors>` — all three validators exit 0 after every task; `bash -n scripts/validate-phase-skills.sh` exits 0 after Task 5; the phase-skills validator asserts `review/child-pr-integration-prompt.md` exists (registered in Task 5).

- Integration: `not-required`
  - Scope: `module boundaries/APIs/db/jobs/etc` — n/a.
  - Reason: `<why>` — no executable pipeline exists in this repository; the validators ARE the integration surface (cross-file existence and reference checks across skills, prompts, and scripts).
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a; see the Broader-regression grep battery (Task 5 Step 2) for cross-file text assertions.

- E2E: `not-required`
  - Scope: `user/business-critical flows` — n/a.
  - Reason: `<why>` — live pipeline behavior is exercised by the epic's own delivery: this epic is the e2e, and the child-PR gate this plan rewrites is exercised on this very ticket's PR.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a.

### Critical Flows

- `Child-PR gate walk reads coherently end to end in review/SKILL.md: integration round (opus) ∥ local CI → integration final (fable) → fix loop → focused fable re-round → clean only on a zero-issue fable round, cap 5, exhaustion escalates`
- `review-prompt.md still carries the complete generic checklist for post-implementation / pre-PR / focused re-review, with the two new rows`

### Regression Surface

- `quality-gate skill directory + deliver-ticket step 6 + the quality-gating checkpoint (must survive C1 untouched)`
- `The unconditional parallel local-CI dispatch clause and the contexts-table cell "local CI runs in parallel" (C3's anchors)`
- `Pre-PR loop semantics: opus rounds cap 5 + fable final (unchanged wording)`

### Commands

- Unit: `bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh && bash scripts/validate-ticket-comment-templates.sh` (run from the repo root; each task's Verify runs the relevant subset, Task 5 runs all three)
- Integration: `not-applicable — no executable pipeline; the validators are the integration surface`
- E2E: `not-applicable — exercised live by this epic's own delivery`
- Broader regression: `bash -n scripts/validate-phase-skills.sh` plus the grep battery in Task 5 Step 2 (stale-text negations + preserved-anchor positives, all file-scoped, all exit 0 on success)

### Harness Requirements

- `bash, python3, grep — repo checkout only; no network, no PM access, no env vars`

### Non-Required Rationale

- Unit: n/a (required).
- Integration: `no executable pipeline exists; the three validators are the only cross-file integration surface and run as the Unit group`
- E2E: `the epic's own delivery is the live exercise of the rewritten gate; a desk e2e of prose skills does not exist`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## Tasks

### Task 1: Create the integration-pair prompt

**Files:**
- Create: `dodi-dev/skills/review/child-pr-integration-prompt.md`

- [ ] **Step 1:** Write `dodi-dev/skills/review/child-pr-integration-prompt.md` with exactly this content. Notes: per-round pins carry Claude alias + tier name (AGENTS.md Editing Rules); the admissibility sentence and delta aims are verbatim-faithful to spec § Change 1; the Leaf-discipline block is byte-identical to the sibling `review-prompt.md`'s; **no `caught-by` line (C5 adds it); no repo-only file references** (the phase-skills validator greps for them).

````markdown
# Child-PR Integration Reviewer Prompt Template

Dispatch as a fresh-context subagent at the child-PR gate. The gate is a **delta-scoped integration pair**, both rounds from this template: the **integration round** at Capable tier (`model: opus` on Claude Code) and the **integration final** at Frontier tier (`model: fable` on Claude Code). A post-fix **focused re-round** is a fresh `model: fable` dispatch of this template aimed at the fix delta. The pre-PR full gate owns the generic checklist; these rounds own what is new or changed since it ran.

```
Agent tool (general-purpose, model: opus for the integration round; model: fable for the integration final and any focused re-round):
  description: "Child-PR integration review ([round]) for [ticket]"
  prompt: |
    You are reviewing a child PR against its epic branch. The implementation
    already passed a full-checklist pre-PR review gate; your aim is the delta —
    exactly what is new or changed since that gate. Start fresh — read the
    artifacts and the diff directly; trust nothing you did not verify.

    **Round:** [integration round | integration final | focused re-round (fix delta: [diff range])]
    **Ticket:** [TICKET_ID_AND_SCOPE_SUMMARY]
    **Spec/Plan (with Testing Contract):** [SPEC_AND_PLAN_FILE_PATHS]
    **Project conventions:** [CLAUDE_MD_OR_AGENTS_MD_PATH]
    **PR diff:** [PR_URL_OR_DIFF_RANGE]
    **Pre-PR gate baseline:** [COMMIT_OR_RANGE_THE_PRE_PR_GATE_REVIEWED]

    ## Integration Aims (the delta since the pre-PR gate)

    **Tests** (they did not exist at the pre-PR gate):
    - Quality: vacuous asserts, mocked-out units under test, wrong-branch coverage
    - Coverage against the ticket's Testing Contract

    **Implementation deltas since the pre-PR gate** (verify-stage fixes):
    - Re-check each fix in place: correct, complete, consistent with the reviewed code around it

    **Epic-branch delta:**
    - Interactions with anything merged into the epic branch since the plan/branch point
    - Branch currency: is the child branch current with the epic branch?

    **Unintended behavior changes relative to the ticket scope:**
    - Requires reading the whole PR diff — anything changed that the ticket did not ask for?

    **Docs and operational follow-through** (where behavior shifted after the pre-PR gate):
    - Docs, README, and config samples updated to match
    - Logging, error surfacing, flags, rollout/rollback addressed

    **PR body/evidence sanity:**
    - The PR body matches the actual diff; claimed evidence (commands, exit codes, digests) is plausible and complete

    Read the whole PR diff — the unintended-changes aim requires it. Aim guides
    attention, not admissibility: any defect seen anywhere in the diff is a
    legal finding — these rounds simply do not re-execute the generic checklist
    the pre-PR gate owns.

    ## CRITICAL: Read the actual diff

    Do NOT trust summaries or the PR body. Read the diff. Verify claims against code.

    ## Output

    **Status:** ✅ Approved | ❌ Issues Found

    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]
    - classify each: spec mismatch | implementation | test | security | hygiene | regression risk

    **Required follow-up (epic lane):** fix in-loop, demotion, or blocker

    **Strengths:**
    - [what was done well]
```

- **Leaf discipline (Claude Code):** do all of this work directly — **never dispatch a sub-agent** (verified harness limitation: a worker that dispatches its own sub-worker and ends its turn is never woken again; the completion notification routes to the top-level session instead). Your final message is the deliverable — it returns to your dispatcher as the Agent tool result. End by writing the digest itself; never SendMessage it.
````

- [ ] **Step 2:** Verify

Run (from the repo root):

```bash
test -f dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_A_OK
grep -qF 'Aim guides' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_B_OK
grep -qF 'Capable tier (`model: opus` on Claude Code)' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_C_OK
grep -qF 'Frontier tier (`model: fable` on Claude Code)' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_D_OK
grep -qF 'Leaf discipline (Claude Code)' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_E_OK
! grep -q 'caught-by' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_F_OK
! grep -qE 'docs/specs/2026|docs/plans/2026|templates/ticket-comments' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T1_G_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T1_H_OK
```

Expected: the eight lines `T1_A_OK` … `T1_H_OK`, in order, every command exit 0.

- [ ] **Step 3:** Commit

```bash
git add dodi-dev/skills/review/child-pr-integration-prompt.md
git commit -m "feat: add review/child-pr-integration-prompt.md — delta-scoped integration pair (opus round, fable final)"
```

### Task 2: `review/SKILL.md` — contexts table, per-context process split, +2 checklist rows, pinned rules

**Files:**
- Modify: `dodi-dev/skills/review/SKILL.md` (frontmatter and all untouched sections stay byte-identical)

- [ ] **Step 1:** Update the contexts-table child-PR row. The literal cell text `local CI runs in parallel` is preserved (C3's anchor).

Old:

```markdown
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | Testing Contract coverage; branch currency with the epic branch; local CI runs in parallel |
```

New:

```markdown
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | delta-scoped integration pair — one `opus` integration round + one `fable` integration final (child-pr-integration-prompt.md); Testing Contract coverage; branch currency with the epic branch; local CI runs in parallel |
```

- [ ] **Step 2:** Add the two new What-to-Check rows (spec Change 2 rows 5–6, landed here by Change 1).

Old:

```markdown
| **API contracts** | If touching APIs — are request/response shapes backwards-compatible? |
```

New:

```markdown
| **API contracts** | If touching APIs — are request/response shapes backwards-compatible? |
| **Documentation** | Docs, README, and config samples updated when behavior changes |
| **Operational concerns** | Logging, error surfacing, flags, rollout/rollback |
```

- [ ] **Step 3:** Split the Process section per context. The full loop stays for post-implementation + pre-PR; child-PR becomes the integration pair. The local-CI dispatch clause is preserved byte-for-byte (only the now-redundant lead-in "In the **child-PR context**, " drops, because the sentence now lives inside the child-PR process); it stays **unconditional** — C3 conditionalizes it.

Old:

```markdown
## Process

1. Identify the spec/plan and the diff (`git diff <base>...HEAD`, or the PR diff in the child-PR context).
2. Dispatch the reviewer subagent (see review-prompt.md) with the context named. In the **child-PR context**, dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent.
3. **Review loop** — if the reviewer reports issues, dispatch fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a fresh reviewer. Cap at 5 rounds; if still not clean, stop and escalate with the unresolved findings.
4. **Final round at Frontier tier** — when a round comes back clean, dispatch one last fresh reviewer at `model: fable`. The gate is clean only when this round reports zero issues. If it finds issues, fix them and resume the loop at the per-round tier.
5. On clean:
   - post-implementation → proceed to `dodi-dev:submit`
   - pre-PR → proceed to tests and local readiness
   - child-PR → report `ready-to-merge-child`
```

New:

```markdown
## Process — post-implementation and pre-PR (full gate)

1. Identify the spec/plan and the diff (`git diff <base>...HEAD`).
2. Dispatch the reviewer subagent (see review-prompt.md) with the context named.
3. **Review loop** — if the reviewer reports issues, dispatch fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a fresh reviewer. Cap at 5 rounds; if still not clean, stop and escalate with the unresolved findings.
4. **Final round at Frontier tier** — when a round comes back clean, dispatch one last fresh reviewer at `model: fable`. The gate is clean only when this round reports zero issues. If it finds issues, fix them and resume the loop at the per-round tier.
5. On clean:
   - post-implementation → proceed to `dodi-dev:submit`
   - pre-PR → proceed to tests and local readiness

## Process — child-PR (integration pair)

The pre-PR gate already ran the full checklist; the child-PR gate re-reviews the delta, not the checklist. One **integration round** at Capable tier (`model: opus` on Claude Code) plus one **integration final** at Frontier tier (`model: fable` on Claude Code), both delta-aimed at exactly what is new or changed since the pre-PR gate, both reading the whole PR diff (see child-pr-integration-prompt.md).

1. Identify the ticket, spec, plan (with its Testing Contract), and the PR diff.
2. Dispatch the **integration round** (child-pr-integration-prompt.md, `model: opus`). Dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent.
3. When the integration round is clean, dispatch the **integration final** — a fresh reviewer, same prompt, `model: fable`.
4. **Fix loop** — findings from either round route to fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a **focused `fable` re-round** aimed at the fix delta. Total child-PR rounds cap at 5; cap exhaustion escalates with the unresolved findings — it never merges.
5. The gate is clean only when a `fable` round reports zero issues. On clean, report `ready-to-merge-child`.
```

- [ ] **Step 4:** Pin the focused re-review rule in place (same list position) and add the delta-aim + admissibility rule to Epic Lane Rules.

Old:

```markdown
- Focused re-review is required when production code changes during verification.
```

New:

```markdown
- **Focused re-review** is required when production code changes during verification: a fresh reviewer at Capable tier (`model: opus` on Claude Code) reads the fix delta plus its blast surface (callers/consumers), full checklist (review-prompt.md) scoped to that delta, before the reset seam — a scoped instance of the review fix loop (findings → fix worker → fresh focused round) under the pre-PR loop's cap.
- Child-PR rounds are delta-aimed — exactly what is new or changed since the pre-PR gate — and read the whole PR diff. Aim guides attention, not admissibility: any defect seen anywhere in the diff is a legal finding; the rounds simply do not re-execute the generic checklist the pre-PR gate owns.
```

- [ ] **Step 5:** Verify

Run (from the repo root):

```bash
grep -qF '## Process — post-implementation and pre-PR (full gate)' dodi-dev/skills/review/SKILL.md && echo T2_A_OK
grep -qF '## Process — child-PR (integration pair)' dodi-dev/skills/review/SKILL.md && echo T2_B_OK
grep -qF 'the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent' dodi-dev/skills/review/SKILL.md && echo T2_C_OK
grep -qF 'local CI runs in parallel' dodi-dev/skills/review/SKILL.md && echo T2_D_OK
grep -qF 'Cap at 5 rounds' dodi-dev/skills/review/SKILL.md && echo T2_E_OK
grep -qF 'Total child-PR rounds cap at 5' dodi-dev/skills/review/SKILL.md && echo T2_F_OK
grep -qF 'Aim guides attention, not admissibility' dodi-dev/skills/review/SKILL.md && echo T2_G_OK
grep -qF 'blast surface (callers/consumers)' dodi-dev/skills/review/SKILL.md && echo T2_H_OK
grep -qF '| **Documentation** |' dodi-dev/skills/review/SKILL.md && echo T2_I_OK
grep -qF '| **Operational concerns** |' dodi-dev/skills/review/SKILL.md && echo T2_J_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T2_K_OK
```

Expected: the eleven lines `T2_A_OK` … `T2_K_OK`, in order, every command exit 0.

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills/review/SKILL.md
git commit -m "feat: review per-context process split — child-PR becomes the delta-scoped integration pair; +docs/operational rows; focused re-review pinned"
```

### Task 3: `review/review-prompt.md` — drop the child-PR section, +2 checklist blocks, narrow served contexts

**Files:**
- Modify: `dodi-dev/skills/review/review-prompt.md`

- [ ] **Step 1:** Extend the dispatch header with the served contexts (the prompt no longer serves child-PR).

Old:

```markdown
Dispatch as a fresh-context subagent. Per-round model: `opus` (Capable tier). The final gate round uses `model: fable` (Frontier tier) per the review skill's process.
```

New:

```markdown
Dispatch as a fresh-context subagent. Per-round model: `opus` (Capable tier). The final gate round uses `model: fable` (Frontier tier) per the review skill's process. Serves the post-implementation and pre-PR contexts, plus the focused re-review (changed-files input = the verify-stage fix delta and its blast surface; full checklist scoped to that delta). The child-PR gate uses child-pr-integration-prompt.md instead.
```

- [ ] **Step 2:** Update the context bracket inside the template (4-space indent preserved).

Old:

```markdown
    **Review context:** [post-implementation | pre-PR | child-PR]
```

New:

```markdown
    **Review context:** [post-implementation | pre-PR | focused re-review]
```

- [ ] **Step 3:** Drop the child-PR-only section and add the two new checklist blocks in its place (4-space indent preserved; the dropped aims live in child-pr-integration-prompt.md now).

Old:

```markdown
    **API contracts (if applicable):**
    - Request/response shapes backwards-compatible?
    - New fields optional or defaulted?

    ## Additional checks in the child-PR context only

    - Test coverage relative to the ticket's Testing Contract
    - Whether the child branch is current with the epic branch
    - Unintended behavior changes relative to the ticket scope

    ## CRITICAL: Read the actual code
```

New:

```markdown
    **API contracts (if applicable):**
    - Request/response shapes backwards-compatible?
    - New fields optional or defaulted?

    **Documentation:**
    - Docs, README, and config samples updated when behavior changes?

    **Operational concerns:**
    - Logging, error surfacing, flags, rollout/rollback handled where behavior shifts?

    ## CRITICAL: Read the actual code
```

- [ ] **Step 4:** Verify

Run (from the repo root):

```bash
! grep -q 'Additional checks in the child-PR context only' dodi-dev/skills/review/review-prompt.md && echo T3_A_OK
grep -qF '**Review context:** [post-implementation | pre-PR | focused re-review]' dodi-dev/skills/review/review-prompt.md && echo T3_B_OK
grep -qF '**Documentation:**' dodi-dev/skills/review/review-prompt.md && echo T3_C_OK
grep -qF '**Operational concerns:**' dodi-dev/skills/review/review-prompt.md && echo T3_D_OK
grep -qF 'The child-PR gate uses child-pr-integration-prompt.md instead.' dodi-dev/skills/review/review-prompt.md && echo T3_E_OK
grep -qF 'Leaf discipline (Claude Code)' dodi-dev/skills/review/review-prompt.md && echo T3_F_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T3_G_OK
```

Expected: the seven lines `T3_A_OK` … `T3_G_OK`, in order, every command exit 0.

- [ ] **Step 5:** Commit

```bash
git add dodi-dev/skills/review/review-prompt.md
git commit -m "feat: review-prompt serves full-gate contexts only — drop child-PR section, add docs/operational checklist rows"
```

### Task 4: `deliver-ticket/SKILL.md` — reviewer-tier parenthetical split + integration-pair step wording

**Files:**
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md` (step numbering, the `quality-gate` step, the checkpoint list, and the Context Hygiene seam wording all stay byte-identical — C2 owns them)

- [ ] **Step 1:** Split the reviewer-tier parenthetical by context in the Internal Sequence intro.

Old:

```markdown
fresh-context reviewers with `opus` rounds and a `fable` final round; `haiku` test runners):
```

New:

```markdown
fresh-context reviewers — pre-PR: `opus` rounds with a `fable` final; child-PR: one `opus` integration round + a `fable` integration final; `haiku` test runners):
```

- [ ] **Step 2:** Reword the child-PR review step to name the integration pair, keeping the current step number and the unconditional parallel local-CI wording. Anchor by the quoted text (the leading `9. ` is intentionally not part of the anchor).

Old:

```markdown
`review` (child-PR context) — PR reviewer and local CI runner in parallel.
```

New:

```markdown
`review` (child-PR context) — the delta-scoped integration pair (one `opus` integration round + a `fable` integration final per `review/child-pr-integration-prompt.md`) and the local CI runner in parallel.
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
grep -qF 'pre-PR: `opus` rounds with a `fable` final; child-PR: one `opus` integration round + a `fable` integration final' dodi-dev/skills/deliver-ticket/SKILL.md && echo T4_A_OK
grep -qF 'and the local CI runner in parallel.' dodi-dev/skills/deliver-ticket/SKILL.md && echo T4_B_OK
grep -qF '`quality-gate` — horizontal checks with command evidence.' dodi-dev/skills/deliver-ticket/SKILL.md && echo T4_C_OK
grep -qF '`quality-gating`' dodi-dev/skills/deliver-ticket/SKILL.md && echo T4_D_OK
grep -qF 'quality-gate→PR seam' dodi-dev/skills/deliver-ticket/SKILL.md && echo T4_E_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T4_F_OK
```

Expected: the six lines `T4_A_OK` … `T4_F_OK`, in order, every command exit 0. (`T4_C_OK`/`T4_D_OK`/`T4_E_OK` prove quality-gate and the seam survive this child untouched.)

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/deliver-ticket/SKILL.md
git commit -m "feat: deliver-ticket names the child-PR integration pair; reviewer tier parenthetical split by context"
```

### Task 5: Register the new prompt in the validator + full regression pass

**Files:**
- Modify: `scripts/validate-phase-skills.sh` (only the `prompt_files` list — the `skills` array, incl. `quality-gate`, stays byte-identical)

- [ ] **Step 1:** Add the new prompt to `prompt_files`, directly after the sibling review prompt (two-space indent preserved).

Old:

```bash
  review/review-prompt.md
  write-plan/plan-reviewer-prompt.md
```

New:

```bash
  review/review-prompt.md
  review/child-pr-integration-prompt.md
  write-plan/plan-reviewer-prompt.md
```

- [ ] **Step 2:** Verify — full Testing Contract (Unit group + Broader-regression grep battery)

Run (from the repo root):

```bash
bash -n scripts/validate-phase-skills.sh && echo T5_A_OK
grep -qF 'review/child-pr-integration-prompt.md' scripts/validate-phase-skills.sh && echo T5_B_OK
bash scripts/validate-plugin-metadata.sh
bash scripts/validate-phase-skills.sh > /dev/null && echo T5_C_OK
bash scripts/validate-ticket-comment-templates.sh
! grep -q 'Additional checks in the child-PR context only' dodi-dev/skills/review/review-prompt.md && echo T5_D_OK
! grep -qE 'docs/specs/2026|docs/plans/2026|templates/ticket-comments' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T5_E_OK
! grep -q 'caught-by' dodi-dev/skills/review/child-pr-integration-prompt.md && echo T5_F_OK
grep -qF 'local CI runs in parallel' dodi-dev/skills/review/SKILL.md && echo T5_G_OK
test -f dodi-dev/skills/quality-gate/SKILL.md && echo T5_H_OK
```

Expected, in order, every command exit 0:

```
T5_A_OK
T5_B_OK
plugin metadata ok: 0.14.2
T5_C_OK
ticket comment templates ok
T5_D_OK
T5_E_OK
T5_F_OK
T5_G_OK
T5_H_OK
```

(If a sibling change already bumped the plugin version on the epic branch, the `plugin metadata ok:` version differs; the load-bearing assertion is exit 0.)

- [ ] **Step 3:** Commit

```bash
git add scripts/validate-phase-skills.sh
git commit -m "chore: validate-phase-skills asserts review/child-pr-integration-prompt.md exists"
```

---

## Notes for the executor

- Verify-command hygiene: every command above exits 0 on success (negations use `! grep -q`, never bare `grep -c`/`grep -L`). No negation pattern in this plan appears in any New-text block it is scoped against.
- The `## Process` header is replaced by two `## Process — …` headers; no other file in `dodi-dev/skills` links to the old header text (prose references say "the review skill's process", which stays true).
- If any Old anchor fails to match byte-exactly, stop and re-read the target file — a sibling child may have landed out of order; report the mismatch instead of adapting the edit.
