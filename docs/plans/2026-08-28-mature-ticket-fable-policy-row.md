# Operator-Choice Fable Policy Row for mature-ticket (DOD-1215) Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** Give the repo's only frontmatter `model: fable` session pin (`dodi-dev/skills/mature-ticket/SKILL.md:4`) its missing Fable Availability Policy row — a fourth, manual-session-only **operator-choice** row (wait, or proceed at `Capable@max`, declared via a `session-tier:` line) — per spec `docs/specs/2026-08-28-mature-ticket-fable-policy-row-design.md` and canon DR-001/DR-004/DR-005.

**Architecture:** Pure doctrine-and-propagation change plus one mechanical guard: prose edits in `AGENTS.md` (§ Model Tiers one bullet; § Fable Availability Policy table + one new Mechanics bullet), the two-file drift pair (`dodi-dev/skills/mature-ticket/SKILL.md` and `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md`) moved together, one new fable-seat-has-a-row check in `scripts/validate-phase-skills.sh`, and the five-file version bump. Nothing on the autonomous path changes: `drive-epic` stays `model: sonnet`, the four mature-lane phase policies and the three existing policy rows stay byte-identical, `dodi-dev/scripts/hook-require-model-pin.sh` stays byte-identical to main, and no `effort:` frontmatter key is introduced anywhere.

**Tech Stack:** Markdown doctrine files, bash validators, JSON plugin metadata. No CI — every check is local (`bash <path>` from the worktree root).

**Worktree:** `/Users/may/github/dodi/dodi-skills/dodi-dev/worktrees/epic-dod-1213`, branch `epic/dod-1213-fable-scarcity-doctrine`. Run every command from this worktree root.

**Upstream precondition (hard):** DOD-1214 (`docs/plans/2026-08-28-effort-first-class-axis.md`) must already be merged into the epic branch — this plan consumes its `<tier>@<effort>` notation, the `Capable@max` substitution target, the effort table, and the extended `tier-degraded(<from>@<effort>→<to>@<effort>,<policy>)` marker grammar. Task 0 verifies this mechanically before any edit.

**Anchoring rule (read first):** DOD-1214 edits the same `AGENTS.md` sections before this plan runs, so **every edit below is anchored by section name + verbatim anchor text, never by line number**. All anchor strings quoted below were verified against the pre-1214 files and chosen from text DOD-1214's plan does not touch (checked against that plan's diffs), so they are expected to match verbatim post-merge — but the implementer MUST re-verify each anchor against the live file at implementation time (a `grep -F` per anchor, as written into each task) and stop with a concrete blocker if an anchor has drifted, rather than guessing a nearby location.

## Testing Contract

### Required Test Groups

- Unit: `not-required`
  - Scope: n/a (doctrine prose plus one validator check)
  - Reason: no unit-test harness for markdown/doctrine content exists in this repo and inventing one is out of scope (ticket testing contract: "There is no automated test harness for doctrine or skill prose in this repo, and none should be invented").
  - Minimum assertions: none.

- Integration: `required`
  - Scope: repository validators over the full skill tree, AGENTS.md, and plugin metadata.
  - Reason: the three `scripts/validate-*.sh` validators are the real regression surface, and the new fable-seat check in `validate-phase-skills.sh` is the ticket's mechanical invariant ("a fable seat without a row is a defect" made code for frontmatter seats).
  - Harness: `existing` — standalone bash scripts, no runner above them.
  - Minimum assertions:
    - `bash scripts/validate-plugin-metadata.sh` exits 0 (five-file version parity at the new version).
    - `bash scripts/validate-phase-skills.sh` exits 0 and prints `phase skills ok` (all existing checks plus the new fable-seat check pass).
    - `bash scripts/validate-ticket-comment-templates.sh` exits 0.
    - **Negative case for the new check, run by hand and recorded in the PR evidence:** delete the `operator-choice` row from `AGENTS.md` → validator exits non-zero printing `frontmatter fable pin without a Fable Availability Policy row: mature-ticket` → restore → validator exits 0 again (exact commands in Task 5). There is no unit-test file for the validators themselves, so this demonstration **is** the test — record commands and exit codes.

- E2E: `not-required` (not-applicable)
  - Scope: n/a.
  - Reason: the operator-choice behavior is a human-in-the-loop prose protocol on a session pin — no hook can see a frontmatter pin (`hook-require-model-pin.sh` reads dispatch payloads only) and no harness surface exists to drive "fable unavailable at invocation" deterministically. Prose-and-declaration is the ticket's declared posture (DR-005 analog), not a coverage oversight.
  - Harness: `not-applicable`
  - Minimum assertions: none.

### Critical Flows

- `bash scripts/validate-phase-skills.sh` passes on the full edited tree, and fails naming `mature-ticket` when the `operator-choice` row is removed from `AGENTS.md` (negative case, Task 5).
- `grep -n "operator-choice" AGENTS.md` returns the table row (three columns populated) between the policy-table header and the "A fable seat without a row is a defect" paragraph, plus the Mechanics bullet and the § Model Tiers sentence.
- `grep -n "Capable tier" dodi-dev/skills/mature-ticket/SKILL.md` returns a line containing `` `model: opus` on Claude Code `` (harness-neutral form per AGENTS.md Editing Rules).
- The `session-tier:` grammar appears exactly once as a definition (AGENTS.md new Mechanics bullet); the two skill files reference it without restating its internals.

### Regression Surface

- `dodi-dev/scripts/hook-require-model-pin.sh` must stay byte-identical to `main` — proven by `git diff main -- dodi-dev/scripts/hook-require-model-pin.sh` (empty). The six `dodi-dev/scripts/tests/*.sh` are **not required** by the ticket (hook untouched); run `test-hooks-payload.sh` only if that file ever shows in the diff (it must not).
- The three existing policy rows (`hard`, `deferred`, `soft`) and the four mature-lane phase policies (`mature-playbook.md` § Phase sequence) stay byte-identical — proven by inspecting `git diff` (Task 7).
- `drive-epic/SKILL.md` untouched; all other SKILL.md frontmatter untouched; frontmatter key inventory across all 20 skills stays exactly `name`, `description`, `model` (no `effort:` key anywhere).
- All pre-existing checks in `validate-phase-skills.sh` (tier/effort self-declaration, script existence, repo-only-reference ban, Testing Contract shape) still pass.

### Commands

- Unit: `not-required — none`
- Integration: `bash scripts/validate-phase-skills.sh` ; `bash scripts/validate-plugin-metadata.sh` ; `bash scripts/validate-ticket-comment-templates.sh` ; negative case per Task 5
- E2E: `not-applicable — none`
- Broader regression: `git diff main -- dodi-dev/scripts/hook-require-model-pin.sh` (empty) ; acceptance greps in Task 7

### Harness Requirements

- `bash`, `python3` (used inside the validators), `git` — all present locally; no services, env vars, seeds, browsers, mocks, or accounts. Run everything from the worktree root (the validators use repo-relative paths).

### Non-Required Rationale

- Unit: doctrine prose plus one grep-shaped validator check; no markdown unit harness exists and inventing one is out of scope per the ticket's own testing contract.
- Integration: (required — n/a)
- E2E: a session pin has no dispatch payload, no hook surface, and no mechanical failure injection point; the row is deliberately prose-and-declaration (spec Goal 4, DR-005 posture). The honest coverage story is the validator-enforced row-existence invariant plus the manual prose verification in Task 7.

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## File Structure

No files are created except this plan. Modified files (9):

| File | Responsibility of the change |
|------|------------------------------|
| `AGENTS.md` | § Model Tiers: extend the judgment-heavy-interactive bullet (operator-choice seat naming, deliberate asymmetry, inherited-session-model exclusion); § Fable Availability Policy: fourth table row + one new Mechanics bullet (the `session-tier:` grammar's single definition) |
| `dodi-dev/skills/mature-ticket/SKILL.md` | Extend the frontmatter-pin paragraph (self-check + operator choice, reference-not-restate); add the `operator-wait` exit-state bullet |
| `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md` | § Model tiers: matching sentence (drift pair); § Evidence: `session-tier:` bullet; § Exit states: one clause naming the operator-choice policy |
| `scripts/validate-phase-skills.sh` | New fable-seat-has-a-row check (frontmatter `model: fable` ⇒ a policy-table row names the skill in backticks) |
| `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json` | Version bump to the next patch above the epic branch's current version (expected `0.17.0` → `0.17.1`) |

**Never modified:** `dodi-dev/skills/drive-epic/SKILL.md`, the four phase policies in `mature-playbook.md` § Phase sequence, the three existing policy rows and the "A fable seat without a row is a defect" paragraph in `AGENTS.md`, `dodi-dev/scripts/hook-require-model-pin.sh` (byte-identical to main), `dodi-dev/skills/epic-orchestrator/execution-model.md`, `dodi-dev/skills/brainstorm/SKILL.md`, `dodi-dev/skills/write-plan/SKILL.md`, any SKILL.md frontmatter, `.agents/plugins/marketplace.json` (carries no version field).

---

### Task 0: Precondition + anchor verification (no edits)

- [ ] **Step 1:** Confirm DOD-1214 is merged into the epic branch (this plan consumes its vocabulary)

Run: `grep -c 'Capable@max' AGENTS.md`
Expected: `1` or more (DOD-1214's elevated-substitution bullet is present). If `0`: **STOP — concrete blocker: DOD-1214 not merged; this ticket has a registered blocked-by edge on it.**

Run: `grep -n 'tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)' AGENTS.md`
Expected: one hit in the § Fable Availability Policy Attribution bullet (the extended marker grammar this plan's `session-tier:` line reuses).

- [ ] **Step 2:** Verify every anchor string this plan edits against exists exactly once in the live files

```bash
grep -cF 'Judgment-heavy interactive skills (brainstorm, write-plan) omit `model:`' AGENTS.md
grep -cF -- '- **soft → substitute, record only:** no obligation queued.' AGENTS.md
grep -cF 'A fable seat without a row is a defect.' AGENTS.md
grep -cF 'which is a defect the tier-pin hook forbids.' dodi-dev/skills/mature-ticket/SKILL.md
grep -cF 'and `hook-require-model-pin.sh` forbids it.' dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md
grep -cF '# Deterministic skeleton: plugin scripts exist, are executable, and parse.' scripts/validate-phase-skills.sh
```
Expected: every command prints `1`. If any prints `0` or `>1`, the anchor drifted (most likely under DOD-1214's merge): re-locate the intended edit site by section name in the live file, adjust the old_string to the live text **without changing the new content this plan specifies**, and note the adjustment in the PR evidence. If the *meaning* of the surrounding text changed (not just its wording), stop with a concrete blocker instead.

- [ ] **Step 3:** Record the current version for Task 6

Run: `bash scripts/validate-plugin-metadata.sh`
Expected: `plugin metadata ok: 0.17.0` (DOD-1214's shipped version). If it prints a different version, use that as the base for Task 6's next-patch bump and substitute it in Task 6's commands.

### Task 1: AGENTS.md § Model Tiers — operator-choice seat, deliberate asymmetry, inherited-model exclusion

**Files:**
- Modify: `AGENTS.md` § Model Tiers (the judgment-heavy-interactive-skills bullet — the one beginning `- Judgment-heavy interactive skills (brainstorm, write-plan)`)

- [ ] **Step 1:** Replace the bullet. Edit `AGENTS.md` — replace (verbatim, one bullet; verified untouched by DOD-1214's plan):

```text
- Judgment-heavy interactive skills (brainstorm, write-plan) omit `model:` and inherit the session model — run those sessions on the Frontier model. Mechanical interactive skills (pickup, file-ticket, submit) pin `sonnet`. The manual `mature-ticket` wrapper's `fable` frontmatter pin covers its own main loop only; in the autonomous epic lane the driver walks `lanes/mature-playbook.md` natively and looks up each dispatch's tier per the gate-policy table (§ Fable Availability Policy).
```

with:

```text
- Judgment-heavy interactive skills (brainstorm, write-plan) omit `model:` and inherit the session model — run those sessions on the Frontier model. Mechanical interactive skills (pickup, file-ticket, submit) pin `sonnet`. The manual `mature-ticket` wrapper's `fable` frontmatter pin covers its own main loop only; it is the **operator-choice** seat in § Fable Availability Policy. In the autonomous epic lane the driver walks `lanes/mature-playbook.md` natively and looks up each dispatch's tier per the gate-policy table (§ Fable Availability Policy) — the manual-Frontier / driver-Standard asymmetry for the same playbook is deliberate: the driver's main loop is a router whose judgment work is entirely dispatched (orchestration routing is Standard, per the tier table), while a manual session's main loop hosts interactive judgment with the operator — it seats Frontier for the same reason brainstorm and write-plan sessions run Frontier. Inherited session models are not fable seats: `brainstorm` and `write-plan` omit `model:`, so their tier is the operator's own session choice made before invocation — there is no pin for scarcity to fail and nothing for a policy row to govern; the operator-choice row covers frontmatter pins only.
```

- [ ] **Step 2:** Verify

Run: `grep -n 'operator-choice seat\|asymmetry for the same playbook is deliberate\|no pin for scarcity to fail' AGENTS.md`
Expected: all three phrases hit, all inside § Model Tiers (one bullet).

### Task 2: AGENTS.md § Fable Availability Policy — fourth row + operator-choice Mechanics bullet

**Files:**
- Modify: `AGENTS.md` § Fable Availability Policy (table: add one row after the `soft` row; Mechanics list: add one bullet after the `soft` bullet)

- [ ] **Step 1:** Add the fourth table row. Edit `AGENTS.md` — the `soft` table row is the long line beginning `| **soft** | `opus` substitutes; no make-up |` and ending `| ... the epic docs-sync sweep is the backstop) |`. Immediately **after** that full line (and before the blank line preceding the `A fable seat without a row is a defect.` paragraph), insert this new line:

```text
| **operator-choice** | manual-session ask: the session stops and the present operator decides — **wait** for fable, or **proceed at `Capable@max`** with the substitution declared. Never automatic: no park, no silent substitution, no make-up obligation. A session-pin policy a manual session applies to itself — never a dispatch policy; the driver never performs this lookup | the manual `mature-ticket` wrapper's `model: fable` main-loop session pin — the repo's only frontmatter fable seat; the `scripts/validate-phase-skills.sh` fable-seat check keeps this cell's scope from going stale if a second frontmatter fable pin is ever added |
```

The three existing rows and the "A fable seat without a row is a defect." paragraph are byte-untouched — the seat now has a row, so the paragraph needs no edit.

- [ ] **Step 2:** Add the Mechanics bullet. Edit `AGENTS.md` — immediately **after** the line:

```text
- **soft → substitute, record only:** no obligation queued.
```

(and before the `- **Attribution (never silent):** ...` bullet), insert:

```text
- **operator-choice → ask the operator (manual sessions only):** a session pin has no dispatch to fail, so detection is invocation-shaped, not dispatch-shaped — at skill start the wrapper **self-checks that its main loop is running Frontier tier** (the session-level analog of tier self-declaration; it covers a visible harness failure, a silent fallback, and an allowance the operator already knows is exhausted, without depending on which the harness does), and a capacity failure mid-lane surfaces in the operator's own terminal. Either way the session stops **before further claims or dispatches** and puts the choice: **wait** — stop and report; resume when capacity returns; never a `pending-capacity` park (manual sessions never park; a mid-lane wait exits `RESUMABLE` with the continuation brief naming fable capacity as the resume condition) — or **proceed at `Capable@max`** — the operator switches the session (`model: opus` on Claude Code, session effort `max`), since only the operator controls session-level dials; the skill cannot rewrite its own frontmatter. A proceed is recorded, never silent: every gate-transition comment the substituted session posts carries `session-tier: tier-degraded(fable@xhigh→opus@max,operator-choice)` — the same extended marker grammar as catch attribution, with `operator-choice` as the policy component; efforts are the declared values per the effort table, never a runtime readout; `opus@max` is legal here because `Capable@max` is the declared elevated-substitution target for exactly this seat. The `session-tier:` prefix (rather than `caught-by:`) exists because the coordinating main loop posts no findings — this line rides the gate-transition comments the lane already posts, and is defined once, here; the skill files reference it. No make-up obligation is queued — the human judged the tradeoff. **No hook enforces a session pin** — `hook-require-model-pin.sh` sees dispatch payloads only — so this row is prose-and-declaration, the same posture as effort. The lane's dispatches are untouched: each still performs its own per-gate lookup at dispatch time, at the pin its own row produces.
```

- [ ] **Step 3:** Verify

Run: `awk '/^## Fable Availability Policy/,/^## Dispatch Discipline/' AGENTS.md | grep -c '^| \*\*'`
Expected: `4` (hard, deferred, soft, operator-choice — header/separator lines don't start `| **`).

Run: `grep -n 'session-tier: tier-degraded(fable@xhigh→opus@max,operator-choice)' AGENTS.md`
Expected: exactly one hit (the grammar's single definition, in the new Mechanics bullet).

Run: `git diff -U0 AGENTS.md | grep '^-' | grep -E '\*\*(hard|deferred|soft)\*\*'`
Expected: no output (the three existing rows and their Mechanics bullets are byte-identical — acceptance criterion 2).

- [ ] **Step 4:** Read the section once end to end and confirm: the row sits between the table header and the "A fable seat without a row is a defect" paragraph with all three columns populated (acceptance criterion 1); no dispatch gate moved into the new row; the bullet states plainly that no hook enforces a session pin (spec Goal 4).

- [ ] **Step 5:** Commit

```bash
git add AGENTS.md
git commit -m "DOD-1215: operator-choice fable policy row for the mature-ticket session pin

Fourth gate-table row + Mechanics bullet: manual sessions self-check the
main-loop tier at invocation, then ask the present operator — wait (stop
and report, never a park) or proceed at Capable@max with the substitution
declared via a session-tier: line on each gate-transition comment. Also
names the seat in § Model Tiers, states the manual-Frontier/driver-Standard
asymmetry as deliberate, and excludes inherited session models
(brainstorm/write-plan) from the table. Three existing rows byte-identical.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 3: mature-ticket/SKILL.md — pin paragraph + operator-wait exit state

**Files:**
- Modify: `dodi-dev/skills/mature-ticket/SKILL.md` (the frontmatter-pin paragraph; § Exit states)

- [ ] **Step 1:** Extend the pin paragraph (reference, never restate). Replace:

```text
The `model: fable` frontmatter pin covers this wrapper's main loop only — it never flows into worker dispatches. Every dispatch inside the playbook carries its own explicit pin and fable-policy (per `execution-model.md` § 2); a dispatch without a pin inherits the frontmatter default, which is a defect the tier-pin hook forbids.
```

with:

```text
The `model: fable` frontmatter pin covers this wrapper's main loop only — it never flows into worker dispatches. Every dispatch inside the playbook carries its own explicit pin and fable-policy (per `execution-model.md` § 2); a dispatch without a pin inherits the frontmatter default, which is a defect the tier-pin hook forbids. The pin itself is the **operator-choice** seat in AGENTS.md § Fable Availability Policy: at invocation, before claiming, confirm the main loop is running Frontier tier — if it is not, or if fable capacity fails mid-lane, stop and put the choice to the operator per that policy: **wait**, or **proceed at Capable tier (`model: opus` on Claude Code) at `max` effort** with the substitution declared per the policy's `session-tier:` grammar on each gate-transition comment.
```

(Deliberately no restatement of detection retries, make-up obligations, or the marker's internals — acceptance criterion 5.)

- [ ] **Step 2:** Add the `operator-wait` exit state. In `## Exit states`, immediately **after** the existing final bullet (the `- **RESUMABLE** — ...` bullet, which is preserved byte-unchanged), append:

```text
- **operator-wait** — fable unavailable at the session pin and the operator chose to wait (the operator-choice policy, AGENTS.md § Fable Availability Policy): stop and report — never a park. At invocation this is a plain stop before any claim; mid-lane it is a `RESUMABLE` exit (push + continuation brief naming fable capacity as the resume condition). A **proceed** choice is not an exit — the lane continues at the declared substitution.
```

- [ ] **Step 3:** Verify

Run: `grep -n "Capable tier" dodi-dev/skills/mature-ticket/SKILL.md`
Expected: one hit, containing `` `model: opus` on Claude Code `` (acceptance criterion 4 — harness-neutral form).

Run: `grep -n "pending-capacity" dodi-dev/skills/mature-ticket/SKILL.md; echo "exit: $?"`
Expected: no output, `exit: 1` (acceptance criterion 6 — the word is never introduced in this file).

Run: `grep -cF 'capacity-park and refresh-park are driver-only exits, not reachable by a manual session' dodi-dev/skills/mature-ticket/SKILL.md`
Expected: `1` (the existing driver-only exclusion is preserved unchanged).

### Task 4: mature-playbook.md — drift pair, evidence bullet, exit-state clause

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md` (§ Model tiers, § Evidence, § Exit states)

- [ ] **Step 1:** Extend § Model tiers (the matching half of the two-file drift pair). Replace:

```text
The `model: fable` frontmatter pin on the manual wrapper covers its main loop only — it never flows into worker dispatches. Every dispatch carries its own explicit pin: spec drafter, spec/plan reviewers, and plan writer carry Frontier pins; research and read-and-digest workers (external/integration API docs, test-harness orientation, codebase exploration) pin Standard tier (`model: sonnet` on Claude Code). A dispatch without a pin inherits the frontmatter default — that is a defect, not a default, and `hook-require-model-pin.sh` forbids it.
```

with:

```text
The `model: fable` frontmatter pin on the manual wrapper covers its main loop only — it never flows into worker dispatches. Every dispatch carries its own explicit pin: spec drafter, spec/plan reviewers, and plan writer carry Frontier pins; research and read-and-digest workers (external/integration API docs, test-harness orientation, codebase exploration) pin Standard tier (`model: sonnet` on Claude Code). A dispatch without a pin inherits the frontmatter default — that is a defect, not a default, and `hook-require-model-pin.sh` forbids it. The frontmatter pin is the **operator-choice** seat in AGENTS.md § Fable Availability Policy; when a manual session runs under that row's declared substitution, its main loop is `Capable@max` while every dispatch keeps its own per-gate pin and fable-policy, unchanged.
```

- [ ] **Step 2:** Add the evidence bullet. In `## Evidence`, immediately **after** the bullet beginning `- Post each review gate's close-out `gate-ledger` line`, insert:

```text
- A session running under an operator-choice substitution appends the `session-tier:` line (grammar: AGENTS.md § Fable Availability Policy) to each gate-transition comment it posts. A wait needs no marker — nothing was substituted.
```

- [ ] **Step 3:** Extend the § Exit states RESUMABLE bullet with one clause naming the policy. Replace:

```text
- **RESUMABLE** — a deliberate context exit (an emergency reset for either executor, or — driver-only — a capacity-park or refresh-park; a manual `mature-ticket` session stops and reports rather than parking): push to the epic branch, write the continuation brief keyed to that SHA + last seam, and exit for re-dispatch.
```

with:

```text
- **RESUMABLE** — a deliberate context exit (an emergency reset for either executor, or — driver-only — a capacity-park or refresh-park; a manual `mature-ticket` session stops and reports rather than parking, including an operator-chosen **wait** under the operator-choice fable policy): push to the epic branch, write the continuation brief keyed to that SHA + last seam, and exit for re-dispatch.
```

- [ ] **Step 4:** Verify the drift pair agrees

Run: `grep -n 'operator-choice' dodi-dev/skills/mature-ticket/SKILL.md dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md`
Expected: hits in both files; read the two pin paragraphs side by side and confirm they make the same claims (pin = operator-choice seat; substitution = Capable@max main loop; dispatches unchanged) — acceptance criterion 7.

Run: `git diff -U0 dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md | grep '^-' | grep -E 'Draft spec|Spec review loop|Write plan|Plan review loop'`
Expected: no output (the four phase-policy rows are untouched — Non-Goals).

- [ ] **Step 5:** Commit

```bash
git add dodi-dev/skills/mature-ticket/SKILL.md dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md
git commit -m "DOD-1215: mature-ticket wrapper + playbook name the operator-choice seat

The two-file drift pair moves together: SKILL.md gains the invocation-time
self-check, the operator choice (wait / proceed at Capable tier
(model: opus on Claude Code) at max effort), and the operator-wait exit
state; the playbook gains the matching Model-tiers sentence, the
session-tier evidence bullet, and one exit-state clause. Reference, never
restate: grammar and mechanics live in AGENTS.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 5: Validator fable-seat check + hand-run negative case

**Files:**
- Modify: `scripts/validate-phase-skills.sh` (insert a new check block after the tier/effort self-declaration loop, before the deterministic-skeleton block)

- [ ] **Step 1:** Insert the check. Edit `scripts/validate-phase-skills.sh` — immediately **before** the comment line:

```text
# Deterministic skeleton: plugin scripts exist, are executable, and parse.
```

insert (followed by a blank line separating it from that comment):

```bash
# Fable Availability Policy: every frontmatter `model: fable` pin has a policy
# row naming its skill (AGENTS.md "a fable seat without a row is a defect").
# Scoped to the frontmatter block only (a `model: fable` in prose never
# matches); the match is any policy-table row line naming the skill in
# backticks, so bucket renames never break it and prose mentions outside the
# table never false-positive.
for skill in "${skills[@]}"; do
  f="dodi-dev/skills/${skill}/SKILL.md"
  if awk 'NR==1 && /^---$/ {inf=1; next} inf && /^---$/ {exit} inf' "$f" | grep -q '^model: fable$'; then
    if ! grep -q "^[[:space:]]*|.*\`${skill}\`" AGENTS.md; then
      echo "frontmatter fable pin without a Fable Availability Policy row: ${skill}" >&2
      exit 1
    fi
  fi
done
```

(Implementation notes, per spec § 6: the `skills` array is already defined at the top of the script; the script runs from the repo root, and reading `AGENTS.md` is legal here — the repo-only-reference ban applies to skills, not `scripts/`. The single-grep form `^[[:space:]]*|.*\`skill\`` replaces the spec sketch's two-grep pipeline — same predicate, no pipeline under `set -o pipefail`, and `[[:space:]]` instead of `\s` for portable ERE/BRE.)

- [ ] **Step 2:** Verify positive case and syntax

Run: `bash -n scripts/validate-phase-skills.sh && bash scripts/validate-phase-skills.sh; echo "exit: $?"`
Expected: file listing then `phase skills ok`, `exit: 0` (the `operator-choice` row's Gates cell names `` `mature-ticket` `` in backticks on a `|`-prefixed line, so the check passes).

- [ ] **Step 3:** Hand-run the negative case and record the transcript in the lane's PR evidence. AGENTS.md is committed (Task 2), so an in-place delete restored by git is the scratch edit the ticket's contract calls for — same demonstration, same evidence.

```bash
sed -i '' '/^| \*\*operator-choice\*\*/d' AGENTS.md
bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `frontmatter fable pin without a Fable Availability Policy row: mature-ticket` on stderr, `exit: 1`.

```bash
git checkout -- AGENTS.md
bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `phase skills ok`, `exit: 0`. Record all four commands and both exit codes — this demonstration **is** the test (acceptance criterion 3).

- [ ] **Step 4:** Commit

```bash
git add scripts/validate-phase-skills.sh
git commit -m "DOD-1215: validator requires a policy row for every frontmatter fable pin

Frontmatter-scoped (awk over the --- block), name-agnostic on the bucket,
backtick-anchored to policy-table row lines. Negative case hand-verified:
deleting the operator-choice row fails naming mature-ticket.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 6: Version bump — next patch above the epic branch's current version (five files)

Expected base is `0.17.0` (DOD-1214's ship); target then `0.17.1`. If Task 0 Step 3 reported a different base, substitute the next patch above it throughout this task. `.agents/plugins/marketplace.json` carries no version field — do not touch it.

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `dodi-dev/.claude-plugin/plugin.json`
- Modify: `dodi-dev/.codex-plugin/plugin.json`
- Modify: `.grok-plugin/marketplace.json`
- Modify: `dodi-dev/.grok-plugin/plugin.json`

- [ ] **Step 1:** In each of the five files, replace:
```text
"version": "0.17.0",
```
with:
```text
"version": "0.17.1",
```

- [ ] **Step 2:** Verify (acceptance criteria 8 and 11)

Run: `bash scripts/validate-plugin-metadata.sh; echo "exit: $?"`
Expected: `plugin metadata ok: 0.17.1`, `exit: 0`.

Run: `grep -h '"version"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json`
Expected: five lines, all carrying `"version": "0.17.1"` (indentation may differ between marketplace and plugin files; the metadata validator is the authoritative parity check).

- [ ] **Step 3:** Commit (bare version string in the message per AGENTS.md Editing Rules; the `v0.17.1` tag is applied at release time by the epic PR process, not by this lane)

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json
git commit -m "DOD-1215: 0.17.1 — operator-choice fable policy row for the mature-ticket session pin

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 7: Full acceptance + regression sweep (no code changes)

- [ ] **Step 1:** Run the acceptance-criteria greps

```bash
grep -n "operator-choice" AGENTS.md                                              # criterion 1: row inside the policy table + Mechanics bullet + Model Tiers sentence
git log -p --follow -1 AGENTS.md >/dev/null; git diff main -- AGENTS.md | grep '^-' | grep -E '\*\*(hard|deferred|soft)\*\*'   # criterion 2: no output — existing rows byte-identical
grep -rn "model: fable" dodi-dev/skills | grep 'SKILL.md:4'                      # criterion 3 input: mature-ticket is still the only frontmatter fable pin
grep -n "Capable tier" dodi-dev/skills/mature-ticket/SKILL.md                    # criterion 4: line contains `model: opus` on Claude Code
grep -n "pending-capacity" dodi-dev/skills/mature-ticket/SKILL.md                # criterion 6: no output (exit 1)
for f in dodi-dev/skills/*/SKILL.md; do awk 'NR>1 && /^---$/{exit} NR>1{print $1}' "$f"; done | sort -u   # criterion 12: exactly `description:` `model:` `name:`
git diff main -- dodi-dev/scripts/hook-require-model-pin.sh                      # Non-Goals: empty output
git diff main -- dodi-dev/skills/drive-epic/SKILL.md                             # Non-Goals: empty output
```
Expected: as annotated per line.

- [ ] **Step 2:** Manual prose verification (the ticket's checklist, verbatim — no runner exists for these). Read the changed AGENTS.md section and both skill paragraphs end to end and confirm:
  - (a) harness-neutral per AGENTS.md Editing Rules — every harness-specific mechanic is written as the Claude form plus the tier name (`Capable tier (`model: opus` on Claude Code)`, `Capable@max`); the row reads correctly on Codex and Grok Build, where Frontier and Capable collapse to the same configuration and the row is simply never triggered (spec Edge case 7 — no runtime-conditional text needed);
  - (b) no repo-only file is referenced from inside a skill — the two skill files reference `AGENTS.md § Fable Availability Policy` (established convention, e.g. `review/SKILL.md`) and nothing under `docs/`;
  - (c) the scannable-header rule (AGENTS.md § Scannable Artifacts) is untouched — this change adds no human-facing artifact;
  - (d) `mature-ticket/SKILL.md` and `mature-playbook.md` agree about what the frontmatter pin covers (criterion 7);
  - (e) the `session-tier:` grammar is defined exactly once (AGENTS.md Mechanics bullet) and only referenced from the skill files (criterion 5 — reference, never restate; no retry counts, no make-up text, no marker internals in skill prose).

- [ ] **Step 3:** Run the three validators

```bash
bash scripts/validate-plugin-metadata.sh             # exit 0, "plugin metadata ok: 0.17.1"
bash scripts/validate-phase-skills.sh                # exit 0, "phase skills ok"
bash scripts/validate-ticket-comment-templates.sh    # exit 0
```
Expected: every validator exits 0. (The six `dodi-dev/scripts/tests/*.sh` are not required — the hook is untouched, proven by the empty `git diff main` in Step 1.)

- [ ] **Step 4:** Confirm the working tree is clean

Run: `git status --short`
Expected: empty (all changes committed across Tasks 2, 4, 5, 6). If the negative-case scratch edit from Task 5 leaked, `git checkout -- AGENTS.md` and re-run Step 3 before finishing.
