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
  # Capture the python call's output BEFORE testing it: set -e does not fire
  # inside an `if` condition, and (( $(...) )) reads an EMPTY substitution as
  # false — so a raised ValueError (e.g. a non-numeric --age-threshold-hours)
  # would otherwise fall through to self-healing with exit 0, the exact
  # "never silent" violation this script exists to prevent.
  local verdict
  if ! verdict="$(python3 -c "print(1 if float('$age_h') >= float('$age_threshold_h') or int('$flap_count') >= int('$flap_threshold') else 0)" 2>&1)" \
      || [[ "$verdict" != "0" && "$verdict" != "1" ]]; then
    echo "capacity-park-scan: classify: bad input (age_h=$age_h flap_count=$flap_count age_threshold_h=$age_threshold_h flap_threshold=$flap_threshold): $verdict" >&2
    return 1
  fi
  if (( verdict )); then
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
# /bin/bash) cannot parse a heredoc within command substitution when the body
# contains an ODD number of backticks (a balanced pair is fine; apostrophes
# are fine either way). The function wrapper is what's load-bearing here: it
# parses the heredoc at function-definition time, never inside a $(...). The
# python's own chr(96) backtick-building is defense in depth on top of that
# (the claim.sh precedent).
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
