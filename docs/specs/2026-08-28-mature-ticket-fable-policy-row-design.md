# Operator-Choice Fable Policy Row for `mature-ticket`'s Session Pin — DOD-1215 Spec

Epic: DOD-1213 (fable scarcity doctrine). Ticket: DOD-1215. Status: draft for spec review.

Binding inputs: epic Decision Register canon DR-001..DR-005; DOD-1214 spec (`docs/specs/2026-08-28-effort-first-class-axis-design.md`) for the `<tier>@<effort>` vocabulary — DOD-1214 lands first (registered blocked-by edge), and this spec is written against its merged doctrine.

## TL;DR

`mature-ticket/SKILL.md:4` is the repo's only frontmatter `model: fable` pin and the only fable seat with no row in AGENTS.md § Fable Availability Policy — the defect `AGENTS.md:54` names. This spec implements canon **DR-001**: a fourth policy row, **operator-choice**, keyed to the manual wrapper's main-loop session pin. When fable is unavailable, the manual session stops and puts the choice to the present operator — **wait** (stop and report; never a park) or **proceed at `Capable@max`** (the operator switches the session; the substitution is declared, never silent, via a `session-tier:` line on each gate-transition comment). Detection is an invocation-time self-check (the manual analog of tier self-declaration, DR-005 posture), because a session pin has no dispatch to fail and no hook can see it. Nothing on the autonomous path changes; no dispatch gate moves; no `effort:` frontmatter key is introduced.

## Key Points

- **Decision — fourth row, not a clause.** The rule lives as an `operator-choice` row inside the gate-keyed table (the ticket's acceptance criteria require a three-column row between the header and the `AGENTS.md:54` defect sentence). Its Meaning cell states it is a session-pin policy manual sessions apply to themselves — never a dispatch policy, never a lookup the driver performs — which defuses the "reads like a fourth dispatch bucket" risk the ticket flagged.
- **Decision — detection is a self-check, not a dispatch signature.** At skill start the wrapper confirms its main loop is running Frontier tier; if not — whatever the cause: harness hard-fail (operator saw the error), silent fallback, or an allowance the operator already knows is exhausted — it stops and puts the choice before claiming or dispatching anything. This covers both possible harness failure modes without needing to verify which one occurs (the ticket's open question 2 dissolves rather than resolves).
- **Decision — substitution target is `Capable@max`, expressed as vocabulary, not frontmatter.** Per DR-005 and DOD-1214's non-goals, no `effort:` key is added anywhere; the operator effects the switch (session model `opus` on Claude Code, session effort `max`) because only the operator controls session-level dials. The frontmatter stays `model: fable`.
- **Decision — recording surface is the gate-transition comments.** A substituted session appends `session-tier: tier-degraded(fable@xhigh→opus@max,operator-choice)` to each of the four gate-transition comments it posts (grammar defined once, in the new AGENTS.md mechanics bullet, reusing DOD-1214's extended marker). A wait needs no marker — nothing was substituted; the `RESUMABLE` continuation brief records the resume condition.
- **Decision — `brainstorm`/`write-plan` get an exclusion sentence, not a row.** They omit `model:`; their tier is the operator's own session choice made before invocation — no pin exists for scarcity to fail, so they are not fable seats under DR-004's standard. One sentence at AGENTS.md § Model Tiers (the line-41 bullet) says so.
- **The autonomous path changes not at all.** `drive-epic` keeps `model: sonnet`; the four mature-lane dispatch policies and the three existing table rows stay byte-identical. The § Model Tiers bullet gains the explicit statement that the manual-Frontier / driver-Standard asymmetry for the same playbook is deliberate.
- **Proceeding at Capable does not soften the lane's hard dispatch gates.** Detection is never guessed in advance (`AGENTS.md:58`): the substituted session still attempts every fable dispatch at `fable`, and only an actual dispatch failure triggers the existing manual-session stop-and-report at a hard gate. See § Edge cases 1 — no dispatch policy is touched.
- **Mechanical guard included:** `scripts/validate-phase-skills.sh` gains a check that every frontmatter `model: fable` pin corresponds to a policy-table row naming that skill (the ticket's optional in-scope item; § Deterministic Skeleton — this is an invariant, so it becomes code).
- ⚠ Delegated assumptions are listed at the end; none is blocking. The one product-adjacent boundary — whether operator authority should ever extend to substituting a **hard dispatch gate** in a manual session — is explicitly out of this ticket's scope (dispatch policies unchanged) and flagged for a follow-up ticket only if the operator wants it.

## Problem

Verified in this worktree (branch `epic/dod-1213-fable-scarcity-doctrine`):

- `dodi-dev/skills/mature-ticket/SKILL.md:4` pins `model: fable` — confirmed the only frontmatter fable pin across all 20 skills (`grep -rn "model: fable" dodi-dev/skills`: every other hit is a worker-prompt or skill-prose dispatch seat, each already covered by a gate row).
- The § Fable Availability Policy table (`AGENTS.md:48-52`) is gate-keyed; every Gates cell names dispatch gates. `AGENTS.md:54`: "A fable seat without a row is a defect." The session pin has no row — the defect is missing coverage, not a wrong pin (DR-003: no seat moves).
- None of the three buckets fits: `hard` ends in a `pending-capacity` park, which `AGENTS.md:59` explicitly denies manual sessions ("Manual (non-driver) lane sessions do not park — they stop and report to the operator, who is present by definition"); `deferred` queues an epic-scoped `Kind: FABLE_MAKEUP` obligation a hand-driven single ticket may not be inside; `soft` is silent-by-default and the coordinating main loop has no catch-attribution line to carry the marker.
- The lookup and detection machinery is dispatch-shaped: `execution-model.md` § 2 places the fable-policy lookup "immediately before writing a dispatch's tier pin", and `AGENTS.md:58` defines detection as a dispatch failure signature plus bounded retry. A frontmatter pin is applied by the harness at invocation; neither mechanism reaches it. `hook-require-model-pin.sh` reads `tool_input.model` on dispatches and never sees frontmatter or the main-loop model.
- `mature-ticket/SKILL.md:13` and `mature-playbook.md:49` carry the same "the pin covers the main loop only" paragraph — the two-file drift surface the change must move together.

DR-001 settles the behavior: operator-choice — ask the present human; wait or proceed at Capable with the substitution declared; manual sessions never park. This spec is the implementation of that ruling.

## Goals

1. The session pin has a policy row: `operator-choice`, inside the gate-keyed table, three columns populated, `AGENTS.md:54` satisfied by a row rather than an exemption.
2. "Asks the operator" is mechanically defined for a manual Claude Code session: an invocation-time self-check plus the two options and their exact consequences (wait ⇒ stop/report/`RESUMABLE`; proceed ⇒ operator switches the session to `Capable@max`, declared).
3. The substitution is never silent: a pinned, grep-able `session-tier:` grammar on the lane's durable gate comments, reusing DOD-1214's `tier-degraded(...)` marker with policy component `operator-choice`.
4. The doctrine says out loud what is not enforced: no hook sees a session pin; the row is prose-and-declaration, the same posture as effort (DR-005).
5. The manual-Frontier / driver-Standard asymmetry for the same playbook is stated as deliberate, and inherited session models (`brainstorm`, `write-plan`) are explicitly outside the table.
6. The "fable frontmatter pin ⇒ policy row" invariant becomes a validator check.

## Non-Goals

- No change to `drive-epic`'s `model: sonnet` pin or any driver behavior — the autonomous answer to "what changes?" is nothing.
- No change to the four mature-lane phase policies (`mature-playbook.md:11-14`) or to any Gates assignment in the three existing buckets (acceptance-checked: their cells stay byte-identical).
- No `effort:` frontmatter key anywhere (DR-005; DOD-1214 non-goals; epic out-of-scope). The frontmatter key inventory across all 20 skills stays exactly `name`, `description`, `model`.
- No `model:` key added to `brainstorm` or `write-plan` (`AGENTS.md:41` deliberately has them inherit).
- No change to `hook-require-model-pin.sh` or its tests (byte-identical to main).
- No change to the make-up machinery (`Kind: FABLE_MAKEUP`, the `submit-epic-pr` make-up round) or the `pending-capacity` wake edge.
- No operator-choice authority over **dispatch** gates — a hard dispatch gate in a manual session keeps its existing stop-and-report behavior, unchanged (see § Edge cases 1).

## Design

### 1. The `operator-choice` row (AGENTS.md § Fable Availability Policy table)

Added as the fourth row (normative content; exact wording at implementation):

| Policy | Meaning | Gates |
|--------|---------|-------|
| **operator-choice** | manual-session ask: the session stops and the present operator decides — **wait** for fable, or **proceed at `Capable@max`** with the substitution declared. Never automatic: no park, no silent substitution, no make-up obligation. A session-pin policy a manual session applies to itself — never a dispatch policy; the driver never performs this lookup | the manual `mature-ticket` wrapper's `model: fable` main-loop session pin (the repo's only frontmatter fable seat) |

The three existing rows are untouched. The `AGENTS.md:54` paragraph needs no edit — the seat now has a row.

### 2. The mechanics bullet (AGENTS.md § Fable Availability Policy, after the `soft` bullet)

One new bullet in the Mechanics list (normative content):

- **operator-choice → ask the operator (manual sessions only):** a session pin has no dispatch to fail, so detection is invocation-shaped, not dispatch-shaped — at skill start the wrapper **self-checks that its main loop is running Frontier tier** (the session-level analog of tier self-declaration; it covers a visible harness failure, a silent fallback, and an allowance the operator already knows is exhausted, without depending on which the harness does), and a capacity failure mid-lane surfaces in the operator's own terminal. Either way the session stops **before further claims or dispatches** and puts the choice: **wait** — stop and report; resume when capacity returns; never a `pending-capacity` park (manual sessions never park; a mid-lane wait exits `RESUMABLE` with the continuation brief naming fable capacity as the resume condition) — or **proceed at `Capable@max`** — the operator switches the session (`model: opus` on Claude Code, session effort `max`), since only the operator controls session-level dials; the skill cannot rewrite its own frontmatter. A proceed is recorded, never silent: every gate-transition comment the substituted session posts carries `session-tier: tier-degraded(fable@xhigh→opus@max,operator-choice)` (efforts are the declared values per the effort table). No make-up obligation is queued — the human judged the tradeoff. **No hook enforces a session pin** — `hook-require-model-pin.sh` sees dispatch payloads only — so this row is prose-and-declaration, the same posture as effort. The lane's dispatches are untouched: each still performs its own per-gate lookup at dispatch time, at the pin its own row produces.

Grammar notes: the marker reuses DOD-1214's extended `tier-degraded(<from>@<effort>→<to>@<effort>,<policy>)` form with `operator-choice` as the policy component; `opus@max` is legal because `Capable@max` is the declared elevated-substitution target DOD-1214 defines for exactly this seat. The `session-tier:` prefix (rather than `caught-by:`) exists because the coordinator posts no findings — this line rides the gate comments the lane already posts. Defined once, here; the skill files reference it.

### 3. § Model Tiers, the line-41 bullet (AGENTS.md)

Extend the existing bullet with two sentences (normative content):

- The manual wrapper's pin "is the **operator-choice** seat in § Fable Availability Policy"; and the tier asymmetry is deliberate: the driver's main loop is a router whose judgment work is entirely dispatched (orchestration routing is Standard, per the tier table), while a manual session's main loop hosts interactive judgment with the operator — it seats Frontier for the same reason brainstorm and write-plan sessions run Frontier.
- The exclusion: inherited session models are not fable seats — `brainstorm` and `write-plan` omit `model:`, so their tier is the operator's own session choice made before invocation; there is no pin for scarcity to fail and nothing for a policy row to govern. The operator-choice row covers frontmatter pins only.

### 4. `dodi-dev/skills/mature-ticket/SKILL.md`

- **Line-13 paragraph, extended (reference, never restate):** the pin is the operator-choice seat in AGENTS.md § Fable Availability Policy; at invocation, before claiming, confirm the main loop is running Frontier tier — if it is not, or fable capacity fails mid-lane, stop and put the operator choice per that policy: wait, or proceed at Capable tier (`model: opus` on Claude Code) at `max` effort with the substitution declared per the policy's `session-tier:` grammar. No restatement of detection retries, make-up obligations, or marker internals.
- **§ Exit states, new bullet beside the line-32 driver-only exclusion:** **operator-wait** — fable unavailable at the session pin and the operator chose to wait: stop and report (never a park). At invocation this is a plain stop before any claim; mid-lane it is a `RESUMABLE` exit (push + continuation brief naming fable capacity as the resume condition). A **proceed** choice is not an exit — the lane continues at the declared substitution. The existing line-32 text is preserved unchanged.
- The word `pending-capacity` is not introduced anywhere in this file (acceptance-checked).

### 5. `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md`

- **§ Model tiers (line-49 paragraph):** add the matching sentence — the frontmatter pin is the operator-choice seat in AGENTS.md § Fable Availability Policy; when a manual session runs under that row's declared substitution, its main loop is `Capable@max` while every dispatch keeps its own per-gate pin and policy, unchanged. Kept consistent with SKILL.md's paragraph (the two-file drift pair moves together).
- **§ Evidence:** one bullet — a session running under an operator-choice substitution appends the `session-tier:` line (grammar: AGENTS.md § Fable Availability Policy) to each gate-transition comment it posts.
- **§ Exit states (line 66):** already states the manual stop-and-report; verify consistency, extend only if the operator-wait bullet's phrasing requires it (expected: one clause naming the operator-choice policy).

### 6. Validator check (`scripts/validate-phase-skills.sh`)

After the existing tier self-declaration loop, add the fable-seat-has-a-row check (design; implementation refines):

```bash
# Fable Availability Policy: every frontmatter `model: fable` pin has a policy row
# naming its skill (AGENTS.md "a fable seat without a row is a defect").
for skill in "${skills[@]}"; do
  f="dodi-dev/skills/${skill}/SKILL.md"
  if awk 'NR==1 && /^---$/ {inf=1; next} inf && /^---$/ {exit} inf' "$f" | grep -q '^model: fable$'; then
    if ! grep -E '^\s*\|' AGENTS.md | grep -q "$skill"; then
      echo "frontmatter fable pin without a Fable Availability Policy row: ${skill}" >&2
      exit 1
    fi
  fi
done
```

Properties: scoped to the frontmatter block only (a `model: fable` in prose never matches); generic (a future skill adding a frontmatter fable pin fails until a table row names it); the match is any policy-table row line naming the skill, so renaming the bucket later does not break the check. The script runs from the repo root and may read `AGENTS.md` (it is a repo validation script, not plugin-shipped; the repo-only-reference ban applies to skills, not `scripts/`). Negative case demonstrated per the ticket's testing contract.

### 7. Version bump

Same-change bump in all five metadata files (`.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json`), tag `vX.Y.Z`, bare version string in the commit message (`AGENTS.md:15-16`). Target: the next patch above whatever DOD-1214 ships (it recommended `0.17.0`; this would then be `0.17.1`) — delegated to implementation.

## Integration points

- `AGENTS.md` §§ Model Tiers (the line-41 bullet), Fable Availability Policy (table + mechanics list). **Rebase coupling:** DOD-1214 edits the same sections first (effort table, extended `tier-degraded` grammar); this ticket is written against the post-1214 text and rebases onto it — line numbers cited here are pre-1214 anchors, so implementation locates by section + anchor text, not line number.
- `dodi-dev/skills/mature-ticket/SKILL.md` (line-13 paragraph, § Exit states).
- `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md` (§ Model tiers, § Evidence, § Exit states) — the drift pair with SKILL.md moves in the same change.
- `scripts/validate-phase-skills.sh` (new check, § 6).
- Five version-bearing metadata files.
- **Not touched:** `drive-epic/SKILL.md`, the four phase policies in `mature-playbook.md:11-14`, the three existing table rows (byte-identical), `dodi-dev/scripts/hook-require-model-pin.sh` (byte-identical), all other SKILL.md frontmatter, `execution-model.md` (its § 2 dispatch lookup already composes correctly with the new row — dispatches were never the row's subject).
- **Upstream dependency:** DOD-1214 (`Capable@max` notation, effort table, extended marker grammar) — registered blocked-by edge; must merge first.

## Edge cases

1. **Hard dispatch gates under a continuing outage.** Proceeding at `Capable@max` covers the session pin only. Per `AGENTS.md:58`, unavailability is "never guessed in advance": the substituted session still attempts the spec-drafter and final-spec-review dispatches at `fable`, and they may well succeed (session-level consumption and single dispatches fail independently; capacity fluctuates; the allowance may reset mid-lane). Only an actual dispatch failure (capacity signature + bounded retry) triggers the hard gate's existing manual-session behavior — stop and report to the operator (`AGENTS.md:59`, last sentence, unchanged). What the operator directs at that point is a live human decision existing doctrine already assigns to them; this ticket neither extends the operator-choice row to dispatch gates nor changes any dispatch policy.
2. **Silent harness fallback vs hard failure at invocation.** Unverified which the harness does when `model: fable` cannot be satisfied — and the design does not need to know: a hard failure is operator-visible by construction (their own terminal), and a silent fallback is caught by the step-zero self-check. Both branches funnel into the same operator ask.
3. **Effort is declared, not guaranteed.** `CLAUDE_CODE_EFFORT_LEVEL` and enterprise clamps can override the operator's `max`; per DOD-1214, the `session-tier:` line records the **declared** effort, never a runtime readout.
4. **Resume after an operator-wait.** A successor session re-runs the step-zero self-check: fable back ⇒ normal lane, no marker; still out ⇒ the same ask. A lane matured across mixed sessions is legal — each gate-transition comment records the coordinator tier that posted it, and per-dispatch tiers are already in the gate-ledger lines.
5. **Driver misreading the row as a dispatch policy.** Guarded twice: the Meaning cell's "never a dispatch policy; the driver never performs this lookup," and the § Model Tiers statement that the driver's Standard main loop for the same playbook is deliberate.
6. **A future frontmatter fable pin.** Fails the § 6 validator check until a policy row names the skill — the `AGENTS.md:54` invariant is now mechanical for frontmatter seats.
7. **Grok Build degeneracy.** All tiers map to `grok-4.6`, so "fable unavailable but opus available" cannot arise there — the row is harness-neutral prose that is simply never triggered on a runtime where Frontier and Capable share a slug; the wait option remains meaningful everywhere. No Grok-specific text needed beyond the existing tier-mapping doctrine.

## Testing contract

Matches the ticket's contract; no doctrine/prose test harness exists and none is invented.

- **Required (each exits 0, from repo root):** `scripts/validate-plugin-metadata.sh` (five-file version parity), `scripts/validate-phase-skills.sh` (prints `phase skills ok`), `scripts/validate-ticket-comment-templates.sh`.
- **Required — negative case for the new check (§ 6):** in a scratch copy, delete the `operator-choice` row from `AGENTS.md` → non-zero exit naming `mature-ticket`; restore → exit 0. Record commands and exit codes as evidence; this demonstration is the test.
- **Not required:** the six `dodi-dev/scripts/tests/*.sh` — the hook is untouched; run `test-hooks-payload.sh` only if the hook file shows in the diff (it must not).
- **Manual verification (prose):** read the changed AGENTS.md section and both skill paragraphs end to end — (a) harness-neutral per `AGENTS.md:13-14` (Claude form + tier name), (b) no repo-only file referenced from inside a skill, (c) SKILL.md and playbook paragraphs agree, (d) the three existing table rows byte-identical in the diff.

## Acceptance criteria

The ticket's criteria are adopted as written; mapping: row inside the table with three columns (§ 1); Gates cell names the session pin, existing rows byte-identical (§ 1); every fable seat maps to a row, mechanical check included (§ 6); harness-neutral `Capable tier (model: opus on Claude Code)` sentence in SKILL.md (§ 4); reference-not-restate (§ 4 — no retry counts, no make-up text, no marker internals in skill prose); no new `pending-capacity` occurrence and the line-32 exclusion preserved (§ 4); SKILL.md/playbook consistency (§§ 4-5); three validators green plus five-file version parity (§ 7, testing contract); frontmatter key inventory unchanged — this spec chooses the vocabulary-only option, no `effort:` key (Non-Goals); tag + bare version string in the release commit (§ 7).

## Open assumptions and delegated decisions

⚠ **Operator-choice stops at the session pin** — hard dispatch gates keep stop-and-report (§ Edge cases 1). Anchored by the ticket's out-of-scope list (dispatch policies unchanged) and DR-001's own wording (the ruling names the session pin case). If the operator wants standing authority to substitute hard **dispatch** gates in manual sessions, that is a policy-table change → its own ticket. Non-blocking.

⚠ **Recording surface and grammar** (§ 2): gate-transition comments + `session-tier: tier-degraded(fable@xhigh→opus@max,operator-choice)`. The ticket delegated this pick to the spec; anchored to DOD-1214's marker grammar and the lane's existing durable evidence surface. Non-blocking.

⚠ **Self-check feasibility**: the step-zero check relies on the session knowing its own model identity (Claude Code states it in the session context). Best-effort prose, honestly declared unenforced — the same posture DR-005 pins for effort. If a runtime cannot introspect, the operator-known branch still covers it. Non-blocking.

⚠ **Bucket name `operator-choice`**: matches DR-001's own vocabulary and the ticket's grep-based acceptance criterion; implementation keeps it unless spec review prefers another name (the validator check is name-agnostic). Non-blocking.

⚠ **Version bump target**: next patch above DOD-1214's shipped version; delegated to implementation. Non-blocking.
