#!/usr/bin/env bash
# Deploy signal: is a given epic merge commit deployed to production?
# Reads GitHub deployments + statuses; a commit counts as deployed when a
# production deployment whose SHA reaches it reports success.
#
# Usage: check-deploy.sh <epic-merge-sha> <environment> [repo-dir=.] [lookback=15]
# Exit: 0 deployed (prints deployment id + sha); 1 not yet deployed;
#       4 latest production deployment FAILED (escalate — details on stdout); 2 error.
set -euo pipefail

epic_sha="${1:?usage: check-deploy.sh <epic-merge-sha> <environment> [repo-dir] [lookback]}"
environment="${2:?usage: check-deploy.sh <epic-merge-sha> <environment> [repo-dir] [lookback]}"
repo_dir="${3:-.}"
lookback="${4:-15}"
cd "$repo_dir"

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
deployments="$(gh api "repos/$repo/deployments?environment=$environment&per_page=$lookback" \
  --jq '[.[] | {id, sha, created_at}]')"

count="$(DEP="$deployments" python3 -c 'import json,os; print(len(json.loads(os.environ["DEP"])))')"
if [[ "$count" == "0" ]]; then
  echo "check-deploy: no deployments found for environment=$environment"
  exit 1
fi

git fetch origin --quiet || true

latest_checked=""
for i in $(seq 0 $((count - 1))); do
  dep_id="$(DEP="$deployments" IDX="$i" python3 -c 'import json,os; print(json.loads(os.environ["DEP"])[int(os.environ["IDX"])]["id"])')"
  dep_sha="$(DEP="$deployments" IDX="$i" python3 -c 'import json,os; print(json.loads(os.environ["DEP"])[int(os.environ["IDX"])]["sha"])')"
  status="$(gh api "repos/$repo/deployments/$dep_id/statuses" --jq '.[0].state' 2>/dev/null || echo unknown)"
  [[ -z "$latest_checked" ]] && latest_checked="$status id=$dep_id sha=$dep_sha"
  if [[ "$status" == "success" ]]; then
    if git merge-base --is-ancestor "$epic_sha" "$dep_sha" 2>/dev/null; then
      echo "deployed: deployment=$dep_id sha=$dep_sha environment=$environment"
      exit 0
    fi
  fi
done

# Not deployed. If the most recent deployment failed, that is an escalation.
if [[ "$latest_checked" == failure* || "$latest_checked" == error* ]]; then
  echo "DEPLOY_FAILED: latest production deployment: $latest_checked"
  exit 4
fi
echo "check-deploy: $epic_sha not reachable from any successful $environment deployment (latest: $latest_checked)"
exit 1
