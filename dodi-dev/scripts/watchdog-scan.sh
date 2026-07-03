#!/usr/bin/env bash
# Stalled-epic watchdog data gatherer. Prints a per-child digest (state, labels,
# last update, open blockers) plus epic-level facts (coherence-pending, last
# activity) as TSV for the janitor to judge. This script gathers; it never judges.
#
# Usage: watchdog-scan.sh <epic-id>
# Exit: 0 digest printed; 2 error.
set -euo pipefail
source "$(dirname "$0")/linear-api.sh"

epic="${1:?usage: watchdog-scan.sh <epic-id>}"

resp="$(linear_gql 'query($id: String!) {
  issue(id: $id) {
    identifier updatedAt
    labels { nodes { name } }
    children(first: 100) {
      nodes {
        identifier updatedAt
        state { name type }
        labels { nodes { name } }
        inverseRelations { nodes { type issue { identifier state { type } } } }
      }
    }
  }
}' "{\"id\": \"$epic\"}")"

RESP="$resp" python3 <<'PY'
import json, os
epic = json.loads(os.environ["RESP"])["data"]["issue"]
epic_labels = ",".join(sorted(l["name"] for l in epic["labels"]["nodes"])) or "-"
print(f"EPIC\t{epic['identifier']}\t{epic['updatedAt']}\t{epic_labels}")
for c in epic["children"]["nodes"]:
    labels = ",".join(sorted(l["name"] for l in c["labels"]["nodes"])) or "-"
    blockers = ",".join(r["issue"]["identifier"] for r in c["inverseRelations"]["nodes"]
                        if r["type"] == "blocks" and r["issue"]["state"]["type"] not in ("completed", "canceled")) or "-"
    print(f"CHILD\t{c['identifier']}\t{c['updatedAt']}\t{c['state']['type']}:{c['state']['name']}\t{labels}\t{blockers}")
PY
