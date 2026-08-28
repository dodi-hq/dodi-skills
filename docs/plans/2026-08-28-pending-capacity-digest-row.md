# Two-Band Capacity-Park Digest + Steady-Park Coverage Correction (DOD-1216) Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** Give `pending-capacity` parks a two-band janitor digest sub-section (self-healing / escalating) backed by a new tested `capacity-park-scan.sh`, and correct the false "retry ceiling covers persistent capacity trouble" claim in all three places it is asserted.

**Architecture:** A new read-only plugin script `dodi-dev/scripts/capacity-park-scan.sh` (the `watchdog-scan.sh` shape: per-epic arg, `set -euo pipefail`, source-guarded `linear-api.sh`, embedded `python3`, one TSV digest line, exit 0/2) with a pure `classify` subcommand as the testable core (the `claim.sh classify` precedent). The `reconcile-tickets` digest gains a `### Capacity Parks` sub-section that runs the script per parked epic and renders by band; `AGENTS.md` and `drive-epic/SKILL.md` scope the retry-ceiling coverage claim to the flapping case and name the janitor band as the steady-case backstop. Released-skill change: all five version-bearing metadata files bump together; the script joins the `plugin_scripts` validator array.

**Tech Stack:** bash (macOS `/bin/bash` 3.2-compatible — heredocs inside functions not `$(...)`, backticks via `chr(96)` in `$()`-heredoc python), `python3` for JSON/date arithmetic, `mktemp` shim-dir test stubbing. No new dependencies, no `LINEAR_API_KEY` in any test.

**Spec:** `docs/specs/2026-08-28-pending-capacity-digest-row-design.md` (approved). Epic canon DR-001..DR-005 honored: policy gaps only (DR-003), no seat moves, no gate reclassification. Thresholds ship as parameterized defaults (24h age / 168h window / 3 flaps) — ⚠ delegated assumption per the spec, non-blocking.

**Note on drafting:** the script and test below were executed against fixtures during plan drafting (bash 5 and `/bin/bash` 3.2, all assertions green, including the clock-skew clamp). They are complete, verified content — transcribe exactly.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `capacity-park-scan.sh classify` — the pure band decision (label predicate, `>=` boundaries on both signals, threshold parameterization); no network, no sourcing
  - Reason: band arithmetic is the change's only deterministic invariant surface; the digest itself is prose executed by a Standard-tier (`model: sonnet` on Claude Code) main loop with no harness
  - Minimum assertions: label absent → `none` regardless of history; age just under threshold + flap 1 → `self-healing`; age just over → `escalating`; age exactly at threshold → `escalating` (pins the `>=` boundary on the age signal); age well under + flaps at threshold → `escalating`; flaps one below → `self-healing`; non-default thresholds flip a band the defaults would classify differently (both the age and flap parameters)

- Integration: `required`
  - Scope: full `capacity-park-scan.sh` flow over a stubbed `linear-api.sh` (shim-dir pattern per `dodi-dev/scripts/tests/test-claim-liveness.sh:30-42`)
  - Reason: the entry-discrimination, window-counting, provenance-extraction, degenerate-case, and exit-code contracts are what the janitor's rendering depends on
  - Harness: `existing` (standalone bash tests under `dodi-dev/scripts/tests/`, `mktemp -d` shim dirs)
  - Minimum assertions: fixture park's `Gate:`/`Child:` land verbatim in the digest line; three in-window entries + one outside count 3, not 4; a newest `Kind: MODE`/`FABLE_MAKEUP` entry contributes nothing to age, flap count, or provenance; entries-without-label → `none`; label-without-entries → `escalating` with `-` provenance; non-default `--age-threshold-hours` honored end-to-end; API failure → non-zero exit distinguishable from a clean `none` (no band printed); future `createdAt` clamps age to 0

- E2E: `not-required`
  - Scope: n/a
  - Reason: deliberate — no scheduled-run harness exists in this repo and none is invented for this change (spec § Testing contract)
  - Harness: `not-applicable`
  - Minimum assertions: `none`

### Critical Flows

- `Steady park: pending-capacity label + one old CAPACITY_PARK entry → age signal escalates alone (flap count may be 0 or 1)`
- `Flapping park: several recent CAPACITY_PARK entries → flap signal escalates alone while age stays low`
- `Cleared park: entries present, label absent → band none, no digest row`
- `Defective write: label present, zero entries → escalating with '-' provenance, never silent`
- `API failure: exit 2, never readable as "no parks"`

### Regression Surface

- `dodi-dev/scripts/watchdog-scan.sh` — byte-unchanged (shares `linear-api.sh`; the other paged-register reader)
- `dodi-dev/scripts/linear-api.sh` — untouched (its exit-2 contract propagates into the new script)
- The six existing tests under `dodi-dev/scripts/tests/` — all still pass
- The three repo validators — all green; `validate-phase-skills.sh` lines 100-105 ban skill references to `docs/`/`templates/` paths, which the new digest section must not carry
- The other six digest classes in `reconcile-tickets/SKILL.md:40` — untouched apart from the removed `pending-capacity` clause and the amended empty-digest sentence

### Commands

- Unit: `bash dodi-dev/scripts/tests/test-capacity-park-scan.sh` (unit + integration are one standalone file, per repo convention)
- Integration: `bash dodi-dev/scripts/tests/test-capacity-park-scan.sh`
- E2E: `not applicable`
- Broader regression: `for t in dodi-dev/scripts/tests/test-*.sh; do bash "$t" || echo "FAIL $t"; done && scripts/validate-plugin-metadata.sh && scripts/validate-phase-skills.sh && scripts/validate-ticket-comment-templates.sh`

### Harness Requirements

- `bash`, `python3`, `mktemp` only — all already required by the existing tests
- `LINEAR_API_KEY` must NOT be needed by any test (a test requiring live Linear credentials is a defect in this contract)
- Run all commands from the worktree root: `/Users/may/github/dodi/dodi-skills/dodi-dev/worktrees/epic-dod-1213`

### Non-Required Rationale

- Unit: `required — n/a`
- Integration: `required — n/a`
- E2E: `The consuming surface is a Standard-tier main loop rendering prose to an escalation channel; no end-to-end scheduled-task harness exists in this repo and inventing one is out of scope by spec decision.`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## File Structure

- Create: `dodi-dev/scripts/capacity-park-scan.sh` — the band scanner + pure `classify` core (executable)
- Create: `dodi-dev/scripts/tests/test-capacity-park-scan.sh` — standalone unit + shim-dir integration test (executable)
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md:40` — remove the `pending-capacity` clause, amend the empty-digest sentence, add `### Capacity Parks`
- Modify: `AGENTS.md:59` — coverage-correction sentence (worktree root `AGENTS.md`)
- Modify: `dodi-dev/skills/drive-epic/SKILL.md:37` — same coverage-correction sentence
- Modify: `scripts/validate-phase-skills.sh:73-89` — add `capacity-park-scan.sh` to `plugin_scripts`
- Modify: the five version-bearing metadata files — `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json` — `0.16.4` → `0.16.5` together in one commit
- Untouched, verified so: `dodi-dev/scripts/watchdog-scan.sh`, `dodi-dev/scripts/linear-api.sh`, `.agents/plugins/marketplace.json` (carries no `version` key — not one of the five)

### Task 1: `capacity-park-scan.sh`

**Files:**
- Create: `dodi-dev/scripts/capacity-park-scan.sh`

- [ ] **Step 1:** Write the script — complete content, exactly this:

```bash
#!/usr/bin/env bash
# Capacity-park band scanner. Computes park age and flap count for ONE epic from
# the durable data drive-epic's hard-gate park already writes — the epic's
# `pending-capacity` label plus its `Kind: CAPACITY_PARK` decision-register
# entries — and classifies the park into a digest band. Read-only; no new
# durable writes. The janitor's digest § Capacity Parks renders the line; band
# arithmetic lives HERE, never re-derived in skill prose.
#
# Usage: capacity-park-scan.sh <epic-id> [--age-threshold-hours N] [--flap-window-hours W] [--flap-threshold K]
#        capacity-park-scan.sh classify <label_present yes|no> <age_h> <flap_count> <age_threshold_h> <flap_threshold>
#          -> prints none|self-healing|escalating; pure, no network, no
#             sourcing — the testable core.
# Defaults: N=24 (assumes one daily allowance-reset cycle — an operator-
#           confirmable parameter, never a baked literal), W=168 (7 days), K=3.
#
# Output (full flow): one TSV digest line
#   CAPACITY_PARK <epic-id> label=<yes|no> age_h=<n|-> flaps=<n>@<W>h gate=<gate|-> child=<child|-> band=<none|self-healing|escalating>
# Exit: 0 digest printed (band may be `none`); non-zero on error — 2 for
#       API/transport failure, 1 for a malformed/parse-failure response under
#       `set -e` — NEVER readable as "no parks"; the sweep escalates on any
#       non-zero exit, not on exit=2 specifically.
#
# Semantics pinned here (this script is the arithmetic's single home):
# - A comment is a CAPACITY_PARK entry iff its first non-empty line is the
#   `# Decision Register Entry` header AND a line carries `Kind: CAPACITY_PARK`
#   (backticks tolerated) — Kind-discrimination per the register's species
#   rule, so MODE / FABLE_MAKEUP / bare-verdict entries never contribute.
# - The label is the park predicate: entries with no label are re-park history
#   and classify to `none` (a cleared park must never render).
# - park age = now minus the newest entry's createdAt (negative clock skew
#   clamps to 0); flap count = entries with createdAt inside the trailing
#   flap window. Independent signals: `>=` escalates on both.
# - Degenerate case, decided: label present with ZERO entries (a park with no
#   recorded provenance — a defective write somewhere) emits age_h=-, gate=-,
#   child=-, band=escalating WITHOUT calling classify: missing provenance must
#   reach a human (the janitor's ambiguous-evidence posture — escalate, never
#   guess).
# - comments(last: 100) bounds the scan; CAPACITY_PARK entries are recent by
#   construction (the flap window is trailing), so newest-100 truncation is a
#   documented, accepted bound.
set -euo pipefail

# --- pure band decision (no network, no sourcing) — the testable core ---
_classify() {
  local label_present="${1:?classify: label_present}" age_h="${2:?classify: age_h}"
  local flap_count="${3:?classify: flap_count}" age_threshold_h="${4:?classify: age_threshold_h}"
  local flap_threshold="${5:?classify: flap_threshold}"
  # Label absent: not a park, whatever the history says.
  if [[ "$label_present" != "yes" ]]; then echo none; return 0; fi
  if (( $(python3 -c "print(1 if float('$age_h') >= float('$age_threshold_h') or int('$flap_count') >= int('$flap_threshold') else 0)") )); then
    echo escalating
  else
    echo self-healing
  fi
}

# Test/inspection subcommand — dispatched BEFORE any sourcing so the pure core
# needs nothing on disk beside this file.
if [[ "${1:-}" == "classify" ]]; then
  shift
  _classify "$@"
  exit 0
fi

# Source-guarded (tests may pre-stub linear_gql; the shim-dir pattern drops a
# stub linear-api.sh beside a copy of this script).
if ! declare -F linear_gql >/dev/null 2>&1; then source "$(dirname "$0")/linear-api.sh"; fi

epic="${1:?usage: capacity-park-scan.sh <epic-id> [--age-threshold-hours N] [--flap-window-hours W] [--flap-threshold K]}"
shift
age_threshold_h=24
flap_window_h=168
flap_threshold=3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --age-threshold-hours) age_threshold_h="${2:?--age-threshold-hours needs a value}"; shift 2 ;;
    --flap-window-hours)   flap_window_h="${2:?--flap-window-hours needs a value}"; shift 2 ;;
    --flap-threshold)      flap_threshold="${2:?--flap-threshold needs a value}"; shift 2 ;;
    *) echo "capacity-park-scan: unknown argument: $1" >&2; exit 2 ;;
  esac
done

resp="$(linear_gql 'query($id: String!) {
  issue(id: $id) { identifier labels { nodes { name } }
    comments(last: 100) { nodes { createdAt body } } }
}' "{\"id\": \"$epic\"}")"

# NOTE: heredoc lives inside a function, not inside $(...) — bash 3.2 (macOS
# /bin/bash) cannot parse heredocs within command substitution when the body
# contains backticks or odd apostrophes; the python builds backticks via
# chr(96) for the same reason (the claim.sh precedent).
_compute_facts() {
  RESP="$resp" FLAP_WINDOW_H="$flap_window_h" python3 <<'PY'
import json, os, re
from datetime import datetime, timezone
BT = chr(96)  # no literal backticks in a $()-heredoc — bash 3.2 parser bug
data = json.loads(os.environ["RESP"])["data"]["issue"]
labels = {l["name"] for l in data["labels"]["nodes"]}
label_present = "yes" if "pending-capacity" in labels else "no"
window_h = float(os.environ["FLAP_WINDOW_H"])
now = datetime.now(timezone.utc)
def parse_ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))
entries = []
for c in data["comments"]["nodes"]:
    body = c["body"]
    first = next((l for l in body.splitlines() if l.strip()), "")
    if not first.startswith("# Decision Register Entry"):
        continue
    # Kind discrimination: only CAPACITY_PARK entries contribute. Strip
    # backticks before matching — the register template renders the kind line
    # inside code spans.
    if not any("Kind: CAPACITY_PARK" in line.replace(BT, "") for line in body.splitlines()):
        continue
    entries.append(c)
entries.sort(key=lambda c: c["createdAt"])  # ISO-8601 sorts lexicographically
count = len(entries)
if count == 0:
    print(f"{label_present}\t0\t-\t0\t-\t-")
    raise SystemExit
newest = entries[-1]
age_h = (now - parse_ts(newest["createdAt"])).total_seconds() / 3600
if age_h < 0:
    age_h = 0.0  # clock-skew clamp; the band falls to the flap signal
flaps = sum(1 for c in entries
            if (now - parse_ts(c["createdAt"])).total_seconds() / 3600 <= window_h)
def field(name, body):
    m = re.search(name + r":\s*" + BT + r"([^" + BT + r"]+)" + BT, body)
    return m.group(1) if m else "-"
gate = field("Gate", newest["body"])
child = field("Child", newest["body"])
print(f"{label_present}\t{count}\t{age_h:.1f}\t{flaps}\t{gate}\t{child}")
PY
}
facts="$(_compute_facts)"
IFS=$'\t' read -r label_present entry_count age_h flap_count gate child <<<"$facts"

if [[ "$label_present" == "yes" && "$entry_count" == "0" ]]; then
  # Label without provenance: a defective write — escalate, never guess.
  band="escalating"
else
  band="$(_classify "$label_present" "$age_h" "$flap_count" "$age_threshold_h" "$flap_threshold")"
fi

printf 'CAPACITY_PARK\t%s\tlabel=%s\tage_h=%s\tflaps=%s@%sh\tgate=%s\tchild=%s\tband=%s\n' \
  "$epic" "$label_present" "$age_h" "$flap_count" "$flap_window_h" "$gate" "$child" "$band"
```

- [ ] **Step 2:** Make it executable and verify

Run: `chmod +x dodi-dev/scripts/capacity-park-scan.sh && test -x dodi-dev/scripts/capacity-park-scan.sh && bash -n dodi-dev/scripts/capacity-park-scan.sh && echo OK`
Expected: `OK`

Run: `bash dodi-dev/scripts/capacity-park-scan.sh classify yes 24 1 24 3 && bash dodi-dev/scripts/capacity-park-scan.sh classify no 999 9 24 3`
Expected (two lines): `escalating` then `none`

- [ ] **Step 3:** Commit

```bash
git add dodi-dev/scripts/capacity-park-scan.sh
git commit -m "feat: capacity-park-scan.sh — two-band park classifier over CAPACITY_PARK register entries (DOD-1216)"
```

### Task 2: `test-capacity-park-scan.sh`

**Files:**
- Create: `dodi-dev/scripts/tests/test-capacity-park-scan.sh`

- [ ] **Step 1:** Write the test — complete content, exactly this:

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCAN="$HERE/../capacity-park-scan.sh"
bash -n "$SCAN"

# ---------- Unit: the pure classify subcommand (no network, no stubs) ----------
# classify args: <label_present yes|no> <age_h> <flap_count> <age_threshold_h> <flap_threshold>
cl() { bash "$SCAN" classify "$@"; }

# Label absent -> none, regardless of history (a cleared park must never render).
[[ "$(cl no 999 9 24 3)" == none ]] || { echo "FAIL label-absent" >&2; exit 1; }
# Age just under threshold, flap 1 -> self-healing.
[[ "$(cl yes 23.9 1 24 3)" == self-healing ]] || { echo "FAIL age-under" >&2; exit 1; }
# Age just over threshold -> escalating (boundary from both sides).
[[ "$(cl yes 24.1 1 24 3)" == escalating ]] || { echo "FAIL age-over" >&2; exit 1; }
# Age EXACTLY at threshold -> escalating (pins the >= boundary on the age signal).
[[ "$(cl yes 24 1 24 3)" == escalating ]] || { echo "FAIL age-at-threshold" >&2; exit 1; }
# Age well under, flaps AT threshold -> escalating (flap signal fires independently).
[[ "$(cl yes 1 3 24 3)" == escalating ]] || { echo "FAIL flap-at-threshold" >&2; exit 1; }
# Flaps one below threshold -> self-healing.
[[ "$(cl yes 1 2 24 3)" == self-healing ]] || { echo "FAIL flap-below" >&2; exit 1; }
# Non-default thresholds flip a band the defaults would classify differently:
[[ "$(cl yes 10 1 24 3)" == self-healing ]] || { echo "FAIL nondefault-baseline" >&2; exit 1; }
[[ "$(cl yes 10 1 8 3)" == escalating ]] || { echo "FAIL nondefault-age" >&2; exit 1; }
[[ "$(cl yes 1 2 24 2)" == escalating ]] || { echo "FAIL nondefault-flap" >&2; exit 1; }

# ---------- Integration: full flow over a stubbed linear-api.sh ----------
# Shim-dir pattern (test-claim-liveness precedent): a mktemp dir holds a copy of
# capacity-park-scan.sh plus a stub linear-api.sh, so the script's
# $(dirname "$0")-relative source guard resolves to the stub. Fixtures are
# built by python (real timestamps relative to now; backticks via chr(96)).
#
# make_fixture <out.json> <labels-csv|-> <entry-spec>...
#   entry-spec: <kind>:<hours-ago>[:<gate>:<child>]   kind in CAPACITY_PARK|CAPACITY_PARK_BT|MODE|FABLE_MAKEUP|NOISE
#   CAPACITY_PARK_BT writes the kind line fully backtick-wrapped (template code-span form).
make_fixture() {
  local out="$1" labels="$2"; shift 2
  OUT="$out" LABELS="$labels" SPECS="$*" python3 <<'PY'
import json, os
from datetime import datetime, timedelta, timezone
BT = chr(96)
now = datetime.now(timezone.utc)
def iso(hours_ago):
    return (now - timedelta(hours=float(hours_ago))).strftime("%Y-%m-%dT%H:%M:%S.000Z")
labels = [] if os.environ["LABELS"] == "-" else os.environ["LABELS"].split(",")
nodes = []
for spec in os.environ["SPECS"].split():
    parts = spec.split(":")
    kind, hours = parts[0], parts[1]
    gate = parts[2] if len(parts) > 2 else "spec-authoring"
    child = parts[3] if len(parts) > 3 else "DOD-9"
    if kind == "NOISE":
        body = "# Lane Checkpoint\n\nnot a register entry"
    elif kind == "CAPACITY_PARK":
        body = ("# Decision Register Entry\n\n"
                f"Kind: CAPACITY_PARK {chr(183)} Gate: {BT}{gate}{BT} {chr(183)} Child: {BT}{child}{BT}\n\n"
                f"## Session\n\n- Run id: {BT}sridX{BT}")
    elif kind == "CAPACITY_PARK_BT":
        body = ("# Decision Register Entry\n\n"
                f"{BT}Kind: CAPACITY_PARK{BT} {chr(183)} Gate: {BT}{gate}{BT} {chr(183)} Child: {BT}{child}{BT}\n\n"
                f"## Session\n\n- Run id: {BT}sridX{BT}")
    else:  # MODE / FABLE_MAKEUP
        body = ("# Decision Register Entry\n\n"
                f"Kind: {parts[0]} {chr(183)} Gate: {BT}other-gate{BT} {chr(183)} Merge SHA: {BT}abc123{BT}\n\n"
                f"## Session\n\n- Run id: {BT}sridX{BT}")
    nodes.append({"createdAt": iso(hours), "body": body})
doc = {"data": {"issue": {"identifier": "EPIC-1",
                          "labels": {"nodes": [{"name": n} for n in labels]},
                          "comments": {"nodes": nodes}}}}
open(os.environ["OUT"], "w").write(json.dumps(doc))
PY
}

# run_scan <fixture.json|FAIL> [extra scan args...] — prints the digest line,
# returns the scan's exit code. FAIL installs a stub whose linear_gql fails
# (transport error), per the linear-api.sh exit-2 contract.
run_scan() {
  local fixture="$1"; shift
  local shim; shim="$(mktemp -d)"
  cp "$SCAN" "$shim/capacity-park-scan.sh"
  if [[ "$fixture" == "FAIL" ]]; then
    printf '%s\n' 'linear_gql() { echo "linear-api: transport error" >&2; return 2; }' >"$shim/linear-api.sh"
  else
    cp "$fixture" "$shim/fixture.json"
    printf '%s\n' "linear_gql() { cat \"$shim/fixture.json\"; }" >"$shim/linear-api.sh"
  fi
  local out rc
  set +e
  out="$(bash "$shim/capacity-park-scan.sh" EPIC-1 "$@" 2>&1)"; rc=$?
  set -e
  rm -rf "$shim"
  printf '%s\n' "$out"
  return "$rc"
}

fx="$(mktemp -d)"

# (1) Label + one 2h-old park: Gate:/Child: land VERBATIM; band self-healing.
make_fixture "$fx/one.json" pending-capacity "CAPACITY_PARK:2:spec-review-final:DOD-1299"
out="$(run_scan "$fx/one.json")"
grep -q $'gate=spec-review-final\tchild=DOD-1299' <<<"$out" || { echo "FAIL verbatim gate/child: $out" >&2; exit 1; }
grep -q 'band=self-healing' <<<"$out" || { echo "FAIL one-park band: $out" >&2; exit 1; }
grep -q 'label=yes' <<<"$out" || { echo "FAIL one-park label: $out" >&2; exit 1; }

# (2) Three entries inside the 168h window + one outside -> flaps=3 (not 4),
#     and the flap signal alone escalates (newest is 2h old). One in-window
#     entry uses the fully backtick-wrapped kind line (template code-span form).
make_fixture "$fx/flap.json" pending-capacity \
  "CAPACITY_PARK:2:g1:c1" "CAPACITY_PARK_BT:50:g2:c2" "CAPACITY_PARK:100:g3:c3" "CAPACITY_PARK:200:g4:c4"
out="$(run_scan "$fx/flap.json")"
grep -q 'flaps=3@168h' <<<"$out" || { echo "FAIL flap window count: $out" >&2; exit 1; }
grep -q 'band=escalating' <<<"$out" || { echo "FAIL flap escalation: $out" >&2; exit 1; }
grep -q $'gate=g1\tchild=c1' <<<"$out" || { echo "FAIL newest-entry provenance: $out" >&2; exit 1; }

# (3) Newest comment is Kind: MODE / FABLE_MAKEUP -> contributes NOTHING:
#     age comes from the 30h-old CAPACITY_PARK (escalating on age), flaps=1,
#     provenance from the park entry, not the make-up entry.
make_fixture "$fx/kinds.json" pending-capacity \
  "FABLE_MAKEUP:1" "MODE:1" "NOISE:1" "CAPACITY_PARK:30:hard-gate:DOD-7"
out="$(run_scan "$fx/kinds.json")"
grep -q 'flaps=1@168h' <<<"$out" || { echo "FAIL kind discrimination flaps: $out" >&2; exit 1; }
grep -qE 'age_h=(29|30|31)\.[0-9]' <<<"$out" || { echo "FAIL kind discrimination age: $out" >&2; exit 1; }
grep -q 'band=escalating' <<<"$out" || { echo "FAIL steady-age escalation: $out" >&2; exit 1; }
grep -q $'gate=hard-gate\tchild=DOD-7' <<<"$out" || { echo "FAIL kind provenance: $out" >&2; exit 1; }

# (4) Entries but NO label -> band=none (re-park history must never render).
make_fixture "$fx/nolabel.json" - "CAPACITY_PARK:2:g:c"
out="$(run_scan "$fx/nolabel.json")"
grep -q 'band=none' <<<"$out" || { echo "FAIL no-label none: $out" >&2; exit 1; }
grep -q 'label=no' <<<"$out" || { echo "FAIL no-label field: $out" >&2; exit 1; }

# (5) Label but ZERO entries (defective write) -> escalating with '-' provenance.
make_fixture "$fx/noentry.json" pending-capacity "NOISE:1"
out="$(run_scan "$fx/noentry.json")"
grep -q $'age_h=-\tflaps=0@168h\tgate=-\tchild=-\tband=escalating' <<<"$out" || { echo "FAIL label-without-entry: $out" >&2; exit 1; }

# (6) Non-default thresholds are honored end-to-end: the 2h/1-flap park that is
#     self-healing under defaults escalates under --age-threshold-hours 1.
out="$(run_scan "$fx/one.json" --age-threshold-hours 1)"
grep -q 'band=escalating' <<<"$out" || { echo "FAIL threshold parameter: $out" >&2; exit 1; }

# (7) API failure -> non-zero exit, distinguishable from a clean none.
set +e
out="$(run_scan FAIL)"; rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "FAIL api-failure exit: got 0 :: $out" >&2; exit 1; }
if grep -q 'band=' <<<"$out"; then echo "FAIL api-failure printed a band: $out" >&2; exit 1; fi

# (8) Clock skew: a future createdAt clamps age to 0; band falls to the flap
#     signal (self-healing at 1 flap).
make_fixture "$fx/skew.json" pending-capacity "CAPACITY_PARK:-5:g:c"
out="$(run_scan "$fx/skew.json")"
grep -q 'age_h=0.0' <<<"$out" || { echo "FAIL skew clamp: $out" >&2; exit 1; }
grep -q 'band=self-healing' <<<"$out" || { echo "FAIL skew band: $out" >&2; exit 1; }

rm -rf "$fx"
echo "capacity park scan tests ok"
```

- [ ] **Step 2:** Make it executable and run it under both bashes

Run: `chmod +x dodi-dev/scripts/tests/test-capacity-park-scan.sh && bash dodi-dev/scripts/tests/test-capacity-park-scan.sh && /bin/bash dodi-dev/scripts/tests/test-capacity-park-scan.sh`
Expected: `capacity park scan tests ok` printed twice (bash 5 and macOS `/bin/bash` 3.2), exit 0.

- [ ] **Step 3:** Run the full existing suite (regression)

Run: `for t in dodi-dev/scripts/tests/test-*.sh; do bash "$t" || echo "FAIL $t"; done`
Expected: each test's ok line (`await-worker tests ok`-style closing lines from the six existing tests plus `capacity park scan tests ok`); **no** `FAIL` lines.

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/scripts/tests/test-capacity-park-scan.sh
git commit -m "test: unit + shim-dir integration coverage for capacity-park-scan.sh (DOD-1216)"
```

### Task 3: `reconcile-tickets/SKILL.md` — lift `pending-capacity` into `### Capacity Parks`

**Files:**
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md:38-40` (the `## Waiting-On-You Digest` section)

- [ ] **Step 1:** Replace the line-40 paragraph. Exact old text (one paragraph, currently line 40):

> Every run produces the daily digest of human-parked items across all epics: each Gate 1 request, `QUESTIONS_FOR_HUMAN`, `needs-human-spec` wait, demotion awaiting a ruling, unresolved pending-human coherence-ruling register entry (a `coherence-pending` epic with a GATE1_AMENDMENT/GATE1_REFRESH entry and no later `RULING` for its SHA — awaited via `rule-coherence`; the reminder loop the park depends on, since the 3-day watchdog exempts explicit human-wait states), each `pending-capacity` park (age-tracked; the guard auto-probes for capacity return, so this row is informational unless the park persists — a flapping park hits the retry ceiling and escalates to `blocked`), `blocked` ticket, and open Gate 2 PR — with age, the one-line ask, and the link. Deliver it to the escalation channel. **Re-escalation:** any item older than the staleness window (default 3 days) is flagged with its age — escalations are not fire-and-forget. An empty digest is one line: "nothing waiting on you."

Exact new text (the `pending-capacity` clause removed — six classes remain — and the empty-digest sentence made conditional on the sub-section too):

> Every run produces the daily digest of human-parked items across all epics: each Gate 1 request, `QUESTIONS_FOR_HUMAN`, `needs-human-spec` wait, demotion awaiting a ruling, unresolved pending-human coherence-ruling register entry (a `coherence-pending` epic with a GATE1_AMENDMENT/GATE1_REFRESH entry and no later `RULING` for its SHA — awaited via `rule-coherence`; the reminder loop the park depends on, since the 3-day watchdog exempts explicit human-wait states), `blocked` ticket, and open Gate 2 PR — with age, the one-line ask, and the link. Deliver it to the escalation channel. **Re-escalation:** any item older than the staleness window (default 3 days) is flagged with its age — escalations are not fire-and-forget. The one-line empty digest — "nothing waiting on you." — is emitted only when this paragraph's classes are all empty **and** the Capacity Parks sub-section below rendered no row.

- [ ] **Step 2:** Insert the sub-section immediately after that paragraph (still inside `## Waiting-On-You Digest`, before `## Deploy Signal`), preceded by a blank line. Exact new content:

> ### Capacity Parks
>
> For each epic in scope carrying the `pending-capacity` label, run `${CLAUDE_PLUGIN_ROOT}/scripts/capacity-park-scan.sh <epic-id>` and render its digest line here by band — band arithmetic lives in the script, never re-derived in the sweep.
>
> - **Self-healing:** informational — the guard's hourly probe is the active corrective, so this row is status, not a human ask. But its presence means the digest is not empty: never emit "nothing waiting on you" while any capacity park exists — a parked epic is not healthy-quiet.
> - **Escalating:** a full escalation-channel item with a concrete operator ask naming the blocked gate and child, the park age, and the flap count: automation has no remaining corrective — the wake-edge probe keeps failing, and the retry ceiling cannot count a park that never boots a lane — so restore Fable capacity, or decide the path forward. Re-escalated with its age on every subsequent run, like any needs-human item. (The ask states the block; it never proposes changing a gate's policy row in AGENTS.md § Fable Availability Policy.) When the script reports an escalating park with missing `Gate`/`Child` provenance (a defective write), the ask still fires — it names the epic and states that provenance is missing, never rendering it as a self-healing or absent row.
> - The shared 3-day staleness window does **not** govern this class: the guard re-probes hourly, so this clock measures failed self-corrections, not human response latency. The band thresholds are the script's parameters (defaults: escalate at 24h park age, or ≥ 3 parks in 7 days).
> - A non-zero exit from `capacity-park-scan.sh` escalates as a script-failure item — never rendered as "no parks" or silently skipped; without the exit code the sweep cannot tell a clean none from a read failure.

(Markdown note: the `>` blockquote markers above are plan formatting only — write the content as plain markdown lines in the SKILL.md, no blockquote.)

- [ ] **Step 3:** Verify the section's own acceptance greps

Run: `grep -n "^### Capacity Parks" dodi-dev/skills/reconcile-tickets/SKILL.md | wc -l`
Expected: `1`

Run: `grep -c "pending-capacity" dodi-dev/skills/reconcile-tickets/SKILL.md && grep -n "pending-capacity" dodi-dev/skills/reconcile-tickets/SKILL.md`
Expected: exactly one hit, on the `### Capacity Parks` sub-section's "For each epic in scope carrying the `pending-capacity` label" line — none in the digest paragraph.

Run: `grep -n 'capacity-park-scan.sh' dodi-dev/skills/reconcile-tickets/SKILL.md`
Expected: two hits; the invocation one reads `${CLAUDE_PLUGIN_ROOT}/scripts/capacity-park-scan.sh <epic-id>` (plugin-root-relative), the other is the non-zero-exit bullet.

Run: `grep -nE '\b(opus|sonnet|haiku|fable)\b' dodi-dev/skills/reconcile-tickets/SKILL.md`
Expected: only the pre-existing hits — the frontmatter `model: sonnet` line and the line-57 `Fast tier — model: haiku on Claude Code` rule. The new sub-section adds none (its "Fable" mentions are capitalized and do not match).

- [ ] **Step 4:** Commit

```bash
git add dodi-dev/skills/reconcile-tickets/SKILL.md
git commit -m "feat: two-band Capacity Parks digest sub-section in reconcile-tickets (DOD-1216)"
```

### Task 4: three-place coverage correction (prose only)

**Files:**
- Modify: `AGENTS.md:59` (worktree root — `/Users/may/github/dodi/dodi-skills/dodi-dev/worktrees/epic-dod-1213/AGENTS.md`)
- Modify: `dodi-dev/skills/drive-epic/SKILL.md:37`

(The third assertion site was the line-40 clause deleted in Task 3.)

- [ ] **Step 1:** In `AGENTS.md:59` (the `**hard → pending-capacity park:**` bullet), replace exactly this sentence:

> Persistent capacity flapping is counted by the standard retry ceiling → `blocked` + escalation, so an epic never loops park↔probe forever.

with exactly this:

> Persistent capacity **flapping** — probe success boots a driver whose retried dispatch fails again, burning a lane attempt each time — is counted by the standard retry ceiling → `blocked` + escalation. A **steady** park (every probe fails; no driver ever boots, so no lane attempt increments the ceiling) is outside the ceiling's reach by construction — the janitor's capacity-park digest bands (`reconcile-tickets` § Capacity Parks) are the declared backstop, so a park↔probe loop is never silent.

The bullet's trailing sentence ("Manual (non-driver) lane sessions do not park — they stop and report to the operator, who is present by definition.") stays byte-identical, as does everything before the replaced sentence.

- [ ] **Step 2:** In `dodi-dev/skills/drive-epic/SKILL.md:37` (the **Pending-capacity wake edge** guard item), replace exactly this sentence:

> Persistent capacity flapping is counted by the standard retry ceiling → `blocked` + escalation, so the epic never loops park↔probe forever.

with exactly the same replacement text as Step 1 (verbatim — "A **steady** park … is never silent."). Everything else in the item stays byte-identical (probe mechanics untouched — spec non-goal).

- [ ] **Step 3:** Verify

Run: `grep -n "park↔probe forever" AGENTS.md dodi-dev/skills/drive-epic/SKILL.md dodi-dev/skills/reconcile-tickets/SKILL.md; echo "exit=$?"`
Expected: no matches, `exit=1` (the false claim is gone everywhere).

Run: `grep -rn "retry ceiling" AGENTS.md dodi-dev/skills/drive-epic/SKILL.md dodi-dev/skills/reconcile-tickets/SKILL.md`
Expected: hits remain (the ceiling's own definition sites, the two corrected flapping-scoped sentences, and the digest sub-section's "cannot count a park that never boots a lane") — read each hit and confirm **no surviving line claims the ceiling bounds a steady capacity park**.

Run: `git diff --stat dodi-dev/scripts/watchdog-scan.sh dodi-dev/scripts/linear-api.sh`
Expected: empty output (both byte-unchanged).

- [ ] **Step 4:** Commit

```bash
git add AGENTS.md dodi-dev/skills/drive-epic/SKILL.md
git commit -m "fix: scope retry-ceiling capacity coverage to flapping; janitor bands are the steady-park backstop (DOD-1216)"
```

### Task 5: validator wiring

**Files:**
- Modify: `scripts/validate-phase-skills.sh:73-89` (the `plugin_scripts` array)

- [ ] **Step 1:** Add `capacity-park-scan.sh` to the array. Exact edit — old:

```bash
  watchdog-scan.sh
  heartbeat.sh
```

new:

```bash
  watchdog-scan.sh
  capacity-park-scan.sh
  heartbeat.sh
```

- [ ] **Step 2:** Verify

Run: `scripts/validate-phase-skills.sh | tail -1`
Expected: `phase skills ok` (this also enforces existence + executable bit + `bash -n` for the new script, the skill-reference existence check at line 102, and the repo-only-document ban at lines 107-110 against the new digest section).

- [ ] **Step 3:** Commit

```bash
git add scripts/validate-phase-skills.sh
git commit -m "chore: register capacity-park-scan.sh in the plugin_scripts validator array (DOD-1216)"
```

### Task 6: version bump — five files, one commit

**Files:**
- Modify: `.claude-plugin/marketplace.json:12`
- Modify: `dodi-dev/.claude-plugin/plugin.json:4`
- Modify: `dodi-dev/.codex-plugin/plugin.json:3`
- Modify: `.grok-plugin/marketplace.json:12`
- Modify: `dodi-dev/.grok-plugin/plugin.json:4`

- [ ] **Step 1:** Resolve the target version against the epic-branch head (sibling children of this epic also bump). Run:

```bash
grep -h '"version"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json | sort -u
```

Expected today: exactly one line carrying `0.16.4`. The target is the next patch above whatever this prints (if `0.16.4` → `0.16.5`; if a sibling already bumped, increment from that instead and use that value everywhere below).

- [ ] **Step 2:** In each of the five files, change the `"version"` value `"0.16.4"` → `"0.16.5"` (or the resolved target). `.agents/plugins/marketplace.json` carries no `version` key — do not touch it.

- [ ] **Step 3:** Verify

Run: `scripts/validate-plugin-metadata.sh`
Expected: `plugin metadata ok: 0.16.5`

Run: `grep -h '"version"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json | sort -u | wc -l`
Expected: `1`

- [ ] **Step 4:** Commit — all five files together (the AGENTS.md:15 same-change invariant; include the bare version string so the release stays `git log --grep`-findable):

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json
git commit -m "0.16.5: two-band capacity-park digest + steady-park coverage correction (DOD-1216)"
```

(Tagging `v0.16.5` happens at release on the merged version-bump commit per AGENTS.md:16 — not on this child branch.)

### Task 7: full verification + acceptance sweep

**Files:** none (verification only)

- [ ] **Step 1:** Full test + validator pass

```bash
bash dodi-dev/scripts/tests/test-capacity-park-scan.sh
for t in dodi-dev/scripts/tests/test-*.sh; do bash "$t" || echo "FAIL $t"; done
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
```

Expected: `capacity park scan tests ok`; seven per-test ok lines with no `FAIL`; `plugin metadata ok: 0.16.5`; `phase skills ok`; `ticket comment templates ok`. All exit 0.

- [ ] **Step 2:** Ticket acceptance criteria not already pinned by earlier tasks:

```bash
# AC 1-5, 9, 10, 16 — Task 3 Step 3 greps plus a read of the sub-section
grep -n "^### Capacity Parks" dodi-dev/skills/reconcile-tickets/SKILL.md
grep -nE "self-healing|escalating" dodi-dev/skills/reconcile-tickets/SKILL.md
# AC 6 — Task 4 Step 3 greps
# AC 7
test -x dodi-dev/scripts/capacity-park-scan.sh && bash -n dodi-dev/scripts/capacity-park-scan.sh && echo AC7-ok
# AC 8
grep -n "capacity-park-scan.sh" scripts/validate-phase-skills.sh
# AC 14
grep -h '"version"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json | sort -u
```

Expected: AC 1/2 greps match as in Task 3; `AC7-ok`; AC 8 matches inside the `plugin_scripts` array; AC 14 prints exactly one line and it is not `0.16.4`. Then read the sub-section once and confirm AC 3 (3-day window disclaimed with the hourly-probe reason), AC 4 (operator ask names gate, child, park age), AC 5 (self-healing suppresses the one-liner), AC 10 (no arithmetic restated — defaults are named as parameters only).

- [ ] **Step 3:** Regression confirmation

Run: `git diff main...HEAD --stat -- dodi-dev/scripts/watchdog-scan.sh dodi-dev/scripts/linear-api.sh` (use the epic branch as base if `main` diverges: `git diff epic/dod-1213-fable-scarcity-doctrine...HEAD --stat` from the child branch)
Expected: empty — both files byte-unchanged by this ticket.

## Out of scope (do not do these)

- No change to the guard's probe mechanics at `drive-epic/SKILL.md:37` beyond the one coverage sentence; no durable probe-failure counter (sibling ticket, spec OQ5).
- No restructuring of the other six digest classes; the paragraph stays a paragraph.
- No change to the shared 3-day staleness window for any other class.
- No gate fable-policy change (DR-003); no auto-clearing of parks; no cross-epic aggregation (spec OQ3, deferred).
- `watchdog-scan.sh` byte-unchanged; the watchdog's parked-epic exemption stays.
- The new SKILL.md section must not reference `docs/` or `templates/` paths (validator-enforced) — the `CAPACITY_PARK` entry shape is consumed via the script, never cited by template path.
