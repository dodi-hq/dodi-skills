#!/usr/bin/env bash
# Post the tick's daily heartbeat — the dead-man's switch. If the target is a
# ticket id, posts a PM comment; if it is a writable file path, appends a line.
# The *absence* of the heartbeat is the signal that the substrate died.
#
# Usage: heartbeat.sh <ticket-id-or-file-path> [note]
# Exit: 0 posted; 2 error.
set -euo pipefail

target="${1:?usage: heartbeat.sh <ticket-id-or-file-path> [note]}"
note="${2:-tick alive}"
host="$(hostname -s)"
line="heartbeat $(date -u +%Y-%m-%dT%H:%M:%SZ) host=$host $note"

if [[ "$target" == */* || -f "$target" ]]; then
  printf '%s\n' "$line" >>"$target"
  echo "heartbeat appended to $target"
else
  source "$(dirname "$0")/linear-api.sh"
  resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id } }' "{\"id\": \"$target\"}")"
  uuid="$(RESP="$resp" python3 -c 'import json,os; print(json.loads(os.environ["RESP"])["data"]["issue"]["id"])')"
  vars="$(python3 -c 'import json,sys; print(json.dumps({"input": {"issueId": sys.argv[1], "body": sys.argv[2]}}))' "$uuid" "$line")"
  linear_gql 'mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success } }' "$vars" >/dev/null
  echo "heartbeat posted to $target"
fi
