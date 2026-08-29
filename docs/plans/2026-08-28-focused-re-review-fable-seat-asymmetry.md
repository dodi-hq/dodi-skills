# Focused Re-Review Fable-Seat Asymmetry (DOD-1218, DR-025) Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** Implement operator ruling DR-025 — Direction B scoped to standard-tier tickets only: the child-PR post-fix focused re-round becomes tier-conditional (**hard** `fable@xhigh` seat on `needs-capable-delivery` tickets; plain `opus@high` on standard-tier tickets — no substitution, no make-up), the verify-stage focused re-review stays Capable on every tier, and the gate-clean rule (`review/SKILL.md:48`) names the re-round as the fix-loop closer — per spec `docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md` §§ Design 1–8 and canon DR-001..DR-005, DR-015, DR-017, DR-018, DR-025.

**Architecture:** Pure doctrine-and-propagation change plus grep-shaped guards: prose edits in `AGENTS.md` (§ Fable Availability Policy: hard-row Gates cell + replacement of the `:72` inherit sentence with the DR-025 doctrine sentence), `dodi-dev/skills/review/SKILL.md` (`:47` fix-loop seat, `:48` closure semantics — `:55` byte-identical), `dodi-dev/skills/review/child-pr-integration-prompt.md` (four tier-conditional slots), five positive wording pins + two negative assertions in `scripts/validate-phase-skills.sh`, three one-line spec touch-ups carried forward from the clean spec-review round, the five-file version bump to `0.17.4`, and the DR-025 implementation decision-register entry (entry comment on epic DOD-1213 + canon-table maintenance including the scoped DR-003 amendment-by-operator-ruling). No hook changes, no orchestrator-surface changes, no shell-script behavior changes beyond the validator assertions.

**Tech Stack:** Markdown doctrine files, bash validators, JSON plugin metadata, PM (Linear) decision-register surfaces. No CI — every check is local (`bash <path>` from the worktree root).

**Worktree:** the child delivery worktree that `pickup-ticket` creates from the epic branch `epic/dod-1213-fable-scarcity-doctrine` (expected base: at or after `f9d76ad` — siblings DOD-1214..1217 merged). Run every command from that worktree root.

**Anchoring rule (read first):** every edit below is anchored by section name + verbatim anchor text, never by line number (line citations like `:47` are orientation only — siblings have already shifted `AGENTS.md` line numbers once). Each task's Task-0-verified anchor MUST be re-verified against the live file at implementation time (`grep -cF` per anchor, written into Task 0); if an anchor has drifted, stop with a concrete blocker rather than guessing a nearby location. The replacement texts are the spec's normative text instantiated literally — do not reword them.

## Testing Contract

### Required Test Groups

- Unit: `not-required`
  - Scope: n/a (doctrine prose plus grep-literal validator assertions)
  - Reason: no unit-test harness for markdown/doctrine content exists in this repo and none should be invented (ticket testing contract; spec § Acceptance: "No new test harness; no shell-script behavior changes beyond the pins").
  - Minimum assertions: none.

- Integration: `required`
  - Scope: repository validators over the full skill tree, `AGENTS.md`, and plugin metadata; the new DR-025 wording pins and negative assertions in `scripts/validate-phase-skills.sh`.
  - Reason: the three `scripts/validate-*.sh` validators are the real regression surface; the wording pins are the ticket's mechanical invariant — the ruled doctrine cannot drift silently (positive pins a–e) and the retired pre-ruling shapes cannot reappear (both negative assertions).
  - Harness: `existing` — standalone bash scripts, no runner above them.
  - Minimum assertions:
    - `bash scripts/validate-plugin-metadata.sh` exits 0 printing `plugin metadata ok: 0.17.4` (five-file lockstep).
    - `bash scripts/validate-phase-skills.sh` exits 0 and prints `phase skills ok` (all pre-existing checks plus the five positive pins and two negative assertions pass on the edited tree).
    - `bash scripts/validate-ticket-comment-templates.sh` exits 0 printing `ticket comment templates ok`.
    - **Negative cases, run by hand and recorded in the PR evidence (Task 5 Step 3 — this demonstration IS the test; there is no unit-test file for the validators):** (i) deleting the doctrine sentence's pinned fragment from `AGENTS.md` → non-zero exit (pin (c) fires — the spec § 6 scratch-copy verification); (ii) re-introducing the retired phrase `focused re-round at the gate's fable seat` into `review/SKILL.md` → exit 1 with the retired-wording message; (iii) re-introducing `inherit their gate's policy` into `AGENTS.md` → exit 1 with the retired-inherit message; each followed by `git checkout --` restore and a passing re-run.

- E2E: `not-required` (not-applicable)
  - Scope: n/a.
  - Reason: the tier-conditional seat is dispatch-time prose consumed by the executing session's per-gate lookup (`execution-model.md` § 2); no harness surface exists to drive a live child-PR fix loop deterministically, and `hook-require-model-pin.sh` (untouched) already enforces the only mechanical layer — that a pin exists. Prose-plus-validator-pins is the declared posture, not a coverage oversight.
  - Harness: `not-applicable`
  - Minimum assertions: none.

### Critical Flows

- `bash scripts/validate-phase-skills.sh` passes on the full edited tree, and fails (a) when the AGENTS.md doctrine-sentence fragment is deleted, (b) when either retired phrase is re-introduced (negative cases, Task 5 Step 3).
- `grep -n "focused re-round at the gate's fable seat" dodi-dev/skills/review/SKILL.md` comes back **empty** (the ticket's acceptance grep).
- **Manual read-through (recorded verbatim in the PR body — the acceptance-criterion read-through):** a reader given only `AGENTS.md` § Fable Availability Policy + `epic-orchestrator/execution-model.md` § 2 states the pin for both post-fix re-rounds on both ticket tiers — expected four answers: standard-tier verify-stage re-review `opus@high`; standard-tier child-PR re-round `opus@high`; `needs-capable-delivery` verify-stage re-review `opus@high`; `needs-capable-delivery` child-PR re-round `fable@xhigh`, **hard**. Plus, from `review/SKILL.md` step 5 (`:48`) **alone**: does a re-round-closed standard-tier gate queue a make-up? Expected: **no** — plain `opus@high`, no substitution, no make-up (Task 8 Step 3).

### Regression Surface

- `review/SKILL.md` `:55` (verify-stage focused re-review clause) byte-identical; proven by pin (b) plus `git diff` inspection (Task 8).
- `dodi-dev/skills/review/review-prompt.md`, `dodi-dev/scripts/hook-require-model-pin.sh`, `dodi-dev/skills/epic-orchestrator/execution-model.md`, `epic-orchestrator/state-transitions.md`, `epic-orchestrator/lanes/deliver-playbook.md`, `epic-orchestrator/lanes/mature-playbook.md` — all byte-identical to the epic branch (`git diff` empty, Task 8).
- `AGENTS.md` deferred row (`:68`) and soft/operator-choice rows byte-identical: the standard-tier child-PR **final** stays deferred; the pre-PR final stays deferred; no park edge moves.
- All pre-existing `validate-phase-skills.sh` checks (tier/effort self-declaration, flattened-parenthetical effort regex, multi-tier seat registry incl. `review/child-pr-integration-prompt.md` = "Capable Frontier" (DR-017), fable-seat frontmatter check, repo-only-reference ban, Testing Contract shape) still pass — the § 3 `:10` replacement is designed to keep the effort regex and seat registry satisfied.
- Ledger/catch grammar (`review/SKILL.md:62–:81`) untouched — § Design 4's consequences are prose-pinned in the spec, no grammar change.

### Commands

- Unit: `not-required — none`
- Integration: `bash scripts/validate-plugin-metadata.sh` ; `bash scripts/validate-phase-skills.sh` ; `bash scripts/validate-ticket-comment-templates.sh` ; negative cases per Task 5 Step 3
- E2E: `not-applicable — none`
- Broader regression: `git diff <epic-branch> -- <untouched files>` empties per Task 8 Step 2; acceptance greps per Task 8 Step 1

### Harness Requirements

- `bash`, `python3` (used inside the validators and Task 5's scratch edit), `git` — all present locally; no services, env vars, seeds, browsers, mocks, or accounts. Run everything from the worktree root (the validators use repo-relative paths). PM access (Linear) for Task 7 only.

### Non-Required Rationale

- Unit: doctrine prose plus grep-literal assertions; no markdown unit harness exists and inventing one is out of scope per the ticket's testing contract.
- Integration: (required — n/a)
- E2E: the tier-conditional lookup is a dispatch-time prose protocol with no mechanical injection point; the honest coverage story is the validator-enforced wording pins, the hand-run negative demonstrations, and the manual read-through recorded in the PR body.

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## Delivery-Tier Classification Inputs (for the plan reviewer — do not skip)

The plan reviewer classifies this ticket's delivery tier (standard | capable) as a required output; this plan supplies the inputs and deliberately does **not** classify:

- **Work shape:** doctrine-prose replacement (three markdown files, normative text supplied verbatim by the spec and instantiated literally in this plan), grep-literal validator pins (no control flow beyond `if ! grep`/`if grep` + `exit 1`, following two existing in-file styles), a five-file JSON version bump, three one-line spec touch-ups, and one PM register entry with exact text supplied.
- **Density signals:** no concurrency, no locking, no state machines, no ordering/idempotence invariants, no cross-component runtime interactions — the invariant-dense classes `AGENTS.md` § Model Tiers names for `needs-capable-delivery` are absent. The risk concentration is exact-literal fidelity: every replacement is checkable by `grep -F` against this plan, and the validator pins make the load-bearing literals self-checking.
- **Blast surface:** the edited `:47`/`:48`/`:72` text governs every future child-PR fix loop's tier lookup; a wording error is caught by the pins (Task 5) and the manual read-through (Task 8), both inside this lane.

---

## File Structure

Created: this plan only. Modified files (10):

| File | Responsibility of the change |
|------|------------------------------|
| `docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md` | Three carried-forward spec-review advisories: ⚠-prefix two delegated-assumption Key Points bullets; pin § 6(a)'s hard-clause assertion as an exact literal; correct § 8's integration-pair citation `:44–:46` → `:42–:46` |
| `AGENTS.md` | § Fable Availability Policy: hard-row Gates cell gains "and its post-fix focused re-round"; the `:72` inherit sentence is replaced by the DR-025 doctrine sentence (opener and closing asymmetry sentence retained verbatim) |
| `dodi-dev/skills/review/SKILL.md` | Child-PR step 4 (`:47`): tier-conditional re-round seat; step 5 (`:48`): two-path gate-clean closure naming the re-round as the fix-loop closer. `:55` byte-identical |
| `dodi-dev/skills/review/child-pr-integration-prompt.md` | Four tier-conditional slots: preamble (`:3`), Agent-tool line (`:6`), tier self-declaration (`:10`), Round slot (`:16`) — standard-tier path only |
| `scripts/validate-phase-skills.sh` | Five positive DR-025 wording pins (a–e) + two negative retired-shape assertions |
| `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json` | Version bump `0.17.3` → `0.17.4` (patch per DR-015; if Task 0 reports a different base, current+1) |

**Never modified:** `dodi-dev/skills/review/review-prompt.md`, `dodi-dev/scripts/hook-require-model-pin.sh`, `dodi-dev/skills/epic-orchestrator/execution-model.md`, `epic-orchestrator/state-transitions.md`, `epic-orchestrator/lanes/deliver-playbook.md`, `epic-orchestrator/lanes/mature-playbook.md`, the `AGENTS.md` deferred/soft/operator-choice rows and every Mechanics bullet, `review/SKILL.md` `:55` and §§ Catch Attribution / Gate Ledger, `.agents/plugins/marketplace.json` (carries no version key — do not add one), `docs/specs/2026-07-07-execution-model-flatten-design.md` (historical record — never edited).

---

### Task 0: Precondition + anchor verification (no edits)

- [ ] **Step 1:** Confirm the sibling baseline and version base (DR-015; spec ⚠ version assumption: take current+1 at implementation time)

Run: `bash scripts/validate-plugin-metadata.sh`
Expected: `plugin metadata ok: 0.17.3`. If it prints a different version, use that as the base and substitute next-patch throughout Task 6 (and in the Testing Contract's expected output). If it prints a version at or above `0.17.4`, re-check that no other lane also targets that number before proceeding.

Run: `grep -c 'Capable@max' AGENTS.md && grep -cF '<tier>@<effort>' AGENTS.md`
Expected: both ≥ 1 (DOD-1214's notation, which every replacement text below uses, is merged).

- [ ] **Step 2:** Verify every anchor this plan edits exists exactly once in the live files

```bash
grep -cF "the capable-tier child-PR final round (\`needs-capable-delivery\` tickets)" AGENTS.md
grep -cF "Focused post-fix re-rounds inherit their gate's policy (the child-PR post-fix re-round is hard on capable-tier, deferred on standard-tier — it establishes gate-clean)." AGENTS.md
grep -cF "then a **focused re-round at the gate's fable seat** aimed at the fix delta" dodi-dev/skills/review/SKILL.md
grep -cF "5. The gate is clean only when the child-PR final round reports zero issues" dodi-dev/skills/review/SKILL.md
grep -cF "A post-fix **focused re-round** is a fresh \`model: fable\` dispatch of this template aimed at the fix delta." dodi-dev/skills/review/child-pr-integration-prompt.md
grep -cF "Agent tool (general-purpose, model: opus for the integration round; model: fable for the integration final and any focused re-round):" dodi-dev/skills/review/child-pr-integration-prompt.md
grep -cF "and any focused re-round — match this dispatch's pin). You are reviewing a" dodi-dev/skills/review/child-pr-integration-prompt.md
grep -cF "**Round:** [integration round | integration final | focused re-round (fix delta: [diff range])]" dodi-dev/skills/review/child-pr-integration-prompt.md
grep -cF "check_count_at_least \"\$file\" \"Minimum assertions: \\\`<specific flows>\\\`\" 2" scripts/validate-phase-skills.sh
grep -cF "a fresh reviewer at Capable tier (\`model: opus\` on Claude Code) reads the fix delta" dodi-dev/skills/review/SKILL.md
grep -cF -- "- **The operative principle (the doctrine sentence \`AGENTS.md:72\` will carry):**" docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md
grep -cF -- "- **Version:** five-file lockstep bump to **0.17.4**" docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md
grep -cF "(\`:44–:46\`)" docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md
```
Expected: every command prints `1`. If any prints `0` or `>1`, the anchor drifted: stop and report a concrete blocker (do not guess a nearby location) unless the drift is pure line-number citation noise with the anchor text itself intact.

- [ ] **Step 3:** Confirm the retired phrases occur nowhere else (so the Task 5 negative assertions bind only the intended sites until those sites are edited)

Run: `grep -rn "focused re-round at the gate's fable seat" dodi-dev/skills/ | wc -l && grep -c "inherit their gate's policy" AGENTS.md`
Expected: `1` and `1` (the `:47` occurrence and the `:72` occurrence — both removed by Tasks 2–3).

### Task 1: Spec touch-ups (three carried-forward advisories, same commit stream)

**Files:**
- Modify: `docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md` (Key Points ×2; § 6(a); § 8)

- [ ] **Step 1:** ⚠-prefix the two delegated-assumption Key Points bullets (AGENTS.md § Scannable Artifacts: prefix delegated assumptions with ⚠). Replace the bullet opener:

```text
- **The operative principle (the doctrine sentence `AGENTS.md:72` will carry):**
```

with:

```text
- ⚠ **The operative principle (the doctrine sentence `AGENTS.md:72` will carry):**
```

and the bullet opener:

```text
- **Version:** five-file lockstep bump to **0.17.4**
```

with:

```text
- ⚠ **Version:** five-file lockstep bump to **0.17.4**
```

(Only the two openers change; the bullet bodies are untouched.)

- [ ] **Step 2:** Pin § 6(a)'s hard-clause assertion as an exact literal, matching pins (b)–(e) in style. In § 6 "Validator pins", replace:

```text
  - (a) `review/SKILL.md` contains the `:47` hard clause fragment (`focused re-round` … `hard` … `model: fable`) and the standard clause fragment ("on a standard-tier ticket it runs at Capable tier (`model: opus` on Claude Code");
```

with:

```text
  - (a) `review/SKILL.md` contains the `:47` hard clause fragment ("on a `needs-capable-delivery` ticket it runs at the gate's **hard** fable seat (`model: fable` on Claude Code") and the standard clause fragment ("on a standard-tier ticket it runs at Capable tier (`model: opus` on Claude Code");
```

- [ ] **Step 3:** Correct § 8's integration-pair range citation. Replace:

```text
the child-PR integration pair (`:44–:46`)
```

with:

```text
the child-PR integration pair (`:42–:46`)
```

- [ ] **Step 4:** Verify

```bash
grep -c '^- ⚠' docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md
grep -cF '(`:42–:46`)' docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md
grep -cF 'the gate'\''s **hard** fable seat (`model: fable` on Claude Code")' docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md
```
Expected: `2`, `1`, `1` (the third pattern's closing `")` scopes it to the § 6(a) literal — § Design 2's own hard clause continues with an em-dash instead).

- [ ] **Step 5:** Commit

```bash
git add docs/specs/2026-08-28-focused-re-review-fable-seat-asymmetry-design.md
git commit -m "DOD-1218: spec touch-ups — ⚠ delegated-assumption bullets, exact 6(a) literal, :42–:46 citation

Three advisories carried forward from the clean final spec-review round.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 2: AGENTS.md § Fable Availability Policy — hard-row cell + doctrine sentence (spec § Design 1)

**Files:**
- Modify: `AGENTS.md` § Fable Availability Policy (hard table row; the "A fable seat without a row is a defect." paragraph)

- [ ] **Step 1:** Hard-row Gates cell. Inside the `| **hard** | ... |` table row, replace (verbatim, verified unique in Task 0):

```text
the capable-tier child-PR final round (`needs-capable-delivery` tickets)
```

with:

```text
the capable-tier child-PR final round **and its post-fix focused re-round** (`needs-capable-delivery` tickets)
```

Everything else in the row — and the deferred, soft, and operator-choice rows — is byte-untouched.

- [ ] **Step 2:** Doctrine sentence. In the paragraph immediately below the policy table, replace the middle sentence (verbatim, verified unique in Task 0):

```text
Focused post-fix re-rounds inherit their gate's policy (the child-PR post-fix re-round is hard on capable-tier, deferred on standard-tier — it establishes gate-clean).
```

with (the spec § Design 1 normative text, literally):

```text
Post-fix focused re-rounds run at Capable tier (`opus@high`) by default; a re-round keeps its gate's **hard** fable seat only where both hold: it is the last checkpoint before the fix delta reaches the epic branch, and the fix worker is itself Capable — a Capable re-round there would collapse writer and reviewer with no independent look left before the merge (DR-025). Concretely: on a `needs-capable-delivery` ticket the child-PR post-fix re-round runs at the gate's **hard** fable seat (`fable@xhigh` — the `opus` fix worker makes it the last independent Frontier check before merge-into-epic); on a standard-tier ticket the child-PR post-fix re-round runs at Capable (`opus@high` — not a fable seat: no substitution, no make-up, no row needed); and the verify-stage focused re-review runs at Capable (`opus@high`) on any ticket tier — its delta still faces the child-PR integration pair downstream. Either re-round is the round that re-establishes gate-clean, never a confirmation sweep.
```

The paragraph's opener ("A fable seat without a row is a defect. ") and its closing sentence ("The deliberate asymmetry — spec-review final **hard**, plan-review final **deferred** — is because …") are retained verbatim around it — the paragraph stays one paragraph.

- [ ] **Step 3:** Verify

```bash
grep -cF 'Post-fix focused re-rounds run at Capable tier (`opus@high`) by default' AGENTS.md   # 1
grep -cF 'and its post-fix focused re-round' AGENTS.md                                          # 1
grep -c "inherit their gate's policy" AGENTS.md; echo "exit: $?"                                # 0, exit: 1
git diff -U0 AGENTS.md | grep '^-|' | grep -cE '\*\*(deferred|soft|operator-choice)\*\*'         # 0 (grep exits 1)
```
Expected: as annotated. Then read the section once end to end and confirm the acceptance read-through works from the doctrine sentence alone: all four tier×re-round cells are stated by name; the deferred row still carries the standard-tier child-PR **final**.

- [ ] **Step 4:** Commit

```bash
git add AGENTS.md
git commit -m "DOD-1218: DR-025 doctrine sentence + hard-row re-round cell in Fable Availability Policy

Replaces the inherit rule: post-fix focused re-rounds run Capable by
default; a re-round keeps its gate's hard fable seat only where it is the
last checkpoint before the fix delta reaches the epic branch AND the fix
worker is itself Capable. All four tier×re-round cells stated by name;
deferred/soft/operator-choice rows byte-identical.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 3: review/SKILL.md — tier-conditional re-round (`:47`) + two-path gate-clean closure (`:48`) (spec § Design 2)

**Files:**
- Modify: `dodi-dev/skills/review/SKILL.md` § Process — child-PR, steps 4 and 5. `:55` and everything else byte-identical.

- [ ] **Step 1:** Replace step 4 in full. The current step-4 line begins `4. **Fix loop** — findings from either round route to fix workers` and ends `— it never merges.` Replace the entire line with (spec § Design 2 normative text, literally):

```text
4. **Fix loop** — findings from either round route to fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a **focused re-round** aimed at the fix delta — tier-conditional per AGENTS.md § Fable Availability Policy (DR-025): on a `needs-capable-delivery` ticket it runs at the gate's **hard** fable seat (`model: fable` on Claude Code — the fix worker is `opus`, so this re-round is the last independent Frontier check before the merge); on a standard-tier ticket it runs at Capable tier (`model: opus` on Claude Code — the `sonnet` fix worker leaves no writer/reviewer collapse to guard against; not a fable seat — no substitution, no make-up). Either way it is the round that re-establishes gate-clean, not a confirmation sweep. Total child-PR rounds cap at 5; cap exhaustion escalates with the unresolved findings — it never merges.
```

- [ ] **Step 2:** Replace step 5 in full. The current step-5 line begins `5. The gate is clean only when the child-PR final round reports zero issues` and ends `On clean, report ` + backticked `ready-to-merge-child` + `.` Replace the entire line with (spec § Design 2 normative text, literally):

```text
5. The gate is clean only when its closing round reports zero issues. With no fix loop, the closing round is the child-PR **final** — at its fable seat under **hard** policy (`needs-capable-delivery` tickets), or at the substituted effective tier (`model: opus`) under **deferred** policy (standard-tier tickets) with the make-up obligation queued. After a fix loop, it is the **focused re-round** at its tier-conditional seat (step 4) — hard `fable@xhigh` on `needs-capable-delivery` tickets, plain `opus@high` on standard-tier tickets with **no** substitution and **no** make-up. **No gate is ever clean by silence.** On clean, report `ready-to-merge-child`.
```

- [ ] **Step 3:** Verify

```bash
grep -c "focused re-round at the gate's fable seat" dodi-dev/skills/review/SKILL.md; echo "exit: $?"   # 0, exit: 1 — the ticket's acceptance grep
grep -cF 'it runs at the gate'"'"'s **hard** fable seat (`model: fable` on Claude Code' dodi-dev/skills/review/SKILL.md   # 1
grep -cF 'on a standard-tier ticket it runs at Capable tier (`model: opus` on Claude Code' dodi-dev/skills/review/SKILL.md   # 1
grep -cF 'it is the **focused re-round** at its tier-conditional seat' dodi-dev/skills/review/SKILL.md   # 1
git diff -U0 dodi-dev/skills/review/SKILL.md | grep '^[+-]' | grep -c 'Focused re-review'   # 0 (grep exits 1) — :55 untouched
```
Expected: as annotated. Also confirm via `git diff` that only the two step lines changed (steps 1–3 of Process — child-PR, § Epic Lane Rules, § Catch Attribution, § Gate Ledger all byte-identical).

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/review/SKILL.md
git commit -m "DOD-1218: tier-conditional child-PR focused re-round + two-path gate-clean closure

Step 4: re-round hard fable on needs-capable-delivery, plain Capable on
standard tier (no substitution, no make-up) per DR-025. Step 5: the
closing round is the final on the no-fix-loop path (policy unchanged) and
the focused re-round at its tier-conditional seat after a fix loop, so :48
read alone answers the make-up question on both paths. :55 byte-identical.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 4: child-pr-integration-prompt.md — four tier-conditional slots (spec § Design 3)

**Files:**
- Modify: `dodi-dev/skills/review/child-pr-integration-prompt.md` (preamble, Agent-tool line, self-declaration, Round slot). `review-prompt.md` untouched.

- [ ] **Step 1:** Preamble (`:3`). Replace the sentence:

```text
A post-fix **focused re-round** is a fresh `model: fable` dispatch of this template aimed at the fix delta.
```

with:

```text
A post-fix **focused re-round** is a fresh dispatch of this template aimed at the fix delta — `model: fable` on `needs-capable-delivery` tickets (the gate's hard seat), `model: opus` on standard-tier tickets (DR-025).
```

- [ ] **Step 2:** Agent-tool line (`:6`, inside the fenced block). Replace:

```text
Agent tool (general-purpose, model: opus for the integration round; model: fable for the integration final and any focused re-round):
```

with:

```text
Agent tool (general-purpose, model: opus for the integration round; model: fable for the integration final; for a focused re-round: model: fable on `needs-capable-delivery` tickets, model: opus on standard-tier tickets):
```

- [ ] **Step 3:** Tier self-declaration (`:10` — the wrapped opening parenthetical, three lines inside the fenced block at 4-space indent). Replace:

```text
    You are a child-PR integration reviewer (Capable tier, high effort for the
    integration round; Frontier tier, xhigh effort for the integration final
    and any focused re-round — match this dispatch's pin). You are reviewing a
```

with:

```text
    You are a child-PR integration reviewer (Capable tier, high effort for the
    integration round and a standard-tier focused re-round; Frontier tier,
    xhigh effort for the integration final and a `needs-capable-delivery`
    focused re-round — match this dispatch's pin). You are reviewing a
```

(This keeps the validator's flattened `\((Frontier|Capable|Standard|Fast) tier[^)]{0,200}effort` effort check, the DR-017 seat-registry tiers `Capable` + `Frontier`, and the literal `match this dispatch's pin` all satisfied.)

- [ ] **Step 4:** Round slot (`:16` — spec's citation; the template line inside the fenced block). Replace:

```text
    **Round:** [integration round | integration final | focused re-round (fix delta: [diff range])]
```

with:

```text
    **Round:** [integration round | integration final | focused re-round at [Frontier@xhigh (`needs-capable-delivery`) | Capable@high (standard-tier)] (fix delta: [diff range])]
```

- [ ] **Step 5:** Verify

```bash
grep -c 'model: opus on standard-tier tickets' dodi-dev/skills/review/child-pr-integration-prompt.md   # 1 (the Agent-tool line; the preamble's occurrence backticks `model: opus`, so it does not match this plain pattern)
grep -cF 'Frontier@xhigh (`needs-capable-delivery`) | Capable@high (standard-tier)' dodi-dev/skills/review/child-pr-integration-prompt.md   # 1
grep -cF 'and a standard-tier focused re-round' dodi-dev/skills/review/child-pr-integration-prompt.md   # 1
bash scripts/validate-phase-skills.sh; echo "exit: $?"   # pre-pin validator still passes: "phase skills ok", exit: 0
```
Expected: as annotated. Confirm via `git diff` that the Integration Aims, Output section, and leaf-discipline footer are byte-identical.

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills/review/child-pr-integration-prompt.md
git commit -m "DOD-1218: tier-conditional focused re-round pins in child-PR integration prompt

Preamble, Agent-tool line, self-declaration, and Round slot each name both
seats: fable on needs-capable-delivery (hard), opus on standard tier
(DR-025). Effort-regex, seat-registry, and match-this-dispatch's-pin
checks all still satisfied.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 5: Validator pins + hand-run negative cases (spec § Design 6)

**Files:**
- Modify: `scripts/validate-phase-skills.sh` — insert one block after the write-plan Testing Contract checks (the three `check_count_at_least` lines) and before the symlink check (`find dodi-dev/skills -type l -print`).

- [ ] **Step 1:** Insert the block. Immediately **after** the line:

```text
check_count_at_least "$file" "Minimum assertions: \`<specific flows>\`" 2
```

and **before** the `find dodi-dev/skills -type l -print` line, insert (blank-line separated on both sides):

```bash
# DR-025 (DOD-1218): tier-conditional focused re-round wording pins. The
# ruled doctrine is prose; these literals keep it from drifting silently.
# (a) review/SKILL.md :47 hard + standard clauses; (b) the unchanged :55
# verify-stage clause — the resolved asymmetry's stationary half; (c) the
# AGENTS.md doctrine sentence's core; (d) the hard-row re-round cell;
# (e) the :48 fix-loop closure clause — the gate-clean rule's two-path shape.
dr025_pins_review=(
  "on a \`needs-capable-delivery\` ticket it runs at the gate's **hard** fable seat (\`model: fable\` on Claude Code"
  "on a standard-tier ticket it runs at Capable tier (\`model: opus\` on Claude Code"
  "a fresh reviewer at Capable tier (\`model: opus\` on Claude Code) reads the fix delta"
  "it is the **focused re-round** at its tier-conditional seat"
)
for pin in "${dr025_pins_review[@]}"; do
  if ! grep -qF -- "$pin" dodi-dev/skills/review/SKILL.md; then
    echo "review/SKILL.md missing DR-025 wording pin: ${pin}" >&2
    exit 1
  fi
done
dr025_pins_agents=(
  "Post-fix focused re-rounds run at Capable tier (\`opus@high\`) by default"
  "and its post-fix focused re-round"
)
for pin in "${dr025_pins_agents[@]}"; do
  if ! grep -qF -- "$pin" AGENTS.md; then
    echo "AGENTS.md missing DR-025 wording pin: ${pin}" >&2
    exit 1
  fi
done
# Negative assertions: the retired pre-DR-025 shapes must not reappear.
# Combined with the positive pins, the asymmetry cannot silently return:
# re-adding either retired phrase fails here, and deleting the new doctrine
# text fails the positive pins instead.
if grep -qF -- "focused re-round at the gate's fable seat" dodi-dev/skills/review/SKILL.md; then
  echo "retired pre-DR-025 wording (unconditional re-round fable seat) reappeared: dodi-dev/skills/review/SKILL.md" >&2
  exit 1
fi
if grep -qF -- "inherit their gate's policy" AGENTS.md; then
  echo "retired pre-DR-025 inherit rule reappeared: AGENTS.md" >&2
  exit 1
fi
```

- [ ] **Step 2:** Verify positive case and syntax

Run: `bash -n scripts/validate-phase-skills.sh && bash scripts/validate-phase-skills.sh; echo "exit: $?"`
Expected: file listing then `phase skills ok`, `exit: 0`.

- [ ] **Step 3:** Hand-run the three negative cases and record every command + exit code in the lane's PR evidence. The edited files are committed (Tasks 2–3), so an in-place scratch edit restored by git is the spec § 6 "scratch copy" demonstration — same evidence, established precedent (DOD-1215 plan, Task 5).

Case (i) — deleting the doctrine sentence breaks the build via pin (c) (spec § 6's explicit verification):

```bash
python3 - <<'PY'
from pathlib import Path
p = Path("AGENTS.md"); s = p.read_text()
frag = "Post-fix focused re-rounds run at Capable tier (`opus@high`) by default"
assert s.count(frag) == 1
p.write_text(s.replace(frag, "", 1))
PY
bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `AGENTS.md missing DR-025 wording pin: Post-fix focused re-rounds run at Capable tier (`opus@high`) by default` on stderr, `exit: 1`.

```bash
git checkout -- AGENTS.md && bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `phase skills ok`, `exit: 0`.

Case (ii) — the retired `:47` wording cannot reappear:

```bash
printf '\n%s\n' "scratch negative: focused re-round at the gate's fable seat" >> dodi-dev/skills/review/SKILL.md
bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `retired pre-DR-025 wording (unconditional re-round fable seat) reappeared: dodi-dev/skills/review/SKILL.md` on stderr, `exit: 1`.

```bash
git checkout -- dodi-dev/skills/review/SKILL.md && bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `phase skills ok`, `exit: 0`.

Case (iii) — the retired inherit rule cannot reappear:

```bash
printf '\n%s\n' "scratch negative: re-rounds inherit their gate's policy" >> AGENTS.md
bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `retired pre-DR-025 inherit rule reappeared: AGENTS.md` on stderr, `exit: 1`.

```bash
git checkout -- AGENTS.md && bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `phase skills ok`, `exit: 0`. All six validator runs + exit codes go in the PR evidence — this demonstration is the test.

- [ ] **Step 4:** Commit

```bash
git add scripts/validate-phase-skills.sh
git commit -m "DOD-1218: DR-025 wording pins — five positives, two retired-shape negatives

Pins the :47 hard+standard clauses, the unchanged :55 clause, the AGENTS.md
doctrine core, the hard-row re-round cell, and the :48 fix-loop closure;
fails if either retired pre-ruling phrase reappears. Negative cases
hand-verified with git-restored scratch edits.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 6: Version bump 0.17.3 → 0.17.4 (five files, lockstep)

Expected base is `0.17.3`; target `0.17.4` (patch per DR-015's boundary — row coverage and doctrine wording, no new axis). ⚠ If Task 0 Step 1 reported a different base, substitute the next patch above it throughout. `.agents/plugins/marketplace.json` carries no version key — do not add one.

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `dodi-dev/.claude-plugin/plugin.json`
- Modify: `dodi-dev/.codex-plugin/plugin.json`
- Modify: `.grok-plugin/marketplace.json`
- Modify: `dodi-dev/.grok-plugin/plugin.json`

- [ ] **Step 1:** In each of the five files, replace:

```text
"version": "0.17.3",
```

with:

```text
"version": "0.17.4",
```

(Indentation differs between marketplace and plugin files; the metadata validator is the authoritative parity check.)

- [ ] **Step 2:** Verify the metadata lockstep

Run: `bash scripts/validate-plugin-metadata.sh; echo "exit: $?"`
Expected: `plugin metadata ok: 0.17.4`, `exit: 0`.

Run: `grep -h '"version"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json`
Expected: five lines, all `"version": "0.17.4"`.

Run: `grep -c '"version"' .agents/plugins/marketplace.json; echo "exit: $?"`
Expected: `0`, `exit: 1` (no version key added).

- [ ] **Step 3:** Commit — the release commit message carries the bare version string per AGENTS.md Editing Rules, so releases stay findable with `git log --grep`. The `v0.17.4` tag is applied to this version-bump commit **at release time by the epic PR process** (tag + push per AGENTS.md's release rule happen when the epic reaches main) — this lane never pushes and never tags.

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json
git commit -m "DOD-1218: 0.17.4 — tier-conditional child-PR focused re-round (DR-025)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 7: Decision-register entry — DR-025 implementation record + scoped DR-003 amendment (spec § Design 5)

No repository files change. Executed by the lane's top-level session against the PM system (epic ticket DOD-1213), at the lane's close-out surface for this ticket (with the child-PR evidence; keyed by ticket id pre-merge per register convention). Both halves land together — entry comment first, canon table in the same sitting.

- [ ] **Step 1:** Read the epic description's `## Decision Register — Canon` table and take the **next free DR number** (expected `DR-026` — DR-025 is the ruling itself and is already canon; if entries landed since, use the actual next free number and substitute it below, including in the DR-003 annotation).

- [ ] **Step 2:** Post the entry comment on epic DOD-1213 (append-only; never edit a posted comment):

```text
DR-026 — Implementation of DR-025 (DOD-1218; keyed to ticket DOD-1218 pre-merge, child-PR evidence attached to the lane exit report).

**Ruled direction implemented:** DR-025 (operator, 2026-08-29Z) — Direction B scoped to standard-tier tickets only. Child-PR post-fix focused re-round: **hard** fable seat (`fable@xhigh`) on `needs-capable-delivery` tickets; plain Capable seat (`opus@high` — no substitution, no `tier-degraded` marker, no make-up) on standard-tier tickets. Verify-stage focused re-review unchanged at Capable (`opus@high`) on every ticket tier. Rejected alternatives, by name: A (parity via inherit — unnecessary added cost), full B (all-`opus` re-round would collapse writer and reviewer on `needs-capable-delivery`), C (first-class deferred row — same bill as A), D (ratify status quo — the standard-tier asymmetry was not retained).

**Operative principle (now doctrine, AGENTS.md § Fable Availability Policy):** post-fix focused re-rounds run at Capable tier (`opus@high`) by default; a re-round keeps its gate's hard fable seat only where both hold — it is the last checkpoint before the fix delta reaches the epic branch, and the fix worker is itself Capable.

**DR-003 amendment (scoped, by operator ruling):** DR-003 is amended by operator ruling DR-025 — the standard-tier child-PR post-fix re-round's deferred seat is removed on the operator's own authority; DR-003 continues to bind every other seat and all agent-proposed removals.

**Fable bill:** −1 deferred fable dispatch (and one fewer potential FABLE_MAKEUP obligation) per standard-tier child-PR fix loop; zero park-edge change — no hard seat moved.

**Revisit trigger:** at N≥10 tickets carrying a `focused-re-review` gate-ledger line paired with a completed child-PR ledger, run the fix-delta location analysis (spec § Evidence) and re-open as an evidence-based reclassification of DR-025's standard-tier scope. N=2 today (DOD-1098 conforming, DOD-990 the retroactively non-conforming reading — stands as posted, append-only).
```

- [ ] **Step 3:** Maintain the canon table in the epic **description** (the one surface maintained in place):
  - Append a `DR-026` row summarizing the entry: `child-PR post-fix re-round tier-conditional per DR-025 (hard fable on needs-capable-delivery, plain Capable on standard tier); verify-stage re-review Capable on all tiers; DR-003 scope-amended by operator ruling`.
  - Annotate DR-003's **existing** row (append to its text — do not rewrite its original wording, per the spec's ⚠ record-shape assumption): `(amended by DR-025/DR-026 — the standard-tier child-PR post-fix re-round's deferred seat removed on the operator's own authority; binds every other seat and all agent-proposed removals)`.

- [ ] **Step 4:** Verify: re-read the canon table and confirm no live contradiction remains — DR-003's row carries the amendment annotation, the DR-026 row is present, and DR-025's row is untouched. Record the comment URL/id in the lane exit evidence.

### Task 8: Full acceptance + regression sweep (no code changes)

- [ ] **Step 1:** Acceptance greps

```bash
grep -n "focused re-round at the gate's fable seat" dodi-dev/skills/review/SKILL.md; echo "exit: $?"   # empty, exit: 1 — the ticket's acceptance grep
grep -cF 'tier-conditional per AGENTS.md § Fable Availability Policy (DR-025)' dodi-dev/skills/review/SKILL.md   # 1
grep -cF 'Post-fix focused re-rounds run at Capable tier (`opus@high`) by default' AGENTS.md   # 1
grep -cF 'and its post-fix focused re-round' AGENTS.md   # 1
grep -cF 'a fresh reviewer at Capable tier (`model: opus` on Claude Code) reads the fix delta' dodi-dev/skills/review/SKILL.md   # 1 — :55 stationary
```
Expected: as annotated per line.

- [ ] **Step 2:** Invariant sweep (spec § Design 8) — every listed surface byte-identical to the epic branch base. With `<base>` = the merge-base with the epic branch (`git merge-base HEAD origin/epic/dod-1213-fable-scarcity-doctrine`):

```bash
git diff <base> -- dodi-dev/skills/review/review-prompt.md                                  # empty
git diff <base> -- dodi-dev/scripts/hook-require-model-pin.sh                               # empty
git diff <base> -- dodi-dev/skills/epic-orchestrator/execution-model.md                     # empty
git diff <base> -- dodi-dev/skills/epic-orchestrator/state-transitions.md                   # empty
git diff <base> -- dodi-dev/skills/epic-orchestrator/lanes/deliver-playbook.md              # empty
git diff <base> -- dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md               # empty
git diff <base> -- docs/specs/2026-07-07-execution-model-flatten-design.md                  # empty — historical record, never edited
git diff -U0 <base> -- dodi-dev/skills/review/SKILL.md | grep '^[+-]' | grep -c 'caught-by\|gate-ledger'   # 0 (grep exits 1) — ledger/catch grammar untouched
```
Expected: as annotated.

- [ ] **Step 3:** Manual read-through — record both halves **verbatim in the PR body** (the acceptance-criterion read-through; spec § Acceptance):
  - Reading only `AGENTS.md` § Fable Availability Policy + `dodi-dev/skills/epic-orchestrator/execution-model.md` § 2, state the pin for each of the four cells. Expected answers: standard-tier ticket — verify-stage focused re-review `opus@high`, child-PR post-fix re-round `opus@high`; `needs-capable-delivery` ticket — verify-stage focused re-review `opus@high`, child-PR post-fix re-round `fable@xhigh`, **hard**. All four must be answerable from the doctrine sentence alone, deterministically.
  - Reading `dodi-dev/skills/review/SKILL.md` step 5 (the `:48` closure rule) **alone**: does a standard-tier gate closed by a post-fix re-round queue a fable make-up? Expected: **no** — plain `opus@high`, no substitution, no make-up (versus the no-fix-loop path, where the deferred final does queue one).

- [ ] **Step 4:** Full three-validator battery

```bash
bash scripts/validate-plugin-metadata.sh             # exit 0, "plugin metadata ok: 0.17.4"
bash scripts/validate-phase-skills.sh                # exit 0, "phase skills ok"
bash scripts/validate-ticket-comment-templates.sh    # exit 0, "ticket comment templates ok"
```
Expected: every validator exits 0.

- [ ] **Step 5:** Confirm the working tree is clean

Run: `git status --short`
Expected: empty (all changes committed across Tasks 1–6). If a Task 5 scratch edit leaked, `git checkout -- AGENTS.md dodi-dev/skills/review/SKILL.md` and re-run Step 4 before finishing.
