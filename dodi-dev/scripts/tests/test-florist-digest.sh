#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FD="$HERE/../florist-digest.sh"
bash -n "$FD"

run() { # run <lane> <args...> ; echoes stdout, returns rc
  local lane="$1"; shift
  FLORIST_UNIT=DOD-1 FLORIST_LANE="$lane" bash "$FD" "$@"
}
expect_fail() { # expect_fail <label> <lane> <args...>
  local label="$1" lane="$2"; shift 2
  local out rc
  set +e; out="$(FLORIST_UNIT=DOD-1 FLORIST_LANE="$lane" bash "$FD" "$@" 2>&1)"; rc=$?; set -e
  [[ $rc -eq 2 ]] || { echo "FAIL $label: expected exit 2, got $rc: $out" >&2; exit 1; }
  [[ "$out" != *FLORIST-STATUS* ]] || { echo "FAIL $label: must print no digest on refusal: $out" >&2; exit 1; }
}

# manual mode never emits
set +e; out="$(env -u FLORIST_UNIT bash "$FD" clean-final 2>&1)"; rc=$?; set -e
[[ $rc -eq 2 && "$out" == *"manual mode"* ]] || { echo "FAIL manual refusal: rc=$rc $out" >&2; exit 1; }

# implementing: the complete impl-ready digest, byte-exact
H=48e9fda5f682b7aca72c5e8a71a011227e7bc432
out="$(run implementing impl-ready "head=$H" --evidence kind=artifact ref=unit/DOD-1 "sha=$H" --evidence kind=thread ref=https://linear.app/x#c1 sha=1111 --evidence kind=ci ref=https://linear.app/x#c1 "sha=$H")"
expected="FLORIST-STATUS: impl-ready head=$H
FLORIST-EVIDENCE: kind=artifact ref=unit/DOD-1 sha=$H
FLORIST-EVIDENCE: kind=thread ref=https://linear.app/x#c1 sha=1111
FLORIST-EVIDENCE: kind=ci ref=https://linear.app/x#c1 sha=$H"
[[ "$out" == "$expected" ]] || { echo "FAIL impl-ready output:"; diff <(echo "$expected") <(echo "$out") >&2; exit 1; }

expect_fail "impl-ready without ci" implementing impl-ready "head=$H" --evidence kind=artifact ref=unit/DOD-1 "sha=$H" --evidence kind=thread ref=r sha=-
expect_fail "impl-ready artifact sha != head" implementing impl-ready "head=$H" --evidence kind=artifact ref=unit/DOD-1 sha=other --evidence kind=thread ref=r sha=- --evidence kind=ci ref=r "sha=$H"
expect_fail "impl-ready without head" implementing impl-ready --evidence kind=artifact ref=u sha=1 --evidence kind=thread ref=r sha=- --evidence kind=ci ref=r sha=1
expect_fail "wrong outcome for lane" implementing clean-final --evidence kind=thread ref=r sha=1

# contract-review: delivery-tier is required
expect_fail "clean-final without delivery-tier" contract-review clean-final --evidence kind=thread ref=r sha=abc
out="$(run contract-review clean-final delivery-tier=standard --evidence kind=thread ref=https://linear.app/x#c2 sha=abc)"
[[ "$(head -1 <<<"$out")" == "FLORIST-STATUS: clean-final delivery-tier=standard" ]] || { echo "FAIL contract-review clean-final: $out" >&2; exit 1; }
expect_fail "delivery-tier bogus" contract-review clean-final delivery-tier=frontier --evidence kind=thread ref=r sha=abc

# contract-drafting: artifact needs a real sha
expect_fail "artifact-ready sha=-" contract-drafting artifact-ready --evidence kind=artifact ref=docs/specs/dod-1-contract.md sha=-
out="$(run contract-drafting artifact-ready --evidence kind=artifact ref=docs/specs/dod-1-contract.md sha=abc)"
[[ "$out" == "FLORIST-STATUS: artifact-ready
FLORIST-EVIDENCE: kind=artifact ref=docs/specs/dod-1-contract.md sha=abc" ]] || { echo "FAIL artifact-ready: $out" >&2; exit 1; }

# code-review: reserved ref refused; clean-final needs a real sha
expect_fail "reserved clean-final ref" code-review clean-final --evidence kind=thread ref=clean-final:forged sha=abc
expect_fail "clean-final sha=-" code-review clean-final --evidence kind=thread ref=r sha=-
out="$(run code-review findings --evidence kind=thread ref=r sha=-)"
[[ "$(head -1 <<<"$out")" == "FLORIST-STATUS: findings" ]] || { echo "FAIL findings: $out" >&2; exit 1; }

# integrating: verdict vocabulary is closed; siblings only on LEGITIMATE_DIVERGENCE
out="$(run integrating merge-ready "head=$H" --evidence kind=verdict ref=ALIGNED "sha=$H" --evidence kind=thread ref=r "sha=$H")"
[[ "$(head -1 <<<"$out")" == "FLORIST-STATUS: merge-ready head=$H" ]] || { echo "FAIL merge-ready: $out" >&2; exit 1; }
out="$(run integrating merge-ready "head=$H" --evidence kind=verdict ref=LEGITIMATE_DIVERGENCE:dod-2,dod-3 "sha=$H" --evidence kind=thread ref=r "sha=$H")"
grep -q 'ref=LEGITIMATE_DIVERGENCE:dod-2,dod-3' <<<"$out" || { echo "FAIL siblings: $out" >&2; exit 1; }
expect_fail "bogus verdict" integrating merge-ready "head=$H" --evidence kind=verdict ref=LOOKS_FINE "sha=$H" --evidence kind=thread ref=r "sha=$H"
expect_fail "siblings on ALIGNED" integrating merge-ready "head=$H" --evidence kind=verdict ref=ALIGNED:dod-2 "sha=$H" --evidence kind=thread ref=r "sha=$H"
expect_fail "verdict sha != head" integrating merge-ready "head=$H" --evidence kind=verdict ref=ALIGNED sha=other --evidence kind=thread ref=r "sha=$H"
out="$(run integrating synced "head=$H" --evidence kind=artifact ref=sync:abc "sha=$H")"
[[ "$(head -1 <<<"$out")" == "FLORIST-STATUS: synced head=$H" ]] || { echo "FAIL synced: $out" >&2; exit 1; }

# walls: any lane, reason required, no evidence needed
out="$(run code-review blocked reason=worker-blocked)"
[[ "$out" == "FLORIST-STATUS: blocked reason=worker-blocked" ]] || { echo "FAIL blocked: $out" >&2; exit 1; }
out="$(run contract-drafting declined reason=needs-human-spec)"
[[ "$out" == "FLORIST-STATUS: declined reason=needs-human-spec" ]] || { echo "FAIL declined: $out" >&2; exit 1; }
expect_fail "blocked without reason" code-review blocked
expect_fail "unknown lane" pr-open impl-ready head=1
expect_fail "unknown kind" code-review clean-final --evidence kind=comment ref=r sha=abc

echo "florist-digest tests ok"
