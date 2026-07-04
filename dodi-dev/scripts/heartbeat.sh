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
