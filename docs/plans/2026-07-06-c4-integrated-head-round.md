# C4: Integrated-Head Epic Round (Change 2 epic-level) — Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute tasks in order (1→5). Each task ends with its own Verify (all commands must exit 0) and its own local commit; every task leaves the phase-skills validator green, Task 3 lands the template heading and its validator assertion atomically (one commit), and Task 5 closes with all three repo validators plus the full grep battery. All Old-text anchors below are byte-exact from the epic branch @ `0afc96a` (C1+C2+C3 merged); **anchor by the quoted text, never by step or line number** (line numbers in this plan are hints — sibling children renumber). If an Old anchor does not match exactly, STOP and re-read the file — never fuzzy-match or approximate.

**Goal:** Replace `submit-epic-pr`'s "Run epic-level `quality-gate`" step with the **integrated-head review round** — the re-homed epic-level horizontal pass, per the v7 attempt lifecycle: loop round → mechanical fixes → fresh round to clean **before** the full-regression gate, freeze the head at the recorded reviewed SHA, regression on that same SHA, SHA-equality immediately before push/PR-create — and sweep every consumer surface (template heading + validator, state-transitions epic row, sole-writer glosses, Capable-tier row), retiring the last C4-owned quality-gate wording (spec § Change 2 epic row + sweep rows; scope = GitHub issue #6 as amended).

**Architecture:** The round lives where the epic PR is made — `submit-epic-pr` — as a bounded per-attempt loop: a fresh reviewer at Capable tier (`model: opus` on Claude Code) per round via the **new** `submit-epic-pr/epic-integration-reviewer-prompt.md` (all six horizontal classes at cross-child scope against **Gate 1 as amended by the register canon**, plus contract seams; required per-finding mechanical-vs-judgment classification, fail-closed to judgment). Mechanical findings (no runtime-behavior effect) are fixed by Standard-tier fix workers writing in the epic worktree under the session walking the skill (single-writer — the same writer as the merge slot) and re-reviewed by a fresh round; judgment findings route as corrective child tickets and stop the attempt (epic lands `epic-active` via the not-done child); cap semantics are the `review` skill's loop (cap 5; exhaustion ⇒ `blocked` + escalation, never opens the PR). The clean round records the reviewed head SHA; the head is frozen for the attempt; regression runs on that SHA; the three-way SHA equality (reviewed = regression = PR head) is evaluated immediately before push/PR-create; head movement restarts the attempt at the review round; re-entry after a stop is a new attempt, with SHA-keyed crash-successor idempotence; clean-tree check at attempt start. The coherence-audit bypass on the mechanical path is by design and stated in the step.

**Tech Stack:** Markdown skills (harness-neutral per AGENTS.md Editing Rules), Bash validator scripts. The three repo validators are the regression suite.

**Source of truth:** `docs/specs/2026-07-06-review-pipeline-consolidation-design.md` § Change 2 epic-level row (coverage table, last row) + the C4 reference-sweep rows + the hardening-log **plan-phase pins** (log header: SHA-equality timing immediately before push/PR-create; stop landing states — judgment-corrective ⇒ epic-active via the not-done child, cap exhaustion ⇒ blocked + escalation; clean-tree check at attempt start; re-entry idempotence — a crash successor with evidence current-with-head may complete the attempt, else re-round; validators assert prompt existence, not dispatch-wiring); GitHub issue #6 body **as amended** (prompt born WITHOUT a caught-by line per [S1] — C5 adds it; writer-discipline clause explicit); epic canon (#3 § Decision Register — Canon): [C2-c] (the survivor set this child consumes — text anchors govern), [S1], [C3-c] (this lane runs under installed 0.14.2; these edits are branch-text law until the 0.15.0 release applies).

**File surface (eight files — one create, seven modify):** Create `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md`. Modify `dodi-dev/skills/submit-epic-pr/SKILL.md` (4 hunks: steps 2–4 block, step 6, evidence line, stop condition), `scripts/validate-phase-skills.sh` (prompt_files +1), `templates/ticket-comments/epic-pr-ready.md` (heading + coverage line), `scripts/validate-ticket-comment-templates.sh` (one heading assertion), `dodi-dev/skills/epic-orchestrator/state-transitions.md` (epic-table row only), `dodi-dev/skills/drive-epic/SKILL.md` (sole-writer clause only), `AGENTS.md` (Capable row + layering rule). No metadata changes (C5 owns the 0.15.0 bump).

**Boundary discipline — do NOT touch (sibling-owned or out of scope):**

- `dodi-dev/skills/review/`, `verify/`, `submit-ticket-pr/`, `deliver-ticket/`, `pickup-next/`, `reconcile-tickets/` — zero diff vs `0afc96a` (Task 5 battery asserts the full changed-file set).
- `epic-orchestrator/` — only `state-transitions.md`, and only the epic-table row: the resume-mapping line keeps its legacy `quality-gating` token (C2's, **permanent** — the one quality-gat line that survives this child) and the [C2-b] backstop parenthetical; the Child-Ticket table, Lane Checkpoint table, and all other rows stay byte-identical.
- `submit-epic-pr/SKILL.md` outside the four hunks — the Why section, Inputs, step 1, step 5 (readiness summary), steps 7–9, the Commands block (its regression comment stays true post-reorder), and Rules lines other than the one stop condition stay byte-identical.
- `caught-by` lines anywhere — C5's ([S1]); none of this plan's New text carries the tag, and the new prompt is born without one.
- AGENTS.md outside lines 28/88 — the Frontier row, the tier-diversity doctrine sentence (line 35 adjacency is a C5 plan-phase note), the Dispatch Discipline section: byte-identical.
- Plugin metadata (three files) — no version bump in C4.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `functions/components/modules` — the seven modified files plus the created prompt, exercised by the three repo validators (skill/prompt file existence incl. the NEW prompt in `prompt_files`, repo-only-reference hygiene, template heading integrity incl. the RENAMED heading assertion).
  - Reason: `<why>` — this is a docs/prose/validator repository; the validators are the executable unit surface, and this child moves a validator-asserted heading — the template rename and the line-100 assertion edit must co-land in the same task (Task 3, atomic) or the templates validator goes red between commits.
  - Minimum assertions: `<specific behaviors>` — `validate-phase-skills.sh` exits 0 after every task (1–5); `validate-ticket-comment-templates.sh` exits 0 at the Task 3 boundary and in Task 5; all three validators exit 0 in Task 5.

- Integration: `not-required`
  - Scope: `module boundaries/APIs/db/jobs/etc` — n/a.
  - Reason: `<why>` — no executable pipeline exists in this repository; the validators ARE the integration surface (cross-file existence and reference checks). Same rationale class as C1/C2/C3.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a; see the Broader-regression battery (Task 5 Step 5) for cross-file text assertions.

- E2E: `not-required`
  - Scope: `user/business-critical flows` — n/a.
  - Reason: `<why>` — prose-skill behavior has no desk harness; the live exercise arrives with the 0.15.0 release — this epic's own PR is walked under installed 0.14.2 rules per canon [G1]/[C3-c]. Same rationale class as C1/C2/C3.
  - Harness: `not-applicable`
  - Minimum assertions: `<specific flows>` — n/a.

### Critical Flows

- `Epic-PR attempt lifecycle: children done → attempt start (clean-tree check; takeover-orphaned fix worker guard) → sync → integrated-head review loop to clean (fresh opus round each time; sonnet mechanical fixes under the walking session; cap 5) → clean round records reviewed head SHA, head frozen → full regression on that same SHA → summary → SHA-equality (reviewed = regression = PR head) immediately before push/PR-create → push → PR`
- `Judgment finding (runtime behavior — flags, contracts, data shapes; when in doubt ⇒ judgment): corrective child ticket through the normal pipeline + stop — epic lands epic-active via the not-done child; never fixed in place`
- `Cap exhaustion: stop + escalate with unresolved findings — epic lands blocked; the PR is never opened over unresolved findings`
- `Head movement after the clean round (late sync, conflict fix, corrective child merged): restart the attempt at the review round; re-entry after a stop = new attempt; a crash successor whose recorded clean-round evidence still equals the current epic head completes the attempt (SHA-keyed skip-what-exists), else re-rounds`
- `Coherence-audit bypass (mechanical path) is by design and stated: audit domain = merged child PRs; judgment forced through that domain; every mechanical commit re-reviewed by the fresh clean round before the freeze`

### Regression Surface

- `The [C2-c] survivor set flips to its end state: ZERO quality-gat lines repo-wide (ship surfaces) except state-transitions' resume-mapping legacy token — exact counts submit-epic-pr 0, state-transitions 1, validator 0, epic-pr-ready 0`
- `submit-epic-pr survivors: Gate-2 rules (never merge), regression hard-gate prose, steps 1/5/7/8/9, Commands block, sync-conflict and PR-failure stop conditions — byte-identical`
- `state-transitions: every row except the epic-table epic-ready-for-pr row — byte-identical (incl. ready-for-child-pr row, lane-exit row, resume mapping, coherence-pending row)`
- `epic-pr-ready: all other headings (validator-asserted set) and the What Changed Since Signoff section — byte-identical`
- `review/child-pr-integration-prompt.md — untouched; its leaf-discipline line must remain byte-identical to the new prompt's (cross-file equality asserted)`
- `AGENTS.md: Frontier/Standard/Fast rows, doctrine bullet, Dispatch Discipline — byte-identical outside the two C4 hunks`

### Commands

- Unit: `bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh && bash scripts/validate-ticket-comment-templates.sh` (from the repo root; Tasks 1–4 run phase-skills at each boundary, Task 3 also runs the templates validator, Task 5 runs all three)
- Integration: `not-applicable — no executable pipeline; the validators are the integration surface`
- E2E: `not-applicable — live exercise arrives with the 0.15.0 release; this epic runs under installed 0.14.2 per canon [G1]/[C3-c]`
- Broader regression: the Task 5 Step 5 battery — survivor flip asserted precisely (file list + per-file counts), new heading present in template + validator, prompt-file existence + validator registration + no caught-by, cross-file gloss equality, per-file hunk counts, full changed-file-set equality vs `0afc96a`; every command exits 0 on success.

### Harness Requirements

- `bash, python3, grep, git — repo checkout only; no network, no PM access, no env vars`

### Non-Required Rationale

- Unit: n/a (required).
- Integration: `no executable pipeline exists; the three validators are the only cross-file integration surface and run as the Unit group (same rationale class as C1/C2/C3)`
- E2E: `no desk e2e of prose skills exists; live behavior lands at the 0.15.0 release — this epic dogfoods 0.14.2 per canon [G1]/[C3-c] (same rationale class as C1/C2/C3)`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

**Survivor-set flip (before → after C4; asserted in Task 5):**

| File | `quality`-`gat` lines @ 0afc96a | after C4 |
| --- | --- | --- |
| `dodi-dev/skills/submit-epic-pr/SKILL.md` | 3 | **0** |
| `dodi-dev/skills/epic-orchestrator/state-transitions.md` | 2 | **1** — only the resume-mapping legacy `quality-gating` token (C2's, permanent) |
| `scripts/validate-ticket-comment-templates.sh` | 1 | **0** |
| `templates/ticket-comments/epic-pr-ready.md` | 1 | **0** |

---

## Tasks

### Task 1: NEW `submit-epic-pr/epic-integration-reviewer-prompt.md` + validator registration (atomic)

**Files:**
- Create: `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` (81 lines)
- Modify: `scripts/validate-phase-skills.sh` (prompt_files array, one added line)

- [ ] **Step 1:** Create the prompt file with EXACTLY this content, by running this heredoc from the repo root (the heredoc IS the byte pin — do not retype the content through an editor tool; the quoted delimiter suppresses all expansion). The file mirrors `review/child-pr-integration-prompt.md`'s structure; the admissibility sentence's core clause is mirrored verbatim, the leaf-discipline line is byte-identical to the sibling's, and the file carries **no caught-by line** ([S1] — C5 adds it) and no repo-only references.

````bash
cat > dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md <<'EOF_PROMPT'
# Epic Integration Reviewer Prompt Template

Dispatch as a fresh-context subagent per round of the **integrated-head review loop** in `submit-epic-pr`, at Capable tier (`model: opus` on Claude Code) — a fresh reviewer every round, never a reused one. The per-child gates already reviewed each child individually at its own merge time; this round owns what only the integrated head can show: the six horizontal classes at cross-child scope, plus the contract seams between children. Mechanical findings are fixed in-loop by the walking session's fix workers and re-reviewed by a fresh round; judgment findings stop the epic PR (see `submit-epic-pr/SKILL.md`).

```
Agent tool (general-purpose, model: opus):
  description: "Integrated-head epic review (round [N]) for [epic]"
  prompt: |
    You are reviewing the integrated head of an epic branch before its epic PR
    opens. Every merged child PR already passed its own review gates; your aim
    is what only the integration can show — defects arising from the children's
    interaction, and divergence from the approved design as legitimately
    amended. Start fresh — read the artifacts and the diff directly; trust
    nothing you did not verify.

    **Round:** [N — rounds count within this epic-PR attempt]
    **Epic:** [EPIC_ID_AND_SCOPE_SUMMARY]
    **Post-sync epic diff vs base:** [BASE_BRANCH...EPIC_HEAD_DIFF_RANGE]
    **Epic design artifact:** [EPIC_DESIGN_ARTIFACT_PATH]
    **Gate 1 package:** [GATE1_PACKAGE_LINK_OR_TEXT]
    **Decision-register canon:** [CANON_SUMMARY_PLUS_REGISTER_ENTRIES]
    **Project conventions:** [CLAUDE_MD_OR_AGENTS_MD_PATH]

    ## Aims (all six horizontal classes, at cross-child scope)

    **Implementation compliance — against Gate 1 as amended by the canon:**
    - The integrated result implements what Gate 1 approved, as legitimately
      evolved by the decision register. **Un-canonized divergence is the
      finding; canonized divergence is not** — read the canon summary and
      register entries before flagging any divergence.

    **Security — arising from the interaction of children:**
    - Injection, auth bypass, data leaks that the combination introduces
      (each child was individually clean at its own gate)

    **Code hygiene — on the integrated result:**
    - Duplication across children, dead code a later child orphaned,
      convention drift no per-child gate could see

    **Regression risk — from the children's interaction:**
    - One child breaking assumptions another child's code relies on; risks
      introduced by the latest base sync

    **Docs coherence — across children:**
    - Docs, README, and config samples consistent with the union of the
      children's changes, not just each child's own slice

    **Operational interactions:**
    - Logging, error surfacing, flags, rollout/rollback coherent across
      children — e.g. a flag one child adds and another disables

    **Contract seams between children:**
    - Every interface where one child produces what another consumes:
      shapes, invariants, ordering, error paths

    Read the whole integrated diff — the cross-child aims require it. Aim
    guides attention, not admissibility: any defect seen anywhere in the diff
    is a legal finding — this round simply does not re-execute the generic
    checklists the per-child gates own.

    ## CRITICAL: Read the actual diff

    Do NOT trust summaries, the design artifact, or prior review verdicts.
    Read the diff. Verify claims against code.

    ## Output

    **Status:** ✅ Approved | ❌ Issues Found

    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]
    - classify each: implementation compliance | security | hygiene | regression risk | docs | operational | contract seam
    - **also classify each finding `mechanical` or `judgment` (required):** mechanical ≡ **no runtime-behavior effect** (docs, config samples, comments, formatting/hygiene); anything touching **runtime behavior** — flags, contracts, data shapes — is **judgment**; **when in doubt ⇒ judgment**

    **Required follow-up:** mechanical ⇒ fix in-loop (the walking session's fix workers) + fresh round; judgment ⇒ corrective child ticket + stop — never fixed in place

    **Strengths:**
    - [what was done well]
```

- **Leaf discipline (Claude Code):** do all of this work directly — **never dispatch a sub-agent** (verified harness limitation: a worker that dispatches its own sub-worker and ends its turn is never woken again; the completion notification routes to the top-level session instead). Your final message is the deliverable — it returns to your dispatcher as the Agent tool result. End by writing the digest itself; never SendMessage it.
EOF_PROMPT
````

- [ ] **Step 2:** Register the prompt in the phase-skills validator (the two-line Old block is unique — it is the prompt_files array's tail).

Old:

```bash
  submit-ticket-pr/local-ci-runner-prompt.md
)
```

New:

```bash
  submit-ticket-pr/local-ci-runner-prompt.md
  submit-epic-pr/epic-integration-reviewer-prompt.md
)
```

- [ ] **Step 3:** Verify

Run (from the repo root):

```bash
test -f dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_A_OK
test "$(wc -l < dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md | tr -d ' ')" = "81" && echo T1_B_OK
grep -qF 'at Capable tier (`model: opus` on Claude Code) — a fresh reviewer every round, never a reused one' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_C_OK
grep -qF 'Agent tool (general-purpose, model: opus):' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_D_OK
grep -qF '**Round:** [N — rounds count within this epic-PR attempt]' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_E_OK
grep -qF '**Decision-register canon:** [CANON_SUMMARY_PLUS_REGISTER_ENTRIES]' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_F_OK
grep -qF '**Implementation compliance — against Gate 1 as amended by the canon:**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_G_OK
grep -qF 'finding; canonized divergence is not' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_H_OK
grep -qF '**Security — arising from the interaction of children:**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_I_OK
grep -qF '**Code hygiene — on the integrated result:**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_J_OK
grep -qF "**Regression risk — from the children's interaction:**" dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_K_OK
grep -qF '**Docs coherence — across children:**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_L_OK
grep -qF '**Operational interactions:**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_M_OK
grep -qF '**Contract seams between children:**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_N_OK
grep -qF 'guides attention, not admissibility: any defect seen anywhere in the diff' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_O_OK
grep -qF 'mechanical ≡ **no runtime-behavior effect**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_P_OK
grep -qF 'is **judgment**; **when in doubt ⇒ judgment**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_Q_OK
grep -qF 'judgment ⇒ corrective child ticket + stop — never fixed in place' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_R_OK
test "$(grep -F '**Leaf discipline (Claude Code):**' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md)" = "$(grep -F '**Leaf discipline (Claude Code):**' dodi-dev/skills/review/child-pr-integration-prompt.md)" && echo T1_S_OK
! grep -qi 'caught-by' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T1_T_OK
grep -qF '  submit-epic-pr/epic-integration-reviewer-prompt.md' scripts/validate-phase-skills.sh && echo T1_U_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T1_V_OK
```

Expected: the twenty-two lines `T1_A_OK` … `T1_V_OK`, in order, every command exit 0. (`T1_B_OK` pins the byte-exact creation at 81 lines; `T1_S_OK` proves the leaf-discipline line is byte-identical to the sibling prompt's; `T1_T_OK` proves the prompt is born without a caught-by line per [S1]; `T1_V_OK` proves the validator is green with the new prompt_files entry asserting the file it now requires — validators assert prompt existence, not dispatch-wiring, per the pre-existing posture. The validator's repo-only-reference grep also runs here, proving the new prompt carries none.)

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md scripts/validate-phase-skills.sh
git commit -m "feat: epic-integration reviewer prompt — six horizontal classes vs Gate-1-as-amended-by-canon, mechanical/judgment razor fail-closed, opus pin; registered in phase-skills validator"
```

### Task 2: `submit-epic-pr/SKILL.md` — the integrated-head review round (v7 attempt lifecycle)

**Files:**
- Modify: `dodi-dev/skills/submit-epic-pr/SKILL.md` (exactly 4 hunks: Process steps 2–4 block, line ~31; Process step 6, line ~35; one Expected-evidence item, line ~59; one Rules stop condition, line ~71. Everything else — Why section, Inputs, steps 1/5/7/8/9, Commands block, all other Rules — stays byte-identical)

- [ ] **Step 1:** Replace the Process steps 2–4 block (sync / regression / quality-gate) with the attempt-start + review-round + frozen-head-regression sequence. The three Old lines are consecutive.

Old:

```markdown
2. Update the epic branch with the latest main/master.
3. Run `verify` as a full regression suite on the integrated epic head: all required unit, integration, and e2e groups across the merged children — the union of child Testing Contracts — must pass. Dispatch one test-runner worker per group (see `verify/test-runner-prompt.md`) and claim results only from the returned digests (commands + exit codes). This is a hard gate. Do not proceed if any required group fails or a required harness cannot be set up.
4. Run epic-level `quality-gate`.
```

New:

```markdown
2. **Attempt start.** Everything from here through PR creation is one **epic-PR attempt**; re-entry after any stop begins a new attempt here (a crash successor with still-current clean-round evidence may instead complete the in-flight attempt — step 3). **Clean-tree check:** `git status --porcelain` in the epic worktree must come back empty before anything else — a takeover-orphaned fix worker may have left uncommitted writes; stop and escalate on an unexplained dirty tree, never commit or discard it blindly. Then update the epic branch with the latest main/master.
3. **Integrated-head review round — loop to clean, before the regression gate.** Dispatch a fresh reviewer at Capable tier (`model: opus` on Claude Code) per round (see `epic-integration-reviewer-prompt.md`), reading the post-sync epic diff vs base, the epic design artifact, the Gate 1 package, and the decision-register canon summary + entries. The reviewer classifies every finding **mechanical** or **judgment**: mechanical ≡ **no runtime-behavior effect** (docs, config samples, comments, formatting/hygiene); anything touching **runtime behavior** — flags, contracts, data shapes — is judgment; **when in doubt ⇒ judgment**. Mechanical findings route to fix workers at Standard tier (`model: sonnet` on Claude Code) writing in the epic worktree under the session walking this skill (single-writer discipline — the same writer as the merge slot), then a **fresh round** re-reviews; loop until a round is clean, with the same cap semantics as the `review` skill's loop (cap 5 rounds; cap exhaustion stops and escalates with the unresolved findings — it **never opens the PR**; the epic lands `blocked`). A **judgment** finding is never fixed in place: file a corrective child ticket through the normal pipeline (its own review gates + coherence registration), stop this attempt, and return the epic to `epic-active` via the not-done child. The clean round's evidence records the **reviewed head SHA**; the head is then **frozen for the attempt** — any head movement after the clean round (late sync, conflict fix, corrective child merged) restarts the attempt at this step. Re-entry after a stop is a **new attempt** with a new round; a crash successor whose recorded clean-round evidence is still current with the head (recorded reviewed SHA = current epic head) may complete the attempt from the recorded state instead (SHA-keyed skip-what-exists), else it re-rounds. (The mechanical-fix path bypasses the coherence set-difference audit **by design**: that audit's domain is merged child PRs; judgment — the decision-bearing class — is forced through that domain as a corrective child, and every mechanical commit is re-reviewed by the fresh clean round before the freeze.)
4. Run `verify` as a full regression suite on the integrated epic head — **the frozen head at the reviewed SHA the clean round recorded**: all required unit, integration, and e2e groups across the merged children — the union of child Testing Contracts — must pass. Dispatch one test-runner worker per group (see `verify/test-runner-prompt.md`) and claim results only from the returned digests (commands + exit codes). This is a hard gate. Do not proceed if any required group fails or a required harness cannot be set up.
```

- [ ] **Step 2:** Replace Process step 6 (push) with the SHA-equality-guarded push.

Old:

```markdown
6. Push the epic branch.
```

New:

```markdown
6. **SHA-equality check — evaluated immediately before push/PR-create:** the clean round's reviewed head SHA = the SHA the regression suite ran against = the current epic head (the PR head). Any mismatch means the head moved after the clean round: do not push — restart the attempt at step 3 (the review round). Then push the epic branch.
```

- [ ] **Step 3:** Replace the Expected-evidence item.

Old:

```markdown
- epic quality-gate evidence
```

New:

```markdown
- integrated-head review evidence incl. reviewed head SHA
```

- [ ] **Step 4:** Replace the quality-gate stop condition in Rules.

Old:

```markdown
- Stop if epic-level `quality-gate` fails.
```

New:

```markdown
- Stop on unresolved integrated-head review findings: a **judgment** finding stops the attempt with its corrective child ticket filed (the epic returns to `epic-active` via the not-done child); review-loop cap exhaustion stops as `blocked` + escalation. Never open the PR over unresolved findings.
```

- [ ] **Step 5:** Verify

Run (from the repo root):

```bash
grep -qF '**Attempt start.**' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_A_OK
grep -qF 'git status --porcelain' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_B_OK
grep -qF 'takeover-orphaned fix worker' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_C_OK
grep -qF '**Integrated-head review round — loop to clean, before the regression gate.**' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_D_OK
grep -qF '(see `epic-integration-reviewer-prompt.md`)' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_E_OK
grep -qF 'the same writer as the merge slot' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_F_OK
grep -qF 'it **never opens the PR**; the epic lands `blocked`' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_G_OK
grep -qF 'return the epic to `epic-active` via the not-done child' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_H_OK
grep -qF 'frozen for the attempt' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_I_OK
grep -qF 'restarts the attempt at this step' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_J_OK
grep -qF 'SHA-keyed skip-what-exists' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_K_OK
grep -qF 'set-difference audit **by design**' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_L_OK
grep -qF 'the frozen head at the reviewed SHA the clean round recorded' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_M_OK
grep -qF '**SHA-equality check — evaluated immediately before push/PR-create:**' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_N_OK
grep -qF -- '- integrated-head review evidence incl. reviewed head SHA' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_O_OK
grep -qF -- '- Stop on unresolved integrated-head review findings' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_P_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/submit-epic-pr/SKILL.md)" = "0" && echo T2_Q_OK
grep -qF '5. Prepare the epic readiness summary.' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_R_OK
grep -qF '# Full regression on the integrated epic head, via `verify`, before pushing.' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_S_OK
grep -qF -- '- Stop if syncing latest main/master introduces conflicts or required fixes; return the epic to `epic-active`.' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T2_T_OK
test "$(git diff --unified=0 0afc96a -- dodi-dev/skills/submit-epic-pr/SKILL.md | grep -c '^@@')" = "4" && echo T2_U_OK
# Full-block pin: the entire New steps 2–4 block must be present byte-exact (closes the retype-corruption gap the token greps cannot). Heredoc is literal (<<'PATN' — no backtick/$ expansion); grep -Ff counts file lines matching any pattern line — each of the three pattern lines matches exactly its own file line.
PATN4="$(mktemp)"; cat > "$PATN4" <<'PATN'
2. **Attempt start.** Everything from here through PR creation is one **epic-PR attempt**; re-entry after any stop begins a new attempt here (a crash successor with still-current clean-round evidence may instead complete the in-flight attempt — step 3). **Clean-tree check:** `git status --porcelain` in the epic worktree must come back empty before anything else — a takeover-orphaned fix worker may have left uncommitted writes; stop and escalate on an unexplained dirty tree, never commit or discard it blindly. Then update the epic branch with the latest main/master.
3. **Integrated-head review round — loop to clean, before the regression gate.** Dispatch a fresh reviewer at Capable tier (`model: opus` on Claude Code) per round (see `epic-integration-reviewer-prompt.md`), reading the post-sync epic diff vs base, the epic design artifact, the Gate 1 package, and the decision-register canon summary + entries. The reviewer classifies every finding **mechanical** or **judgment**: mechanical ≡ **no runtime-behavior effect** (docs, config samples, comments, formatting/hygiene); anything touching **runtime behavior** — flags, contracts, data shapes — is judgment; **when in doubt ⇒ judgment**. Mechanical findings route to fix workers at Standard tier (`model: sonnet` on Claude Code) writing in the epic worktree under the session walking this skill (single-writer discipline — the same writer as the merge slot), then a **fresh round** re-reviews; loop until a round is clean, with the same cap semantics as the `review` skill's loop (cap 5 rounds; cap exhaustion stops and escalates with the unresolved findings — it **never opens the PR**; the epic lands `blocked`). A **judgment** finding is never fixed in place: file a corrective child ticket through the normal pipeline (its own review gates + coherence registration), stop this attempt, and return the epic to `epic-active` via the not-done child. The clean round's evidence records the **reviewed head SHA**; the head is then **frozen for the attempt** — any head movement after the clean round (late sync, conflict fix, corrective child merged) restarts the attempt at this step. Re-entry after a stop is a **new attempt** with a new round; a crash successor whose recorded clean-round evidence is still current with the head (recorded reviewed SHA = current epic head) may complete the attempt from the recorded state instead (SHA-keyed skip-what-exists), else it re-rounds. (The mechanical-fix path bypasses the coherence set-difference audit **by design**: that audit's domain is merged child PRs; judgment — the decision-bearing class — is forced through that domain as a corrective child, and every mechanical commit is re-reviewed by the fresh clean round before the freeze.)
4. Run `verify` as a full regression suite on the integrated epic head — **the frozen head at the reviewed SHA the clean round recorded**: all required unit, integration, and e2e groups across the merged children — the union of child Testing Contracts — must pass. Dispatch one test-runner worker per group (see `verify/test-runner-prompt.md`) and claim results only from the returned digests (commands + exit codes). This is a hard gate. Do not proceed if any required group fails or a required harness cannot be set up.
PATN
grep -cFf "$PATN4" dodi-dev/skills/submit-epic-pr/SKILL.md | grep -qx 3 && echo T2_V_OK; rm -f "$PATN4"
bash scripts/validate-phase-skills.sh > /dev/null && echo T2_W_OK
```

Expected: the twenty-three lines `T2_A_OK` … `T2_W_OK`, in order (validator last), every command exit 0. (`T2_Q_OK` proves this file's three quality-gate lines are gone — no New text in this plan contains a `quality`-`gat` string; `T2_R_OK`–`T2_T_OK` prove step 5, the Commands-block regression comment, and the sync-conflict stop condition survive byte-exact; `T2_U_OK` proves exactly the four intended hunks; `T2_V_OK` is the full-block pin — all three New Process lines byte-exact via `grep -Ff`, count exactly 3.)

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills/submit-epic-pr/SKILL.md
git commit -m "feat: submit-epic-pr — integrated-head review round replaces epic quality-gate, re-ordered before regression; attempt lifecycle (clean-tree start, freeze at reviewed SHA, SHA-equality before push, restart on head movement, crash-successor idempotence)"
```

### Task 3: `epic-pr-ready` template + templates validator — heading rename (atomic co-land)

**Files:**
- Modify: `templates/ticket-comments/epic-pr-ready.md` (the validator-asserted heading, line ~29; the coverage-summary line, line ~46 — both surfaces move together per the sweep row)
- Modify: `scripts/validate-ticket-comment-templates.sh` (the one heading assertion, line ~100 — MUST land in this same task/commit or the templates validator goes red between boundaries)

- [ ] **Step 1:** Rename the template heading.

Old:

```markdown
## Quality Gate Evidence
```

New:

```markdown
## Integrated-Head Review Evidence
```

- [ ] **Step 2:** Rename the coverage-summary line.

Old:

```markdown
- Local CI-equivalent: `<summary>`
```

New:

```markdown
- Repo-local + broader checks: `<summary>`
```

- [ ] **Step 3:** Update the validator's heading assertion to match.

Old:

```bash
check_heading templates/ticket-comments/epic-pr-ready.md "Quality Gate Evidence"
```

New:

```bash
check_heading templates/ticket-comments/epic-pr-ready.md "Integrated-Head Review Evidence"
```

- [ ] **Step 4:** Verify

Run (from the repo root):

```bash
grep -qF '## Integrated-Head Review Evidence' templates/ticket-comments/epic-pr-ready.md && echo T3_A_OK
grep -qF -- '- Repo-local + broader checks: `<summary>`' templates/ticket-comments/epic-pr-ready.md && echo T3_B_OK
! grep -qF 'Local CI-equivalent:' templates/ticket-comments/epic-pr-ready.md && echo T3_C_OK
test "$(grep -ci 'quality.gat' templates/ticket-comments/epic-pr-ready.md)" = "0" && echo T3_D_OK
grep -qF 'check_heading templates/ticket-comments/epic-pr-ready.md "Integrated-Head Review Evidence"' scripts/validate-ticket-comment-templates.sh && echo T3_E_OK
test "$(grep -ci 'quality.gat' scripts/validate-ticket-comment-templates.sh)" = "0" && echo T3_F_OK
grep -qF '## What Changed Since Signoff' templates/ticket-comments/epic-pr-ready.md && echo T3_G_OK
bash scripts/validate-ticket-comment-templates.sh
bash scripts/validate-phase-skills.sh > /dev/null && echo T3_H_OK
```

Expected: `T3_A_OK` … `T3_G_OK`, then `ticket comment templates ok`, then `T3_H_OK`, every command exit 0. (`T3_C_OK` proves the old coverage label is gone — the New line "Repo-local + broader checks:" does not contain it; `T3_D_OK`/`T3_F_OK` prove both files reach zero quality-gat lines; `T3_G_OK` proves the other validator-asserted sections survive — the templates validator's own green run is the authoritative co-land proof.)

- [ ] **Step 5:** Commit

```bash
git add templates/ticket-comments/epic-pr-ready.md scripts/validate-ticket-comment-templates.sh
git commit -m "feat: epic-pr-ready — Integrated-Head Review Evidence heading + repo-local/broader-checks line; templates-validator assertion co-lands atomically"
```

### Task 4: `state-transitions.md` — epic row: evidence currency + the two new stop causes

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/state-transitions.md` (the Epic-Level table's `epic-ready-for-pr` row ONLY — one line, one hunk. The resume-mapping line with its legacy `quality-gating` token, the Child-Ticket and Lane Checkpoint tables, and every other row stay byte-identical)

- [ ] **Step 1:** Replace the epic row: Required-evidence cell gets the currency-qualified review evidence; the fallback cell gains the judgment-corrective and cap-exhaustion stop causes with their durable landing states.

Old:

```markdown
| epic-ready-for-pr | all children are done | child PR links, latest main/master sync, full regression suite green on integrated epic head, epic quality gate evidence | scannable epic readiness summary | epic-pr-open | returns to epic-active if a child reopens, sync introduces required fixes, or the full regression suite fails |
```

New:

```markdown
| epic-ready-for-pr | all children are done | child PR links, latest main/master sync, full regression suite green on integrated epic head, integrated-head review evidence **current with the epic head** (reviewed SHA = regression SHA = PR head) | scannable epic readiness summary | epic-pr-open | returns to epic-active if a child reopens, sync introduces required fixes, the full regression suite fails, or an integrated-head **judgment** finding files a corrective child ticket (epic-active via the not-done child); integrated-head loop-cap exhaustion ⇒ blocked + escalation |
```

- [ ] **Step 2:** Verify

Run (from the repo root):

```bash
grep -qF 'integrated-head review evidence **current with the epic head** (reviewed SHA = regression SHA = PR head)' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_A_OK
grep -qF 'or an integrated-head **judgment** finding files a corrective child ticket (epic-active via the not-done child); integrated-head loop-cap exhaustion ⇒ blocked + escalation' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_B_OK
! grep -qF 'epic quality gate evidence' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_C_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/epic-orchestrator/state-transitions.md)" = "1" && echo T4_D_OK
grep -qF 'a previously posted `quality-gating` checkpoint reads as `verifying` complete' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_E_OK
grep -qF '(the no-digest⇒dispatch backstop then forces the child-PR CI run)' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_F_OK
grep -qF "verification evidence, including each runner digest's recorded head SHA with the local-CI runner's named explicitly; continuation brief |" dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_G_OK
grep -qF '| epic-pr-open | epic PR created — Gate 2 |' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T4_H_OK
test "$(git diff --unified=0 0afc96a -- dodi-dev/skills/epic-orchestrator/state-transitions.md | grep -c '^@@')" = "1" && echo T4_I_OK
bash scripts/validate-phase-skills.sh > /dev/null && echo T4_J_OK
```

Expected: the ten lines `T4_A_OK` … `T4_J_OK`, in order, every command exit 0. (`T4_C_OK` proves the old evidence phrase is gone — not a substring of any New text in this plan; `T4_D_OK`/`T4_E_OK` prove the file lands at exactly ONE quality-gat line, the permanent C2 resume-mapping `quality-gating` token — never strip it; `T4_F_OK`/`T4_G_OK` prove the [C2-b] backstop and the `ready-for-child-pr` row survive byte-exact; `T4_H_OK` proves the adjacent epic-pr-open row is untouched; `T4_I_OK` proves this file changed in exactly one hunk.)

- [ ] **Step 3:** Commit

```bash
git add dodi-dev/skills/epic-orchestrator/state-transitions.md
git commit -m "feat: state-transitions epic row — integrated-head review evidence current with head (reviewed = regression = PR head); judgment-corrective and cap-exhaustion stop causes with landing states"
```

### Task 5: sole-writer ownership glosses (`drive-epic` + AGENTS.md) + Capable row — then the full battery

**Files:**
- Modify: `dodi-dev/skills/drive-epic/SKILL.md` (Boot step 5's sole-writer clause, line ~65 — one hunk; no other behavior text changes)
- Modify: `AGENTS.md` (Capable tier row, line ~28; Scheduled Operation layering rule, line ~88 — two hunks; nothing else)

- [ ] **Step 1:** Add the ownership gloss to drive-epic's sole-writer clause (find by the quoted text; the gloss string is identical in both files).

Old:

```markdown
and is that worktree's **sole writer**; all lane work happens in per-lane ephemeral worktrees.
```

New:

```markdown
and is that worktree's **sole writer** — leaf fix workers dispatched by the walking session write under its ownership (one supervising session still serializes all epic-worktree writes); all lane work happens in per-lane ephemeral worktrees.
```

- [ ] **Step 2:** Add the same gloss to AGENTS.md's layering rule (the bold span now closes after "only writer"; the gloss is plain text).

Old:

```markdown
- Layering rule: **claims serialize tickets; worktrees serialize files; nothing serializes runs; the driver is the epic worktree's only writer.**
```

New:

```markdown
- Layering rule: **claims serialize tickets; worktrees serialize files; nothing serializes runs; the driver is the epic worktree's only writer** — leaf fix workers dispatched by the walking session write under its ownership (one supervising session still serializes all epic-worktree writes).
```

- [ ] **Step 3:** Add the integrated-head epic review to the Capable tier's Used-for list.

Old:

```markdown
| Capable | `opus` | Per-round code review, PR review, delivery (implementers + fix workers) on `needs-capable-delivery` tickets |
```

New:

```markdown
| Capable | `opus` | Per-round code review, PR review, integrated-head epic review, delivery (implementers + fix workers) on `needs-capable-delivery` tickets |
```

- [ ] **Step 4:** Verify (task-local)

Run (from the repo root):

```bash
grep -qF "and is that worktree's **sole writer** — leaf fix workers dispatched by the walking session write under its ownership (one supervising session still serializes all epic-worktree writes); all lane work happens in per-lane ephemeral worktrees." dodi-dev/skills/drive-epic/SKILL.md && echo T5_A_OK
grep -qF "the driver is the epic worktree's only writer** — leaf fix workers dispatched by the walking session write under its ownership (one supervising session still serializes all epic-worktree writes)." AGENTS.md && echo T5_B_OK
test "$(grep -rlF 'leaf fix workers dispatched by the walking session write under its ownership (one supervising session still serializes all epic-worktree writes)' AGENTS.md dodi-dev/skills/drive-epic/SKILL.md | LC_ALL=C sort | paste -sd' ' -)" = "AGENTS.md dodi-dev/skills/drive-epic/SKILL.md" && echo T5_C_OK
grep -qF '| Capable | `opus` | Per-round code review, PR review, integrated-head epic review, delivery (implementers + fix workers) on `needs-capable-delivery` tickets |' AGENTS.md && echo T5_D_OK
grep -qF '| Frontier | `fable` | Spec drafting/review, plan writing/review, the final pre-PR review round |' AGENTS.md && echo T5_E_OK
```

Expected: the five lines `T5_A_OK` … `T5_E_OK`, in order, every command exit 0. (`T5_C_OK` proves the gloss is byte-identical in both files; `T5_E_OK` proves the Frontier row — not C4's — is untouched.)

- [ ] **Step 5:** Verify — full Testing Contract battery (Unit group + Broader regression)

Run (from the repo root):

```bash
bash scripts/validate-plugin-metadata.sh
bash scripts/validate-phase-skills.sh > /dev/null && echo T5_F_OK
bash scripts/validate-ticket-comment-templates.sh
test "$(grep -ril 'quality.gat' AGENTS.md .claude-plugin .agents dodi-dev scripts templates | LC_ALL=C sort | paste -sd' ' -)" = "dodi-dev/skills/epic-orchestrator/state-transitions.md" && echo T5_G_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/epic-orchestrator/state-transitions.md)" = "1" && echo T5_H_OK
grep -qF 'a previously posted `quality-gating` checkpoint reads as `verifying` complete' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T5_I_OK
test "$(grep -ci 'quality.gat' dodi-dev/skills/submit-epic-pr/SKILL.md)" = "0" && echo T5_J_OK
test "$(grep -ci 'quality.gat' scripts/validate-ticket-comment-templates.sh)" = "0" && echo T5_K_OK
test "$(grep -ci 'quality.gat' templates/ticket-comments/epic-pr-ready.md)" = "0" && echo T5_L_OK
grep -qF '## Integrated-Head Review Evidence' templates/ticket-comments/epic-pr-ready.md && echo T5_M_OK
grep -qF 'check_heading templates/ticket-comments/epic-pr-ready.md "Integrated-Head Review Evidence"' scripts/validate-ticket-comment-templates.sh && echo T5_N_OK
grep -qF -- '- Repo-local + broader checks: `<summary>`' templates/ticket-comments/epic-pr-ready.md && echo T5_O_OK
test -f dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T5_P_OK
grep -qF '  submit-epic-pr/epic-integration-reviewer-prompt.md' scripts/validate-phase-skills.sh && echo T5_Q_OK
! grep -qi 'caught-by' dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md && echo T5_R_OK
grep -qF 'integrated-head review evidence **current with the epic head** (reviewed SHA = regression SHA = PR head)' dodi-dev/skills/epic-orchestrator/state-transitions.md && echo T5_S_OK
grep -qF -- '- integrated-head review evidence incl. reviewed head SHA' dodi-dev/skills/submit-epic-pr/SKILL.md && echo T5_T_OK
test "$(git diff --name-only 0afc96a -- . ':(exclude)docs' | LC_ALL=C sort | paste -sd' ' -)" = "AGENTS.md dodi-dev/skills/drive-epic/SKILL.md dodi-dev/skills/epic-orchestrator/state-transitions.md dodi-dev/skills/submit-epic-pr/SKILL.md dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md scripts/validate-phase-skills.sh scripts/validate-ticket-comment-templates.sh templates/ticket-comments/epic-pr-ready.md" && echo T5_U_OK
test "$(git diff --unified=0 0afc96a -- dodi-dev/skills/submit-epic-pr/SKILL.md | grep -c '^@@')" = "4" && echo T5_V_OK
test "$(git diff --unified=0 0afc96a -- dodi-dev/skills/epic-orchestrator/state-transitions.md | grep -c '^@@')" = "1" && echo T5_W_OK
test "$(git diff --unified=0 0afc96a -- dodi-dev/skills/drive-epic/SKILL.md | grep -c '^@@')" = "1" && echo T5_X_OK
test "$(git diff --unified=0 0afc96a -- AGENTS.md | grep -c '^@@')" = "2" && echo T5_Y_OK
test "$(git diff --unified=0 0afc96a -- templates/ticket-comments/epic-pr-ready.md | grep -c '^@@')" = "2" && echo T5_Z_OK
test "$(git diff --unified=0 0afc96a -- scripts/validate-ticket-comment-templates.sh | grep -c '^@@')" = "1" && echo T5_AA_OK
test "$(git diff --unified=0 0afc96a -- scripts/validate-phase-skills.sh | grep -c '^@@')" = "1" && echo T5_AB_OK
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
T5_W_OK
T5_X_OK
T5_Y_OK
T5_Z_OK
T5_AA_OK
T5_AB_OK
```

(`T5_G_OK`–`T5_L_OK` assert the survivor-set flip precisely — the ONLY quality-gat line left on ship surfaces is state-transitions' legacy resume-mapping token, counts 0/1/0/0; `T5_M_OK`–`T5_O_OK` the heading sweep; `T5_P_OK`–`T5_R_OK` prompt existence, validator registration, and the [S1] no-caught-by invariant; `T5_U_OK` asserts the complete changed-file set vs base `0afc96a` is exactly C4's eight files (docs/ excluded — the plan file lands there); `T5_V_OK`–`T5_AB_OK` assert per-file hunk precision: 4/1/1/2/2/1/1. The metadata validator prints 0.14.2 — C4 does not bump; C5 owns the 0.15.0 version change. The load-bearing assertion is exit 0.)

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills/drive-epic/SKILL.md AGENTS.md
git commit -m "feat: sole-writer ownership gloss in drive-epic + AGENTS layering rule (leaf fix workers write under the walking session); Capable row adds integrated-head epic review — C4 complete"
```

---

## Notes for the executor

- **Verify-command hygiene:** every command above exits 0 on success; negations use `! grep -q…` scoped to a single file, and no negation pattern is a substring of any New text in this plan (`Local CI-equivalent:`, `epic quality gate evidence`, `caught-by`, and every `quality`-`gat` form appear in NO New text — checked per task in the Expected notes). Dash-leading patterns carry `--` before the pattern (`T2_O`, `T2_P`, `T2_T`, `T3_B`, `T5_O`, `T5_T`). Patterns containing an apostrophe but no backtick use double quotes (`T4_G`, `T5_A`, `T5_B`); the steps 2–4 block holds both apostrophes and backticks, so its pin (`T2_V_OK`) writes the exact three New lines to a temp file via a literal `<<'PATN'` heredoc and asserts `grep -cFf … | grep -qx 3` — no pattern line is empty (an empty line would match everything) and none is a substring of any other file line. Sorted list comparisons pin `LC_ALL=C sort` (the submit-epic-pr pair mixes case at the deciding character; locale sorts would reorder it).
- **Task 1's creation heredoc is the byte pin** for the new prompt (no editor-tool retype; `wc -l` = 81 plus the key-line greps close transcription drift). The plan-mandated full-text pins are thereby both discharged: the new prompt via its creation heredoc, the reworked step block via `T2_V_OK`.
- **Ordering:** the prompt + its validator registration land first (Task 1, atomic — the validator asserts the file it now requires, keeping phase-skills green from that boundary onward and letting Task 2's SKILL.md reference an existing file); the SKILL rework second; the template + templates-validator heading rename land atomically in Task 3 (splitting them reds the templates validator between commits); state-transitions and the glosses follow. Validators are green at every task boundary.
- **Sibling-prompt conventions carried:** own-directory prompt references are bare (`(see \`epic-integration-reviewer-prompt.md\`)` — matching `review`'s `(see review-prompt.md)`); the leaf-discipline line is byte-identical to `child-pr-integration-prompt.md`'s (`T1_S_OK`); the admissibility sentence's core clause ("Aim guides attention, not admissibility: any defect seen anywhere in the diff is a legal finding") is mirrored verbatim with the tail adapted to this gate's non-aim ("the generic checklists the per-child gates own" — the child gates, not the pre-PR gate, are what this round does not re-execute).
- **Disclosed format-mirroring addition:** the prompt's input list carries a **Project conventions** line beyond the spec's four named inputs (post-sync diff, design artifact, Gate 1 package, canon) — the sibling integration prompt's established input shape, load-bearing for the hygiene class (convention drift); issue #6's "inputs incl." phrasing accommodates it. Not a behavior change.
- **Two re-entry points, by design:** a STOP (judgment corrective, cap exhaustion) re-enters as a **new attempt** at step 2 (clean-tree check first); **head movement after the clean round** restarts **at step 3** (the review round) — the spec's own distinction; the crash-successor completion rule (`SHA-keyed skip-what-exists`) is the only path that resumes an in-flight attempt.
- **Untouched-but-adjacent, verified still true post-reorder (not edits):** step 5's readiness-summary inventory, the Commands block's regression comment, and Rules' "run on the current epic head after the latest main/master sync" all remain accurate with the round in front of regression and the SHA-equality check enforcing reviewed = regression = head; Task 2's survivor greps assert them byte-exact. The `epic-pr-ready` evidence placeholder under the renamed heading stays generic (`<command or evidence link>`) — the sweep row names exactly the two template edits.
- **[C3-c] context:** this lane itself runs under installed 0.14.2 — the walked pipeline still says quality-gate until the 0.15.0 release applies; these edits are branch-text law from this child forward, exercised live after release (fresh session, `plugin update`).
- If any Old anchor fails to match byte-exactly, stop and re-read the target file — a sibling child may have landed out of order; report the mismatch instead of adapting the edit.
