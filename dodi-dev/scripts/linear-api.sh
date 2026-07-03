#!/usr/bin/env bash
# Shared Linear GraphQL helper. Source this, or call directly:
#   linear-api.sh '<graphql-query>' ['<variables-json>']
# Requires LINEAR_API_KEY. Prints the JSON response body; exits 2 on transport
# or GraphQL errors (error details on stderr).
set -euo pipefail

linear_gql() {
  local query="$1"
  local variables="${2:-{\}}"
  if [[ -z "${LINEAR_API_KEY:-}" ]]; then
    echo "linear-api: LINEAR_API_KEY is not set — concrete blocker, do not improvise PM writes" >&2
    return 2
  fi
  local payload response
  payload="$(python3 -c 'import json,sys; print(json.dumps({"query": sys.argv[1], "variables": json.loads(sys.argv[2])}))' "$query" "$variables")"
  response="$(curl -sS --fail-with-body -X POST https://api.linear.app/graphql \
    -H "Authorization: ${LINEAR_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "$payload")" || { echo "linear-api: transport error" >&2; return 2; }
  if python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); sys.exit(0 if "errors" not in d else 1)' <<<"$response"; then
    printf '%s\n' "$response"
  else
    echo "linear-api: GraphQL errors:" >&2
    printf '%s\n' "$response" >&2
    return 2
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  linear_gql "$@"
fi
