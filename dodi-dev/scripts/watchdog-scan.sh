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
