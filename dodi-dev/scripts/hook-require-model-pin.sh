#!/usr/bin/env bash
# PreToolUse hook (matcher: Task|Agent) — dispatch-pin enforcement.
#
# Two checks, both from AGENTS.md § Dispatch Discipline:
#
#   1. PIN PRESENCE. Rejects any subagent dispatch without an explicit `model`
#      parameter: an unpinned dispatch silently inherits the session model,
#      which in spec/plan sessions is Frontier — a defect, not a default.
#
#   2. TIER FIT. Rejects a mechanical-shape dispatch (test/suite runs, local
#      CI, state readers, evidence checkers, branch/worktree creation) pinned
#      above Standard. Presence alone cannot catch a blanket `model: opus` over
#      a whole lane — the observed failure mode, where test runners ran at
#      review tier. A deliberate escalation declares itself with
#      `tier-justified: <reason>` in the dispatch prompt.
#
# Shape matching reads the dispatch `description` only (the short purposeful
# label), never the prompt body — a reviewer prompt that happens to mention
# running tests must not trip the guard.
#
# Escape hatches: DODI_ALLOW_UNPINNED=1 (both checks); `tier-justified:` in the
# prompt or description (tier-fit check only).
set -uo pipefail

if [[ "${DODI_ALLOW_UNPINNED:-0}" == "1" ]]; then
  exit 0
fi

input="$(cat)"

verdict="$(HOOK_IN="$input" python3 <<'PY' 2>/dev/null
import json, os, re, sys

try:
    d = json.loads(os.environ["HOOK_IN"])
except Exception:
    print("SKIP"); sys.exit(0)

# Dual-payload contract: Claude Code sends tool_input, Grok Build sends toolInput.
ti = d.get("tool_input") or d.get("toolInput") or {}
model = (ti.get("model") or "").strip()
if not model:
    print("UNPINNED"); sys.exit(0)

desc = str(ti.get("description") or "")
prompt = str(ti.get("prompt") or "")

# Declared escalation — never silent, same posture as a fable substitution.
if re.search(r"tier-justified\s*:", desc + "\n" + prompt, re.I):
    print("OK"); sys.exit(0)

# Tier rank from the Claude aliases. Unknown slugs (e.g. the Grok grok-4.6 slug,
# where every tier is one model) skip the fit check: only presence is checkable.
m = model.lower()
rank = None
for alias, r in (("haiku", 1), ("sonnet", 2), ("opus", 3), ("fable", 4)):
    if alias in m:
        rank = r
        break
if rank is None or rank <= 2:
    print("OK"); sys.exit(0)

# Judgment-bearing shapes: never mechanical regardless of wording overlap.
# Whole words only, inflections listed explicitly — a suffix wildcard would
# swallow module names ("designer" under design, "fixtures" under fix).
JUDGMENT = (
    r"\b(review|reviews|reviewer|reviewing|implement|implements|implementing"
    r"|implementation|implementer|fix|fixes|fixing|draft|drafts|drafting"
    r"|drafter|plan|plans|planning|planner|audit|audits|auditing|triage"
    r"|investigate|investigating|investigation|coherence|spec|specs"
    r"|docs-sync|judgment)\b"
)
if re.search(JUDGMENT, desc, re.I):
    print("OK"); sys.exit(0)

# "spec" is deliberately absent below: in this repo it means specification far
# more often than test-spec, and the judgment list already claims it.
MECHANICAL = (
    r"test[-_ ]?runner"
    r"|state[-_ ]?reader"
    r"|evidence[-_ ]?check"
    r"|local[-_ ]?ci"
    r"|\b(run|execute|rerun|re-run)\b.{0,50}?\b(tests?|suite)\b"
    r"|\b(create|set ?up|make)\b.{0,30}?\b(branch|worktree)\b"
)
if re.search(MECHANICAL, desc, re.I):
    print("MISFIT")
else:
    print("OK")
PY
)" || exit 0

case "$verdict" in
  UNPINNED)
    echo "BLOCKED by dodi-dev dispatch-pin guard: this Agent dispatch has no explicit 'model' parameter. An unpinned dispatch inherits the session model — a defect, not a default. Pin by capability: fable = spec/plan drafting+review and final review rounds; opus = per-round code/PR review + implementers/fix workers on needs-capable-delivery tickets; sonnet = writing code (implementers), tests, research digests, orchestration routing; haiku = git mechanics, test runners, state digests. Add the pin and retry. (Escape hatch for non-dodi work: DODI_ALLOW_UNPINNED=1.)" >&2
    exit 2
    ;;
  MISFIT)
    echo "BLOCKED by dodi-dev tier-fit guard: this dispatch reads as mechanical work (test/suite run, local CI, state read, evidence check, or branch/worktree creation) but is pinned above the Standard tier. Mechanics belong at haiku — zero-variance beats frontier intelligence here, and blanket-pinning a whole lane at opus is the observed way a delivery lane ends up running its test runners at review tier. Note that 'needs-capable-delivery' routes implementers and fix workers only; it never escalates runners or git mechanics. Re-pin as 'haiku', or — if the escalation is deliberate — put 'tier-justified: <reason>' in the dispatch prompt and retry. (Escape hatch for non-dodi work: DODI_ALLOW_UNPINNED=1.)" >&2
    exit 2
    ;;
esac

exit 0
