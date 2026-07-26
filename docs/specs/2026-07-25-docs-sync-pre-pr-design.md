# Docs-Sync Before PR Submission Design

## TL;DR

Add a Frontier-judged **docs-sync step** to both PR-submission seams: before a child PR is pushed (`submit-ticket-pr` Open) and at epic-PR attempt start (`submit-epic-pr`), a fable-seated worker reads the diff and decides whether the module-level agent metadata files (`CLAUDE.md` / `AGENTS.md`, per module and sub-module) must be updated to stay true — and makes the smallest true edit when they must. The two instantiations do different jobs: the child step syncs docs for that ticket's slice; the epic step is a **cross-child coherence sweep** that catches drift only visible at epic scope. "No update needed" is a first-class, recorded decision — never a silent skip — and both placements are chosen so every doc edit lands *inside* a reviewed diff, not after the gates.

## Key Points

- **The gap: code review gates never ask "are the docs still true?"** Every future session reads module `CLAUDE.md`/`AGENTS.md` files as ground truth, so doc staleness compounds exactly like design drift — silently, and worst on the modules that change most.
- **Judgment, not ceremony.** A small bug fix almost never moves architecture docs; a contract or invariant change almost always does. The step is a judgment call with a rubric (below), seated at Frontier per the intelligence-over-cost decree — doc content steers every downstream session, so the judgment compounds.
- **Child placement: `submit-ticket-pr` Open, before the push.** The doc edits are committed on the child branch, so the child-PR review gate reviews them as part of the diff. No unreviewed content reaches the epic branch.
- **Epic placement: `submit-epic-pr` attempt start, before the integrated-head round.** Forced by the head-freeze semantics: any commit after the clean round restarts the attempt, so docs-sync must land before the round. The integrated-head reviewer then reads the docs delta as part of the epic diff.
- **Fable policy: child seat `soft`, epic sweep `hard`.** The child seat may substitute `opus` (attributed, no make-up) precisely because the epic sweep backstops it; the epic sweep is the last look before Gate 2 and its output is canon for every future session — park-and-wait, like the other coherence-class checks. Both get gate-policy table rows (a fable seat without a row is a defect).
- **"No update" is a decision with a paper trail.** Every run emits exactly one grep-able evidence line — `docs-sync: updated <paths>` or `docs-sync: no update — <reason>` — into the PR body (child) or readiness summary (epic). Skips are auditable the same way gate-ledger lines are.
- **Smallest true edit wins.** No wholesale rewrites, no style passes, no new metadata files except for a newly introduced module. Anti-churn is a hard rule, not taste.
- **When in doubt, update.** Over-eagerness is caught by the very review gates the step feeds into; silent staleness is caught by nothing until it misleads a session. The asymmetry decides the default.
- **One prompt file, two modes.** `submit-ticket-pr/docs-sync-prompt.md` is the single worker contract; the epic sweep dispatches the same prompt with a scope preamble (same pattern as the fable make-up round reusing the integration-reviewer prompt).
- **Single-writer discipline is preserved.** The worker edits doc files in the lane's/epic's worktree; the session walking the skill commits — same shape as fix workers in the integrated-head round.
- **Watch the no-op rate.** If docs-sync is ~all no-ops across a few epics, the rubric is doing the work and the seat can drop tier or to sampling — same empirical posture as the gate ledger.

---

## The Docs-Sync Worker

One worker prompt, `submit-ticket-pr/docs-sync-prompt.md`, dispatched at Frontier tier (`model: fable` on Claude Code; policy per seat, below).

Inputs:

- the diff for its scope (child: child branch vs epic branch; epic: epic branch vs base, post-sync)
- the ticket spec (child) or epic design artifact + decision-register canon summary (epic)
- the set of `CLAUDE.md` / `AGENTS.md` files discovered by walking each changed path upward: nearest module doc, any sub-module docs on the way, and the repo root doc

Responsibilities:

- judge, per discovered doc file, whether the diff makes any statement in it false, incomplete, or misleading — architecture, module responsibilities, public contracts and data shapes, invariants, conventions, commands/workflows, module existence
- when an update is warranted, make the **smallest true edit** directly in the worktree — correct the stale statements, add what a future session must know, nothing else
- create a new module doc **only** when the diff introduces a new module that peers document; never for the sake of coverage
- when a module carries both `CLAUDE.md` and `AGENTS.md` covering the same ground, keep both consistent — never let the sync itself create drift between them
- when no update is warranted, say so with a one-line reason — the no-op rationale is a required output, not an omission
- never touch code, config, or tests; doc files only

Rubric anchors (the judgment stays with the model; these bound its failure modes):

- **Update** when the diff moves architecture or responsibility placement, public contracts/interfaces/data shapes, invariants, cross-module conventions, commands or workflows, dependency direction, or module add/remove/rename.
- **No-op** when the diff is a behavior-preserving fix, test-only, comment/typo-level, or an internal refactor with unchanged contracts — the "small bug fix" case.
- **When in doubt ⇒ update.** Review gates catch over-eagerness; nothing catches silent staleness.

Output contract — exactly one evidence line, verbatim grammar:

```
docs-sync: updated <path>[, <path>...]
docs-sync: no update — <one-line reason>
```

## Child Seam — `submit-ticket-pr` (Open half)

New step 2, between branch verification and the push (Open renumbers to six steps):

1. Verify the child branch is not main/master and targets the epic branch.
2. **Docs-sync.** Dispatch the docs-sync worker at Frontier (policy **soft** — `opus` substitutes attributed, no make-up; the epic sweep is the designed backstop). Scope: child diff vs epic branch. If the worker edited files, commit them on the child branch with message `docs-sync: <summary>`. Carry the evidence line forward.
3. Push the child branch.
4. Open a PR from child branch to epic branch.
5. PR body as today, **plus the `docs-sync:` line** — spec, plan, test evidence, verification evidence, ticket link, non-closing `Part of <ticket-id>`.
6. Return to the lane — the lane runs `review` (child-PR context) next, which now reviews the doc edits as part of the diff. Do not merge from this half.

Expected-evidence list gains: the `docs-sync:` line (update or attributed no-op).

The Merge half is unchanged. (Docs-sync commits are docs-only by contract, so they compose with the de-minimis staleness exception exactly as existing docs-only housekeeping does.)

## Epic Seam — `submit-epic-pr`

New sub-step inside step 2 (attempt start), after the base sync and before the integrated-head review round:

- **Docs-sync sweep.** Dispatch the docs-sync worker at Frontier (policy **hard** — fable unavailable ⇒ `pending-capacity` park; the epic PR does not open with an unswept docs surface). Scope: the full post-sync epic diff vs base, with the epic design artifact and register canon as inputs. The sweep's job is what per-child syncs cannot see: cumulative drift across children touching the same module, and epic-level statements (root docs, cross-module contracts) no single child owned. The session commits any edits on the epic branch with message `docs-sync: <summary>`.
- The integrated-head review round (step 3) then reads a diff that already contains the docs delta; the head freeze happens after the clean round as today, so no SHA-equality interaction.
- **Once per attempt.** A restart at step 3 (mechanical fixes, make-up-round fixes) does not re-run docs-sync — mechanical fixes have no runtime-behavior effect by definition. A **new attempt** (corrective child, late sync, any re-entry at step 2) re-runs it against the new diff.

The epic readiness summary (step 6) carries the sweep's `docs-sync:` line among its Key Points; the expected-evidence list gains it.

## AGENTS.md Gate-Policy Table

Two row amendments (a fable seat without a row is a defect):

- **soft** row gains: "the child docs-sync step (the epic docs-sync sweep is the backstop)"
- **hard** row gains: "the epic docs-sync sweep (last docs look before Gate 2; its output is canon for every future session)"

## Changes by File

| File | Change |
|------|--------|
| `dodi-dev/skills/submit-ticket-pr/SKILL.md` | Open half: insert docs-sync as step 2 (steps renumber to 6); PR-body and expected-evidence additions |
| `dodi-dev/skills/submit-ticket-pr/docs-sync-prompt.md` | New worker prompt (single contract, child + epic modes via scope preamble) |
| `dodi-dev/skills/submit-epic-pr/SKILL.md` | Step 2 gains the docs-sync sweep sub-step; once-per-attempt rule; readiness-summary and evidence additions |
| `AGENTS.md` | Gate-policy table: soft + hard row amendments |
| `dodi-dev/skills/epic-orchestrator/lanes/deliver-playbook.md` | Step 7 wording (docs-sync, then push/PR); prompt-file column for the `submit-ticket-pr` row gains `docs-sync-prompt.md` with its Frontier seat |
| Three metadata files | Version bump to 0.16.2 |

`state-transitions.md` needs no state or label changes — docs-sync lives inside existing steps and states.

## Release

Standard point release: bump `0.16.2` in the three metadata files, run the three validators, release commit carrying the bare version string, tag `v0.16.2`.

## Out of Scope / Watch

- No hook or script enforcement — docs-sync is a judgment contract, and its mechanical postcondition (evidence line present) rides the existing review gates. Revisit only if skipped-line defects actually occur.
- No PM states, labels, or ledger lines — one evidence line per run is the whole trail.
- **Watch:** the update/no-op ratio per epic, grep-able from `docs-sync:` lines. Near-all no-ops across a few epics ⇒ consider dropping the child seat to Capable or to sampling; frequent epic-sweep catches that children missed ⇒ tighten the child rubric instead.
