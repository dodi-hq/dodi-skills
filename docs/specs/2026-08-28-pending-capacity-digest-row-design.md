# Two-Band Capacity-Park Digest + Steady-Park Coverage Correction — DOD-1216 Spec

Epic: DOD-1213 (fable scarcity doctrine). Ticket: DOD-1216. Status: draft for spec review.

Binding inputs: epic Decision Register canon DR-001..DR-005 (esp. DR-003 — policy gaps only, no seat moves; DR-004 — coverage defects are the epic's standard). No blocked-by relations: this child does not consume DOD-1214's `<tier>@<effort>` vocabulary. All line citations verified in this worktree (branch `epic/dod-1213-fable-scarcity-doctrine`, base `3b69343`).

## TL;DR

The `pending-capacity` digest clause at `reconcile-tickets/SKILL.md:40` exists but is toothless, and the claim it leans on — "persistent capacity trouble is caught by the retry ceiling" (`AGENTS.md:59`, `drive-epic/SKILL.md:37`, `reconcile-tickets/SKILL.md:40`) — is structurally false for a **steady** park: the ceiling counts lane attempts (`AGENTS.md:112`), and a park whose hourly probe fails every tick never boots a driver, so no attempt ever increments it. A permanently frozen Fable cap today has no escalation path at all. This spec lifts capacity parks into their own two-band digest sub-section (self-healing / escalating), backed by a new `capacity-park-scan.sh` that computes park age and flap count from the durable `Kind: CAPACITY_PARK` register entries, and corrects the false coverage claim in all three places — scoping the retry ceiling to the flapping case and naming the janitor band as the steady-case backstop.

## Key Points

- **Decision — the bug is the false claim plus a threshold-less clause, not a missing row.** The digest already mentions `pending-capacity`; what it lacks is a rendered consequence. The fix is a `### Capacity Parks` sub-section under `## Waiting-On-You Digest` with two bands and its own thresholds, and the clause removed from the line-40 run-on paragraph.
- **Decision — two independent signals, zero new durable writes.** Park **age** = `createdAt` of the newest `Kind: CAPACITY_PARK` register entry while the epic's `pending-capacity` label is present; **flap count** = number of such entries in a trailing window. Steady park = high age, low flaps; flapping park = low age, high flaps. Both derivable today from data `drive-epic` already writes (`AGENTS.md:59`).
- **Decision — band arithmetic ships as `capacity-park-scan.sh` with a pure `classify` subcommand** (the `claim.sh classify` precedent), thresholds as parameters with documented defaults, plus a standalone test in the existing `dodi-dev/scripts/tests/` convention. This is also the only testable surface the change has — the digest itself is prose executed by a Standard-tier (`model: sonnet` on Claude Code) main loop.
- **Decision — the shared 3-day staleness window explicitly does not govern this class.** The wake edge probes hourly (`drive-epic/SKILL.md:31,37`); three days is ~72 failed self-corrections. The other six digest classes wait on a human; this one waits on a cap. The sub-section says so in so many words.
- ⚠ **Delegated assumption — thresholds: escalate at park age ≥ 24h, or ≥ 3 parks in a trailing 7-day (168h) window.** The repo documents no Fable allowance reset cadence; 24h assumes one daily reset cycle. Both are script parameters, never baked literals, so operator confirmation later is a default change, not a redesign. (Epic canon ⚠-flags this same assumption; the epic's DR list pins no numbers.)
- **Decision — the escalating band's operator ask states facts and stops at the charter line.** It names the blocked gate + child (the `CAPACITY_PARK` entry's two recorded fields), park age, and flap count, states that automation has no remaining corrective, and asks the operator to restore Fable capacity or decide the path forward. It never proposes a `hard`→`deferred` gate reclassification — the janitor repairs state, never advances work (`reconcile-tickets/SKILL.md:11`), and gate policy is epic-out-of-scope (DR-003). This resolves the ticket's open question 4 by decision.
- **Decision — a self-healing park suppresses the "nothing waiting on you" one-liner** but is rendered informationally, not as a human ask: an epic frozen on a park is not healthy-quiet (`AGENTS.md:103`), yet a park under threshold is the guard's job, not the operator's.
- **Decision — per-epic scan and thresholds; cross-epic aggregation is out of scope.** The script takes one epic id (the `watchdog-scan.sh` shape); the janitor runs it per parked epic. Detecting a global allowance shortage across epics is a follow-up, flagged non-blocking.
- **Out of scope by deliberate choice:** guard probe behavior and any durable probe-failure counter (sibling ticket if wanted); restructuring the other six digest classes; the shared 3-day window for any other class; any gate's fable policy; auto-clearing parks; `watchdog-scan.sh` (byte-unchanged).
- **Released-skill change:** all five version-bearing metadata files bump in the same commit (`AGENTS.md:15`); all three repo validators stay green; `capacity-park-scan.sh` joins the `plugin_scripts` array in `scripts/validate-phase-skills.sh` (line 73).

## Problem

Verified at worktree head:

1. **The clause exists but declares itself informational.** `reconcile-tickets/SKILL.md:40` renders each `pending-capacity` park inside a single seven-class paragraph, "informational unless the park persists," with no threshold for "persists," no distinct rendering for persistence, and an escalation deferral — "a flapping park hits the retry ceiling and escalates to `blocked`" — that cannot fire for the steady case.
2. **The retry ceiling structurally cannot count a steady park.** The ceiling is 3 consecutive failed/`RESUMABLE` **lane attempts** (`AGENTS.md:112`; incremented on a no-progress exit, `epic-orchestrator/execution-model.md` § 4; driver-owned, `drive-epic/SKILL.md:80`). The wake edge (`drive-epic/SKILL.md:37`) exits on probe failure **before acquiring the claim** — no driver boots, no attempt starts, no counter moves. The closing sentence of both `AGENTS.md:59` and `drive-epic/SKILL.md:37` ("so an epic never loops park↔probe forever") is false for exactly the epic whose cap never returns.
3. **Every other symmetry-breaker misses it.** The 3-day watchdog (`reconcile-tickets/SKILL.md:35`) exempts explicit parks; the heartbeat keeps ticking (the guard is healthy — the probe is what fails); the digest's shared re-escalation window (3 days, sized for human response latency) is miscalibrated for a condition that self-tests hourly.
4. **Nothing reads the durable data.** `Kind: CAPACITY_PARK` entries record gate + child (`templates/ticket-comments/decision-register-entry.md:8`, asserted by `scripts/validate-ticket-comment-templates.sh:156`); no script computes age or flap count from them. `watchdog-scan.sh` has no notion of `CAPACITY_PARK`.

The stakes: six gates are policy-**hard** and park rather than substitute (`AGENTS.md:50`), two of them in the mature lane; the operator's Fable allowance runs to 100% every cycle. A hard-gate park under a frozen cap is a fully stopped epic whose only signal is a line labeled informational — silent, indefinite, lights-out by construction, the shape `AGENTS.md:103-104` exists to forbid.

## Goals

1. A steady capacity park becomes a human ping: past threshold, it renders as a full escalation-channel item with a concrete operator ask, re-escalated on staleness like every needs-human event (`AGENTS.md:104`).
2. Under threshold, the park is visible but not noisy: an informational band under its own sub-heading that never collapses the digest to "nothing waiting on you."
3. Band classification is deterministic, parameterized, and tested — a script, not main-loop prose arithmetic (`AGENTS.md:88`).
4. The false retry-ceiling coverage claim is corrected in all three places: scoped to flapping, with the janitor band named as the steady-case backstop.
5. This class gets its own clock: the shared 3-day staleness window explicitly does not govern it.

## Non-Goals

- No change to the guard's probe behavior at `drive-epic/SKILL.md:37` (the wake edge's mechanics are untouched; only its closing coverage sentence is corrected) and no durable probe-failure counter — that is a `drive-epic` behavior change with its own park-protocol/idempotence surface (sibling ticket; ticket OQ2).
- No restructuring of the other six digest classes; the line-40 paragraph stays a paragraph, minus the `pending-capacity` clause.
- No change to the shared 3-day staleness window for any other class.
- No fable-policy reclassification of any gate (`AGENTS.md:48-52`, DR-003); the escalating band names a blocked hard gate, it never changes one.
- No auto-clearing or auto-resolving of a park (the wake edge stays the guard's; the janitor never advances work).
- `dodi-dev/scripts/watchdog-scan.sh` byte-unchanged; the watchdog's parked-epic exemption stays.
- No per-park duration history (ticket OQ3): probe success clears the label without a durable park-end write, so flap *duration* is not derivable; `(age, flap count)` is the design's full input.

## Design

### 1. `dodi-dev/scripts/capacity-park-scan.sh` (new)

Conventions: `watchdog-scan.sh`'s shape (per-epic arg, `set -euo pipefail`, `source "$(dirname "$0")/linear-api.sh"` behind a source guard, embedded `python3` for JSON/date arithmetic, TSV digest line, header comment with usage + exit codes) plus `claim.sh`'s pure-subcommand pattern.

```
Usage: capacity-park-scan.sh <epic-id> [--age-threshold-hours N] [--flap-window-hours W] [--flap-threshold K]
       capacity-park-scan.sh classify <label_present yes|no> <age_h> <flap_count> <age_threshold_h> <flap_threshold>
Defaults: N=24, W=168, K=3.
Exit: 0 digest printed (band may be `none`); 2 error (API/transport/parse failure —
      never readable as "no parks").
```

**Full flow** (network path): one `linear_gql` query for the epic's labels plus `comments(last: 100) { nodes { createdAt body } }` (the `watchdog-scan.sh` comment-window shape; `CAPACITY_PARK` entries are recent by construction — the flap window is trailing — so newest-100 truncation is a documented, acceptable bound). A comment is a `CAPACITY_PARK` entry iff its first non-empty line is the `# Decision Register Entry` header **and** its key line carries `Kind: CAPACITY_PARK` — `Kind:`-discrimination per the register's species rule, so `MODE`, `FABLE_MAKEUP`, and bare-verdict entries never contribute. From the matching set:

- `label_present` — epic labels contain `pending-capacity`.
- `park_age_hours` — now minus the newest entry's `createdAt` (negative clock skew clamps to 0). Meaningful only when the label is present.
- `flap_count_window` — entries with `createdAt` within the trailing flap window.
- `gate` / `child` — the newest entry's `Gate:` and `Child:` backticked values, verbatim.

Then band = `classify label_present park_age_hours flap_count_window age_threshold flap_threshold`, and print one TSV digest line:

```
CAPACITY_PARK	<epic-id>	label=<yes|no>	age_h=<n|->	flaps=<n>@<W>h	gate=<gate|->	child=<child|->	band=<none|self-healing|escalating>
```

**`classify` subcommand** (pure, no network, no sourcing needed — the testable core):

- `label_present != yes` → `none` (the label is the park predicate; historical entries with no label are re-park history, never a row).
- else `age_h >= age_threshold_h` **or** `flap_count >= flap_threshold` → `escalating` (the two signals fire independently: a flapping park keeps resetting its own age and must escalate on count alone).
- else → `self-healing`.

Boundary semantics: `>=` escalates on both signals.

**Degenerate case, decided:** label present but zero `CAPACITY_PARK` entries (a park with no recorded provenance — a defective write somewhere). The flow emits `age_h=-`, `gate=-`, `child=-`, `band=escalating` without calling `classify`: missing provenance must reach a human, and the janitor's ambiguous-evidence posture (escalate, never guess) is the governing rule. Documented in the script header.

### 2. `dodi-dev/scripts/tests/test-capacity-park-scan.sh` (new)

Standalone bash test per the existing convention; assertions exactly per the ticket's Testing Contract (carried forward below, § Testing contract). No `LINEAR_API_KEY` anywhere in it.

### 3. `reconcile-tickets/SKILL.md` — the `### Capacity Parks` sub-section

Remove the `pending-capacity` clause from the line-40 paragraph (the other six classes stay untouched in it). Amend the empty-digest sentence so the one-liner is conditional on *both* an empty paragraph-class list *and* no capacity-park rows. Add under `## Waiting-On-You Digest` (normative content; exact wording at implementation):

> ### Capacity Parks
>
> For each epic in scope carrying the `pending-capacity` label, run `${CLAUDE_PLUGIN_ROOT}/scripts/capacity-park-scan.sh <epic-id>` and render its digest line here by band — band arithmetic lives in the script, never re-derived in the sweep.
>
> - **Self-healing:** informational — the guard's hourly probe is the active corrective, so this is status, not a human ask. But its presence means the digest is not empty: never emit "nothing waiting on you" while any capacity park exists — a parked epic is not healthy-quiet.
> - **Escalating:** a full escalation-channel item with a concrete operator ask naming the blocked gate and child, the park age, and the flap count: automation has no remaining corrective — the wake-edge probe keeps failing, and the retry ceiling cannot count a park that never boots a lane — so restore Fable capacity, or decide the path forward. Re-escalated with its age on every subsequent run, like any needs-human item. (The ask states the block; it never proposes changing a gate's fable policy.)
> - The shared 3-day staleness window does **not** govern this class: the guard re-probes hourly, so this clock measures failed self-corrections, not human response latency. The band thresholds are the script's parameters (defaults: escalate at 24h park age, or ≥ 3 parks in 7 days).

Constraints honored: script referenced plugin-root-relative (`AGENTS.md:90`); no restatement of the script's arithmetic (`AGENTS.md:92` — defaults are named as parameters, the counting procedure is not); no reference to `docs/` or `templates/` (validator lines 100-105); any tier mention carries its tier name (harness neutrality — the section as drafted names none).

### 4. Three-place coverage correction (prose only)

Replace the closing coverage sentence in both `AGENTS.md:59` and `drive-epic/SKILL.md:37` (normative content; exact wording at implementation):

> Persistent capacity **flapping** — probe success boots a driver whose retried dispatch fails again, burning a lane attempt each time — is counted by the standard retry ceiling → `blocked` + escalation. A **steady** park (every probe fails; no driver ever boots, so no lane attempt increments the ceiling) is outside the ceiling's reach by construction — the janitor's capacity-park digest bands (`reconcile-tickets` § Capacity Parks) are the declared backstop, so a park↔probe loop is never silent.

The third assertion site is the line-40 clause itself, deleted by § 3. `AGENTS.md:59`'s trailing manual-session sentence stays byte-identical.

### 5. Validator + version bump

- `scripts/validate-phase-skills.sh`: add `capacity-park-scan.sh` to the `plugin_scripts` array (line 73) — existence, executable bit, `bash -n`.
- All five version-bearing metadata files (`.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json`) bump together from `0.16.4` to the next unreleased version — resolved against the epic-branch head at implementation time, since sibling children of this epic also bump.

## Integration points

- **Producer:** `drive-epic`'s hard-gate park writes the label + `Kind: CAPACITY_PARK` entry (`AGENTS.md:59`) — unchanged; this spec only adds a reader.
- **Consumer:** the janitor's digest step runs the script per parked epic and renders by band; delivery rides the digest's existing escalation-channel path with its existing re-escalation mechanic (`reconcile-tickets/SKILL.md:40`, `AGENTS.md:104`) — no new notification surface.
- **Species/register discipline:** `Kind:`-discrimination matches the register template and the coherence audit's verdict/non-verdict split (`drive-epic/SKILL.md:63`); the script parses entry bodies itself and does not touch `comment-species.sh` (which classifies progress vs bookkeeping, a different axis).
- **Shared dependency:** sources `linear-api.sh` only; its exit-2 error contract propagates, satisfying the PM-unreachable-escalates rule (`reconcile-tickets/SKILL.md:72`).

## Edge cases

1. Label present, no `CAPACITY_PARK` entries → `escalating` with `-` provenance fields (§ Design 1; ambiguous-evidence posture).
2. Entries present, label absent → `none`, no row (cleared park; re-park history must never render).
3. Newest entry is `Kind: MODE` / `Kind: FABLE_MAKEUP` / a bare verdict → excluded from age and flap count (mis-keying would make every epic with a make-up obligation look parked).
4. Steady park older than the flap window → flap count may be 0; the age signal escalates regardless (the two signals are independent in both directions).
5. Flapping park under 24h age → flap-count signal escalates alone.
6. Clock skew (entry `createdAt` in the future) → age clamps to 0; band falls to the flap signal.
7. API/transport failure → exit 2 with stderr detail; the sweep escalates and never reads it as "no parks."
8. Epic with > 100 comments → the newest-100 window bounds the scan; the flap window is trailing so live parks are unaffected; documented in the script header.

## Testing contract

Adopted verbatim from the ticket (it was written against this repo's real layout: standalone executables under `dodi-dev/scripts/tests/`, no CI, no aggregate runner; SKILL.md prose has no test harness — prose changes are covered by the ticket's grep/read acceptance criteria and review, which is itself the argument for the script).

- **Unit (pure `classify`, per `test-claim-liveness.sh:9-28`):** label absent → `none` regardless of history; age just under threshold + flap 1 → `self-healing`; age just over → `escalating` (boundary from both sides); age well under + flaps at threshold → `escalating`; flaps one below → `self-healing`; non-default thresholds flip a band that defaults would classify differently.
- **Integration (stubbed `linear-api.sh`, shim-dir pattern per `test-claim-liveness.sh:30-42`):** fixture park's `Gate:`/`Child:` land verbatim in the digest line; three in-window entries + one outside count 3; a newest `Kind: MODE`/`FABLE_MAKEUP` entry contributes nothing; entries-without-label → `none`; API failure → non-zero exit distinguishable from clean `none`.
- **E2E:** none, deliberately — no scheduled-run harness exists and none is invented here.
- **Regression:** `watchdog-scan.sh` byte-unchanged; all three `scripts/validate-*.sh` green; the six existing tests pass (`linear-api.sh` untouched); no skill references `docs/`/`templates/` paths (validator-enforced).
- **Commands:**

```bash
bash dodi-dev/scripts/tests/test-capacity-park-scan.sh
for t in dodi-dev/scripts/tests/test-*.sh; do bash "$t" || echo "FAIL $t"; done
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
```

No requirement beyond `bash`, `python3`, `mktemp`; `LINEAR_API_KEY` must not be needed by any test.

## Acceptance

The ticket's 16 acceptance criteria are adopted unchanged; this design satisfies each by construction (criteria 1-5, 10 → § Design 3; 6 → § Design 4; 7, 15 → §§ Design 1-2; 8, 12 → § Design 5; 9 → the sub-section's plugin-root-relative reference; 11, 13, 14 → § Design 5 + regression list; 16 → the sub-section names no bare model alias).

## Open questions / delegated assumptions

1. ⚠ **24h age threshold** (informational→escalating). Assumes one daily allowance-reset cycle; the repo documents no cadence, and if the cap resets on a rolling window an age threshold may be the wrong instrument. Ships as a parameterized default; confirm with the operator. **Non-blocking** (default change, not redesign). *(Also ⚠-flagged in the epic canon.)*
2. ⚠ **7-day flap window / ≥ 3 escalates.** Same posture: parameterized default, operator to confirm. **Non-blocking.**
3. **Per-epic thresholds only.** Three epics each parking once in a week is a global allowance shortage no per-epic threshold sees; cross-epic aggregation is deliberately deferred (the janitor could sum script outputs later without changing this script). **Non-blocking**, recorded for follow-up.
4. **Escalating-ask boundary — decided:** facts + "restore capacity or decide the path forward"; never a proposed gate reclassification (janitor charter + DR-003). Resolves ticket OQ4. **Non-blocking.**
5. **Durable probe-failure counter (ticket OQ2) — deferred** to a sibling `drive-epic` ticket; thresholds being parameters means a future hourly-resolution counter slots in without redesign. **Non-blocking.**
6. **Label-without-entry → `escalating`** (missing provenance reaches a human). Decision, documented in the script. **Non-blocking.**
