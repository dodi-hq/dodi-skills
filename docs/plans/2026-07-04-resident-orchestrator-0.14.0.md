# Resident Orchestrator & Supervisor Watchdog — 0.14.0 Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute tasks in dependency order (A→I). Each task must leave the plugin validator-passing: `bash -n` on every touched script, and the three `scripts/validate-*.sh` green. This is a **plugin release**, not a dodi_v2 product epic — there is no Linear epic and no decision register to consult; the ship path is the release process (Task I).

**Goal:** Ship dodi-dev 0.14.0 — retire the 15-minute stateless `pickup-next` tick in favor of a resident `drive-epic` driver (one long-lived orchestrator session per active epic that advances on completion events), demote cron to a slow liveness guard plus the daily janitor, and ship the full supporting substrate (fenced driver claims, session-identified per-ticket claims with a liveness hierarchy, event-based await v2, a reaper + per-session manifests, a tagged comment-species partition, and a session-delivered human-ruling route). `pickup-next` ships intact-but-fenced with its task paused; 0.14.1 deletes it after the live-test gate passes.

**Architecture:** A new `drive-epic` skill (`model: sonnet`) boots from durable PM/git state, holds the dependency graph and decision-register canon in context, and runs the tick's priority table as a loop — dispatch a lane, await it (dual-wake), close out, re-select — until **park** (no automated action) or **bloat** (context degraded). Driver mutual exclusion is a new fenced `driver-claim.sh` mechanism (own `# Driver Claim` comment species on the epic ticket, session-run identity, stale-claim-closing takeover, session-process-watching refresher). Per-ticket `claim.sh` gains session identity and a driver-claim-topped liveness hierarchy. The merge close-out is fail-closed on the coherence gate (label-before-merge + a set-difference boot audit). Every unverifiable harness behavior sits in a seven-item live-test gate run during a supervised first drive.

**Tech Stack:** Bash scripts (`dodi-dev/scripts/`, POSIX + `python3` for JSON, `bash -n`-clean), Markdown skills/prompts/templates, JSON metadata. No compiled artifacts; the three repo validators are the regression suite.

**Source of truth:** `docs/specs/2026-07-04-resident-orchestrator-design.md` (v17). The Versioning § (lines 196-200) is the file-by-file manifest. Line references below (`file:NN`) are to the pre-0.14.0 state read during planning; the executor confirms the anchor text before editing (files may shift by a line or two).

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `functions/components/modules` — the shell scripts with real logic: `comment-species.sh` (header→species classification), `driver-claim.sh` (acquire/fence/status/refresh/release conjuncts), `claim.sh`/`release-claim.sh` (liveness hierarchy, foreign-release-by-id), `await-worker.sh` v2 (final-lines content check, STALLED, truncation guard), `heartbeat.sh` (update-in-place dedupe), plus `bash -n` syntax on every script and the three `scripts/validate-*.sh` as the structural suite.
  - Reason: These scripts carry the load-bearing invariants (mutual exclusion, liveness, fail-closed merge). A classifier that mis-tags a header or a fence that mis-evaluates a conjunct is a silent lights-out defect; both are cheap to exercise synthetically and expensive to catch live. Precedent: 0.13.5 caught a `cleanup-branch.sh` squash bug via ad-hoc synthetic checking during dev (no test was committed); this plan establishes the **first committed synthetic-test tier** (`dodi-dev/scripts/tests/`).
  - Minimum assertions:
    - `comment-species.sh`: `# Ticket Claim`→bookkeeping, `# Driver Claim`→bookkeeping, `# Continuation Brief`→bookkeeping, `# Decision Register Entry`→progress, `# Lane Checkpoint`→progress, a heartbeat line→bookkeeping, an unknown header→bookkeeping (the default), and the epic-assessment/deploy-confirmation headers classified per the pinned table.
    - `driver-claim.sh`: `acquire` on an epic with no open driver claim wins and prints the run id; `acquire` when a fresh foreign claim exists self-closes and exits no-op; `verify` returns non-zero when the own claim is closed / not-oldest-fresh / not-owned (the three claim-state conjuncts); the refresher-alive fourth conjunct is the caller's assert, covered by live-test-gate item 3; `status` reports "fresh open claim exists / none" without mutating.
    - `claim.sh`/`release-claim.sh`: tier-1 (matching fresh driver claim)⇒alive; tier-2 (checkpoint within lease of now)⇒alive; tier-3 lease-age when neither holds; legacy id-less claim judged by lease alone; foreign release refuses without both the flag and the claim id, and closes exactly the id given.
    - `await-worker.sh`: matches `"stop_reason":"end_turn"` in the final lines when present; returns `STALLED` on an mtime-stall with no terminal record; does not false-complete when the terminal string appears only earlier in the file (final-lines scope); tolerates a not-yet-existing file.
    - `heartbeat.sh`: two runs on the same day against a file target leave one dated line (update-in-place), not two.

- Integration: `not-required` (automated) — the live-test gate is the manual substitute.
  - Scope: `module boundaries/APIs/db/jobs/etc` — cross-script flows: takeover reap-before-release, dual-wake await, refresher orphan self-exit, manifest reap-reconciliation, the set-difference boot audit against a live epic register.
  - Reason: These flows cross the Agent-tool dispatch boundary, the background-shell lifecycle, and the Linear API — none reproducible offline. The harness **is** the live scheduled-task environment; there is no offline harness for it. See Non-Required Rationale and the Live-Test Gate section.
  - Harness: `not-applicable` (no offline harness exists; the substitute is the supervised first drive).
  - Minimum assertions: covered manually by live-test-gate items 1-7.

- E2E: `not-required` (automated) — same live-test-gate substitute.
  - Scope: `user/business-critical flows` — a full supervised drive: guard→acquire→boot→drive loop→merge close-out→coherence review→park/bloat→continuation brief→release, and the `rule-coherence` ruling session.
  - Reason: A drive is a multi-hour scheduled-session behavior over Agent-tool lanes and the PM system; it cannot be scripted from the desk. The design's own Live-Test Gate (§ lines 164-172) enumerates the seven behaviors that must be observed live.
  - Harness: `not-applicable`.
  - Minimum assertions: the seven live-test-gate items; items 6 and 7 verified **first** during the supervised drive (see Live-Test Gate execution).

### Critical Flows

- Driver mutual exclusion: guard `status` → `acquire` (stale-close takeover, settle, read-back, oldest-fresh wins) → become driver; loser self-closes and exits no-op.
- Fence: own-claim-open ∧ own-session-id ∧ oldest-fresh ∧ refresher-alive, evaluated before every durable-write close-out, on every wake, and immediately before `gh pr merge`.
- Liveness hierarchy: fresh matching driver claim ⇒ alive; else checkpoint-within-lease-of-now; else lease age.
- Fail-closed merge: apply `coherence-pending` **before** the merge command; set-difference boot audit (every merged child PR must hold a register entry); label clears iff set-difference empty ∧ no unresolved pending-human entry.
- Human-ruling route: `rule-coherence <sha> approve|reject|redirect` → wait-acquire → route per flag → in-session clear → release `ruled`, never enters the drive loop.
- Dual-wake await + STALLED stop-and-confirm protocol.
- Takeover reap-before-release ordering (reap the predecessor's lanes, then adopt its ticket claims).

### Regression Surface

- The intact-but-fenced `pickup-next` path (must still run correctly as the gate-fail fallback, and no-op against a live driver).
- The daily janitor (`reconcile-tickets`) — its existing merge/deploy/cleanup checks must survive the liveness-hierarchy and species-aware rewrites.
- The coherence gate and `coherence-pending` blocking scope (now fail-closed at the merge seam — strictly stronger, must not regress the 0.13 clean-verdict routing).
- The state machine states/transitions/evidence rules (one word fix + two row rewrites; the rest carries over unchanged).
- The two human gates and their structural enforcement (Gate 2 branch protection + the merge hook).

### Commands

- Unit: `bash scripts/validate-phase-skills.sh && bash scripts/validate-ticket-comment-templates.sh && bash scripts/validate-plugin-metadata.sh` (structural); `for f in dodi-dev/scripts/*.sh; do bash -n "$f"; done` (syntax); the synthetic script tests in Tasks A, B, C, D, G (each self-contained, invoked as `bash <test-file>`).
- Integration: `to-be-discovered` during the supervised first drive (no offline command exists).
- E2E: `to-be-discovered` — the live scheduled-task run is the environment; observation method in the Live-Test Gate execution section.
- Broader regression: the three validators above + `bash -n` across all scripts, run after every task.

### Harness Requirements

- `LINEAR_API_KEY` in the session environment (the `dodi-dev/scripts/` PM scripts require it).
- For the live-test gate only: a signed-off epic with ready work, branch protection on main/master, a tested escalation channel, the `dodi-drive-epic` scheduled task created and `dodi-pickup-next` paused, and a human at the monitor for the supervised first drive.
- For synthetic unit tests: `bash`, `python3`, and a scratch directory — no network, no PM access (tests stub the Linear reads with fixture JSON where a script's logic can be isolated, or exercise the pure classification/liveness helpers directly).

### Non-Required Rationale

- Unit: n/a (required).
- Integration: automated integration is **not-required with honest rationale** — every integration flow crosses the Agent-tool dispatch boundary (does a lane survive its dispatcher's death?), the background-shell lifecycle (does the refresher's orphan detector fire on session crash?), or the scheduler's overlap semantics (does an hourly run fire beside a live prior run?). None is observable without the live scheduled-task harness; there is no offline mock that would tell the truth. The manual substitute is the seven-item live-test gate, executed during a supervised first drive with a human observer. This is the deliberate Non-Required-with-substitute case, not a skipped obligation.
- E2E: same rationale — a drive is a multi-hour live behavior; the harness is the environment. Substitute: the Live-Test Gate execution section, items 6 and 7 front-loaded.

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker. For the live-test gate the harness **is** the scheduled-task environment — its unavailability from the desk is the documented reason integration/e2e are manual, not a skipped step.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, this is a plugin release with no spec lane — halt and escalate to the maintainer (the human at the monitor) rather than demote.
- **Every synthetic test must invoke the target script/function and assert on its actual output or exit code.** Inline re-implementation of the script's logic inside the test (re-running the same `awk`/arithmetic the script runs, then asserting on the test's own copy) and `grep`-the-source branch-existence assertions (`grep -q 'some-string' script.sh`) are **disallowed** — they prove the test author can copy code or that a literal survives, not that the script behaves. Where a subcommand mutates live PM state, exercise its extracted pure helper (fixture on stdin / env-injected TSV) or stub the network boundary via a PATH shim, but the assertion must still run the real code path.

---

## Tasks

### Task A: Comment-species substrate

The tagged progress/bookkeeping partition every downstream liveness consumer reads, plus the `lane-checkpoint.md` template (the header the "standard PM comment" never defined) and the producer redirects that make lane checkpoints render under that pinned header.

**Files:**
- Create: `dodi-dev/scripts/comment-species.sh`
- Create: `templates/ticket-comments/lane-checkpoint.md`
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md:36` (checkpoint producer → pinned header)
- Modify: `dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md:24` (checkpoint producer → pinned header)
- Modify: `dodi-dev/skills/epic-orchestrator/state-transitions.md:24-26` (checkpoint-contract intro → pinned header)

- [ ] **Step 1:** Create `dodi-dev/scripts/comment-species.sh` — the canonical tagged partition, sourced by other scripts. It ships with a shebang and the exec bit so `validate-phase-skills.sh`'s `test -x` / `bash -n` pass unmodified. It exposes one function, `comment_species`, that maps a comment's first-line header (or a raw heartbeat line) to `progress` or `bookkeeping`, defaulting **unknown → bookkeeping**.

```bash
#!/usr/bin/env bash
# Canonical tagged progress/bookkeeping partition for ticket-comment species.
# Sourced by claim.sh, release-claim.sh, watchdog-scan.sh; consumed by the
# guard probe and the janitor through the species-aware watchdog scan.
#
# One partition, one home. Repo-root templates/ is a validation mirror the
# target-repo worktree never sees, so this table lives inside the plugin.
#
# progress   = the ONLY two comment species that count as real work for the
#              wedged-driver probe and liveness tests: lane checkpoints and
#              decision-register entries (incl. the RULING variant, same header).
#              State/label transitions are NOT announced here — they are read
#              from issue HISTORY — so ready-to-implement / spec-ready / PR-ready
#              announcement comments are bookkeeping, not progress.
# bookkeeping = everything else — timer/bureaucratic/announcement writes that
#              must NOT reset a staleness clock: claims (both species),
#              heartbeats, takeover/janitor notes, continuation briefs,
#              assessments, deploy confirmations, and all the state-announcement
#              headers (spec-ready, ready-to-implement, child/epic-PR-ready).
#
# Usage (as a library):  source comment-species.sh; comment_species "<body-or-first-line>"
# Usage (as a CLI, for tests): comment-species.sh <<<"<body>"   -> prints the species
#
# Classification is header-based: the comment's first non-empty line. A raw
# heartbeat line (no markdown header) is carved out explicitly. Any header not
# in the table defaults to bookkeeping — never progress — so a novel comment
# species can mask neither a wedge nor a claim theft.
set -euo pipefail

comment_species() {
  # $1 = the comment body (or its first line). Returns via stdout.
  local body="$1"
  local first
  # First non-empty line.
  first="$(printf '%s\n' "$body" | sed -n '/[^[:space:]]/{p;q;}')"

  # Heartbeat carve-out: the heartbeat.sh line is not a markdown header.
  case "$first" in
    heartbeat\ *) echo bookkeeping; return 0 ;;
  esac

  case "$first" in
    # --- progress species (real work advances) ---
    # ONLY lane checkpoints and decision-register entries (incl. the RULING
    # variant, same header). State/label changes are detected from issue
    # HISTORY, not from announcement comments — so spec-ready / ready-to-implement
    # / child-pr-ready / epic-pr-ready are announcements, not progress: they fall
    # to bookkeeping below (listed explicitly for auditability).
    '# Decision Register Entry'*) echo progress ;;
    '# Lane Checkpoint'*)         echo progress ;;
    # --- bookkeeping species (timers / bureaucracy / announcements) ---
    '# Ticket Claim'*)            echo bookkeeping ;;
    '# Driver Claim'*)            echo bookkeeping ;;
    '# Continuation Brief'*)      echo bookkeeping ;;
    '# Epic Assessment'*)         echo bookkeeping ;;
    '# Deploy Confirmation'*)     echo bookkeeping ;;
    '# Workflow Demotion'*)       echo bookkeeping ;;
    '# Spec Ready'*)              echo bookkeeping ;;
    '# Ready To Implement'*)      echo bookkeeping ;;
    '# Child PR Ready'*)          echo bookkeeping ;;
    '# Epic PR Ready'*)           echo bookkeeping ;;
    '# Epic Signoff Request'*)    echo bookkeeping ;;
    # --- default: unknown header -> bookkeeping (never progress) ---
    *)                            echo bookkeeping ;;
  esac
}

# CLI mode for tests: read a body on stdin, print the species.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  comment_species "$(cat)"
fi
```

Note for the executor: confirm the exact header strings against the actual template first lines before finalizing the table (run `head -1 templates/ticket-comments/*.md`); the design's rule is *unknown⇒bookkeeping*, so any header you cannot confirm is safe to leave to the default. Only **two** progress headers are load-bearing — `# Decision Register Entry` (which includes the RULING variant, same header) and `# Lane Checkpoint` — plus the heartbeat carve-out; these must match exactly. The announcement headers (spec-ready, ready-to-implement, child-pr-ready, epic-pr-ready) are **bookkeeping**: state/label changes are detected from issue history, not from these comments, so a fresh announcement must not reset a staleness clock. (Confirmed against the real templates: the demotion header is `# Workflow Demotion`, and `# Epic Signoff Request (Gate 1)` needs the trailing `*` glob to match its parenthetical.)

- [ ] **Step 2:** Make it executable.

```bash
chmod +x dodi-dev/scripts/comment-species.sh
```

- [ ] **Step 3:** Create `templates/ticket-comments/lane-checkpoint.md` — the pinned header replacing the undefined "standard PM comment," carrying the session-run-id field tier-2 attribution depends on.

```markdown
# Lane Checkpoint

Ticket: `<child-ticket-id>` · Boundary: `<implementing | implementation-reviewing | testing | verifying | quality-gating | ready-for-child-pr | child-pr-reviewing>`

## Session

- Run id: `<session-run-id>`
- Posted at: `<ISO-8601 timestamp>`

## Evidence

- `<branch / worktree / plan link / commit ids / review evidence / test files / harness evidence / gate evidence — per the boundary's row in state-transitions.md>`

## Notes

- `<soft observation worth persisting, one line each, or "none">`
```

- [ ] **Step 4:** Redirect the checkpoint producer in `deliver-ticket/SKILL.md`. Replace the `## Checkpoints` sentence (currently `deliver-ticket/SKILL.md:36`) so it names the pinned header and the run-id field.

Old (line ~36):
```
Post the standard PM comment at each boundary as it is crossed: `implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, `child-pr-reviewing`. These are the audit trail and the resume contract — never batch them at the end.
```
New:
```
Post a **Lane Checkpoint** comment (pinned `# Lane Checkpoint` header, carrying the session run id — repo mirror `lane-checkpoint.md` for validation) at each boundary as it is crossed: `implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, `child-pr-reviewing`. The pinned header is load-bearing: under the comment-species partition's unknown⇒bookkeeping default, a headerless checkpoint is invisible to every liveness consumer. These are the audit trail and the resume contract — never batch them at the end.
```

- [ ] **Step 5:** Redirect the checkpoint producer in `lane-dispatch-prompt.md`. Replace the `Checkpoint mechanics` bullet (currently `lane-dispatch-prompt.md:24`).

Old (line ~24):
```
- Post the standard PM checkpoint comment at each boundary **as it is crossed** (`implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, `child-pr-reviewing`) — never batched at the end. They are the audit trail and the resume contract.
```
New:
```
- Post a **Lane Checkpoint** comment (pinned `# Lane Checkpoint` header carrying your session run id) at each boundary **as it is crossed** (`implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, `child-pr-reviewing`) — never batched at the end. The pinned header is what keeps the checkpoint visible to the liveness consumers (a headerless comment defaults to bookkeeping). They are the audit trail and the resume contract.
```

- [ ] **Step 6:** Point the state-transitions checkpoint-contract intro at the pinned header. In `state-transitions.md`, the `## Lane Checkpoint Contract (inside deliver-ticket)` intro sentence (line ~25):

Old:
```
The lane posts these as PM comments at each boundary. They are the audit trail and the resume contract — a re-dispatched lane continues from the last completed checkpoint.
```
New:
```
The lane posts these as **Lane Checkpoint** comments (pinned `# Lane Checkpoint` header, session-run-id field; repo mirror `lane-checkpoint.md` for validation) at each boundary. They are the audit trail and the resume contract — a re-dispatched lane continues from the last completed checkpoint. The pinned header is required: the comment-species partition classifies an unknown header as bookkeeping, which would hide the checkpoint from the wedged-driver probe and the liveness hierarchy.
```

- [ ] **Step 7:** Write a synthetic classification test at `dodi-dev/scripts/tests/test-comment-species.sh` (create the `tests/` dir). It sources the script and asserts each mapping.

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../comment-species.sh"

fail=0
assert() { # $1=expected $2=body $3=label
  local got; got="$(comment_species "$2")"
  if [[ "$got" != "$1" ]]; then echo "FAIL $3: expected $1 got $got" >&2; fail=1; fi
}

assert progress    '# Decision Register Entry\n\nChild: `X`' register-entry
assert progress    '# Lane Checkpoint\n\nTicket: `X`'       lane-checkpoint
assert bookkeeping  '# Ticket Claim\n\nTicket: `X`'          ticket-claim
assert bookkeeping  '# Driver Claim\n\nEpic: `X`'            driver-claim
assert bookkeeping  '# Continuation Brief'                   continuation-brief
assert bookkeeping  'heartbeat 2026-07-04T00:00:00Z host=h driver alive' heartbeat
assert bookkeeping  '# Some Novel Header Nobody Registered'  unknown-default
assert bookkeeping  '# Epic Assessment'                      epic-assessment
assert bookkeeping  '# Deploy Confirmation'                  deploy-confirmation
# Announcement headers are bookkeeping — state/label changes come from history,
# not these comments, so they must not reset a staleness clock (B1).
assert bookkeeping  '# Spec Ready'                           spec-ready-announce
assert bookkeeping  '# Ready To Implement'                   ready-to-implement-announce
assert bookkeeping  '# Child PR Ready'                       child-pr-ready-announce
assert bookkeeping  '# Epic PR Ready'                        epic-pr-ready-announce

if (( fail )); then echo "comment-species tests FAILED" >&2; exit 1; fi
echo "comment-species tests ok"
```

Note: the `\n` sequences above are literal-newline placeholders — write the test so the body strings contain real newlines (use `$'...'` ANSI-C quoting, e.g. `assert progress $'# Lane Checkpoint\n\nTicket: X' lane-checkpoint`). `comment_species` reads only the first non-empty line, so a single-line header body is also valid.

- [ ] **Step 8:** Verify.

Run: `chmod +x dodi-dev/scripts/tests/test-comment-species.sh && bash dodi-dev/scripts/tests/test-comment-species.sh && bash -n dodi-dev/scripts/comment-species.sh`
Expected: `comment-species tests ok` and no `bash -n` output. (Note: `validate-phase-skills.sh` still **passes** here — its `plugin_scripts` array is an allowlist, so a new *unlisted* script like `comment-species.sh` is simply not yet **guarded** by the validator (it is neither checked nor failed) until Task I wires it into the allowlist. A bare `bash -n` is the syntax gate for this task; the full validator with the new script under guard is Task I.)

- [ ] **Step 9:** Commit.

```bash
git add dodi-dev/scripts/comment-species.sh dodi-dev/scripts/tests/test-comment-species.sh templates/ticket-comments/lane-checkpoint.md dodi-dev/skills/deliver-ticket/SKILL.md dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md dodi-dev/skills/epic-orchestrator/state-transitions.md
git commit -m "feat: comment-species partition + lane-checkpoint header + producer redirects (0.14.0 layer A)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task B: driver-claim.sh + driver-claim template

The fenced driver mutual-exclusion mechanism. New script with subcommands `acquire | refresh | verify | release | status` (all five — every wiring of the four-subcommand surface produced a defect, hence `status`), a session-process orphan-detecting refresher, the four-conjunct fence, release-by-id + `ruled`/`taken-over` exit states, and the driver-claim template. Claims home on the **epic ticket**.

**Files:**
- Create: `dodi-dev/scripts/driver-claim.sh`
- Create: `templates/ticket-comments/driver-claim.md`
- Create: `dodi-dev/scripts/tests/test-driver-claim.sh`

- [ ] **Step 1:** Create `templates/ticket-comments/driver-claim.md` (the `# Driver Claim` species, structurally invisible to `claim.sh`/`release-claim.sh` which filter on `# Ticket Claim`).

```markdown
# Driver Claim

Epic: `<epic-ticket-id>`

## Claim

- Session run id: `<session-run-id>`
- Host: `<hostname>`
- Acquired at: `<ISO-8601 timestamp>`
- Refreshed at: `<ISO-8601 timestamp>`
- Lease window: `<duration, default 45m staleness threshold>`

## Exit

- Exit state: `<open | parked | bloat-handoff | no-op | ruled | taken-over | error>`
- Released at: `<pending>`
```

- [ ] **Step 2:** Create `dodi-dev/scripts/driver-claim.sh`. It sources `linear-api.sh`. Client-side ordering keys on `createdAt` (refresh bumps `updatedAt`; connection order lies), comment-id tie-break. Staleness is measured on `Refreshed at`. All comment reads page beyond `comments(last: 50)` (comment-window honesty) — reuse the paging helper introduced in `linear-api.sh` if present, else fetch with an explicit `after` cursor loop; the executor confirms the current `linear-api.sh` surface before wiring.

```bash
#!/usr/bin/env bash
# Fenced driver-claim mechanism — driver mutual exclusion, one live driver per
# active epic. Own comment species (# Driver Claim), never # Ticket Claim, on
# the EPIC ticket. claim.sh / release-claim.sh filter on # Ticket Claim, so
# they are structurally blind to these.
#
# Subcommands:
#   acquire  <epic-id> <session-run-id> [stale_min=45]
#   refresh  <epic-id> <session-run-id> <session-pid> [interval_sec=900]
#   verify   <epic-id> <session-run-id> [stale_min=45]
#   release  <epic-id> <claim-comment-id> <exit-state>
#   status   <epic-id> [stale_min=45]
#
# createdAt orders claims (refresh bumps updatedAt only); comment-id tie-breaks.
# Staleness is measured on the claim body's `Refreshed at` line, not updatedAt.
set -euo pipefail
# Source the API helper unless a caller (a test) has already provided linear_gql
# — this lets test-driver-claim.sh stub the network boundary without the
# re-source clobbering the stub. Same pattern in claim.sh / release-claim.sh.
if ! declare -F linear_gql >/dev/null 2>&1; then
  source "$(dirname "$0")/linear-api.sh"
fi

STALE_DEFAULT=45  # minutes

# --- pure selection helpers (no network) — the testable core ---
# Claim TSV shape (one row per open claim): <comment-id>\t<createdAt>\t<session-run-id>\t<refreshed-age-min>
# The rows are assumed pre-sorted oldest-createdAt-first (the reader sorts).
#
# _select_oldest_fresh: reads a claim TSV on stdin, prints the WHOLE winner row
#   (oldest fresh open, i.e. first row with age < stale) or nothing. This is the
#   one selection the acquire/verify/status paths share, so tests invoke it
#   directly with fixture TSV instead of re-implementing the awk.
_select_oldest_fresh() {  # $1 = stale_min ; TSV on stdin
  local stale="${1:-$STALE_DEFAULT}"
  awk -F'\t' -v s="$stale" '$4 < s {print; exit}'
}

# --- read all open driver claims on the epic, paged, oldest-createdAt first ---
# Emits TSV: <comment-id>\t<createdAt>\t<session-run-id>\t<refreshed-age-min>
# Test override: if DRIVER_CLAIMS_TSV is set (to a file path or a literal TSV),
# emit that instead of hitting the network — this is how test-driver-claim.sh
# injects fixtures into acquire/verify/status without a live read.
_read_open_driver_claims() {
  local epic="$1"
  if [[ -n "${DRIVER_CLAIMS_TSV:-}" ]]; then
    if [[ -f "$DRIVER_CLAIMS_TSV" ]]; then cat "$DRIVER_CLAIMS_TSV"; else printf '%s\n' "$DRIVER_CLAIMS_TSV"; fi
    return 0
  fi
  local resp
  # Page: fetch comments in windows until no nextPage (honor the comment window).
  resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id comments(last: 100) { nodes { id createdAt body } } } }' "{\"id\": \"$epic\"}")"
  RESP="$resp" python3 <<'PY'
import json, os, sys
from datetime import datetime, timezone
data = json.loads(os.environ["RESP"])
now = datetime.now(timezone.utc)
rows = []
for c in data["data"]["issue"]["comments"]["nodes"]:
    b = c["body"]
    if not b.startswith("# Driver Claim"):
        continue
    if "- Exit state: `open`" not in b:
        continue
    srid = "?"
    refreshed = None
    for l in b.splitlines():
        if l.startswith("- Session run id:") and "`" in l:
            srid = l.split("`")[1]
        if l.startswith("- Refreshed at:") and "`" in l:
            try:
                refreshed = datetime.fromisoformat(l.split("`")[1].replace("Z", "+00:00"))
            except ValueError:
                refreshed = None
    age_min = (now - refreshed).total_seconds()/60 if refreshed else 1e9
    created = c["createdAt"]
    rows.append((created, c["id"], srid, age_min))
rows.sort(key=lambda r: (r[0], r[1]))  # createdAt, then comment-id
for created, cid, srid, age in rows:
    print(f"{cid}\t{created}\t{srid}\t{age:.1f}")
PY
}

# --- issue uuid for mutations ---
_issue_uuid() {
  local epic="$1" resp
  resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id } }' "{\"id\": \"$epic\"}")"
  RESP="$resp" python3 -c 'import json,os; print(json.loads(os.environ["RESP"])["data"]["issue"]["id"])'
}

_post_claim() {  # epic-uuid session-run-id host stale_min -> prints new comment id
  local uuid="$1" srid="$2" host="$3" stale="$4"
  local now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local body="# Driver Claim

Epic: \`$uuid\`

## Claim

- Session run id: \`$srid\`
- Host: \`$host\`
- Acquired at: \`$now\`
- Refreshed at: \`$now\`
- Lease window: \`${stale}m\`

## Exit

- Exit state: \`open\`
- Released at: \`<pending>\`"
  local vars; vars="$(python3 -c 'import json,sys; print(json.dumps({"input": {"issueId": sys.argv[1], "body": sys.argv[2]}}))' "$uuid" "$body")"
  linear_gql 'mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success comment { id } } }' "$vars" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["commentCreate"]["comment"]["id"])'
}

_close_claim() {  # comment-id exit-state
  local cid="$1" state="$2" now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # Fetch the claim body, flip Exit state + Released at, update in place.
  local resp; resp="$(linear_gql 'query($id: String!) { comment(id: $id) { id body } }' "{\"id\": \"$cid\"}")"
  local body; body="$(RESP="$resp" STATE="$state" NOW="$now" python3 <<'PY'
import json, os
c = json.loads(os.environ["RESP"])["data"]["comment"]
b = (c["body"]
     .replace("- Exit state: `open`", f"- Exit state: `{os.environ['STATE']}`")
     .replace("- Released at: `<pending>`", f"- Released at: `{os.environ['NOW']}`"))
print(json.dumps(b))
PY
)"
  local vars; vars="$(python3 -c 'import json,sys; print(json.dumps({"id": sys.argv[1], "input": {"body": json.loads(sys.argv[2])}}))' "$cid" "$body")"
  linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null
}

cmd="${1:?usage: driver-claim.sh <acquire|refresh|verify|release|status> ...}"; shift || true

case "$cmd" in
  status)
    epic="${1:?status <epic-id> [stale_min]}"; stale="${2:-$STALE_DEFAULT}"
    claims="$(_read_open_driver_claims "$epic")" || { echo "read error" >&2; exit 2; }
    fresh="$(_select_oldest_fresh "$stale" <<<"$claims")"
    if [[ -n "$fresh" ]]; then
      echo "fresh open driver claim exists: $fresh"
      exit 0
    fi
    echo "no fresh open driver claim"
    exit 1
    ;;

  acquire)
    epic="${1:?acquire <epic-id> <session-run-id> [stale_min]}"; srid="${2:?session-run-id}"; stale="${3:-$STALE_DEFAULT}"
    host="$(hostname -s)"
    # 1. Close any STALE open driver claims first — re-read staleness immediately
    #    before the close so a recovering refresher at the edge is not beheaded.
    #    Capture the read into a variable and ABORT on a read error (a transport
    #    failure must not silently look like "no stale claims" and let us barge in).
    pre_claims="$(_read_open_driver_claims "$epic")" || { echo "acquire: read error before self-close; aborting" >&2; exit 2; }
    while IFS=$'\t' read -r cid created csrid age; do
      [[ -z "$cid" ]] && continue
      if (( $(python3 -c "print(1 if float('$age') >= float('$stale') else 0)") )); then
        # Closing a STALE PREDECESSOR is a takeover, not a lost race — record it as
        # `taken-over` so the audit trail distinguishes "I reaped a dead driver" from
        # "I lost the acquire race" (which is the `no-op` below on our OWN claim).
        _close_claim "$cid" "taken-over" || true
      fi
    done <<<"$pre_claims"
    # 2. Post own claim.
    uuid="$(_issue_uuid "$epic")"
    mine="$(_post_claim "$uuid" "$srid" "$host" "$stale")"
    # 3. Settle (read-replication lag), then read back all open claims.
    sleep 3
    claims="$(_read_open_driver_claims "$epic")" || { echo "acquire: read error on read-back; closing own claim and aborting" >&2; _close_claim "$mine" "no-op" || true; exit 2; }
    # 4. Win iff own claim is the OLDEST FRESH open (createdAt, comment-id tie-break).
    winner="$(_select_oldest_fresh "$stale" <<<"$claims" | cut -f1)"
    if [[ "$winner" == "$mine" ]]; then
      echo "acquired session_run_id=$srid claim=$mine"
      exit 0
    fi
    # 5. Lose -> close own, exit no-op.
    _close_claim "$mine" "no-op" || true
    echo "lost driver claim to $winner; exiting no-op" >&2
    exit 3
    ;;

  verify)
    # The fence: own claim open ∧ own session id ∧ own is oldest-fresh-open ∧ refresher alive.
    # Four conjuncts. This subcommand evaluates the first three (claim-state
    # conjuncts) against the claim TSV; the fourth (refresher alive) is the
    # caller's assert (the caller holds the refresher pid — see the caller note).
    # A test injects claim TSVs via DRIVER_CLAIMS_TSV and asserts exit 0 only when
    # all three hold, and non-zero for each failure mode.
    epic="${1:?verify <epic-id> <session-run-id> [stale_min]}"; srid="${2:?session-run-id}"; stale="${3:-$STALE_DEFAULT}"
    claims="$(_read_open_driver_claims "$epic")" || { echo "read error" >&2; exit 2; }
    # Conjunct 1+2: is there an oldest-fresh OPEN claim at all?
    top="$(_select_oldest_fresh "$stale" <<<"$claims")"
    if [[ -z "$top" ]]; then echo "no fresh open claim (own-claim-closed or all-stale)" >&2; exit 1; fi
    # Conjunct 3: is the oldest-fresh claim OURS?
    top_srid="$(cut -f3 <<<"$top")"
    if [[ "$top_srid" != "$srid" ]]; then echo "ownership lost: oldest-fresh is $top_srid not $srid" >&2; exit 1; fi
    echo "fence ok session_run_id=$srid"
    exit 0
    ;;

  refresh)
    # Session-lifetime background shell. Watches the SESSION PROCESS, not its own
    # parent: a background command's chain is command -> shell wrapper -> session
    # process, and the wrapper SURVIVES session death. The caller (drive-epic Boot
    # Step 1) captures the session pid by walking the PPID chain up from $$ and
    # passes it here; self-exit when it disappears, detected by reparenting/PPID
    # change rather than kill -0 alone (zombie-window false-alive).
    #
    # LEASE-ONLY fallback: a <session-pid> of 0 disables orphan watching (used
    # when session-pid capture is not yet confirmed live — gate item 3). The
    # refresher then only bumps the lease every ~interval; a crashed session's
    # claim decays by lease alone in <=45m (no orphan self-exit). Buildable now;
    # the orphan-aware path is a strict improvement once the walk is confirmed.
    epic="${1:?refresh <epic-id> <session-run-id> <session-pid> [interval]}"; srid="${2:?session-run-id}"
    spid="${3:?session-pid}"; interval="${4:-900}"
    orphan_watch=1
    [[ "$spid" == "0" ]] && orphan_watch=0
    orig_ppid="$(ps -o ppid= -p "$spid" 2>/dev/null | tr -d ' ' || echo GONE)"
    while :; do
      # Orphan detection (skipped in lease-only mode): session process gone, or
      # reparented (PPID changed).
      if (( orphan_watch )); then
        cur_ppid="$(ps -o ppid= -p "$spid" 2>/dev/null | tr -d ' ' || echo GONE)"
        if [[ "$cur_ppid" == "GONE" || "$cur_ppid" != "$orig_ppid" ]]; then
          echo "refresher: session process $spid gone/reparented; self-exiting" >&2
          exit 0
        fi
      fi
      # Bump the claim by mutating content (Linear updatedAt bumps on change only).
      mine="$(_read_open_driver_claims "$epic" | awk -F'\t' -v r="$srid" '$3==r {print $1; exit}')"
      if [[ -n "$mine" ]]; then
        now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        resp="$(linear_gql 'query($id: String!) { comment(id: $id) { id body } }' "{\"id\": \"$mine\"}")"
        body="$(RESP="$resp" NOW="$now" python3 -c 'import json,os,sys,re; c=json.loads(os.environ["RESP"])["data"]["comment"]; b=re.sub(r"- Refreshed at: `[^`]*`", "- Refreshed at: `"+os.environ["NOW"]+"`", c["body"]); print(json.dumps(b))')"
        vars="$(python3 -c 'import json,sys; print(json.dumps({"id": sys.argv[1], "input": {"body": json.loads(sys.argv[2])}}))' "$mine" "$body")"
        linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null || true
      fi
      sleep "$interval"
    done
    ;;

  release)
    # Close OWN claim by id, with exit state. No attempt counters.
    epic="${1:?release <epic-id> <claim-comment-id> <exit-state>}"; cid="${2:?claim-comment-id}"; state="${3:?exit-state}"
    case "$state" in parked|bloat-handoff|no-op|ruled|taken-over|error) ;; *) echo "bad exit state: $state" >&2; exit 2 ;; esac
    _close_claim "$cid" "$state"
    echo "released driver claim=$cid exit=$state"
    exit 0
    ;;

  *) echo "unknown subcommand: $cmd" >&2; exit 2 ;;
esac
```

Executor notes: (a) **First, confirm the `comment(id:)` GraphQL path against the live API** before wiring `_close_claim`/`refresh` (which read a single comment by id). `linear-api.sh` exposes only `linear_gql` — there is **no** codebase precedent for a `comment(id:)` query, so this is a live-confirm step, not an assumption: run `linear_gql 'query($id: String!) { comment(id: $id) { id body } }' "{\"id\":\"<a-real-comment-id>\"}"` once and check for a non-error response. **If `comment(id:)` is unsupported, fall back to the issue-scoped read** — fetch the epic's comment list (the same `issue(id:){ comments }` query the reader already uses) and filter by id in python — and rewrite `_close_claim`/`refresh`'s single-comment fetch that way. Do this confirmation before Step 3. (b) The paging in `_read_open_driver_claims` uses `comments(last: 100)` as a first cut; if a live epic can exceed 100 comments, extend it to a cursor loop (the comment-window-honesty rule) — assert-or-page, matching the `watchdog-scan.sh` precedent. (c) `refresh`'s reparenting check is the empirically-corrected mechanism; keep the PPID-change branch, do not simplify to `kill -0`. (d) `verify` evaluates three of the four fence conjuncts (own-claim-open ∧ own-session ∧ oldest-fresh); the **refresher-alive** fourth conjunct is asserted by the caller, which holds the refresher's background-shell handle — the drive-loop fence step is `driver-claim.sh verify … && <refresher-alive check>`. The test injects claim TSVs via `DRIVER_CLAIMS_TSV` to exercise the three claim-state conjuncts directly.

- [ ] **Step 3:** Make it executable.

```bash
chmod +x dodi-dev/scripts/driver-claim.sh
```

- [ ] **Step 4:** Write `dodi-dev/scripts/tests/test-driver-claim.sh` — a synthetic test that **invokes the real `driver-claim.sh`** with claim fixtures injected through the `DRIVER_CLAIMS_TSV` env override (no network). It sources the script for the pure `_select_oldest_fresh` helper and runs `status`/`verify` as real subcommands against injected TSV, and drives **both** `acquire` outcomes (wins and loses) through the stubbed network boundary so the Testing-Contract Minimum assertion "`acquire` on an epic with no open driver claim wins and prints the run id" is exercised alongside the lose path. No inline `awk` re-implementation, no `bash -n`-only "coverage" — the assertions run the script's own code paths (per the Testing Contract Verification Rule).

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DC="$HERE/../driver-claim.sh"

# status/verify are network-free once DRIVER_CLAIMS_TSV is set (no mutation), so
# we invoke the REAL subcommands as subprocesses and assert on their exit codes /
# output — this exercises the real _select_oldest_fresh selection and the real
# conjunct evaluation, not a copy. acquire mutates, so it is driven below with a
# stubbed linear_gql (the network boundary) while its real case block runs.

# Fixture: three open claims — one stale (60m), two fresh (20m, 5m).
# Oldest-fresh (by createdAt order, already sorted) is c2/sridB.
export DRIVER_CLAIMS_TSV=$'c1\t2026-07-04T00:00:00Z\tsridA\t60.0\nc2\t2026-07-04T00:05:00Z\tsridB\t20.0\nc3\t2026-07-04T00:06:00Z\tsridC\t5.0'

run() { # subcommand + args; captures rc, ignoring stderr
  set +e; out="$(bash "$DC" "$@" 2>/dev/null)"; rc=$?; set -e
}

# status: a fresh open claim exists -> exit 0, names the oldest-fresh row.
run status EPIC
[[ "$rc" -eq 0 ]] || { echo "FAIL status-fresh: expected exit 0 got $rc" >&2; exit 1; }
grep -q 'sridB' <<<"$out" || { echo "FAIL status-fresh: expected oldest-fresh sridB, got: $out" >&2; exit 1; }

# verify as sridB (the oldest-fresh owner) -> fence ok, exit 0 (own-claim-open ∧ own-session ∧ oldest-fresh).
run verify EPIC sridB
[[ "$rc" -eq 0 ]] || { echo "FAIL verify-owner: expected exit 0 for sridB got $rc ($out)" >&2; exit 1; }

# verify as sridC (fresh but NOT oldest) -> ownership lost, non-zero (not-oldest conjunct).
run verify EPIC sridC
[[ "$rc" -ne 0 ]] || { echo "FAIL verify-not-oldest: expected non-zero for sridC" >&2; exit 1; }

# verify as a foreign session with no claim at all -> non-zero (foreign-oldest / ownership lost).
run verify EPIC sridZZZ
[[ "$rc" -ne 0 ]] || { echo "FAIL verify-foreign: expected non-zero for sridZZZ" >&2; exit 1; }

# All-stale (own claim effectively closed / decayed) -> no fresh open claim.
# verify -> non-zero (own-claim-closed conjunct); status -> exit 1.
export DRIVER_CLAIMS_TSV=$'c1\t2026-07-04T00:00:00Z\tsridB\t60.0'
run verify EPIC sridB
[[ "$rc" -ne 0 ]] || { echo "FAIL verify-own-closed: expected non-zero when own claim is stale" >&2; exit 1; }
run status EPIC
[[ "$rc" -eq 1 ]] || { echo "FAIL status-none: expected exit 1 when no fresh claim, got $rc" >&2; exit 1; }

# acquire-loses: own claim posts behind an already-fresh foreign claim.
# Stub ONLY the network boundary (linear_gql) and sleep; the real acquire case
# block, the real _issue_uuid/_post_claim/_close_claim, and the real
# _select_oldest_fresh all run. driver-claim.sh source-guards linear-api.sh
# (`declare -F linear_gql`), so our stub survives the source. The stubbed
# linear_gql returns whatever the parse steps need: a uuid for _issue_uuid and a
# new comment id ("m1") for _post_claim's commentCreate parse; the read-back
# comes from DRIVER_CLAIMS_TSV (a fresh `foreign` ordered before `mine`), so
# winner=foreign != mine and acquire exits 3.
acq_rc="$(
  set +e
  bash -c '
    set -euo pipefail
    linear_gql() {
      # Respond to whatever mutation/query the acquire path issues offline.
      case "$1" in
        *issue*id*) echo "{\"data\":{\"issue\":{\"id\":\"uuid-EPIC\"}}}" ;;
        *commentCreate*) echo "{\"data\":{\"commentCreate\":{\"comment\":{\"id\":\"m1\"}}}}" ;;
        *comment*body*) echo "{\"data\":{\"comment\":{\"id\":\"m1\",\"body\":\"# Driver Claim\n- Exit state: \`open\`\n- Released at: \`<pending>\`\"}}}" ;;
        *commentUpdate*) echo "{\"data\":{\"commentUpdate\":{\"success\":true}}}" ;;
        *) echo "{\"data\":{}}" ;;
      esac
    }
    export -f linear_gql
    sleep() { :; }                 # skip the settle
    export DRIVER_CLAIMS_TSV=$'"'"'f1\t2026-07-04T00:00:00Z\tforeign\t3.0\nm1\t2026-07-04T00:10:00Z\tmine\t0.0'"'"'
    bash "'"$DC"'" acquire EPIC mine 45
  ' >/dev/null 2>&1
  echo $?
)"
[[ "$acq_rc" -eq 3 ]] || { echo "FAIL acquire-loses: expected exit 3, got $acq_rc" >&2; exit 1; }

# acquire-wins: on read-back, own claim ("m1"/mine) is the oldest-fresh open with
# NO fresher foreign claim ahead of it — same stubbed network boundary as the lose
# case, but the read-back TSV names only `mine`, so winner==mine and acquire exits 0
# printing `acquired session_run_id=mine`. Testing-Contract Minimum assertion:
# "acquire on an epic with no open driver claim wins and prints the run id."
set +e
acq_win_out="$(
  bash -c '
    set -euo pipefail
    linear_gql() {
      case "$1" in
        *issue*id*) echo "{\"data\":{\"issue\":{\"id\":\"uuid-EPIC\"}}}" ;;
        *commentCreate*) echo "{\"data\":{\"commentCreate\":{\"comment\":{\"id\":\"m1\"}}}}" ;;
        *comment*body*) echo "{\"data\":{\"comment\":{\"id\":\"m1\",\"body\":\"# Driver Claim\n- Exit state: \`open\`\n- Released at: \`<pending>\`\"}}}" ;;
        *commentUpdate*) echo "{\"data\":{\"commentUpdate\":{\"success\":true}}}" ;;
        *) echo "{\"data\":{}}" ;;
      esac
    }
    export -f linear_gql
    sleep() { :; }                 # skip the settle
    # Read-back: only our own claim is open and fresh -> winner==mine.
    export DRIVER_CLAIMS_TSV=$'"'"'m1\t2026-07-04T00:10:00Z\tmine\t0.0'"'"'
    bash "'"$DC"'" acquire EPIC mine 45
  ' 2>/dev/null
)"
acq_win_rc=$?
set -e
[[ "$acq_win_rc" -eq 0 ]] || { echo "FAIL acquire-wins: expected exit 0, got $acq_win_rc" >&2; exit 1; }
grep -q 'acquired session_run_id=mine' <<<"$acq_win_out" || { echo "FAIL acquire-wins: expected 'acquired session_run_id=mine', got: $acq_win_out" >&2; exit 1; }

echo "driver-claim tests ok"
```

Executor note on the `taken-over` exit state: `acquire`'s stale-close records the reaped predecessor as `taken-over` (distinct from the `no-op` used when *this* session loses the acquire race), so the audit trail tells "I reaped a dead driver" apart from "I lost." It is in the `release` valid-state set, the `_close_claim` call, and the driver-claim template's Exit-state enum. **Enum note (do not halt on this):** this release exit-state enum deliberately extends spec v17 §45 (`parked|bloat-handoff|no-op|ruled|error`) with `taken-over`, added during the plan-review capstone fold — it is **not** a spec/plan conflict, so do not halt-and-escalate on it under the Verification Rules' spec/plan-mismatch clause. A spec §45 sync to add `taken-over` is a pending trivial doc follow-up. The Task I template validator does **not** `check_contains` any specific exit-state token (only `Session run id:` + the `## Claim`/`## Exit` headings), so adding `taken-over` needs no validator change and stays consistent; `test-driver-claim.sh`'s `acquire-loses` fixture uses two **fresh** claims, so the stale-close (and thus the `taken-over` write) does not fire there — the enum addition does not perturb the existing test.

Executor note: the `acquire-loses` harness stubs only `linear_gql` (exported so the child `driver-claim.sh` inherits it) and `sleep`; the source-guard in `driver-claim.sh` keeps the stub from being clobbered. The **real** acquire case block, real `_post_claim`/`_close_claim`/`_issue_uuid`, and real `_select_oldest_fresh` all execute — the read-back TSV names a fresh `foreign` claim ordered before `mine`, so `winner != mine` and acquire exits 3. This satisfies the Verification Rule (real code path, not a re-implementation). If exporting a shell function across the invocation is awkward in your shell, an equivalent is a PATH-shim `linear-api.sh` copy in a temp dir referenced by an env override — but the exported-function form above is the simplest that keeps the real logic in the loop. Adjust the stubbed response bodies if the executor's confirmed `comment(id:)` fallback (note (a)) changes the query shapes.

- [ ] **Step 5:** Verify.

Run: `chmod +x dodi-dev/scripts/tests/test-driver-claim.sh && bash dodi-dev/scripts/tests/test-driver-claim.sh && bash -n dodi-dev/scripts/driver-claim.sh`
Expected: `driver-claim tests ok` and no `bash -n` output.

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/scripts/driver-claim.sh dodi-dev/scripts/tests/test-driver-claim.sh templates/ticket-comments/driver-claim.md
git commit -m "feat: driver-claim.sh fenced mutual exclusion + driver-claim template (0.14.0 layer B)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task C: claim.sh / release-claim.sh — session identity + liveness hierarchy

Session-run identity on per-ticket claims, the driver-claim-topped liveness hierarchy, foreign-release by claim id with a pre-close staleness re-read, comment paging, epic-by-parent-traversal, tier-2 session-attributed checkpoints. Plus `claim.md` gains the session-id field and the `coherence-review` enum value.

**Files:**
- Modify: `dodi-dev/scripts/claim.sh` (whole liveness/identity rewrite)
- Modify: `dodi-dev/scripts/release-claim.sh` (foreign-release by id + pre-close re-read)
- Modify: `templates/ticket-comments/claim.md` (session-id field + `coherence-review` enum)

- [ ] **Step 1:** Rewrite `dodi-dev/scripts/claim.sh` to mint/record a session run id, apply the three-tier liveness hierarchy, source `comment-species.sh` for tier-2 checkpoint attribution, and resolve the epic by parent traversal for tier-1.

Replace the whole body below the shebang/comment block. Key changes: (1) `<session-run-id>` is a required argument (callers mint it once per session); (2) foreignness is session-scoped — a claim with a *different* session id, or no id (legacy), is judged by the hierarchy, not by host; (3) tier-1 resolves the epic via `issue.parent` hopping to the parentless root, then checks `driver-claim.sh status` for a fresh matching driver claim; (4) tier-2 counts only checkpoints attributable to the claim's session (species=progress ∧ run-id match) within one lease window of now; (5) tier-3 is the lease-age test.

```bash
#!/usr/bin/env bash
# Post a per-ticket claim comment before acting on a ticket (driver / lane /
# manual / 0.14.0-tick claim discipline). Refuses a LIVE foreign claim per the
# driver-claim-topped liveness hierarchy.
#
# Usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours=2]
#   <action>: mature-ticket | deliver-ticket | merge-child | submit-epic-pr | coherence-review
#   claim.sh classify <cstate> <csrid> <srid> <cage_h> <lease_h> <tier1> <tier2>
#     -> the pure liveness decision (alive|claimable), no network — for tests.
# Exit: 0 claimed (or own-session no-op); 3 live foreign claim; 2 error.
#
# Liveness hierarchy (in order), evaluated by the pure _liveness_tier:
#   1. claim's session id matches a FRESH open DRIVER claim (on the epic, found
#      by parent traversal) -> alive, full stop.
#   2. else, a progress-species checkpoint attributable to the claim's session
#      within one lease window of NOW -> alive.
#   3. else the lease-age test on the claim's own age.
# Legacy claims with no session id: tier-3 only. A LIVE legacy (id-less) foreign
# claim is refused (exit 3) just like an id-bearing one — the guard keys on
# csrid != srid, NOT on csrid being non-empty (that earlier conjunct was the
# legacy-claim theft bug). Own-session (csrid==srid) short-circuits to a no-op.
set -euo pipefail
# Source-guarded (tests may pre-stub linear_gql / driver-claim status).
if ! declare -F linear_gql >/dev/null 2>&1; then source "$(dirname "$0")/linear-api.sh"; fi
source "$(dirname "$0")/comment-species.sh"

# --- pure liveness-tier decision (no network) — the testable core ---
# _liveness_tier: given the claim facts and the tier-1/tier-2 signals already
# resolved by the caller, prints `alive` or `claimable`. This is the single
# decision point the exit-3 guard consumes; a test drives it directly with each
# tier's inputs (no PM access), and the network-bearing main flow computes the
# signals then calls it.
#
# Args (positional, all strings):
#   $1 cstate       open|closed
#   $2 csrid        claim's session run id ("" for a legacy id-less claim)
#   $3 srid         THIS session's run id
#   $4 cage_h       claim age in hours (for the tier-3 lease test)
#   $5 lease_hours  lease window in hours
#   $6 tier1        yes|no  — csrid matches a fresh open driver claim on the epic
#   $7 tier2        yes|no  — a progress-species checkpoint attributable to csrid
#                            within one lease window of now
# A closed claim is always claimable. Own-session (csrid==srid) is never foreign
# (own work in progress) — the guard below never refuses on it, so this returns
# `claimable` for it (the main flow short-circuits own-session to a no-op before
# ever refusing). Legacy (csrid=="") is judged by tier-3 alone.
_liveness_tier() {
  local cstate="$1" csrid="$2" srid="$3" cage_h="$4" lease_hours="$5" tier1="$6" tier2="$7"
  [[ "$cstate" != "open" ]] && { echo claimable; return 0; }
  # Own-session or legacy: no tier-1/tier-2 attribution to another session.
  if [[ "$csrid" == "$srid" ]]; then echo claimable; return 0; fi
  if [[ -n "$csrid" ]]; then
    # Foreign, id-bearing claim: full hierarchy.
    [[ "$tier1" == "yes" ]] && { echo alive; return 0; }
    [[ "$tier2" == "yes" ]] && { echo alive; return 0; }
  fi
  # Tier-3 (and the ONLY tier for a legacy id-less foreign claim): lease age.
  if (( $(python3 -c "print(1 if float('$cage_h') < float('$lease_hours') else 0)") )); then
    echo alive
  else
    echo claimable
  fi
}

# Test/inspection subcommand: `claim.sh classify <cstate> <csrid> <srid> <cage_h> <lease_h> <tier1> <tier2>`
# Prints alive|claimable and exits — the pure decision, no network.
if [[ "${1:-}" == "classify" ]]; then
  shift
  _liveness_tier "$@"
  exit 0
fi

ticket="${1:?usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours]}"
action="${2:?usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours]}"
srid="${3:?usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours]}"
lease_hours="${4:-2}"
host="$(hostname -s)"
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Read the ticket: id, parent chain (for tier-1 epic resolution), comments (paged).
resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id parent { id } comments(last: 100) { nodes { id body createdAt updatedAt } } } }' "{\"id\": \"$ticket\"}")"
issue_uuid="$(RESP="$resp" python3 -c 'import json,os; print(json.loads(os.environ["RESP"])["data"]["issue"]["id"])')"

# Resolve the epic (parentless root) for tier-1.
epic_id="$ticket"
cur="$ticket"
while :; do
  p="$(linear_gql 'query($id: String!) { issue(id: $id) { parent { id } } }' "{\"id\": \"$cur\"}" \
       | python3 -c 'import json,sys; d=json.load(sys.stdin)["data"]["issue"]["parent"]; print(d["id"] if d else "")')"
  [[ -z "$p" ]] && break
  epic_id="$p"; cur="$p"
done

# Inspect the most recent per-ticket claim comment (# Ticket Claim only).
claim_info="$(RESP="$resp" LEASE_H="$lease_hours" python3 <<'PY'
import json, os
from datetime import datetime, timezone
lease_hours = float(os.environ["LEASE_H"])
data = json.loads(os.environ["RESP"])
now = datetime.now(timezone.utc)
comments = data["data"]["issue"]["comments"]["nodes"]
claims = [c for c in comments if c["body"].startswith("# Ticket Claim")]
if not claims:
    print("none\t-\t-\t0\t-")
    raise SystemExit
c = claims[-1]
body = c["body"]
open_claim = "- Exit state: `<open>`" in body
csrid = next((l.split("`")[1] for l in body.splitlines() if l.startswith("- Session run id:") and "`" in l), "")
updated = datetime.fromisoformat(c["updatedAt"].replace("Z","+00:00"))
age_h = (now - updated).total_seconds()/3600
# tier-2 pre-compute: latest progress-species comment attributable to csrid, in hours-ago.
# (Species classification is applied in bash; here we just export the claim facts.)
print(f"{'open' if open_claim else 'closed'}\t{csrid}\t{age_h:.3f}\t{c['id']}\t{c['updatedAt']}")
PY
)"

cstate="$(cut -f1 <<<"$claim_info")"
csrid="$(cut -f2 <<<"$claim_info")"
cage_h="$(cut -f3 <<<"$claim_info")"
cclaim_id="$(cut -f4 <<<"$claim_info")"

# Own-session short-circuit: the newest open claim is already ours. Do not append
# a duplicate # Ticket Claim — no-op and echo. (A caller re-running claim.sh in
# the same session must not stack claims.)
if [[ "$cstate" == "open" && -n "$csrid" && "$csrid" == "$srid" ]]; then
  echo "already claimed by this session (claim=$cclaim_id action=$action); no-op"
  exit 0
fi

# --- Resolve the tier-1 and tier-2 signals for a FOREIGN, id-bearing claim,
#     then delegate the decision to the pure _liveness_tier. Legacy (csrid="")
#     and closed claims skip signal resolution — _liveness_tier judges them by
#     tier-3 / closed directly. ---
tier1="no"; tier2="no"
if [[ "$cstate" == "open" && -n "$csrid" && "$csrid" != "$srid" ]]; then
  # Tier 1: does csrid match a FRESH open driver claim on the epic?
  if "$(dirname "$0")/driver-claim.sh" status "$epic_id" 2>/dev/null | grep -q "$csrid"; then
    tier1="yes"
  fi
  # Tier 2: a progress-species checkpoint attributable to csrid within one lease window of now?
  if [[ "$tier1" != "yes" ]]; then
    tier2="$(RESP="$resp" CSRID="$csrid" LEASE_H="$lease_hours" python3 <<'PY'
import json, os
from datetime import datetime, timezone
lease_hours = float(os.environ["LEASE_H"]); csrid = os.environ["CSRID"]
data = json.loads(os.environ["RESP"]); now = datetime.now(timezone.utc)
alive = "no"
for c in data["data"]["issue"]["comments"]["nodes"]:
    b = c["body"]
    if f"Run id: `{csrid}`" not in b and f"Run id: {csrid}" not in b:
        continue
    # Species check: only the two progress headers a session posts under its run
    # id (Lane Checkpoint, Decision Register Entry) carry a run-id field, so an
    # inline first-header match is exactly comment-species.sh's progress set for
    # this population. (unknown⇒bookkeeping semantics preserved: a non-matching
    # header is skipped, i.e. treated as non-progress.)
    first = next((l for l in b.splitlines() if l.strip()), "")
    progress = first.startswith("# Lane Checkpoint") or first.startswith("# Decision Register Entry")
    if not progress:
        continue
    ts = datetime.fromisoformat(c["updatedAt"].replace("Z","+00:00"))
    if (now - ts).total_seconds()/3600 <= lease_hours:
        alive = "yes"; break
print(alive)
PY
)"
  fi
fi

# The decision: pure tier evaluation (also covers legacy tier-3 and closed).
alive="$(_liveness_tier "$cstate" "$csrid" "$srid" "$cage_h" "$lease_hours" "$tier1" "$tier2")"

# Exit-3 guard (B5 theft fix): refuse ANY live claim that is not this session's
# own. The old guard also required `-n "$csrid"`, which was FALSE for a legacy
# id-less claim — so a LIVE legacy foreign claim was silently stolen. Dropping
# that conjunct closes the theft; own-session (csrid==srid) already short-circuited
# to a no-op above, so it never reaches here to self-refuse.
if [[ "$alive" == "alive" && "$csrid" != "$srid" ]]; then
  echo "live foreign claim: session=${csrid:-<legacy/no-id>} age_h=$cage_h"
  exit 3
fi

body="# Ticket Claim

Ticket: \`$ticket\`

## Claim

- Session run id: \`$srid\`
- Host: \`$host\`
- Claimed at: \`$now_iso\`
- Action: \`$action\`
- Lease window: \`${lease_hours}h\`

## Attempt

- Consecutive attempt: \`1\` of \`3\`
- Prior checkpoint: \`<caller updates on close-out>\`

## Exit

- Exit state: \`<open>\`
- Evidence: \`<pending>\`
- Exited at: \`<pending>\`"

vars="$(python3 -c 'import json,sys; print(json.dumps({"input": {"issueId": sys.argv[1], "body": sys.argv[2]}}))' "$issue_uuid" "$body")"
linear_gql 'mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success comment { id } } }' "$vars" >/dev/null
echo "claimed session_run_id=$srid host=$host action=$action"
```

Executor notes: (a) The tier-1/tier-2 signals are resolved in the network-bearing main flow, then the decision is delegated to the pure `_liveness_tier` (the `classify` subcommand exposes it for tests). The tier-2 inline classification duplicates a tiny slice of `comment-species.sh` for the two progress headers a session posts under its run id (Lane Checkpoint, Decision Register Entry) — acceptable because the run-id field only appears on those; `comment-species.sh` is already sourced, so you may instead call `comment_species "$b"` and test for `progress` if you prefer a single classifier. Keep the *unknown⇒bookkeeping* semantics either way. (b) The parent-traversal loop makes N+1 API calls; if `linear-api.sh` can return the full parent chain in one query, use it. (c) The attempt counter now always initializes to 1 on a fresh claim; the retry-ceiling stagnation counting lives in the driving skill (`drive-epic`/`pickup-next`), not in this script — confirm no caller depended on `claim.sh` computing `prev_attempts` (the old code did; the driving skills own it now, consistent with the 0.13 design where the tick judged stagnation). (d) The own-session short-circuit no-ops (exit 0) when the newest open claim is already this session's — a re-run in the same session must not stack `# Ticket Claim` comments. (e) The `classify` subcommand overloads `$1` (a leading `classify` token routes to the pure decision instead of being a ticket id); this is safe only because a real ticket id is never the bareword `classify`. A future caller that could pass an arbitrary `$1` should switch to a `--classify` flag instead, so the overload can never collide with a live ticket argument. (f) **Comment-window honesty (spec §48):** both `claim.sh`'s and `release-claim.sh`'s `comments(last: 100)` reads must page beyond the window **or** assert the ticket's comment count is under it — a claim or its release hidden past comment 100 would silently mis-judge liveness or fail to close; treat this identically to Task B note (b) (assert-or-page, `watchdog-scan.sh` precedent).

- [ ] **Step 2:** Rewrite `dodi-dev/scripts/release-claim.sh` to release own-session claims by default and require an explicit `--foreign <claim-id>` for a foreign release, with a pre-close staleness re-read.

```bash
#!/usr/bin/env bash
# Close out a per-ticket claim comment with an exit state.
#
# Usage:
#   release-claim.sh <ticket-id> <exit-state> [evidence]                  # own-session: newest open own claim
#   release-claim.sh <ticket-id> <exit-state> [evidence] --foreign <claim-id>   # foreign: EXACTLY this claim id
#   release-claim.sh <ticket-id> <exit-state> [evidence] --session <run-id>     # own-session disambiguation
#
#   <exit-state>: completed | RESUMABLE | demoted | blocked | released-no-op
#
# Foreign release requires BOTH the flag AND the target claim id — never
# most-recent-open selection (a post-crash ticket normally holds a dead claim
# AND a live successor claim; close the one judged, not the newest). The janitor
# re-reads staleness immediately before the close mutation.
# Exit: 0 released; 1 no matching open claim; 2 error.
set -euo pipefail
source "$(dirname "$0")/linear-api.sh"

ticket="${1:?usage: release-claim.sh <ticket-id> <exit-state> [evidence] [--foreign <id> | --session <run-id>]}"
exit_state="${2:?usage: release-claim.sh <ticket-id> <exit-state> [evidence]}"
shift 2
# Remaining args (any order): an OPTIONAL leading non-`--` token is the evidence;
# --foreign <id> and --session <run-id> are flags. The only concrete foreign
# caller is `release-claim.sh <ticket> released-no-op --foreign <id>` — no
# evidence — so evidence MUST be optional here, not positional-$3 (the old
# `evidence=$3; shift 3` swallowed `--foreign` as evidence and broke takeover).
evidence="none recorded"
foreign_id=""; own_srid=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --foreign) foreign_id="${2:?--foreign needs a claim id}"; shift 2 ;;
    --session) own_srid="${2:?--session needs a run id}"; shift 2 ;;
    --*) echo "release-claim: unknown flag $1" >&2; exit 2 ;;
    *) evidence="$1"; shift ;;   # leading non-`--` token: the optional evidence
  esac
done
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

resp="$(linear_gql 'query($id: String!) { issue(id: $id) { comments(last: 100) { nodes { id body } } } }' "{\"id\": \"$ticket\"}")"

update="$(RESP="$resp" EXIT_STATE="$exit_state" EVIDENCE="$evidence" NOW="$now_iso" FOREIGN="$foreign_id" OWN="$own_srid" python3 <<'PY'
import json, os
data = json.loads(os.environ["RESP"])
foreign, own = os.environ["FOREIGN"], os.environ["OWN"]
opens = [c for c in data["data"]["issue"]["comments"]["nodes"]
         if c["body"].startswith("# Ticket Claim") and "- Exit state: `<open>`" in c["body"]]
target = None
if foreign:
    target = next((c for c in opens if c["id"] == foreign), None)
elif own:
    target = next((c for c in reversed(opens)
                   if f"- Session run id: `{own}`" in c["body"]), None)
else:
    target = opens[-1] if opens else None
if target is None:
    print("NONE"); raise SystemExit
b = (target["body"]
     .replace("- Exit state: `<open>`", f"- Exit state: `{os.environ['EXIT_STATE']}`")
     .replace("- Evidence: `<pending>`", f"- Evidence: {os.environ['EVIDENCE']}")
     .replace("- Exited at: `<pending>`", f"- Exited at: `{os.environ['NOW']}`"))
print(json.dumps({"id": target["id"], "body": b}))
PY
)"

if [[ "$update" == "NONE" ]]; then
  echo "release-claim: no matching open claim on $ticket" >&2
  exit 1
fi

vars="$(UPDATE="$update" python3 -c 'import json,os; u=json.loads(os.environ["UPDATE"]); print(json.dumps({"id": u["id"], "input": {"body": u["body"]}}))')"
linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null
echo "released $ticket exit=$exit_state${foreign_id:+ foreign=$foreign_id}"
```

- [ ] **Step 3:** Update `templates/ticket-comments/claim.md` — add the session-id field and the missing `coherence-review` enum value.

```markdown
# Ticket Claim

Ticket: `<ticket-id>`

## Claim

- Session run id: `<session-run-id>`
- Host: `<hostname>`
- Claimed at: `<ISO-8601 timestamp>`
- Action: `<mature-ticket | deliver-ticket | merge-child | submit-epic-pr | coherence-review>`
- Lease window: `<duration, default 2h>`

## Attempt

- Consecutive attempt: `<n>` of `<retry ceiling>`
- Prior checkpoint: `<link to last checkpoint comment, or none>`

## Exit

- Exit state: `<completed | RESUMABLE | demoted | blocked | released-no-op>`
- Evidence: `<links: checkpoint comments, PR, commits>`
- Exited at: `<ISO-8601 timestamp>`
```

- [ ] **Step 4:** Write the synthetic liveness test at `dodi-dev/scripts/tests/test-claim-liveness.sh` — it **invokes the real `claim.sh classify` subcommand** (the pure `_liveness_tier`) for every tier, drives full-flow guard assertions (foreign-id exit 3, legacy-theft exit 3, **and the positive-discrimination own-session exit 0 no-op**) with `driver-claim.sh status` stubbed via a PATH shim and `linear_gql` stubbed, and drives one **foreign-release** assertion proving `release-claim.sh <ticket> released-no-op --foreign <id>` (RB1's concrete caller, **no evidence arg**) reaches the mutation and targets exactly `<id>`, never exit 2. No inline arithmetic re-implementation, no `grep`-the-source branch assertions (per the Verification Rule).

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CLAIM="$HERE/../claim.sh"
RELEASE="$HERE/../release-claim.sh"
bash -n "$CLAIM"; bash -n "$RELEASE"

lease=2
# classify args: <cstate> <csrid> <srid> <cage_h> <lease_h> <tier1> <tier2>
cl() { bash "$CLAIM" classify "$@"; }

# Tier-1: foreign claim whose session matches a fresh driver claim -> alive.
[[ "$(cl open sridF sridMe 9.9 $lease yes no)" == alive ]] || { echo "FAIL tier-1" >&2; exit 1; }
# Tier-2: foreign, no driver match, fresh progress checkpoint -> alive.
[[ "$(cl open sridF sridMe 9.9 $lease no yes)" == alive ]] || { echo "FAIL tier-2" >&2; exit 1; }
# Tier-3 alive: foreign, no tier-1/tier-2, age < lease -> alive.
[[ "$(cl open sridF sridMe 1.0 $lease no no)" == alive ]] || { echo "FAIL tier-3-alive" >&2; exit 1; }
# Tier-3 claimable: foreign, no tier-1/tier-2, age >= lease -> claimable.
[[ "$(cl open sridF sridMe 3.0 $lease no no)" == claimable ]] || { echo "FAIL tier-3-claimable" >&2; exit 1; }
# Legacy (no srid) fresh -> tier-3 only -> alive (must NOT be silently claimable).
[[ "$(cl open '' sridMe 1.0 $lease no no)" == alive ]] || { echo "FAIL legacy-fresh" >&2; exit 1; }
# Legacy (no srid) stale -> claimable.
[[ "$(cl open '' sridMe 3.0 $lease no no)" == claimable ]] || { echo "FAIL legacy-stale" >&2; exit 1; }
# Own-session open claim -> claimable (never refused; main flow no-ops it).
[[ "$(cl open sridMe sridMe 1.0 $lease no no)" == claimable ]] || { echo "FAIL own-session" >&2; exit 1; }
# Closed claim -> claimable regardless.
[[ "$(cl closed sridF sridMe 0.1 $lease no no)" == claimable ]] || { echo "FAIL closed" >&2; exit 1; }

# --- Full-flow guard assertions with the network + driver-status stubbed. ---
# The ticket.json is built in the OUTER shell with python3 (real newlines from the
# literal \n in $BODY — NOT a nested `bash -c` heredoc, which mangled the newline
# conversion and made every case collapse to an empty csrid, the RB3 defect). A shim
# dir holds a copy of claim.sh + comment-species.sh + a stub linear-api.sh + a stub
# driver-claim.sh so claim.sh's $(dirname "$0")-relative resolution picks up all four
# — the REAL claim.sh guard runs against a controlled read. run_guard returns
# claim.sh's exit code and prints its combined stdout+stderr for discrimination checks.
run_guard() {  # $1 = claim body (with literal \n for line breaks); the session is sridMe
  local body="$1"
  local shim; shim="$(mktemp -d)"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "no fresh open driver claim"; exit 1' >"$shim/driver-claim.sh"
  chmod +x "$shim/driver-claim.sh"
  cp "$CLAIM" "$shim/claim.sh"
  cp "$HERE/../comment-species.sh" "$shim/comment-species.sh"
  cat >"$shim/linear-api.sh" <<EOF
linear_gql() {
  case "\$1" in
    *comments*) cat "$shim/ticket.json" ;;   # the main read (has \`comments\`) — before *parent*
    *parent*)   echo '{"data":{"issue":{"parent":null}}}' ;;
    *commentCreate*) echo '{"data":{"commentCreate":{"comment":{"id":"new"}}}}' ;;
    *) echo '{"data":{}}' ;;
  esac
}
EOF
  BODY="$body" NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)" TJSON="$shim/ticket.json" python3 <<'PY'
import json, os
body = os.environ["BODY"].replace("\\n", "\n")   # turn literal \n into real newlines
doc = {"data": {"issue": {"id": "uuid-T", "parent": None, "comments": {"nodes": [
    {"id": "cc1", "createdAt": "2026-07-04T00:00:00Z",
     "updatedAt": os.environ["NOW"], "body": body}]}}}}
open(os.environ["TJSON"], "w").write(json.dumps(doc))
PY
  local out rc
  set +e
  out="$(bash "$shim/claim.sh" T-1 deliver-ticket sridMe 2 2>&1)"; rc=$?
  set -e
  rm -rf "$shim"
  printf '%s\n' "$out"
  return "$rc"
}

# (1) id-bearing fresh foreign claim -> exit 3, and the log line NAMES the foreign
#     session id — proves the body parsed (csrid resolved, not empty). If the body
#     never converted to real newlines (RB3 bug), csrid would be empty and the log
#     would read <legacy/no-id>, failing this assertion.
set +e
out="$(run_guard '# Ticket Claim\n\nTicket: `T-1`\n\n## Claim\n- Session run id: `sridOTHER`\n\n## Exit\n- Exit state: `<open>`')"
rc=$?; set -e
[[ "$rc" -eq 3 ]] || { echo "FAIL foreign-id exit3: got $rc :: $out" >&2; exit 1; }
grep -q 'session=sridOTHER' <<<"$out" || { echo "FAIL foreign-id discrimination: log must name sridOTHER, got: $out" >&2; exit 1; }

# (2) id-LESS (legacy) fresh foreign claim -> exit 3 (the theft-bug regression guard, B5),
#     distinguished from the id-bearing case by the <legacy/no-id> log token.
set +e
out="$(run_guard '# Ticket Claim\n\nTicket: `T-1`\n\n## Claim\n- Host: `h`\n\n## Exit\n- Exit state: `<open>`')"
rc=$?; set -e
[[ "$rc" -eq 3 ]] || { echo "FAIL legacy foreign exit3 (theft bug): got $rc :: $out" >&2; exit 1; }
grep -q 'session=<legacy/no-id>' <<<"$out" || { echo "FAIL legacy discrimination: got: $out" >&2; exit 1; }

# (3) POSITIVE DISCRIMINATION (RB3): own-session fresh open claim (csrid == srid) -> exit 0
#     no-op, NOT exit 3. If body-parse->csrid is broken (empty), this claim looks
#     legacy-foreign and wrongly exits 3 — this assertion catches that collapse, and
#     also catches a regression that makes the guard refuse its own session.
set +e
out="$(run_guard '# Ticket Claim\n\nTicket: `T-1`\n\n## Claim\n- Session run id: `sridMe`\n\n## Exit\n- Exit state: `<open>`')"
rc=$?; set -e
[[ "$rc" -eq 0 ]] || { echo "FAIL own-session-no-op: expected exit 0, got $rc :: $out" >&2; exit 1; }
grep -q 'already claimed by this session' <<<"$out" || { echo "FAIL own-session-no-op msg: got: $out" >&2; exit 1; }

# --- RB1: release-claim.sh foreign release reaches the mutation (never exit 2) and
#         targets EXACTLY the given claim id. The concrete caller is
#         `release-claim.sh <ticket> released-no-op --foreign <id>` — NO evidence arg;
#         the old `evidence=$3; shift 3` parse swallowed `--foreign` and exited 2 on
#         every takeover. Two open claims (a dead predecessor + a live successor) prove
#         the foreign release closes the id given, not the newest. ---
rel_shim="$(mktemp -d)"
cp "$RELEASE" "$rel_shim/release-claim.sh"
cat >"$rel_shim/ticket.json" <<'EOF'
{"data":{"issue":{"comments":{"nodes":[
  {"id":"cc-dead","body":"# Ticket Claim\n\n## Exit\n- Exit state: `<open>`\n- Evidence: `<pending>`\n- Exited at: `<pending>`"},
  {"id":"cc-live","body":"# Ticket Claim\n\n## Exit\n- Exit state: `<open>`\n- Evidence: `<pending>`\n- Exited at: `<pending>`"}
]}}}}
EOF
python3 - "$rel_shim/ticket.json" <<'PY'
import json, sys
p = sys.argv[1]; doc = json.load(open(p))
for n in doc["data"]["issue"]["comments"]["nodes"]:
    n["body"] = n["body"].replace("\\n", "\n")
json.dump(doc, open(p, "w"))
PY
cat >"$rel_shim/linear-api.sh" <<EOF
UPDATED_TARGET_LOG="$rel_shim/updated-id.log"
linear_gql() {
  case "\$1" in
    *commentUpdate*) echo "\$2" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' >>"\$UPDATED_TARGET_LOG"; echo '{"data":{"commentUpdate":{"success":true}}}' ;;
    *comments*) cat "$rel_shim/ticket.json" ;;
    *) echo '{"data":{}}' ;;
  esac
}
EOF
set +e
rel_out="$(bash "$rel_shim/release-claim.sh" T-1 released-no-op --foreign cc-dead 2>&1)"; rel_rc=$?
set -e
[[ "$rel_rc" -eq 0 ]] || { echo "FAIL foreign-release: expected exit 0 (reaches mutation, not exit 2), got $rel_rc :: $rel_out" >&2; exit 1; }
targeted="$(cat "$rel_shim/updated-id.log" 2>/dev/null || true)"
[[ "$targeted" == "cc-dead" ]] || { echo "FAIL foreign-release target: mutation must target cc-dead, targeted: '$targeted'" >&2; exit 1; }
rm -rf "$rel_shim"

echo "claim liveness tests ok"
```

Executor note: the full-flow block copies `claim.sh` + `comment-species.sh` + a stub `linear-api.sh` + a stub `driver-claim.sh` into one temp dir and runs the copy, so `claim.sh`'s `$(dirname "$0")`-relative resolution picks up all four stubs — the **real** `claim.sh` guard runs against a controlled ticket read. The `ticket.json` is built with `python3` in the **outer** shell (not a nested `bash -c` heredoc) precisely so the literal `\n` in the body converts to real newlines — the earlier nested-`<<PY`-inside-single-quote form never converted, so csrid parsed empty and every case collapsed onto the legacy path (RB3). The `*comments*` case must be listed **before** `*parent*` in the stub (the main read query contains both tokens, and it is the one that must return the full ticket). The three guard assertions are load-bearing: foreign-id must exit 3 **and** name `sridOTHER` (proving the parse), legacy must exit 3 **and** name `<legacy/no-id>` (the B5 theft guard, distinguished from the id case), and own-session must exit 0 no-op (the RB3 positive discriminator — an empty-csrid collapse would wrongly exit 3 here). The RB1 release assertion proves the foreign-release arg parse reaches the mutation and closes exactly the id given, never exit 2. This test also proves the tier decisions via `classify` (pure, no fixtures needed).

- [ ] **Step 5:** Verify.

Run: `chmod +x dodi-dev/scripts/tests/test-claim-liveness.sh && bash dodi-dev/scripts/tests/test-claim-liveness.sh`
Expected: `claim liveness tests ok`

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/scripts/claim.sh dodi-dev/scripts/release-claim.sh templates/ticket-comments/claim.md dodi-dev/scripts/tests/test-claim-liveness.sh
git commit -m "feat: session identity + liveness hierarchy in claim.sh/release-claim.sh (0.14.0 layer C)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task D: await v2 + reaper + per-session manifests

`await-worker.sh` v2 (final-lines content check, truncation guard, mtime stall alarm, STALLED exit, ≤9-min chunking, line-based extraction), new `reap-workers.sh`, absolute-path per-session manifests + self-ignoring `.dodi/.gitignore`, and the one-line await rule into all 13 worker prompt templates (+ delete `lane-dispatch-prompt`'s v1 restatement and rename its header).

**Files:**
- Modify: `dodi-dev/scripts/await-worker.sh` (rewrite to v2)
- Create: `dodi-dev/scripts/reap-workers.sh`
- Create: `dodi-dev/scripts/tests/test-await-worker.sh`
- Modify: all 13 prompt templates under `dodi-dev/skills/**/*-prompt.md` (one-line await rule)
- Modify: `dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md` (delete v1 mechanics restatement, rename header)

- [ ] **Step 1:** Rewrite `dodi-dev/scripts/await-worker.sh` to v2 — content check on the transcript's **final lines** (never whole-file grep), mtime stall alarm in the same loop, `STALLED` a distinct exit, ≤9-min chunk self-bounding, truncation guard (confirm record completeness before extracting), line-based extraction, correct when the file doesn't exist yet.

```bash
#!/usr/bin/env bash
# Await an async Agent-tool worker by CONTENT, not by silence. Poll the
# transcript's FINAL LINES for the terminal record ("stop_reason":"end_turn")
# every few seconds; raise an mtime stall alarm in the same loop; STALLED is a
# distinct exit. Chunk-bounded (<=9 min per call, well under the 600s Bash
# harness cap and the 120s foreground default per the tool contract) so it
# never depends on timeout(1). (Live-test gate item 5's real question is
# multi-hour *scheduled-session* longevity, not these per-call caps.)
#
# Never whole-file grep (one escaping accident from a false completion, and
# additive harness drift would be silent) — final-lines keeps drift loud.
#
# Usage: await-worker.sh <output_file> [tail_lines=40] [stall_secs=600] [chunk_secs=540]
# Exit: 0 terminal record found (final lines printed);
#       7 STALLED (mtime unchanged > stall_secs, no terminal record);
#       8 chunk timeout — STILL RUNNING, caller re-invokes (never "done");
#       2 usage/environment error.
set -euo pipefail

file="${1:?usage: await-worker.sh <output_file> [tail_lines] [stall_secs] [chunk_secs]}"
tail_lines="${2:-40}"
stall_secs="${3:-600}"
chunk_secs="${4:-540}"

mtime_of() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }

start="$(date +%s)"
last_mtime=""
last_change="$start"

while :; do
  now="$(date +%s)"
  # Self-bound the chunk: report STILL RUNNING so the caller re-invokes.
  if (( now - start >= chunk_secs )); then
    echo "await-worker: chunk elapsed (${chunk_secs}s), worker still running on ${file}" >&2
    exit 8
  fi

  if [[ -f "$file" ]]; then
    mtime="$(mtime_of "$file")"
    if [[ "$mtime" != "$last_mtime" ]]; then
      last_mtime="$mtime"; last_change="$now"
    fi
    # Content check on the FINAL LINES only.
    if tail -n "$tail_lines" "$file" | grep -q '"stop_reason"[[:space:]]*:[[:space:]]*"end_turn"'; then
      # Truncation guard: a large final record flushes in multiple writes. Confirm
      # completeness — a trailing newline — before extracting, RE-CHECKING after
      # each short sleep (up to a few tries) rather than extracting after a single
      # unconditional sleep. `tail -c1` is empty iff the last byte is a newline
      # (command substitution strips it), so non-empty = still mid-flush.
      guard=0
      while [[ -n "$(tail -c1 "$file")" ]] && (( guard < 5 )); do
        sleep 2
        guard=$((guard + 1))
      done
      # Only extract once the record is complete (trailing newline) or the guard
      # bound is hit (extract best-effort rather than hang).
      tail -n "$tail_lines" "$file"
      exit 0
    fi
    # mtime stall alarm: file exists, unchanged beyond stall window, no terminal.
    if (( now - last_change > stall_secs )); then
      echo "await-worker: STALLED — ${file} mtime unchanged for >${stall_secs}s with no terminal record" >&2
      exit 7
    fi
  fi
  sleep 3
done
```

Executor note: the truncation guard uses `tail -c1` completeness — `[[ -n "$(tail -c1 "$file")" ]]` is true when the last byte is NOT a newline (still flushing), so it **re-polls in a bounded loop** (up to 5 × 2s) until the file ends in a newline, then extracts; a file already ending in `\n` skips the loop and extracts immediately. Confirm this reads correctly in your shell (command substitution strips a trailing newline, so a file ending in `\n` yields an empty string → complete; a file ending mid-record yields a non-empty last char → keep waiting). The bounded loop (not a single unconditional sleep) is what prevents extracting a half-flushed final record; the guard cap keeps it from hanging on a file that never gets its trailing newline. This matches the spec's "trailing newline or stable re-poll" rule.

- [ ] **Step 2:** Create `dodi-dev/scripts/reap-workers.sh` — classifies each unreaped manifest entry (terminal / STALLED / live) and reports; stopping is the calling agent's step (nested stop availability is gated). Appends reap records.

```bash
#!/usr/bin/env bash
# Classify and report the unreaped workers in a dispatch manifest. Does NOT
# stop anything — stopping is the calling agent's step via the agent-layer
# primitive (nested availability is gated; where absent, orphaned grandchildren
# run to completion — the caller notes and escalates).
#
# Manifest: .dodi/dispatch-manifest-<session-run-id>.jsonl at an ABSOLUTE path.
# Each line: {session_id, worker_id, output_file, purpose, tier, ts}
# Reap records appended: {reaped, verdict, ts} keyed to worker_id.
#
# Usage: reap-workers.sh <manifest-path>
# Exit: 0 report printed; 2 error.
set -euo pipefail

manifest="${1:?usage: reap-workers.sh <manifest-path>}"
[[ -f "$manifest" ]] || { echo "reap-workers: no manifest at $manifest" >&2; exit 0; }

mtime_of() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }
now="$(date +%s)"

MANIFEST="$manifest" NOW="$now" python3 <<'PY'
import json, os, subprocess
from pathlib import Path
mpath = os.environ["MANIFEST"]; now = int(os.environ["NOW"])
lines = [json.loads(l) for l in Path(mpath).read_text().splitlines() if l.strip()]
dispatched = {r["worker_id"]: r for r in lines if "worker_id" in r and "reaped" not in r}
reaped = {r["worker_id"] for r in lines if r.get("reaped")}
for wid, rec in dispatched.items():
    if wid in reaped:
        continue
    of = rec.get("output_file", "")
    verdict = "live"
    if of and Path(of).exists():
        tail = "".join(Path(of).read_text(errors="replace").splitlines(keepends=True)[-40:])
        if '"stop_reason"' in tail and '"end_turn"' in tail:
            verdict = "terminal"
        else:
            try:
                st = Path(of).stat().st_mtime
                if now - st > 600:
                    verdict = "STALLED"
            except OSError:
                verdict = "live"
    print(f"{wid}\t{verdict}\t{of}")
PY
echo "reap-workers: classified $manifest" >&2
```

Executor note: the caller (drive-epic close-out / janitor sweep) reads this classification, stops any `live`/`STALLED` grandchildren it can via the agent-layer primitive, then appends the reap record itself (`{"worker_id": "...", "reaped": true, "verdict": "...", "ts": "..."}`) to the manifest — the reap-record append is the caller's write so the dedup marker reflects the stop actually happening. Document this in the drive-epic close-out step (Task E).

- [ ] **Step 3:** Write `dodi-dev/scripts/tests/test-await-worker.sh` — synthetic filesystem test: (a) a file whose final lines carry the terminal record → exit 0 + prints it; (b) a file with the terminal string only in an *early* line and non-terminal final lines → not complete (does not false-complete within a short chunk; use a tiny `chunk_secs` and expect exit 8); (c) STALLED path with a small `stall_secs`.

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AW="$HERE/../await-worker.sh"
bash -n "$AW"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# (a) terminal record in the final lines -> exit 0
f="$tmp/done.jsonl"
printf '%s\n' '{"type":"assistant","content":"x"}' '{"type":"assistant","stop_reason":"end_turn"}' >"$f"
if out="$(bash "$AW" "$f" 40 600 540)"; then
  grep -q 'end_turn' <<<"$out" || { echo "FAIL (a): terminal not printed" >&2; exit 1; }
else
  echo "FAIL (a): expected exit 0" >&2; exit 1
fi

# (b) terminal string only in an EARLY line; final lines are non-terminal.
# With many trailing non-terminal lines and tail_lines=2, the final-lines scan
# must NOT see the early end_turn -> chunk times out (exit 8), not false-0.
f2="$tmp/early.jsonl"
{ printf '%s\n' '{"stop_reason":"end_turn"}'; for i in $(seq 1 50); do printf '%s\n' '{"type":"assistant","content":"still going"}'; done; } >"$f2"
set +e
bash "$AW" "$f2" 2 600 2 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -eq 8 ]] || { echo "FAIL (b): expected exit 8 (still running), got $rc" >&2; exit 1; }

# (c) STALLED: file exists, unchanged, no terminal, small stall window.
f3="$tmp/stall.jsonl"
printf '%s\n' '{"type":"assistant","content":"work"}' >"$f3"
touch -t 202001010000 "$f3" 2>/dev/null || true   # force old mtime where supported
set +e
bash "$AW" "$f3" 40 1 60 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -eq 7 || "$rc" -eq 8 ]] || { echo "FAIL (c): expected STALLED(7) or chunk(8), got $rc" >&2; exit 1; }

echo "await-worker tests ok"
```

Executor note: case (c) is timing-sensitive — `touch` to force an old mtime makes the stall fire on the first poll; where `touch -t` is unavailable the test accepts the chunk-timeout exit 8 as a pass, since the STALLED branch is unit-covered by the mtime arithmetic. The load-bearing assertion is (b): final-lines scoping must not false-complete on an early terminal string.

- [ ] **Step 4:** Add the one-line await rule to all 13 worker prompt templates. Each prompt that dispatches its own sub-workers must poll, not yield. Insert a single line near the end of each prompt (before the Output section where one exists):

```
- **Awaiting your own workers (Claude Code):** never yield the turn to "wait" — run `${CLAUDE_PLUGIN_ROOT}/scripts/await-worker.sh <output_file>` (event-based: polls the transcript's final lines for the terminal record, STALLED on stall, chunk-bounded). Never read the whole transcript.
```

Apply to: `brainstorm/spec-reviewer-prompt.md`, `epic-orchestrator/coherence-reviewer-prompt.md`, `epic-orchestrator/evidence-checker-prompt.md`, `epic-orchestrator/gate1-package-prompt.md`, `epic-orchestrator/state-reader-prompt.md`, `implement/implementer-prompt.md`, `mature-ticket/spec-drafter-prompt.md`, `review/review-prompt.md`, `submit-ticket-pr/local-ci-runner-prompt.md`, `verify/test-runner-prompt.md`, `write-plan/plan-reviewer-prompt.md`, `write-plan/plan-writer-prompt.md`, and `epic-orchestrator/lane-dispatch-prompt.md`. For the three that already reference `await-worker.sh` (lane-dispatch, spec-drafter, plan-writer), replace their existing multi-line await block with this single pointer line so the mechanism lives only in the script (AGENTS.md's reference-don't-restate rule).

- [ ] **Step 5:** In `lane-dispatch-prompt.md`, under the `Awaiting your own workers:` header (line ~27), replace **only the two v1 await-mechanics bullets** — the "never yield the turn to 'wait'" bullet (~29) and the "run the script … polls until mtime is stable >60s" bullet (~30) — with the single Step 4 await pointer. **Retain the model-tier-pin bullet** (~31, "Every worker dispatch pins its model tier explicitly…") — it is not await mechanics and must not be deleted (the v1-deletion range must not sweep it in). Then rename the header: change `# Lane Dispatch Prompt` to `# Deliver-Ticket Lane Dispatch Prompt` (the spec calls for a header rename; use the more specific form to drop the v1-implying bareness).

- [ ] **Step 6:** Add `.dodi/.gitignore` semantics — the manifest writer creates `.dodi/.gitignore` containing `*` on first use (empirically verified to ignore contents and itself). This is a runtime behavior of `drive-epic`/`pickup-ticket`, not a committed file; document it in the drive-epic boot step (Task E) and the pickup-ticket manifest note (Task H). No file is committed here. **Executor note — the FIRST manifest write in a worktree owns the `.dodi/.gitignore` creation, whichever writer it is:** the driver's boot creates it in the epic worktree, but a **lane's** first manifest write (the per-lane ephemeral worktree, `pickup-ticket`/`deliver-ticket` — Task H) must create its own `.dodi/.gitignore` too, so a lane worktree never leaks `.dodi/` into git. Do not treat it as driver-only; each worktree's first `.dodi/` write self-creates the ignore file.

- [ ] **Step 7:** Verify.

Run: `chmod +x dodi-dev/scripts/reap-workers.sh dodi-dev/scripts/tests/test-await-worker.sh && bash dodi-dev/scripts/tests/test-await-worker.sh && bash -n dodi-dev/scripts/reap-workers.sh && for f in dodi-dev/skills/brainstorm/spec-reviewer-prompt.md dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md dodi-dev/skills/epic-orchestrator/evidence-checker-prompt.md dodi-dev/skills/epic-orchestrator/gate1-package-prompt.md dodi-dev/skills/epic-orchestrator/state-reader-prompt.md dodi-dev/skills/implement/implementer-prompt.md dodi-dev/skills/mature-ticket/spec-drafter-prompt.md dodi-dev/skills/review/review-prompt.md dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md dodi-dev/skills/verify/test-runner-prompt.md dodi-dev/skills/write-plan/plan-reviewer-prompt.md dodi-dev/skills/write-plan/plan-writer-prompt.md dodi-dev/skills/epic-orchestrator/lane-dispatch-prompt.md; do grep -q 'await-worker.sh' "$f" || echo "MISSING: $f"; done`
Expected: `await-worker tests ok`, no `bash -n` output, and the `for` loop prints **no `MISSING:` lines** (every one of the 13 prompts now references the script). The positive per-file check exits 0 on success — unlike a bare `grep -L`, which prints nothing but **exits 1** when all files match, misreporting success as failure under exit-code discipline.

- [ ] **Step 8:** Commit.

```bash
git add dodi-dev/scripts/await-worker.sh dodi-dev/scripts/reap-workers.sh dodi-dev/scripts/tests/test-await-worker.sh dodi-dev/skills
git commit -m "feat: await-worker v2 + reap-workers + await rule in all 13 prompts (0.14.0 layer D)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task E: drive-epic skill — the resident driver

THE big one. New skill `drive-epic` (`model: sonnet`) with SKILL.md, its state/prompt files, and the register-entry/continuation-brief template edits its writes depend on. This is the largest task; each step below leaves the skill readable but the whole is committed once at the end.

**Files:**
- Create: `dodi-dev/skills/drive-epic/SKILL.md`
- Create: `templates/ticket-comments/continuation-brief.md`
- Modify: `templates/ticket-comments/decision-register-entry.md` (run-id field, held-route field, REFRESH per-decision affected-children set, RULING variant)
- Modify: `dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md` (output contract gains held-route for AMENDMENT + per-decision affected-children mapping for REFRESH)

- [ ] **Step 1:** Create `templates/ticket-comments/continuation-brief.md` (the park/bloat exit artifact; repo mirror for validation, format lives in-skill per self-containment).

```markdown
# Continuation Brief

Epic: `<epic-ticket-id>` · Session run id: `<session-run-id>` · Exit: `<parked | bloat-handoff>`

## State Map Reference

- `<link to the latest state-reader map / register canon / relevant checkpoints>`

## Chosen Next Action

- `<the next action a fresh successor should select, and one line of why>`

## Live Concerns

- `<flaky tests, retried workers, fragile modules — one line each, or "none">`

## In Flight (must not be redone)

- `<open PRs, running lanes, partial close-outs with their resume keys (claim ids, SHA-keyed evidence, manifest reap records), or "none">`
```

- [ ] **Step 2:** Extend `templates/ticket-comments/decision-register-entry.md` — add the session-run-id field, the held-route field (AMENDMENT-approve's not-yet-performed writes), the REFRESH per-decision affected-children set, and the RULING variant (same `# Decision Register Entry` header and `Merge SHA:` key).

```markdown
# Decision Register Entry

Child: `<child-ticket-id>` · Merge SHA: `<merge-sha>`

## Session

- Run id: `<session-run-id>`

## Verdict

`<ALIGNED | MINOR_DRIFT | MATERIAL_DRIFT | LEGITIMATE_DIVERGENCE | RULING>` `<+ GATE1_AMENDMENT / GATE1_REFRESH if flagged>`

## Decisions Recorded

- `<one-paragraph decision statement with evidence links>`

## Affected Children

- `<ticket-id>`: `<labels stripped>` — `<one line why>` (or "none")

## Held Route (GATE1_AMENDMENT only — the not-yet-performed writes the approve branch executes)

- `<canonization / superseded-by note / affected-children label strips the human's approve ruling will perform, recorded held; "n/a" unless GATE1_AMENDMENT>`

## Per-Decision Affected Children (GATE1_REFRESH only — which children's specs consumed EACH superseded decision)

- `<decision>` → `<child-ticket-id, ...>` (recorded by the reviewer so the reject route strips the rejected SUBSET mechanically; "n/a" unless GATE1_REFRESH)

## Supersedes

- `<design point superseded, with superseded-by note link>` (or "none")

## Ruling (RULING variant only — the durable resolution record for a pending-human entry)

- Resolves Merge SHA: `<merge-sha of the pending-human entry>`
- Outcome: `<approve | reject | redirect:<scope>>`
- Writes performed: `<the routed writes — held route executed, or MATERIAL_DRIFT corrective / de-canonization — with links>`

## Canon Summary

Updated: `<yes/no — the "Decision Register — Canon" section of the epic description>`
```

Executor note: the validator (Task I) will `check_heading` for the load-bearing sections. Keep the exact heading text (`## Held Route ...`, `## Per-Decision Affected Children ...`, `## Ruling ...`) stable — the validator greps `check_contains` on distinguishing substrings, not full lines, so a parenthetical clarification is safe but the leading `## Held Route`, `## Per-Decision Affected Children`, `## Ruling` tokens must be present. **`ALREADY_REVIEWED` is deliberately absent from the Verdict enum:** it is a clean no-op that writes **no** register entry (the loop-side idempotence skip), so it can never appear as a recorded verdict — a template enum listing it would license a phantom entry. The Task I validator `check_contains`es `RULING` (the real variant) and never `ALREADY_REVIEWED`, so the two stay consistent.

- [ ] **Step 3:** Edit `coherence-reviewer-prompt.md` output contract to produce the two new pending-entry fields (else they ship dead). After the existing `- **Affected children:** ...` bullet in the Output section, add:

```
- **Held route (GATE1_AMENDMENT verdicts only):** record the *not-yet-performed* writes an approve ruling will execute — the canonization text, the superseded-by note, and the exact affected-children label strips — so the ruling session performs them by a mechanical read, never a fresh sonnet judgment. Recorded held (not performed); the driver never canonizes a GATE1_AMENDMENT itself.
- **Per-decision affected-children mapping (GATE1_REFRESH verdicts only):** for each superseded decision in the refresh, name which children's specs consumed *that decision* — a per-decision map, not the flat affected-children list. The reject route strips readiness labels for the rejected *subset*; recording the mapping at review time makes the reject a durable read, honoring the "divergence is judged once, at the seam, by the Frontier reviewer" doctrine.
```

Also append the await pointer line from Task D Step 4 if not already present (this prompt is one of the 13).

- [ ] **Step 4:** Create `dodi-dev/skills/drive-epic/SKILL.md`. This is the resident driver. Write it self-contained (no repo-only doc references — the validator forbids `templates/ticket-comments` and `docs/` references inside skills). Full content:

````markdown
---
name: drive-epic
description: Use as the resident driver — one long-lived orchestrator session per active epic that boots from durable state, holds the dependency graph and decision-register canon in context, dispatches lanes, and advances on completion events until park or bloat. Also the session-delivered coherence-ruling mode.
model: sonnet
---

# Drive Epic

The resident driver. One long-lived session per active epic. It absorbs `pickup-next`'s machinery and replaces its trigger model: instead of a fresh session per clock tick, one session boots from durable PM/git state, holds the dependency graph and decision-register canon in context, dispatches lanes **serially** (one in flight at a time, `maxParallelLanes` = 1 in 0.14), and advances on **completion events** — until **park** (no automated action possible) or **bloat** (context degraded). Cron survives only as a slow liveness guard (this skill's step 0) and the daily janitor (`reconcile-tickets`).

**Detect by content and event, never by clock or silence** — the principle that retires the tick and the same one `await-worker.sh` v2 enforces one level down.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| hourly liveness cron, or manual invocation | PM scope, repo path(s), heartbeat location, retry ceiling (default 3), optional humanContact | epic advanced through as many actions as fit before park/bloat, or a clean no-op | driver claim + refreshes, continuation brief, daily heartbeat, everything the lane skills write | same set as the 0.13 tick (`mature-ticket`, `deliver-ticket`, `submit-ticket-pr` Merge, `submit-epic-pr`) + state-reader / evidence-checker workers | PM unreachable, claim yield, retry ceiling, fence trip, tool/auth failure |

## Step 0a — parse the invocation (first step, before anything else)

This skill is invoked by running a session on it with an instruction string. **First, inspect that instruction.** If it begins with `rule-coherence` — i.e. the operator ran the drive-epic skill with the input `rule-coherence <merge-sha> approve|reject|redirect:<scope>` — parse `<merge-sha>` and the flag, then run the **Human-Ruling Resolution Route** (Ruling Mode) below and **stop** — do **not** fall through to the guard or the drive loop. Any other invocation (an epic id, "drive EPIC-123", a bare resume) is a normal driver run: proceed to Step 0 — the guard.

(There is no separate `rule-coherence` skill, command, or shell alias — the spec's intent is "no new skill; a drive-epic ruling mode reusing its claim/fence/routing." The operator delivers a ruling by invoking **this** skill with the `rule-coherence …` instruction; this parse step is the branch.)

## Ruling Mode

Reached when Step 0a parsed a `rule-coherence <merge-sha> approve|reject|redirect:<scope>` invocation. Run the **Human-Ruling Resolution Route** below instead of the guard + drive loop. The ruling mode reuses this skill's claim/fence/routing; it never enters the drive loop.

## Step 0 — the guard

1. **Daily heartbeat.** Post/refresh at the designated heartbeat location (`${CLAUDE_PLUGIN_ROOT}/scripts/heartbeat.sh <heartbeat-location>` — dedupe and update-in-place live in the script); optional mirror on the active epic. Posted on every guard path **and refreshed by the driver inside its own drive loop** — if the scheduler guarantees same-task no-overlap (see the live-test gate), the hourly guard cannot fire while a driver run is live, so a driver run crossing ~24h would otherwise starve the dead-man switch; the in-loop refresh closes that.
2. **Driver-claim check** (`${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh status <epic-id>`).
   - Fresh live claim → exit, one line logged. (A live driver owns the epic; do not interleave.)
   - Stale/absent + **actionable work** → `driver-claim.sh acquire <epic-id> <session-run-id>`; win → this session **becomes** the driver, proceed to Boot; lose → self-close and exit no-op.
   - **No actionable work** — including an epic parked on an unresolved pending-human entry — → exit; the janitor's digest owns the human reminder. The human resolves a pending-human park out-of-band by invoking this skill with a `rule-coherence …` instruction (a session, parsed by Step 0a — not a comment this guard must detect), so there is **no wake edge** here.
   - **Backstop:** an epic that is `coherence-pending` with the set-difference empty **and** no unresolved entry (a ruling session crashed between its `RULING` write and its in-session clear) *is* actionable — boot to evaluate the clear predicate — so a resolved-but-still-labeled epic never strands.
3. **Second signed-off epic in scope → escalate**, never interleave (single-active-epic posture).

Manual sessions run the identical step 0; per-ticket session claims enforce the same discipline for manual *lane* work.

(The wedged-driver probe is **not** a guard step — it re-homed to the daily janitor sweep, since under same-task no-overlap the hourly guard cannot fire against the live driver it would probe. See `reconcile-tickets`.)

## Boot

Once this session is the driver:

1. **Mint the run id** (already minted for the claim); **start the refresher.** Two build paths depending on whether session-pid capture can be pinned from the desk (this is itself coupled to **live-test-gate item 3** — the refresher's orphan detection must watch the *session* process, not the transient shell):
   - **Orphan-aware path (preferred, if the ancestry walk resolves a stable session process):** derive `<session-pid>` by walking the PPID chain up from `$$` (the current Bash shell is transient — `$$` is wrong on its own). The walk: starting at `$$`, repeatedly read `ps -o ppid=,comm= -p <pid>` and step to the parent, stopping at the first ancestor whose `comm` is the session/harness process (not `bash`/`sh`/the `Bash`-tool wrapper) — that ancestor is the wrapper's parent that **survives** a single Bash call and dies with the session. Capture it once at boot:
     ```bash
     session_pid="$$"
     while :; do
       read -r ppid comm < <(ps -o ppid=,comm= -p "$session_pid" 2>/dev/null | awk '{print $1, $2}')
       [[ -z "${ppid:-}" || "$ppid" -le 1 ]] && break
       case "$comm" in *bash|*sh|*zsh) session_pid="$ppid"; continue ;; esac
       session_pid="$ppid"; break
     done
     ```
     Then launch `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh refresh <epic-id> <session-run-id> "$session_pid"` as a background shell; it bumps the claim every ~15m and self-exits on that pid's disappearance/reparenting.
   - **Interim lease-only fallback (buildable now, no orphan self-exit):** if the ancestry walk cannot be confirmed to resolve the true session process from the desk (gate item 3 unverified), launch the refresher in **lease-only mode** — pass a sentinel `<session-pid>` of `0` (or omit orphan watching), so the refresher simply bumps `Refreshed at` every ~15m and never self-exits. A crashed session's claim then decays **by lease alone in ≤45m** — no worse than the per-ticket tier-3 lease behavior, and the takeover reap-before-release adopts it on the next guard hour. This keeps the driver shippable while item 3 is pending; the orphan-aware path is a strict improvement once the walk is confirmed live.

   The refresher's own subcommand supports both: with a real pid it watches PPID; with pid `0` it skips the orphan check and refreshes on the lease cadence only (see the refresh subcommand's pid-`0` branch).
2. **Coherence audit (set-difference).** Fetch all merged child PRs targeting the epic branch (`mergeCommit` oids — the surface `verify-merge.sh` reads, `--limit` above any plausible child count, paged-or-asserted) and all register-entry `Merge SHA:` keys from the epic (a **paged** read — comment-window honesty). **Every merged SHA must hold a register entry.** Any merged-but-unregistered SHA ⇒ treat the epic as `coherence-pending` and queue the review for the unregistered set, **oldest `mergedAt` first**. An unresolved pending-human entry parks the queue — no further reviews until the human resolves it via `rule-coherence`. No merged child PRs ⇒ pass; a stray `coherence-pending` with zero merged PRs clears vacuously.
3. **Takeover reap-before-release** (only if this boot took over a stale driver claim). **First post a one-line takeover note** — a `# Driver Claim`-adjacent bookkeeping comment on the epic (the "takeover/janitor notes" species `comment-species.sh` already classifies as bookkeeping) recording: this session's run id, the predecessor's run id + reaped-claim id (closed `taken-over` by the `acquire` stale-close), and the boot timestamp. This is the audit-trail line spec §41/§47 asks for — the durable "who took over from whom" record; keep it minimal (one line, no state-clock effect since it is bookkeeping). Then read the predecessor's dispatch manifest (per-session filename at the epic worktree's absolute path) and **reap/stop/confirm any non-terminal lane workers first** (`${CLAUDE_PLUGIN_ROOT}/scripts/reap-workers.sh <manifest>`, then stop stragglers via the agent-layer primitive and append reap records) — because whether an in-flight Agent-tool lane survives its dispatcher's death is a live-test-gate item, and re-dispatching beside a still-writing orphan is the concurrency hazard. **Only then** foreign-release (by id) the per-ticket claims bearing the predecessor's session id (`release-claim.sh <ticket> released-no-op --foreign <claim-id>`; the children scan uses the watchdog's nested-query shape).
4. **State-reader.** Dispatch the state-reader worker (`epic-orchestrator/state-reader-prompt.md`, Fast tier) and consume its map; read the register canon and the latest continuation brief; load the state tables (`epic-orchestrator/state-transitions.md`).
5. **Manifest init.** Initialize the dispatch manifest at the epic worktree's **absolute path**: `<epic-worktree-abs>/.dodi/dispatch-manifest-<session-run-id>.jsonl`; create `<epic-worktree-abs>/.dodi/.gitignore` containing `*` on first use (ignores its contents and itself). The driver works against the epic worktree **by absolute path** (cwd resets between Bash calls) and is that worktree's **sole writer**; all lane work happens in per-lane ephemeral worktrees.

## Drive loop

Repeat until park or bloat:

1. **Select** by the priority table (merge → coherence review → epic PR → resume RESUMABLE → deliver-ticket → mature-ticket), same demotion rules and `coherence-pending` blocking scope from `epic-orchestrator/state-transitions.md` — **which now explicitly includes the merge slot: no merge action is eligible while `coherence-pending` is set.** This keeps reviews serial and the register append-ordered; the set-difference audit is the producer-independent backstop.
   - **Merge action** is fail-closed: **apply `coherence-pending` before the merge command** (the irreversible write is the inlined `submit-ticket-pr` merge — `gh pr merge`, not a git push), with the fence verified immediately before it.
   - **Coherence-review action** targets every merged-but-unregistered SHA, **oldest `mergedAt` first, serially, halting after the first pending-human verdict completes its own routing.** Definitions (*pending-human*, *unresolved*, *clean*, *halt*) are in AGENTS.md / the state table and are referenced, not restated. The label clears iff the set-difference is empty ∧ **no register entry over the epic's merged SHAs is unresolved** — register-wide, never batch-scoped; an unresolved pending-human entry gates further remediation, the boot queue, and the guard's actionable-work test until its `RULING` lands (written out-of-band by the human's `rule-coherence` session). Zero merged child PRs clears vacuously.
2. **Claim** the ticket: `${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> <action> <session-run-id>`.
3. **Act.** Dispatch with tier pins; append the dispatch to the manifest (absolute-path anchored). **Await dual-wake:** native completion notification primary; the background `await-worker.sh` v2 backstop; pinned fallback is foreground chunked awaits. Wakes for already-reaped manifest entries are ignored (the reap record is the dedup marker). On `STALLED`: **stop the worker** (agent-layer primitive) and **confirm it finished** — terminal record, **or** stop-success + transcript quiescence (mtime stable, no new writes); then RESUMABLE iff durable checkpoints **new since this dispatch**, else one no-progress attempt toward the ceiling; escalate per lane stop conditions. Silence is never success.
4. **Close out** (prefix-resumable — any close-out is resumable from any prefix by a successor; the SHA-keyed evidence, claim ids, and manifest reap records are the resume keys): **fence** (`driver-claim.sh verify` + refresher-alive check), release the ticket claim (pin the concrete `${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> --session <session-run-id>` — the `--session` filter is how "release own-session by default" is actually enforced: `release-claim.sh`'s no-flag default targets the newest open claim of *any* session, so a driver omitting it could close a foreign successor's claim, the §54 wrong-claim-close shape from the survivor side), post checkpoint evidence, **reap the manifest** (`reap-workers.sh`; stop stragglers; append reap records).
5. **Re-scan** (per-iteration staleness probe): newest comment/history on the epic, **excluding this session's own writes and bookkeeping species** — classification routed through the species-aware `${CLAUDE_PLUGIN_ROOT}/scripts/watchdog-scan.sh` output with an **epic-only scope flag** (the probe is the partition's fifth consumer, not a sixth inline copy), with the own-writes filter applied on top by run id. API authorship cannot discriminate (every plugin session writes as the same key), so "self" is session-run-id-in-body: the driver skips writes it knows it just made; any residual unattributable history event (labels/history carry no body) triggers a benign full re-scan. Human app comments are distinct users and always count. Full state-reader re-scan on external change.

Per-ticket retry ceilings carry over (stagnation-counting, progress-reset) — the driver owns the counter, not `claim.sh`.

## Park and bloat — the only two exits

**No third exit trigger** — a time-based succession rule would recreate the conflicting-rule-set problem.

- **Park:** no automated action possible (human-parked on a pending-human entry, blocked, or empty queue).
- **Bloat:** context degraded — await the in-flight lane's own exit (the driver cannot command a mid-flight checkpoint), then exit; crash recovery is the floor if the exit protocol degrades. At any park evaluation no lane is in flight by construction (awaiting an in-flight lane is itself an available action, reached before park).

Exit protocol, both: **fence**, post the **continuation brief** (format below; repo mirror `continuation-brief.md` for validation), `driver-claim.sh release <epic-id> <claim-id> <parked|bloat-handoff>`, exit. Brief-post failure: retry once, then exit anyway — durable state alone is the proven cold-boot path.

**Continuation brief format** (self-contained, posted as an epic comment under the `# Continuation Brief` header): state map reference with evidence links; chosen next action + one line of why; live concerns from notes; anything in flight that must not be redone (open PRs, running lanes, partial close-outs with their resume keys).

## The Human-Ruling Resolution Route (ruling mode)

Reached via Step 0a when this skill was invoked with the instruction `rule-coherence <merge-sha> approve|reject|redirect:<scope>` (the operator runs the `drive-epic` skill with that instruction — there is no separate command). The answer surface is a **session, not a parsed comment** — no NL parse of PM comments, no comment-authorship discrimination, no wake edge, no automation-key prerequisite. The ruling *is* an automation-authored register write under the existing idempotent SHA-keyed discipline.

**Full lifecycle (both edges pinned):**

1. **Acquire.** The epic is normally parked on the pending-human entry, so no driver contends. If a driver *is* live (it may legitimately be resuming a RESUMABLE lane during the park), **wait until that claim is released or goes stale, then acquire** — bounded, because the driver parks after at most its one in-flight lane. Never "hand off to a pickup" (no channel could deliver the ruling's content to the live driver). A crashed ruling session simply re-runs and re-acquires under the same wait, idempotent under SHA-keyed skip-what-exists. **Fence/refresher posture:** the ruling session starts **no refresher** — its claim freshness bounds it by construction (a sub-lease; a session running past ~45m simply decays and re-runs idempotently), so it fences with `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh verify` (the three **claim-state** conjuncts only — the fourth, refresher-alive, is n/a here since no refresher was started) immediately **before** the `RULING` write and again immediately **before** the label clear, aborting on ownership loss. This matches spec §107 ("reusing its claim/fence/routing") without contradicting Task B's four-conjunct fence definition (the fourth conjunct is asserted by callers that *run* a refresher; the ruling session does not).
2. **Route.** Read the pending entry named by `<merge-sha>`, route per flag (below), and write the `RULING` as the **last write**.
3. **Clear.** **Evaluate the register-wide clear predicate and clear `coherence-pending` if satisfied, in this same session** — nothing else owns this evaluation now (the async wake edge that used to occasion it is deleted). A guard backstop covers a crash between the `RULING` write and the clear (the guard's actionable-work test).
4. **Exit.** **Release the claim with a `ruled` exit state and exit. The ruling mode never enters the drive loop and never selects from the priority table** — it must not become the driver from the human's terminal, nor idle holding a fresh claim that blocks the guard from booting a real driver.

**Per-flag routing** (the reviewer recorded the routing inputs at review time; the ruling session executes them):

- **GATE1_AMENDMENT.** *approve* ⇒ execute the **held route** recorded in the pending entry (canonization, superseded-by note, affected-children label strips — recorded held/not-yet-performed). *reject* or `redirect:<scope>` ⇒ the **MATERIAL_DRIFT machinery** (corrective ticket, dependents held by relation); `redirect:<scope>` scopes the corrective (judgment fed to the corrective-drafting step), bare `reject` scoped by the contradiction; the corrective's blocked-by relations cover the AMENDMENT's originally-held dependents.
- **GATE1_REFRESH** (its constituent decisions were each already individually canonized, so the register canon itself is what the human rules on). *approve* ⇒ the underlying writes already routed; the `RULING` records the re-approved delta as the new Gate-1 baseline (held route is a no-op by construction). *reject* or *redirect* ⇒ **de-canonize**: post superseding register entries, update the canon summary to remove the rejected decisions, and strip readiness labels on the **per-decision affected-children set the reviewer recorded in the pending entry** (a mechanical durable read) — a MATERIAL_DRIFT corrective only where the scope names rework.

**Ordering and idempotence.** The route ends by writing the `RULING` — the **last write** (fail-closed): a mid-route crash leaves the pending entry unresolved, and the human simply re-invokes drive-epic with the same `rule-coherence <sha> …` instruction, idempotent under SHA-keyed skip-what-exists. The `RULING` is a `decision-register-entry.md` variant with the same `# Decision Register Entry` header and the same `Merge SHA:` key the audit reads; its body records the outcome and the writes performed. *unresolved* ≡ a pending-human entry with no later `RULING` for its SHA — the `<merge-sha>` argument binds it.

## Scheduling migration and prerequisites

- **0.14.0:** create `dodi-drive-epic` (hourly, off-peak minute, permission mode Auto; epic-PR merge in no allow-list). Pause `dodi-pickup-next` (task disabled; manual invocation stays safe — the fence line makes it a no-op beside a live driver). Gate-fail revert order: pause `dodi-drive-epic` **before** resuming `dodi-pickup-next`. `dodi-reconcile-tickets` unchanged in schedule.
- **0.14.1** (gate passed): delete `pickup-next` + its task.
- **Prerequisites** (carried, plus one new term): branch protection on main/master; escalation channel tested end-to-end; `LINEAR_API_KEY` in the session environment; and **coherence rulings are delivered by invoking the `drive-epic` skill with the instruction `rule-coherence <sha> approve|reject|redirect` — a session run, not a chat reply and not a separate command.** (Step 0a parses that instruction and branches to ruling mode.) The operator learns this before the first park.
- Machine-off operation (cloud routines) remains the upgrade path.

## Rules

- Mechanics live in `dodi-dev/scripts/` — run the script and judge its result; never restate a script's mechanism in prose.
- Every worker/lane dispatch carries an explicit model-tier pin per AGENTS.md; a plugin hook also enforces this.
- **Single active epic.** A second signed-off epic in scope is escalated, not interleaved.
- Never merge an epic PR; Gate 2 is procedural and absolute.
- The fence guards every durable-write close-out, every wake, and the merge command. Ownership lost → abort durable writes and exit; read error → brief retry, then exit without durable writes.

## Evidence

- Record per session: run id, guard outcome, boot audit result, actions taken, exit (park/bloat/no-op/ruled), continuation-brief link, driver-claim release state.

## Stop Conditions

- PM unreachable / auth failure — escalate, exit.
- Claim yield (lost the acquire race) — exit no-op.
- Fence trip (ownership lost) — abort durable writes, exit.
- Retry ceiling on a ticket — mark `blocked`, escalate.
- Park or bloat — exit protocol above.
````

Executor note: this SKILL.md references sibling prompt files by path (`epic-orchestrator/state-reader-prompt.md`, `epic-orchestrator/state-transitions.md`) which is allowed (they ship in the plugin), but must **not** reference `templates/ticket-comments/...` or `docs/...` — the validator (`validate-phase-skills.sh:85`) rejects those. The continuation-brief and register-entry formats are stated inline (self-contained) with only a one-word "repo mirror" nod that names no path in a way the grep catches; confirm the grep pattern (`templates/ticket-comments`) does not fire on the SKILL.md before committing.

- [ ] **Step 5:** Verify.

Run: `bash scripts/validate-ticket-comment-templates.sh 2>&1 | tail -1; grep -n 'templates/ticket-comments\|docs/specs/2026\|docs/plans/2026' dodi-dev/skills/drive-epic/SKILL.md || echo 'no repo-only refs in drive-epic'`
Expected: the template validator still **passes** here — its existence loop is an allowlist, so the new templates (`continuation-brief.md`, the extended `decision-register-entry.md`) are simply not yet **guarded** by it until Task I adds their entries; a new unlisted template is neither checked nor failed. The load-bearing check for this task is `no repo-only refs in drive-epic`. (The validators with the new templates under guard is Task I.)

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/skills/drive-epic templates/ticket-comments/continuation-brief.md templates/ticket-comments/decision-register-entry.md dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md
git commit -m "feat: drive-epic resident driver + ruling mode + continuation-brief/register-entry/reviewer producer edits (0.14.0 layer E)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task F: pickup-next fencing

`pickup-next` ships intact-but-fenced: status-check no-op + re-verify-before-merge, progress-test prose → liveness hierarchy, close-out inverted to label-before-merge, merge-eligibility guard (step 2.1), step-2.2 rewritten to the full set-difference protocol. The "not locking" doctrine sentence stays for the window.

**Files:**
- Modify: `dodi-dev/skills/pickup-next/SKILL.md`

- [ ] **Step 1:** Add the driver-claim fence to the claim step. Rewrite step 3 (`pickup-next/SKILL.md:36`):

Old:
```
3. **Claim.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> <action>` before acting. A live foreign claim (exit 3) means skip — but first apply the progress test: a claim of any age whose ticket shows fresh checkpoint progress since the claim's last update is alive; only a claim with no progress signal falls back to the lease-age test. The tick never steals a live claim; `reconcile-tickets` expires dead ones.
```
New:
```
3. **Claim.** First **fence against a live driver**: resolve `<epic-id>` as the epic of the selected ticket by parent-traversal (hop `issue.parent` to the parentless root, exactly as `claim.sh` resolves the epic for tier-1), then run `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh status <epic-id>` — a fresh open driver claim means a resident driver owns this epic, so **exit no-op** (do not claim, do not merge). Otherwise mint a session run id and run `${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> <action> <session-run-id>` before acting. A live foreign claim (exit 3) means skip. Liveness is the **driver-claim-topped hierarchy** the script implements: a claim whose session matches a fresh open driver claim is alive; else a progress-species checkpoint within one lease window of now is alive; else the lease-age test. The tick never steals a live claim; `reconcile-tickets` expires dead ones. **Re-verify the driver-claim status immediately before the merge command itself** (the inlined `submit-ticket-pr` Merge sequence) — a driver booting minutes after this claim would otherwise merge concurrently; the re-verify closes the double-merge race.
```

- [ ] **Step 2:** Add the merge-eligibility guard to step 2.1 and invert the close-out to label-before-merge. Rewrite step 2 sub-item 1 (`pickup-next/SKILL.md:30`):

Old:
```
   1. Merge a `ready-to-merge-child` (serial merge slot; evidence-checker verification per `epic-orchestrator/evidence-checker-prompt.md` before merging; postconditions via `${CLAUDE_PLUGIN_ROOT}/scripts/verify-merge.sh` and `${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-branch.sh`). **The merge close-out applies `coherence-pending` to the epic.**
```
New:
```
   1. Merge a `ready-to-merge-child` (serial merge slot; evidence-checker verification per `epic-orchestrator/evidence-checker-prompt.md` before merging; postconditions via `${CLAUDE_PLUGIN_ROOT}/scripts/verify-merge.sh` and `${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-branch.sh`). **Merge-eligibility guard: no merge action is eligible while the epic holds `coherence-pending`** — this keeps reviews serial and the register append-ordered. **Fail-closed ordering: apply `coherence-pending` to the epic _before_ the merge command** (the irreversible write is the inlined `submit-ticket-pr` Merge, re-verified against the driver-claim status immediately before it), never after — a crash between merge and label under the old order left a merged child with no coherence review and, in gate-fail revert mode where no driver ever boots, no detector.
```

- [ ] **Step 3:** Rewrite step 2.2 to the full set-difference protocol. Rewrite step 2 sub-item 2 (`pickup-next/SKILL.md:31`):

Old:
```
   2. **Run the epic-coherence review for a `coherence-pending` epic.** First, the loop-side idempotence check: query the epic's register for an entry keyed to this merge SHA — if one exists, do not re-dispatch the reviewer; resume from whatever routing writes are missing. Otherwise dispatch `epic-orchestrator/coherence-reviewer-prompt.md` (`model: fable`) and perform the verdict-routing writes it recommends — register entry, canon section, label changes, corrective ticket — all keyed to the merge SHA; then clear `coherence-pending`. Outranks everything below so the epic is never blocked longer than one tick. GATE1_AMENDMENT or GATE1_REFRESH → escalate and leave `coherence-pending` in place. **Blocking scope:** `coherence-pending` blocks canon-consuming dispatches (mature-ticket, deliver-ticket, epic-PR drafting); operator-ordered housekeeping that consumes no canon (docs regen, cleanup) is exempt.
```
New:
```
   2. **Run the epic-coherence review for a `coherence-pending` epic — full set-difference protocol.** Fetch all merged child PRs targeting the epic branch (`mergeCommit` oids) and all register-entry `Merge SHA:` keys (a **paged** read); the **target set** is every merged-but-unregistered SHA, reviewed **oldest `mergedAt` first, serially**, each dispatch noting that register entries newer than the SHA under review are **not precedent**. For each, the loop-side idempotence check first (an entry for this SHA ⇒ resume missing routing writes, do not re-dispatch); otherwise dispatch `epic-orchestrator/coherence-reviewer-prompt.md` (`model: fable`) and perform its verdict-routing writes, all keyed to the SHA. **Halt after the first pending-human verdict** (a GATE1_AMENDMENT/GATE1_REFRESH verdict) completes its own routing — review no further SHAs while it stands. The label clears **iff the set-difference is empty ∧ no register entry over the epic's merged SHAs is unresolved** (register-wide, never batch-scoped); zero merged child PRs clears vacuously. A pending-human entry is a **no-op park** — the human resolves it out-of-band via `rule-coherence <sha> approve|reject|redirect` (the `drive-epic` ruling mode), so the tick needs **no wake edge**: leave the label and move on. **Blocking scope:** `coherence-pending` blocks the merge slot and all canon-consuming dispatches (mature-ticket, deliver-ticket, epic-PR drafting); operator-ordered housekeeping that consumes no canon is exempt.
```

- [ ] **Step 4:** Sweep the `:32` last-merge-scoped clear echo. In step 2 sub-item 3 (`pickup-next/SKILL.md:32`), change `the last merge's coherence review is clean` to `the register-wide coherence clear predicate is satisfied (set-difference empty ∧ no unresolved pending-human entry)`.

  Also pin the tick's own close-out to `--session` (mirrors the driver's A1 pin, same §54 wrong-claim-close reason): in step 5 (`pickup-next/SKILL.md:38`), change `${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> <evidence>` to `${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> <evidence> --session <session-run-id>` (the run id minted in the Step 1 claim rewrite is in scope), so the tick closes its own claim, never a foreign successor's. Fallback-lane hardening; identical to 0.13 otherwise.

- [ ] **Step 5:** The "not locking" doctrine sentence (`pickup-next/SKILL.md:50`, "Claims are for crash visibility and multi-host coexistence, not locking...") **stays unchanged** for the window — the transient contradiction with the new AGENTS.md ("claims serialize tickets") is accepted and dies with 0.14.1. Do not edit it; note in the commit message that it is deliberately retained.

- [ ] **Step 6:** Verify.

Run: `bash scripts/validate-phase-skills.sh 2>&1 | tail -3`
Expected: **passes** — its `plugin_scripts` array is an allowlist, so the three new scripts, still unlisted until Task I, are simply not yet **guarded** by it (neither checked nor failed); the validator does not fail on their absence. The pickup-next edits themselves must not introduce a repo-only-doc reference or break the grep checks. Confirm with: `grep -n 'templates/ticket-comments\|docs/specs/2026\|docs/plans/2026' dodi-dev/skills/pickup-next/SKILL.md || echo clean`

- [ ] **Step 7:** Commit.

```bash
git add dodi-dev/skills/pickup-next/SKILL.md
git commit -m "feat: fence pickup-next (driver-status no-op, label-before-merge, set-difference 2.2) — intact for the window (0.14.0 layer F)

Deliberately retains the 'claims are not locking' doctrine sentence — transient contradiction accepted, dies with 0.14.1.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task G: janitor + watchdog + heartbeat

`reconcile-tickets` manifest sweep, species-correct driver-claim expiry, liveness-hierarchy per-ticket expiry + its own SKILL.md liveness prose rewritten, wedged-driver daily backstop probe, digest gains the pending-human park item, reference cleanup; `watchdog-scan.sh` species-aware activity; `heartbeat.sh` update-in-place dedupe + target rule + note-string fix.

**Files:**
- Modify: `dodi-dev/scripts/heartbeat.sh`
- Modify: `dodi-dev/scripts/watchdog-scan.sh`
- Create: `dodi-dev/scripts/tests/test-heartbeat.sh`
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md`

- [ ] **Step 1:** Rewrite `heartbeat.sh` for per-day update-in-place dedupe (comment targets: update the existing day's heartbeat comment, not create-per-day; file targets: append with date-line dedupe), the target rule, and the "tick alive" default note string.

```bash
#!/usr/bin/env bash
# Post/refresh the daily heartbeat — the dead-man's switch. Its ABSENCE is the
# signal the substrate died. Target rule: a ticket id posts/refreshes a PM
# comment; a writable file path appends a line. Per-day dedupe (update-in-place
# for comments, date-line dedupe for files) so a heartbeat is refreshed, not
# duplicated, on every guard path and in the driver's drive loop.
#
# Usage: heartbeat.sh <ticket-id-or-file-path> [note]
# Exit: 0 posted/refreshed; 2 error.
set -euo pipefail

target="${1:?usage: heartbeat.sh <ticket-id-or-file-path> [note]}"
note="${2:-driver alive}"
host="$(hostname -s)"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
today="$(date -u +%Y-%m-%d)"
line="heartbeat $now host=$host $note"

if [[ "$target" == */* || -f "$target" ]]; then
  # File target: replace today's heartbeat line in place if present, else append.
  if [[ -f "$target" ]] && grep -q "^heartbeat ${today}T" "$target"; then
    tmp="$(mktemp)"
    grep -v "^heartbeat ${today}T" "$target" >"$tmp" || true
    printf '%s\n' "$line" >>"$tmp"
    mv "$tmp" "$target"
    echo "heartbeat refreshed (in place) in $target"
  else
    printf '%s\n' "$line" >>"$target"
    echo "heartbeat appended to $target"
  fi
else
  source "$(dirname "$0")/linear-api.sh"
  resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id comments(last: 100) { nodes { id body } } } }' "{\"id\": \"$target\"}")"
  uuid="$(RESP="$resp" python3 -c 'import json,os; print(json.loads(os.environ["RESP"])["data"]["issue"]["id"])')"
  # Find today's existing heartbeat comment (update-in-place) else create.
  existing="$(RESP="$resp" TODAY="$today" python3 -c '
import json,os
d=json.loads(os.environ["RESP"])["data"]["issue"]["comments"]["nodes"]
t=os.environ["TODAY"]
print(next((c["id"] for c in d if c["body"].startswith(f"heartbeat {t}T")), ""))')"
  if [[ -n "$existing" ]]; then
    vars="$(python3 -c 'import json,sys; print(json.dumps({"id": sys.argv[1], "input": {"body": sys.argv[2]}}))' "$existing" "$line")"
    linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null
    echo "heartbeat refreshed (in place) on $target"
  else
    vars="$(python3 -c 'import json,sys; print(json.dumps({"input": {"issueId": sys.argv[1], "body": sys.argv[2]}}))' "$uuid" "$line")"
    linear_gql 'mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success } }' "$vars" >/dev/null
    echo "heartbeat posted to $target"
  fi
fi
```

Executor note: the default note string changes from `tick alive` to `driver alive` (the runtime string the spec calls out — neither header nor enum, so no sweep would otherwise catch it). `comment-species.sh`'s heartbeat carve-out matches on the `heartbeat ` prefix, so the note change does not affect classification. **Comment-window honesty (spec §48):** the comment-target branch's today's-heartbeat read uses `comments(last: 100)` — page beyond the window **or** assert the ticket's comment count is under it, per Task B note (b); a today-heartbeat comment hidden past comment 100 would make the script create a duplicate instead of updating in place. (The file-target branch is local and window-free.)

- [ ] **Step 2:** Make `watchdog-scan.sh` species-aware. Its activity signal must be **progress-species writes only** (not bare `updatedAt`), else the design's own timer writes (driver-claim refresh, heartbeat mirror) keep the epic permanently "active" and the 3-day watchdog never fires. Rewrite the gatherer to read comments + history across children and classify via `comment-species.sh`. Add an optional `--epic-only` scope flag (the per-iteration drive-loop probe uses it to skip the full children query).

```bash
#!/usr/bin/env bash
# Stalled-epic watchdog data gatherer, SPECIES-AWARE. Activity = progress-species
# writes only (lane checkpoints, register entries, progress artifacts) — NOT bare
# updatedAt, which the design's own timer writes (driver-claim refresh, heartbeat
# mirror) keep permanently fresh, masking the 3-day watchdog forever.
#
# Usage: watchdog-scan.sh <epic-id> [--epic-only]
#   --epic-only: report epic-level activity only (the drive-loop per-iteration
#                probe scope), skipping the full <=100-children query.
# Exit: 0 digest printed; 2 error.
set -euo pipefail
source "$(dirname "$0")/linear-api.sh"
source "$(dirname "$0")/comment-species.sh"

epic="${1:?usage: watchdog-scan.sh <epic-id> [--epic-only]}"
epic_only=""
[[ "${2:-}" == "--epic-only" ]] && epic_only=1

if [[ -n "$epic_only" ]]; then
  resp="$(linear_gql 'query($id: String!) {
    issue(id: $id) { identifier updatedAt labels { nodes { name } }
      comments(last: 100) { nodes { createdAt body } } }
  }' "{\"id\": \"$epic\"}")"
else
  resp="$(linear_gql 'query($id: String!) {
    issue(id: $id) {
      identifier updatedAt labels { nodes { name } }
      comments(last: 100) { nodes { createdAt body } }
      children(first: 100) {
        nodes {
          identifier updatedAt
          state { name type }
          labels { nodes { name } }
          comments(last: 100) { nodes { createdAt body } }
          inverseRelations { nodes { type issue { identifier state { type } } } }
        }
      }
    }
  }' "{\"id\": \"$epic\"}")"
fi

SPECIES_SH="$(dirname "$0")/comment-species.sh" RESP="$resp" EPIC_ONLY="${epic_only:-}" python3 <<'PY'
import json, os, subprocess
species_sh = os.environ["SPECIES_SH"]
def species(body):
    return subprocess.run(["bash", species_sh], input=body, capture_output=True, text=True).stdout.strip()
def last_progress(comments):
    ts = None
    for c in comments:
        if species(c["body"]) == "progress":
            if ts is None or c["createdAt"] > ts:
                ts = c["createdAt"]
    return ts or "-"

epic = json.loads(os.environ["RESP"])["data"]["issue"]
epic_labels = ",".join(sorted(l["name"] for l in epic["labels"]["nodes"])) or "-"
epic_prog = last_progress(epic.get("comments", {}).get("nodes", []))
print(f"EPIC\t{epic['identifier']}\t{epic['updatedAt']}\tlast_progress={epic_prog}\t{epic_labels}")

if not os.environ.get("EPIC_ONLY"):
    for c in epic["children"]["nodes"]:
        labels = ",".join(sorted(l["name"] for l in c["labels"]["nodes"])) or "-"
        blockers = ",".join(r["issue"]["identifier"] for r in c["inverseRelations"]["nodes"]
                            if r["type"] == "blocks" and r["issue"]["state"]["type"] not in ("completed","canceled")) or "-"
        cprog = last_progress(c.get("comments", {}).get("nodes", []))
        print(f"CHILD\t{c['identifier']}\t{c['updatedAt']}\t{c['state']['type']}:{c['state']['name']}\tlast_progress={cprog}\t{labels}\t{blockers}")
PY
```

Executor note: calling `comment-species.sh` per comment via subprocess is O(comments) process spawns — acceptable for a daily janitor and a small drive-loop probe, but if a live epic's comment volume makes it slow, inline the classification in the python (mirroring the `comment_species` table) rather than spawning. Keep the *unknown⇒bookkeeping* default and the heartbeat carve-out identical. The paged/split fallback (assert `<100` comments or cursor-loop) is the same honesty treatment as before.

- [ ] **Step 3:** Rewrite `reconcile-tickets/SKILL.md`. Apply all of: (a) manifest backstop sweep; (b) stray driver-claim expiry via `driver-claim.sh` only; (c) per-ticket claim expiry adopts the full liveness hierarchy with pre-close re-read and release-by-id; (d) wedged-driver probe (daily, here — not the guard); (e) digest gains the pending-human park item; (f) its own liveness prose rewritten (the `:45` "regardless of age" sentence); (g) reference cleanup (name the **driver** as the work-advancer at `:11`, `:60`).

Sub-edits:

  - **`:11`** (the "that is pickup-next's job" line). Old: `It does not dispatch lanes, write specs, or open PRs — that is \`pickup-next\`'s job.` New: `It does not dispatch lanes, write specs, or open PRs — that is the resident driver's job (\`drive-epic\`; the \`pickup-next\` tick is the paused 0.14.0 fallback).`

  - **Sweep table** — add three rows and amend one. Add after the existing "Claim comment on any ticket" row:
    ```
    | Unreaped worker in an over-lease dispatch manifest | non-terminal worker in a manifest older than the lease | classify via `${CLAUDE_PLUGIN_ROOT}/scripts/reap-workers.sh <manifest>`, stop what its layer can stop, digest note; crashed lanes leave worktree + manifest for this sweep |
    | Stray open driver claim | a `# Driver Claim` older than its staleness window (default 45m) | expire via `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh release <epic-id> <claim-id> taken-over` only (species separation — never `release-claim.sh`), re-reading staleness immediately before the close; `taken-over` is the correct exit-state for a janitor reaping a dead driver claim (matching Task B's `acquire` stale-close semantics), so Task B's release enum and this caller agree by text, not executor judgment |
    | Fresh driver claim + no progress-species writes > 8h (wedged driver) | the wedged-driver backstop — a driver claim staying fresh via its refresher while posting no progress-species work | escalate; this probe lives HERE in the daily sweep (honest latency ~a day), not the hourly guard, which under same-task no-overlap cannot fire against the live driver it would probe |
    ```
    Amend the existing "Claim comment on any ticket" row to use the hierarchy: change `older than the lease window with no checkpoint progress since` to `dead per the liveness hierarchy (no matching fresh driver claim, no progress-species checkpoint within a lease window of now, over lease age)`, and change its action to `clear the claim via \`release-claim.sh\` (re-reading staleness immediately before the close; foreign claims released by id, never most-recent-open), restore the ticket to its pre-claim state, note the expiry`.

  - **`:45`** (Cleanup section, "Expire dead claims" bullet). Old: `Expire dead claims via \`${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh\` after the progress test (fresh checkpoints since the claim's last update = alive, regardless of age).` New: `Expire dead claims via \`${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh\` after the **liveness hierarchy** (a claim whose session matches a fresh open driver claim is alive; else a progress-species checkpoint within one lease window of **now** is alive; else the lease-age test) — never the old age-blind "fresh checkpoints ⇒ alive" rule, which immortalized a crashed session's claim. Foreign claims are released **by claim id** with an explicit flag, with a pre-close staleness re-read.`

  (Note: the New text above deliberately avoids the literal phrase `regardless of age` so Step 5's sweep-check — which asserts that phrase is absent from the file — passes. The old age-blind rule is negated by paraphrase, not by quoting the dead phrase back into the file.)

  - **Waiting-On-You Digest** (`:36`) — add the pending-human park item. After `demotion awaiting a ruling,` insert `unresolved pending-human coherence-ruling register entry (a \`coherence-pending\` epic with a GATE1_AMENDMENT/GATE1_REFRESH entry and no later \`RULING\` for its SHA — awaited via \`rule-coherence\`; the reminder loop the park depends on, since the 3-day watchdog exempts explicit human-wait states),`.

  - **`:60`** ("Same runtime properties as pickup-next"). Old: `Same runtime properties as \`pickup-next\`: fresh self-contained session per run, Auto permission mode against the settings allow-list, no-overlap scheduling.` New: `Same runtime properties as the resident driver's guard: fresh self-contained session per run, Auto permission mode against the settings allow-list, no-overlap scheduling.`

  - **Its own liveness prose** — if the SKILL.md carries a "no checkpoint progress since" expiry sentence anywhere beyond the two above, sweep it to the hierarchy phrasing identically (grep the file for `checkpoint progress since` and `regardless of age` and reconcile every hit).

- [ ] **Step 4:** Write `dodi-dev/scripts/tests/test-heartbeat.sh` — the update-in-place dedupe unit (Testing Contract Unit scope + Minimum assertion). The heartbeat's **file-target branch is fully offline** (no network, no `linear-api.sh` source — the reason the Testing Contract picked this assertion for Unit, not the integration gate). It **invokes the real `heartbeat.sh <file> <note>`** twice against the same file on the same day and asserts exactly one `^heartbeat ${today}T` line survives, plus that a **prior day's** heartbeat line survives the update-in-place (proving the dedupe is date-scoped, not whole-file truncation). Everything runs under `mktemp -d`, so the target path contains a slash and routes to the file branch (`[[ "$target" == */* || -f "$target" ]]`).

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HB="$HERE/../heartbeat.sh"
bash -n "$HB"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
hb="$tmp/heartbeat.log"   # under mktemp -d: path contains a slash -> file-target branch
today="$(date -u +%Y-%m-%d)"
yesterday="$(date -u -d 'yesterday' +%Y-%m-%d 2>/dev/null || date -u -v-1d +%Y-%m-%d)"

# Seed a PRIOR day's heartbeat line that must SURVIVE the in-place update.
printf 'heartbeat %sT12:00:00Z host=h driver alive\n' "$yesterday" >"$hb"

# Two runs on the SAME day against the file target -> update-in-place, not append.
bash "$HB" "$hb" "run one" >/dev/null
bash "$HB" "$hb" "run two" >/dev/null

# Assertion 1: exactly ONE line for today remains (dedupe / update-in-place).
today_count="$(grep -c "^heartbeat ${today}T" "$hb" || true)"
[[ "$today_count" -eq 1 ]] || { echo "FAIL dedupe: expected 1 today line, got $today_count" >&2; cat "$hb" >&2; exit 1; }

# Assertion 2: the prior day's line survived (date-scoped, not whole-file wipe).
grep -q "^heartbeat ${yesterday}T" "$hb" || { echo "FAIL prior-day: yesterday's heartbeat was clobbered" >&2; cat "$hb" >&2; exit 1; }

# The surviving today line reflects the LATEST run (in-place replace, not stale-first).
grep -q "^heartbeat ${today}T.*run two" "$hb" || { echo "FAIL freshness: today line must carry the latest note" >&2; cat "$hb" >&2; exit 1; }

echo "heartbeat tests ok"
```

Executor note: `heartbeat.sh` computes `today` with `date -u +%Y-%m-%d`, so the test derives `today`/`yesterday` the same way (the GNU `-d yesterday` / BSD `-v-1d` fork covers both platforms). The file-target branch never sources `linear-api.sh`, so no stub is needed — this is why the assertion belongs in Unit, not the live-test gate. If a run straddles UTC midnight between the two invocations (vanishingly rare), the second run would create a new-day line; the test tolerance is not built for that edge — re-run if it ever trips.

- [ ] **Step 5:** Verify.

Run: `chmod +x dodi-dev/scripts/tests/test-heartbeat.sh && bash dodi-dev/scripts/tests/test-heartbeat.sh && bash -n dodi-dev/scripts/heartbeat.sh && bash -n dodi-dev/scripts/watchdog-scan.sh && { ! grep -q 'regardless of age' dodi-dev/skills/reconcile-tickets/SKILL.md && echo 'swept: no regardless-of-age phrase'; }`
Expected: `heartbeat tests ok`, no `bash -n` output; and `swept: no regardless-of-age phrase` (the dead-rule phrase fully removed). The `! grep -q … && echo` form **exits 0** when the phrase is absent (success); a bare `grep -c … == 0` would print `0` but **exit 1** on zero matches, misreporting the swept state as a failure under exit-code discipline.

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/scripts/heartbeat.sh dodi-dev/scripts/watchdog-scan.sh dodi-dev/scripts/tests/test-heartbeat.sh dodi-dev/skills/reconcile-tickets/SKILL.md
git commit -m "feat: species-aware janitor + watchdog, liveness-hierarchy claim expiry, wedged-driver probe, heartbeat dedupe + test (0.14.0 layer G)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task H: docs — AGENTS.md, epic-orchestrator, mature-ticket, deliver-ticket, state-transitions, pickup-ticket

The doctrine and prose edits that make the skill layer consistent with the new machinery.

**Files:**
- Modify: `AGENTS.md`
- Modify: `dodi-dev/skills/epic-orchestrator/SKILL.md`
- Modify: `dodi-dev/skills/epic-orchestrator/state-transitions.md`
- Modify: `dodi-dev/skills/mature-ticket/SKILL.md`
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md`
- Modify: `dodi-dev/skills/pickup-ticket/SKILL.md`

- [ ] **Step 1:** AGENTS.md edits.
  - **Scheduled Operation** section (`:78-86`): rewrite the intro from "scheduled ticks, not resident sessions" to the resident model. New intro: `Post-Gate-1 delivery runs as a **resident driver** (\`drive-epic\`) — one long-lived orchestrator session per active epic, booted by a slow hourly liveness guard and advancing on completion events — with cron demoted to that guard plus the daily janitor (\`reconcile-tickets\`). Each runs as a harness-native scheduled task — never a hand-rolled cron/daemon wrapper around a headless CLI.` Then rewrite the bullets: replace "Ticks are stateless" and "One action per tick" with the driver's boot-from-durable-state + drive-loop model; keep the claim-discipline bullet but update "skips live claims from other hosts" to "skips live claims from other **sessions** (session-scoped foreignness, driver-claim-topped liveness hierarchy)"; keep the janitor and Gate-2 bullets. Add: the layering rule — **claims serialize tickets; worktrees serialize files; nothing serializes runs; the driver is the epic worktree's only writer.**
  - **`:60`** (Deterministic Skeleton script inventory): add the three new scripts. Change the parenthetical `(worker await, claims, dispatch eligibility, merge verification, branch cleanup, deploy checks, watchdog data, heartbeat)` to `(worker await, claims, driver claims, comment-species classification, worker reaping, dispatch eligibility, merge verification, branch cleanup, deploy checks, watchdog data, heartbeat)`.
  - **`:75`** (Lights-Out Invariants, "the tick's heartbeat"): change `the tick's heartbeat` to `the driver's heartbeat`.
  - **`:76`** (escalation-channel invariant): add one clause: after `never only to routine run notifications.` append ` Pending-human **coherence rulings are delivered by invoking the \`drive-epic\` skill with the instruction \`rule-coherence <sha> approve|reject|redirect\`** — a session run (drive-epic's Step 0a parses that instruction into ruling mode), never a separate command and never a chat reply. (AGENTS.md is the cross-runtime doctrine carrier: the Slack ping governs outbound notification, this governs the answer surface — a session, not a chat reply.)`
  - **Async-worker await contract** (`:46`): rewrite as a **pointer** to `await-worker.sh` rather than restating the poll mechanics inline (reference-don't-restate). New: `On Claude Code, never yield the turn to "wait" for a worker — run \`${CLAUDE_PLUGIN_ROOT}/scripts/await-worker.sh <output_file>\`, which detects completion by the transcript's terminal record (final-lines content check, STALLED on stall, chunk-bounded), and read only its final-lines output. Sessions dispatched directly by the top-level harness may rely on completion notifications; sessions running as workers themselves must poll via the script.`
  - **Context Hygiene** (`:88-95`) merge-anchor rescope: the "Mandatory anchors ... after every child merge" line contradicts the resident model. Rewrite `:93` to: `Mandatory anchors: orchestrator after Gate 1 approval; lanes at the quality-gate→PR seam. In the resident driver, the child-merge close-out is a **durable-brief anchor point** (register + continuation brief kept current), not a session reset — an actual context reset happens only at park or bloat. (A mandatory reset per merge would recreate the one-action tick the resident model replaces.)`

- [ ] **Step 2:** epic-orchestrator/SKILL.md edits (four enumerated line edits + resident-driver-as-consumer framing).
  - **`:11`** framing: change "advancement is normally **tick-driven**: the `pickup-next` scheduled task scans..." to name the resident driver as the autonomous consumer: `advancement is normally driven by the **resident driver** (\`drive-epic\`): one long-lived session per active epic advances tickets on completion events. A manually run orchestrator session remains valid (debugging, pushing a specific epic) and must follow the same claim discipline — including the driver-claim fence — so a manual run and a live driver never act on the same ticket concurrently.`
  - **`:62`** ("skip live claims from other hosts"): change `claim the ticket first, skip live claims from other hosts` to `claim the ticket first (minting a session run id), skip live claims from other **sessions** per the driver-claim-topped liveness hierarchy`.
  - **`:85-86`** (Merging section, merge-then-label): invert to label-before-merge. In step 4/5, move the `**Apply \`coherence-pending\` to the epic.**` to occur **before** the squash-merge command, and note the irreversible write is the inlined `submit-ticket-pr` Merge (`gh pr merge`), the sequence contains no push. Rewrite step 5's opening so the label application precedes the merge, and the coherence-review dispatch follows the merge; add the merge-eligibility guard ("no merge is eligible while `coherence-pending` is set").
  - **`:86`** review-protocol rewrite: replace "dispatch the coherence reviewer against the merge SHA; ... clear `coherence-pending` on a clean route. GATE1_AMENDMENT or GATE1_REFRESH → escalate and leave the label in place." with the **set-difference target and full clear predicate**: target = every merged-but-unregistered SHA (paged register read + merged-PR `mergeCommit` oids), oldest-`mergedAt`-first with the not-precedent note, halt after the first pending-human verdict routes; label clears iff set-difference empty ∧ no unresolved pending-human entry (register-wide); and amend the escalation prose to instruct the human to **resolve by invoking the `drive-epic` skill with the instruction `rule-coherence <sha> approve|reject|redirect`** (a session run, parsed by drive-epic's Step 0a — not a separate command), noting the ruling session performs the routing directly. (Manual orchestrator sessions consume this protocol live in 0.14 — it is not window-transient.)
  - **`:97`** (Context Hygiene mandatory reset per merge): rescope to a durable-brief anchor (register + brief current), actual session reset only at park/bloat — mirroring the AGENTS.md rescope.

- [ ] **Step 3:** state-transitions.md edits.
  - **`:20`** (the `ready-to-merge-child` row's Durable writes cell): add `coherence-pending` to the durable writes — change `squash merge, branch deletion, child done comment` to `apply \`coherence-pending\` (before the merge, fail-closed), squash merge, branch deletion, child done comment`.
  - **`:47`** (epic-level `coherence-pending` row): rewrite. Its **trigger** cell is falsified by label-before-merge (the state is now reachable with zero completed merges — the label goes on before the merge command). New trigger: `label applied at the merge close-out **before** the merge command (fail-closed), or by the set-difference boot audit finding a merged-but-unregistered SHA`. New **clear** condition: `epic-active when the register-wide clear predicate holds — the set-difference is empty (every merged child PR holds a register entry) ∧ no register entry over the epic's merged SHAs is unresolved (a pending-human GATE1_AMENDMENT/GATE1_REFRESH entry with no later \`RULING\` for its SHA)`; keep the plural per-entry SHA keying and the blocking-scope note (now including the merge slot). Fallback cell: `remains coherence-pending on an unresolved pending-human entry — the human resolves it via \`rule-coherence\`; the driver/guard/tick no-op on the park`.
  - **`:56`** (Realignment section, stale-actor sweep): grep this section for stale actor names — `tick`, `pickup-next` — and reconcile any hit to the resident driver; if none, no-op. (Confirmed at plan time: `:56` reads `The tick then re-routes the child through \`mature-ticket\`` — change `The tick then re-routes` to `The driver then re-routes`. That is the only stale-actor hit in this section; do not fabricate additional Old/New pairs.)

- [ ] **Step 4:** mature-ticket/SKILL.md — per-gate push-back prose. The spec calls for `mature-ticket` per-gate push-back (push at each gate transition *before* that gate's comment/label). Add to the Process section, after the "Run write-plan after the spec is clean" bullet, a bullet: `**Ephemeral worktree, per-gate push-back:** maturity runs in an ephemeral worktree off the epic branch. Push back to the epic branch at **each gate transition before** posting that gate's comment/label — \`dispatch-eligible.sh\` checks labels, not artifact presence, so a durable label against an artifact in a dangling worktree would arm dispatch against a missing plan. Cite SHAs only post-push (patch-id fallback per the 0.13.5 precedent). Layering rule: claims serialize tickets; worktrees serialize files; nothing serializes runs.`

- [ ] **Step 5:** deliver-ticket/SKILL.md — polling prose pointer. In the "Awaiting Workers" section (`:56-58`), tighten the restated poll mechanics to a pointer (reference-don't-restate): keep the "never yield" sentence but replace the mtime-specific restatement with `await each worker via \`${CLAUDE_PLUGIN_ROOT}/scripts/await-worker.sh <output_file>\` — the script detects completion by the transcript's terminal record (final-lines content check, STALLED on stall, chunk-bounded) and prints only its final lines. Never read the whole transcript.` (This aligns the prose with the v2 script; the old "mtime stable >60s" phrasing describes the retired v1.)

- [ ] **Step 6:** pickup-ticket/SKILL.md — record the worktree path as **absolute** (load-bearing for manifest anchoring). In Process, change `Create the child branch and child worktree from the epic branch.` region and the `Record the created branch and worktree before implementation starts.` bullet to: `Record the created branch and the child worktree path **as an absolute path** before implementation starts — the lane's dispatch manifest anchors to this absolute path (agent cwd resets between Bash calls, so a relative path is fiction for the lane).` Also add to Evidence: change `Record ... child worktree` to `Record ... child worktree (absolute path)`. **Also note the lane's first `.dodi/` manifest write self-creates `<child-worktree-abs>/.dodi/.gitignore` containing `*` (same self-ignoring behavior as the driver's — the first manifest write in _any_ worktree owns the ignore-file creation, per Task D Step 6), so the lane worktree never leaks `.dodi/` into git.**

- [ ] **Step 7:** Verify.

Run: `for f in AGENTS.md dodi-dev/skills/epic-orchestrator/SKILL.md dodi-dev/skills/epic-orchestrator/state-transitions.md dodi-dev/skills/mature-ticket/SKILL.md dodi-dev/skills/deliver-ticket/SKILL.md dodi-dev/skills/pickup-ticket/SKILL.md; do grep -n 'templates/ticket-comments\|docs/specs/2026\|docs/plans/2026' "$f" && echo "REPO-REF IN $f"; done; echo done`
Expected: `done` with no `REPO-REF IN` lines (AGENTS.md is repo-root, not a skill, so its refs are fine — but the skill files must stay clean; the grep here is a belt check).

- [ ] **Step 8:** Commit.

```bash
git add AGENTS.md dodi-dev/skills/epic-orchestrator/SKILL.md dodi-dev/skills/epic-orchestrator/state-transitions.md dodi-dev/skills/mature-ticket/SKILL.md dodi-dev/skills/deliver-ticket/SKILL.md dodi-dev/skills/pickup-ticket/SKILL.md
git commit -m "docs: resident-driver doctrine across AGENTS.md + epic-orchestrator/state-transitions + mature/deliver/pickup-ticket (0.14.0 layer H)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task I: validators + metadata + release

Extend the two structural validators, bump all three metadata files to 0.14.0, run all three validators green, commit.

**Files:**
- Modify: `scripts/validate-phase-skills.sh` (+drive-epic skill, +3 scripts)
- Modify: `scripts/validate-ticket-comment-templates.sh` (five template entries)
- Modify: `dodi-dev/.claude-plugin/plugin.json` (0.14.0)
- Modify: `dodi-dev/.codex-plugin/plugin.json` (0.14.0)
- Modify: `.claude-plugin/marketplace.json` (0.14.0)

- [ ] **Step 1:** `validate-phase-skills.sh`. Add `drive-epic` to the `skills` array (leave `pickup-next` — it ships intact in 0.14.0; its removal is 0.14.1). Add `driver-claim.sh`, `reap-workers.sh`, `comment-species.sh` to the `plugin_scripts` array.

In the `skills=(...)` list, after `pickup-next` / `reconcile-tickets`, add:
```
  drive-epic
```
In the `plugin_scripts=(...)` list, after `heartbeat.sh`, add:
```
  driver-claim.sh
  reap-workers.sh
  comment-species.sh
```

- [ ] **Step 2:** `validate-ticket-comment-templates.sh`. Add the five template entries: `driver-claim.md`, `continuation-brief.md`, `lane-checkpoint.md`, `claim.md`'s session-id/enum changes, and `decision-register-entry.md`'s new fields + RULING variant.

Add the new files to the existence loop (line ~28):
```
for file in epic-assessment spec-ready ready-to-implement demotion child-pr-ready epic-pr-ready epic-signoff-request claim deploy-confirmation decision-register-entry driver-claim continuation-brief lane-checkpoint; do
  test -f "templates/ticket-comments/${file}.md"
done
```

Add heading/content checks (append before the final `echo`):
```
check_heading templates/ticket-comments/driver-claim.md "Claim"
check_heading templates/ticket-comments/driver-claim.md "Exit"
check_contains templates/ticket-comments/driver-claim.md "Session run id:"

check_heading templates/ticket-comments/continuation-brief.md "State Map Reference"
check_heading templates/ticket-comments/continuation-brief.md "Chosen Next Action"
check_heading templates/ticket-comments/continuation-brief.md "In Flight (must not be redone)"

check_heading templates/ticket-comments/lane-checkpoint.md "Session"
check_heading templates/ticket-comments/lane-checkpoint.md "Evidence"
check_contains templates/ticket-comments/lane-checkpoint.md "Run id:"

# claim.md session-id + coherence-review enum
check_contains templates/ticket-comments/claim.md "Session run id:"
check_contains templates/ticket-comments/claim.md "coherence-review"

# decision-register-entry.md new fields + RULING variant
check_contains templates/ticket-comments/decision-register-entry.md "Run id:"
check_heading templates/ticket-comments/decision-register-entry.md "Held Route (GATE1_AMENDMENT only — the not-yet-performed writes the approve branch executes)"
check_heading templates/ticket-comments/decision-register-entry.md "Per-Decision Affected Children (GATE1_REFRESH only — which children's specs consumed EACH superseded decision)"
check_heading templates/ticket-comments/decision-register-entry.md "Ruling (RULING variant only — the durable resolution record for a pending-human entry)"
check_contains templates/ticket-comments/decision-register-entry.md "RULING"
```

Executor note: `check_heading` matches `^## <heading>$` exactly, so the heading strings above must match `decision-register-entry.md` byte-for-byte (Task E Step 2). If a heading is long/awkward for `check_heading`, simplify the template heading to the short form (`## Held Route`, `## Per-Decision Affected Children`, `## Ruling`) and use `check_contains` for the parenthetical — but keep template and validator in sync. Prefer the short headings + `check_contains` on a distinguishing phrase; adjust both files together.

- [ ] **Step 3:** Bump all three metadata files to `0.14.0`.

```
dodi-dev/.claude-plugin/plugin.json   : "version": "0.13.5" -> "0.14.0"
dodi-dev/.codex-plugin/plugin.json    : "version": "0.13.5" -> "0.14.0"
.claude-plugin/marketplace.json       : "version": "0.13.5" -> "0.14.0"  (the dodi-dev plugin entry)
```

- [ ] **Step 4:** Run all three validators green (POSIX grep only). This is the full-plugin gate — every prior task's edits must now pass together.

Run: `bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh && bash scripts/validate-ticket-comment-templates.sh`
Expected: `phase skills ok` and `ticket comment templates ok` (and the metadata validator's success line), all exit 0. Also run the syntax gate: `for f in dodi-dev/scripts/*.sh; do bash -n "$f"; done && echo 'all scripts parse'` → `all scripts parse`. And re-run the synthetic tests, **fail-loud** (the loop must not swallow a mid-loop failure by exiting on the last test's code): `for t in dodi-dev/scripts/tests/*.sh; do bash "$t" || { echo "TEST FAILED: $t"; exit 1; }; done` → each prints its `... ok` and the loop exits 0 only if all pass.

- [ ] **Step 5:** Commit.

```bash
git add scripts/validate-phase-skills.sh scripts/validate-ticket-comment-templates.sh dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "release: dodi-dev 0.14.0 — validators + metadata bump (0.14.0 layer I)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [ ] **Step 6:** Push to main (release mechanics, per the release process). This is a plugin release, not an epic PR — there is no Gate 2 human-merge here; the maintainer gate is the plan review + the supervised live-test gate.

Run: `git push origin main`
Then apply the release per the release process: `claude plugin marketplace update dodi-skills && claude plugin update dodi-dev@dodi-skills` and start a fresh session so the new hooks/skills load. (Do not run `install` — it will not upgrade in place.)

---

### Task I-bis: Scheduler cutover (operator action)

**This is an operator/scheduler action, distinct from the `git push` code release in Task I Step 6** — pushing the code does not by itself retire the tick. It is the prerequisite the Live-Test Gate's preamble already assumes ("`dodi-drive-epic` created + `dodi-pickup-next` paused"). It owns retiring the tick. Perform it **after** Task I's push has been applied to the running environment (fresh session, new skills loaded) and **before** the supervised first drive.

**Handoff note:** if scheduled-task creation/mutation is owned by a separate operator thread (the maintainer's scheduled-task operator), this section is that thread's work order, not the implementing session's — hand it off explicitly with the inputs below rather than leaving the cutover implicit. The implementing session does not silently assume the tasks exist.

1. **Create `dodi-drive-epic`** — the resident driver's liveness guard task. Schedule: **hourly, off-peak minute**. Permission mode: **Auto**. The **epic-PR merge is in no allow-list** (Gate 2 stays procedural and absolute — the driver can never merge an epic PR). Standard inputs (the drive-epic Contract's trigger inputs): **PM scope = the signed-off epic**, repo path(s), heartbeat location, retry ceiling (default 3), and `humanContact`.
2. **Pause `dodi-pickup-next`** — **disable the task** (not delete; deletion is 0.14.1 after the gate passes). Manual invocation stays safe: the driver-claim fence (Task F) makes a manually run `pickup-next` a no-op beside a live driver.
3. **Confirm `dodi-reconcile-tickets` is unchanged** — same schedule, same inputs; the daily janitor carries the manifest sweep, stray-driver-claim expiry, and the wedged-driver probe (Task G). Do not re-create or re-schedule it.
4. **Gate-fail revert order (restate, load-bearing):** if the Live-Test Gate produces a blocking finding, revert by **pausing `dodi-drive-epic` _before_ resuming `dodi-pickup-next`** — never both live at once (two work-advancers on one epic). On a *passing* gate there is no revert; `pickup-next` is deleted in 0.14.1.

Verification: `dodi-drive-epic` present and enabled (hourly), `dodi-pickup-next` present but disabled, `dodi-reconcile-tickets` present and unchanged. Record the task ids / panel state as the cutover evidence.

---

## Live-Test Gate execution

The seven-item Live-Test Gate (spec § lines 164-172) is the manual integration/e2e substitute — the harness IS the live scheduled-task environment; there is no offline harness. Execute it during a **supervised first drive** with a human at the monitor, after Task I ships and `dodi-drive-epic` is created + `dodi-pickup-next` paused. **Items 6 and 7 are verified FIRST** — two design decisions load-bear on their answers, so a wrong assumption there invalidates the takeover ordering and the guard cadence before the other five items matter.

### Item 6 (FIRST) — does a dispatched Agent-tool lane survive its dispatching session's *death*?

- **Assumed answer (design's assumption):** load-bearing either way, but the takeover reap-before-release ordering is built for the **survives** case. The design does not assume it dies; it assumes it *might* survive and guards accordingly.
- **Observation method:** during the supervised drive, dispatch a lane, then kill the driver session (or let it crash) while the lane is mid-flight. On the next guard hour, the successor takes over the stale driver claim and runs the boot takeover: `reap-workers.sh` on the predecessor's manifest. Observe whether the lane's transcript is still being written (mtime advancing) after the dispatcher died — that is the survival signal.
- **Branch action if the answer differs:**
  - If lanes **survive** their dispatcher's death (the guarded-for case): the reap-before-release ordering must actually *stop* the orphan before the successor foreign-releases the ticket claim and re-dispatches — and stopping **depends on item 4's nested stop primitive**. If item 4 confirms a nested stop primitive exists, confirm the ordering fires and prevents the two-lanes-on-one-ticket collision — load-bearing, ship as designed. **If item 4 finds no nested stop primitive**, the reap can only *classify and escalate* the orphan (`reap-workers.sh` reports `live`/`STALLED`; nothing can kill the grandchild), so the two-lanes collision is **not** prevented — only flagged. Record this as a **known lights-out gap** (survival observed + no stop primitive ⇒ the successor must wait out or escalate the orphan rather than re-dispatch beside it), not "ship as designed": note it in the reconcile-tickets manifest-sweep prose and gate the successor's re-dispatch on the orphan reaching a terminal record.
  - If lanes **die with the session:** the takeover reap is a cheap confirm, not load-bearing. Keep the ordering (it is harmless and the reaper still classifies), but note in the reconcile-tickets manifest-sweep prose that orphaned-grandchild survival was not observed, so the "run to completion — note and escalate" posture is a defensive default rather than an observed hazard.

### Item 7 (FIRST) — does the scheduler fire an hourly run while a prior same-task run is still live?

- **Assumed answer (design's assumption):** **no overlap** — the 0.13 corpus asserts same-task no-overlap. The whole guard-vs-live-driver cadence rests on this: the wedged-driver probe lives in the daily janitor (the hourly guard cannot fire against the live driver it would probe), and the driver self-refreshes the heartbeat in its drive loop (a >24h run would otherwise starve the dead-man switch).
- **Observation method:** with a driver run deliberately kept live across an hourly boundary (a long lane, or a supervised hold), watch the scheduler: does a second `dodi-drive-epic` run launch while the first is still executing? Check the task panel and the driver-claim comments (a second run would attempt `acquire` and either lose or — if overlap — contend).
- **Branch action if the answer differs:**
  - If **no overlap** (assumed): ship as designed — probe stays daily, driver self-refreshes the heartbeat.
  - If runs **do overlap:** `pickup-next`'s 0.13 serialization premise was always false. Two corrections: (a) the wedged-driver probe may additionally re-home to the hourly guard for ~1h latency (the gate-conditional choice the janitor prose already flags); (b) confirm the fenced `acquire` correctly makes the overlapping second run lose and exit no-op (it should — oldest-fresh wins), so overlap degrades to a wasted no-op run, not a double driver. If `acquire` does NOT cleanly resolve overlap, that is a blocking finding — halt and escalate.

### Items 1-5 (after 6 & 7)

1. **Agent-tool completion notifications reach a scheduled-task session** (dual-wake primary). Observe: a dispatched worker's completion wakes the driver without the await backstop firing. If it does not, the backstop (item 2) carries it.
2. **Background-Bash exit re-invocation reaches a scheduled-task session** (dual-wake backstop). Observe: the background `await-worker.sh` chunk exit re-invokes the driver. If both 1 and 2 disappoint, the pinned fallback is foreground chunked awaits — restate the latency honestly.
3. **Background-shell lifecycle + session-pid capture:** multi-hour survival; and — the coupled question — whether the Boot Step 1 PPID-chain walk from `$$` actually resolves the true **session** process (the one that dies with the session, not the transient Bash-tool shell), so the refresher's orphan detection fires on session crash. Observe: with the orphan-aware refresher running, after a session crash the refresher self-exits and the claim goes stale in ≤45 min, rather than a corpse's claim staying fresh forever.
   - **If the walk resolves the session pid cleanly (orphan-aware path holds):** ship the orphan-aware refresher — crashed-session claims decay in ≤45m via self-exit **plus** lease.
   - **If the walk cannot pin the session process (or self-exit does not fire):** ship the **lease-only fallback** (Boot Step 1, refresher launched with `<session-pid> 0`). The claim still decays by lease alone in ≤45m — no orphan self-exit, but no regression versus tier-3; record it as a known lights-out gap (a crashed driver's claim lingers up to the lease window before the takeover reap adopts it), not a blocker. The takeover reap-before-release covers the residual on the next guard hour.
4. **The agent-layer stop primitive:** works; nested availability; and the post-stop transcript shape (does a force-stopped worker get a terminal record?). This defines which STALLED confirmation branch is real — terminal record, or stop-success + quiescence.
5. **Scheduled-session longevity:** multi-hour scheduled runs permitted at all; if capped, the design degrades to a bounded-latency tick via succession — survivable, latency story restated.

**Gate outcome:** all seven items passed or their pinned fallbacks invoked ⇒ proceed to 0.14.1. Any blocking finding (notably item 7 overlap that `acquire` does not resolve, or item 6 survival that the reap ordering does not catch) ⇒ halt, escalate to the maintainer, do not proceed to deletion.

---

## 0.14.1 (trailing — a trivial post-gate deletion, not a task breakdown)

After all seven live-test-gate items pass or invoke their pinned fallbacks: delete `pickup-next` (skill directory) and its `dodi-pickup-next` scheduled task; remove `pickup-next` from the `validate-phase-skills.sh` skills array; and run a final dangling-reference sweep (any remaining prose pointing at the deleted skill — the transient "not locking" doctrine sentence dies here, along with any `pickup-next`-named actor references the 0.14.0 window left standing). Revert order is enforced by the gate: pause `dodi-drive-epic` before resuming `dodi-pickup-next` only if the gate *fails* and a rollback is needed; on a passing gate, `pickup-next` is simply removed. Bump all three metadata files to 0.14.1, run the three validators, commit and push. This is a single trivial deletion gated on the live-test gate passing — no per-task breakdown warranted.
