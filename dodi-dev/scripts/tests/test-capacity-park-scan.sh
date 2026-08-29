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
