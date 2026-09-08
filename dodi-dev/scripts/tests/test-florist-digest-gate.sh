#!/usr/bin/env bash
# The Stop gate refuses a Florist seat's exit when its FINAL message carries no
# digest the kernel would accept (DOD-1389). Fixtures mirror the smoke-#3
# transcripts: the seat ran florist-digest.sh, then closed with prose about it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../hook-florist-digest.sh"
GATE="$HERE/../florist-digest-gate.py"
bash -n "$HOOK"
python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$GATE"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
STATE="$TMP/state"

jsonl() { # jsonl <file> ; records on stdin, one compact JSON per line
  cat > "$1"
}

assistant() { # assistant <text> -> one transcript record
  python3 -c '
import json,sys
print(json.dumps({"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":sys.argv[1]}]}}))' "$1"
}

tool_result() { # tool_result <text> -> one transcript record (a Bash result)
  python3 -c '
import json,sys
print(json.dumps({"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":[{"type":"text","text":sys.argv[1]}]}]}}))' "$1"
}

run() { # run <transcript> [session] [stop_hook_active] ; echoes hook stdout
  local transcript="$1" session="${2:-s-default}" active="${3:-false}"
  python3 -c '
import json,sys
print(json.dumps({"session_id":sys.argv[2],"transcript_path":sys.argv[1],"hook_event_name":"Stop","stop_hook_active":sys.argv[3]=="true"}))' \
    "$transcript" "$session" "$active" |
    FLORIST_UNIT=dod-1388 FLORIST_LANE=contract-review DODI_DIGEST_GATE_HOME="$STATE" \
      CLAUDE_PLUGIN_ROOT=/plugin bash "$HOOK"
}

expect_pass() { # expect_pass <label> <transcript> [session]
  local out; out="$(run "$2" "${3:-s-$RANDOM}")"
  [[ -z "$out" ]] || { echo "FAIL $1: expected no output, got: $out" >&2; exit 1; }
}

expect_block() { # expect_block <label> <transcript> <substring> [session] [active]
  local out; out="$(run "$2" "${4:-s-$RANDOM}" "${5:-false}")"
  [[ "$out" == *'"decision": "block"'* ]] || { echo "FAIL $1: expected a block, got: $out" >&2; exit 1; }
  [[ "$out" == *"$3"* ]] || { echo "FAIL $1: reason lacks '$3': $out" >&2; exit 1; }
}

DIGEST='FLORIST-STATUS: clean-final delivery-tier=standard
FLORIST-EVIDENCE: kind=thread ref=https://linear.app/x#c1 sha=0b752b7a8'

# 1. The passing shape: the digest is in the final message.
{ tool_result "$DIGEST"; assistant "Review clean, plan pushed.

$DIGEST"; } | jsonl "$TMP/pass.jsonl"
expect_pass "digest in final message" "$TMP/pass.jsonl"

# 2. The observed failure (smoke #3, 2 of 3 dispatches): the seat RAN the helper,
#    then narrated it. The block hands back the exact lines it already produced.
{ tool_result "$DIGEST"; assistant "...recorded the evidence on the ticket, and emitted \`clean-final delivery-tier=standard\` as the last output."; } | jsonl "$TMP/narrated.jsonl"
expect_block "narrated digest" "$TMP/narrated.jsonl" "FLORIST-STATUS: clean-final delivery-tier=standard"
expect_block "narrated digest names the unit" "$TMP/narrated.jsonl" "unit dod-1388"

# 3. No digest anywhere: the block tells the seat to run the helper.
{ assistant "I finished the review and pushed the plan."; } | jsonl "$TMP/none.jsonl"
expect_block "no digest at all" "$TMP/none.jsonl" "/plugin/scripts/florist-digest.sh"

# 4. Grammar failures the kernel would silently throw away.
{ assistant "FLORIST-STATUS: reviewed-ok"; } | jsonl "$TMP/badoutcome.jsonl"
expect_block "unknown outcome" "$TMP/badoutcome.jsonl" "does not parse"
{ assistant "$DIGEST
FLORIST-EVIDENCE: kind=notes ref=x sha=-"; } | jsonl "$TMP/badevidence.jsonl"
expect_block "unknown evidence kind" "$TMP/badevidence.jsonl" "would be dropped"
{ assistant "Closing:

  FLORIST-STATUS: clean-final delivery-tier=standard"; } | jsonl "$TMP/indented.jsonl"
expect_block "indented digest" "$TMP/indented.jsonl" "column 0"

# 5. A sidechain (dispatched subagent) digest is not this session's stdout.
{ python3 -c '
import json
print(json.dumps({"type":"assistant","isSidechain":True,"message":{"role":"assistant","content":[{"type":"text","text":"FLORIST-STATUS: clean-final delivery-tier=standard"}]}}))'
  assistant "The subagent closed the lane."; } | jsonl "$TMP/sidechain.jsonl"
expect_block "sidechain digest ignored" "$TMP/sidechain.jsonl" "no \`FLORIST-STATUS:\` line"

# 6. Bounded: after DODI_DIGEST_GATE_MAX blocks the session is allowed to end.
for i in 1 2 3; do
  out="$(run "$TMP/none.jsonl" "s-bounded" "$([[ $i -gt 1 ]] && echo true || echo false)")"
  [[ "$out" == *'"decision": "block"'* ]] || { echo "FAIL bounded: block $i missing" >&2; exit 1; }
done
out="$(run "$TMP/none.jsonl" "s-bounded" true)"
[[ -z "$out" ]] || { echo "FAIL bounded: 4th Stop must be allowed, got: $out" >&2; exit 1; }
out="$(DODI_DIGEST_GATE_MAX=1; export DODI_DIGEST_GATE_MAX; run "$TMP/none.jsonl" "s-cap1")"
[[ "$out" == *block* ]] || { echo "FAIL cap: first block missing" >&2; exit 1; }

# 7. A repeated block says so.
expect_block "repeat wording" "$TMP/none.jsonl" "already blocked for the same reason" "s-repeat" true

# 8. Manual mode is untouched, and unreadable evidence fails open.
out="$(printf '{"session_id":"m","transcript_path":"%s","stop_hook_active":false}' "$TMP/none.jsonl" |
  env -u FLORIST_UNIT DODI_DIGEST_GATE_HOME="$STATE" bash "$HOOK")"
[[ -z "$out" ]] || { echo "FAIL manual mode must not block: $out" >&2; exit 1; }
out="$(run "$TMP/does-not-exist.jsonl" "s-missing")"
[[ -z "$out" ]] || { echo "FAIL missing transcript must fail open: $out" >&2; exit 1; }
{ printf '{"type":"assistant",\n'; } | jsonl "$TMP/torn.jsonl"
out="$(run "$TMP/torn.jsonl" "s-torn")"
[[ "$out" == *block* ]] || { echo "FAIL torn transcript: a tail line that does not parse is not a digest" >&2; exit 1; }

echo "PASS test-florist-digest-gate.sh"
