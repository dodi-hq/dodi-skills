# DOD-1217: Declare both tiers in epic-integration-reviewer-prompt (Capable + Frontier)

Epic: DOD-1213 (fable scarcity doctrine). Ticket type: bugfix. Status: spec draft.

## TL;DR

`dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` serves two seats — the step-3 integrated-head rounds at Capable tier and the conditional step-4 fable make-up round at Frontier tier — but names only Capable in all three tier-bearing lines (:3 header prose, :6 Agent-tool block header, :9 in-block self-declaration). This spec fixes the three lines against the in-repo exemplar `review/child-pr-integration-prompt.md`, adds the missing tier name to `submit-epic-pr/SKILL.md:33`, and ships a mechanical seat registry in `scripts/validate-phase-skills.sh` so a multi-seat template naming fewer tiers than its seats fails a script instead of waiting for a reviewer.

## Key Points

- **Three-line template fix, one exemplar.** Lines 3, 6, and 9 of `epic-integration-reviewer-prompt.md` are rewritten to name both seats, mirroring `review/child-pr-integration-prompt.md:3,6,9-11`, including the "match this dispatch's pin" instruction. Both tier names carry the Claude alias form per AGENTS.md § Editing Rules.
- **No substitution hedge on the make-up seat.** `submit-epic-pr/SKILL.md:33` declares the make-up round's fable-policy **hard** (fable unavailable ⇒ `pending-capacity` park, never a substitution), so the declaration carries no "or the tier this dispatch pins" hedge — the docs-sync template's hedge exists because that seat's child mode is soft; this one's is not.
- **One phrase in SKILL.md:33.** "one batched **fable** round" gains the tier name: "one batched **Frontier-tier** round (`model: fable` on Claude Code)" — the bare alias violates AGENTS.md § Editing Rules ("the Claude form plus the tier name"). Nothing else in step 4 changes.
- **Validator decision (ticket open question 1): option (a), an explicit seat registry.** A case-statement registry in `scripts/validate-phase-skills.sh` maps every `*-prompt.md` entry in `prompt_files` to its required tier names; the default case fails, which is the completeness assert. Multi-tier rows additionally require the literal phrase `match this dispatch's pin`. Options (b) prose-derivation and (c) reference-count heuristics are rejected — (b) is demonstrably unreliable on this very file (SKILL.md:33 says "fable" never "Frontier tier", and says of step 3 "it is Capable-tier, not a fable seat" in the same paragraph), and (c) cannot verify *which* tiers are named. Residual gap stated in § Residual gap.
- **Template/preamble boundary (ticket open question 2): the template stays seat-agnostic below the declaration lines.** The make-up seat's distinct input (obligations enumeration) and output obligation (keyed consumption) remain owned by `SKILL.md:33`'s dispatcher-supplied preamble — duplicating them into the template would restate a contract the skill owns (drift risk, per AGENTS.md § Deterministic Skeleton's reference-don't-restate rule). Only the tier declarations name the make-up seat.
- **Merge-order coupling with DOD-1214 (spec-ready, ready-to-implement, not yet merged).** DOD-1214 edits the same line-9 parenthetical (adds effort) and the same validator region (adds an effort-presence check), and bumps to 0.17.0. Whichever ticket merges second rebases its edit onto the other's — composition rules in § Integration with DOD-1214. This ticket's validator change is a **new block after** the existing tier loop, minimizing textual conflict.
- **New negative-case test** at `dodi-dev/scripts/tests/test-validate-phase-skills.sh` — first test of a repo-root validator; copy-tree-and-mutate shape per the ticket's Testing contract.
- ⚠ **Version bump is one patch level relative to the epic-branch value at merge time** (0.16.4 → 0.16.5 if this merges first; 0.17.0 → 0.17.1 if after DOD-1214), five files per AGENTS.md § Editing Rules. Acceptance greps use the resolved value, not a hardcoded one.
- ⚠ **Assumption:** a bugfix warrants a patch-level bump (AGENTS.md states the five-file rule but no semver policy for prompt-text corrections). Non-blocking; consistent with prior releases (0.16.3, 0.16.4 were prompt/policy patches).

## Problem

`submit-epic-pr/SKILL.md:32` dispatches `epic-integration-reviewer-prompt.md` at Capable tier (`model: opus`) per integrated-head round; `SKILL.md:33` dispatches the **same file** as the conditional batched fable make-up round (Frontier tier, "no new prompt file"). The template names only Capable in every tier-bearing line:

- `:3` — "…at Capable tier (`model: opus` on Claude Code)…"
- `:6` — `Agent tool (general-purpose, model: opus):`
- `:9` — "You are an epic integration reviewer (Capable tier)."

A Frontier worker dispatched at step 4 therefore opens by reading a false statement about itself in the one line whose purpose (AGENTS.md § Dispatch Discipline, tier self-declaration) is to make a wrong tier visible. `scripts/validate-phase-skills.sh:60-70` cannot catch it: its grep `\((Frontier|Capable|Standard|Fast) tier` checks that *a* tier is named, never that *every dispatched* tier is named. Verified on this tree: the validator exits 0 today.

Confirmed sole offender: the four other multi-tier templates (`review/review-prompt.md`, `review/child-pr-integration-prompt.md`, `implement/implementer-prompt.md`, `submit-ticket-pr/docs-sync-prompt.md`) already name their alternatives; all ten single-tier `*-prompt.md` files declare exactly their one dispatch tier (verified by grep against dispatch sites).

## Goals

1. The template names both seats in all three tier-bearing lines and instructs the worker to match this dispatch's pin.
2. `SKILL.md:33` names the Frontier tier alongside the `fable` alias.
3. The multi-tier half of the self-declaration invariant becomes code: a template naming fewer tiers than its registered seats fails `scripts/validate-phase-skills.sh`.
4. The new check has a negative-case test.
5. Five-file version bump in the same change.

## Non-Goals

- No new prompt file (`SKILL.md:33` forbids it: "no new prompt file").
- No change to any other template's tier line — the sweep already happened at ticket intake; this file is the sole offender.
- No change to the template's Output section (`:67-80`) — the `caught-by: epic-integration/<round>/<tier>` line already fits both seats (the dispatcher appends the tier segment).
- No change to `hook-require-model-pin.sh` — it inspects live dispatches, not templates; the template-side check belongs in the validator.
- No change to the six aim classes, mechanical/judgment classification, head-freeze semantics, round-cap loop, or step 4's obligations mechanics.
- No effort-axis content of its own — effort declarations are DOD-1214's job; this spec only defines how the two edits compose (§ Integration with DOD-1214).
- No seat-specific input/output contract moved into the template (open question 2, resolved above).

## Design

### 1. Template fix (`dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md`)

Exemplar: `review/child-pr-integration-prompt.md:3,6,9-11`. Three edits; everything below the declaration stays seat-agnostic and unchanged.

**Line 3 (header prose)** — rewrite the dispatch sentence to name both seats:

> Dispatch as a fresh-context subagent per round of the **integrated-head review loop** in `submit-epic-pr`: the step-3 integrated-head rounds at Capable tier (`model: opus` on Claude Code), and the conditional step-4 fable make-up round at Frontier tier (`model: fable` on Claude Code) — a fresh reviewer every round, never a reused one. …

(The remainder of the paragraph — per-child gates context, mechanical/judgment routing — is unchanged.)

**Line 6 (Agent-tool block header)** — the form used at `child-pr-integration-prompt.md:6`:

```
Agent tool (general-purpose, model: opus for the integrated-head rounds; model: fable for the make-up round):
```

**Line 9 (in-block self-declaration)** — both tiers plus the pin instruction, each seat's declaration unit kept on one physical line (matching DOD-1214's reflow convention for multi-seat templates, so its flattened effort grep and any single-line grep both pass):

```
You are an epic integration reviewer (Capable tier for the integrated-head rounds;
Frontier tier for the fable make-up round — match this dispatch's pin).
You are reviewing the integrated head of an epic branch before its epic PR opens. …
```

**No hedge:** the declaration must not contain "or the tier this dispatch pins" or any substitution language. The make-up seat's fable-policy is **hard** (`SKILL.md:33`; AGENTS.md § Fable Availability Policy, "the fable make-up round itself — hard by construction"): fable unavailable means a `pending-capacity` park, never a substituted worker reading this prompt. The step-3 seat is not a fable seat at all. Acceptance: `grep -c "or the tier this dispatch pins"` on the file returns 0.

### 2. Dispatch-site phrase (`dodi-dev/skills/submit-epic-pr/SKILL.md:33`)

One phrase in step 4: "dispatch **one batched fable round**" becomes "dispatch **one batched Frontier-tier round** (`model: fable` on Claude Code)". Nothing else in step 4 changes — in particular the hard-policy sentence, the obligations preamble, keyed consumption, and the restart-at-step-3 rule are untouched. Step 3's Capable pin (`SKILL.md:32`) is untouched.

### 3. Validator seat registry (`scripts/validate-phase-skills.sh`)

**Decision:** option (a) — an explicit registry mapping each `*-prompt.md` entry in `prompt_files` to the tier names it must declare, with a completeness assert.

**Shape.** A new block **after** the existing tier self-declaration loop (do not modify lines 60-70 — DOD-1214 extends that loop with an effort check; keeping the surfaces disjoint minimizes the merge conflict). No associative arrays — the repo has none and macOS ships bash 3.2; use a case statement, whose default branch *is* the completeness assert:

```bash
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
```

**Registry semantics.** A row lists the tiers a template is *dispatched at by design* — the seats, not the substitution outcomes. `submit-ticket-pr/docs-sync-prompt.md` is therefore a single-tier row (`Frontier`): both its modes are designed-Frontier seats; the `opus` outcome under the child mode's soft policy is a policy event attributed by the `tier-degraded(...)` marker, not a seat, and its declaration hedge ("or the tier this dispatch pins under the gate's fable-policy") is policy language, not the multi-tier `match this dispatch's pin` form. All row values above were verified against the templates' current declarations and their dispatch sites on this tree; the only row the fix changes is the last one.

**Why the existing loop stays.** The `\((Frontier|Capable|Standard|Fast) tier` grep at :66 guards the parenthetical *shape* of the self-declaration (and is the anchor DOD-1214's effort check extends); the registry guards seat *coverage* anywhere in the file. Both halves are needed and neither subsumes the other.

**Rejected alternatives (ticket open question 1).**
- *(b) Derive the tier set from skill prose:* demonstrably unreliable on the defect file itself — `submit-epic-pr/SKILL.md:33` names the make-up seat only by the bare alias "fable" and, in the same paragraph, says of step 3 "it is Capable-tier, not a fable seat"; no proximity extractor can assign tiers to seats there, and hardening one is a parser project for a two-line invariant.
- *(c) Reference-count heuristic (>1 dispatch site ⇒ ≥2 tiers or the pin phrase):* cannot verify *which* tiers are named (a template dispatched at Capable+Frontier but declaring Capable+Standard would pass), miscounts prose mentions vs dispatch sites, and misses the exact failure here — this file *would* have passed a "names ≥1 tier" count while lying about the second seat only until someone added the pin phrase without the tier.

### 4. Negative-case test (`dodi-dev/scripts/tests/test-validate-phase-skills.sh`, new)

First test of a repo-root validator; the existing `dodi-dev/scripts/tests/` source-and-assert pattern does not transfer because `validate-phase-skills.sh` is a non-sourceable top-to-bottom script. Shape per the ticket's Testing contract:

- `set -euo pipefail`, executable bit set.
- `mktemp -d`; `cp -R dodi-dev scripts "$tmp"/`; run `(cd "$tmp" && bash scripts/validate-phase-skills.sh)` — valid because the validator reads only `dodi-dev/**` and repo-relative paths (no `templates/`, no git state).
- Case (a): unmutated copy → exit 0.
- Case (b): mutate the copy's `epic-integration-reviewer-prompt.md` to name only Capable (e.g. `sed` the Frontier seat clause out of the declaration), run the validator → assert exit 1 and stderr contains `submit-epic-pr/epic-integration-reviewer-prompt.md`.
- Case (c): append a fake `*-prompt.md` entry to the copy's `prompt_files` array (and `touch` the file with a valid single-tier declaration) → assert exit 1 with the no-seat-registry-row message. (Cheap, and it is the completeness assert's only test.)
- Final line `echo "validate-phase-skills tests ok"`; invoked by path, no aggregate runner (none exists).

### 5. Version bump (five files, same change)

`.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json` — one **patch**-level bump relative to the epic-branch value at merge time (0.16.4 → 0.16.5 if this child merges before DOD-1214; 0.17.0 → 0.17.1 after). `.agents/plugins/marketplace.json` carries no version key and is not bumped. Commit message carries the bare version string (AGENTS.md § Editing Rules). The plan must read the current value at implementation time, not hardcode this spec's example.

## Integration with DOD-1214 (merge-order coupling — read before planning)

DOD-1214 (spec `docs/specs/2026-08-28-effort-first-class-axis-design.md` § 3-4; plan `docs/plans/2026-08-28-effort-first-class-axis.md` Task 5 Step 11, Task 8) is ready-to-implement and touches two of this ticket's surfaces. Its own plan already carries the mirror-image coordination note. Composition rules:

1. **Line 9 parenthetical.** DOD-1214 rewrites it to `(Capable tier, high effort)`; this ticket rewrites it to the dual-tier form. Whichever merges second applies its change *onto* the other's text. Merged target, exactly as DOD-1214's plan anticipates: `(Capable tier, high effort for the integrated-head rounds; Frontier tier, xhigh effort for the fable make-up round — match this dispatch's pin)` — each seat's `<tier> tier, <effort> effort` unit on one physical line. In `<tier>@<effort>` vocabulary the seats are `Capable@high` and `Frontier@xhigh`; this ticket adds no effort text of its own when it merges first.
2. **Lines 3 and 6.** DOD-1214 does not touch them; no composition needed.
3. **Validator.** DOD-1214 extends the existing loop (:60-70) with an effort-presence check; this ticket adds a separate registry block after that loop. Disjoint hunks; whichever merges second resolves at most a trivial context conflict. The registry checks tiers only — effort coverage is DOD-1214's check, and extending the registry to efforts is out of scope here.
4. **DOD-1214's Step-12 verification grep** expects exactly 4 multi-seat files without effort text; if this ticket merges first, `epic-integration-reviewer-prompt.md` becomes a 5th multi-seat file and DOD-1214's coordination note (apply effort onto the dual-tier text) governs. That adjustment lives in DOD-1214's lane, not this one.
5. **Version bump.** Serial patch/minor bumps per child; see § 5.

This ticket must not duplicate any DOD-1214 edit (no effort parentheticals, no effort validator check) and must not revert one if DOD-1214 lands first.

## Edge cases

- **Make-up round dispatched with the template unfixed** (race during epic delivery): out of scope — this epic's own step-4 round, if any, runs against whatever is merged; the fix is not retroactive to transcripts.
- **A future third seat for this template:** the registry row gains a tier name; the completeness assert cannot force that (see § Residual gap) — the prose rule at AGENTS.md § Dispatch Discipline remains the backstop and a wrong-tier self-declaration remains a review finding.
- **Registry vs `prompt_files` drift:** impossible to under-register (default case fails on any array entry without a row); over-registration (a row for a deleted template) is inert dead code caught by normal hygiene review, not by the script — acceptable, since it cannot green a defect.
- **Grep looseness:** `grep -q "Capable tier"` matches the tier name anywhere in the file, including header prose. See § Residual gap.

## Residual gap (what the check does NOT close)

1. **Row contents are hand-maintained.** The registry mechanizes "does the template name every registered tier", not "is the registry right". A new dispatch site at a new tier for an existing template stays green until a human updates the row — the same class of miss as b558cd9's, moved from N template files into one registry co-located with `prompt_files` and forced through a conscious per-file decision by the completeness assert. The prose invariant (AGENTS.md § Dispatch Discipline) remains the authority; the registry is its tripwire, not its replacement.
2. **File-scope grep, not declaration-scope.** A file could name both tiers in header prose while the in-block self-declaration names one. The `match this dispatch's pin` phrase requirement narrows this (the phrase conventionally lives inside the declaration parenthetical), but the check does not parse the parenthetical. Tightening to declaration-scope parsing is not worth a parser for prompt prose; the exemplar-following fix plus review covers it.

## Acceptance criteria

The ticket's criteria 1-14 stand, with two amendments:

- Criteria 8/10/14 (version): replace the hardcoded `0.16.5` with the resolved value per § 5 (one patch level above the epic-branch value at merge time).
- Criterion 12 stands as written (the check ships — open question 1 is resolved as option (a)); criterion 13 stands (the test ships), extended by the completeness-assert case (§ 4 case c).
- Additional criterion: if DOD-1214 has merged first, `epic-integration-reviewer-prompt.md:9`'s declaration carries both tier *and* effort per § Integration rule 1, and `git diff` shows no reverted DOD-1214 text.

## Open assumptions

- ⚠ Patch-level semver for a prompt-text bugfix (non-blocking; consistent with 0.16.3/0.16.4 precedent).
- ⚠ Merge order vs DOD-1214 is unknown at spec time; both orders are specified (§ Integration). Non-blocking — the plan reads the tree at implementation time.
- ⚠ `submit-ticket-pr/docs-sync-prompt.md` registered single-tier (Frontier) on the seats-not-substitutions principle (§ 3 Registry semantics). Non-blocking; flagged for spec review since it fixes the registry's semantics precedent.
