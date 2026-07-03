# Epic Coherence Gate & Deterministic Skeleton Implementation Plan

> **For agentic workers:** Execute tasks in order. Single tree — skills under `dodi-dev/skills/`, plugin scripts under `dodi-dev/scripts/`, hooks under `dodi-dev/hooks/`.

**Goal:** Ship 0.13.0: the deterministic skeleton (plugin scripts + PreToolUse hooks), the epic-coherence gate at the post-merge seam, the decision register on the epic ticket, native PM dependency relations, and the lights-out hardening package.

**Spec:** `docs/specs/2026-07-03-epic-coherence-gate-design.md`

**Testing Contract (repo-native):** the three validation scripts (extended in task 9) are the regression suite; additionally every new shell script must pass `bash -n` and be executable, hook scripts must behave correctly on synthetic stdin, and `await-worker.sh` gets a live filesystem smoke test. All must pass after every task.

## Tasks

1. **Skeleton scripts** (`dodi-dev/scripts/`): `linear-api.sh` (shared GraphQL curl helper, requires `LINEAR_API_KEY`), `await-worker.sh` (mtime-stable >60s poll, tail final JSONL entries), `claim.sh`/`release-claim.sh` (claim comment with progress-based liveness), `dispatch-eligible.sh` (labels ∧ no open blockers ∧ epic not coherence-pending), `verify-merge.sh` (PR MERGED + merge commit reachable), `cleanup-branch.sh` (SHA-reachability check → remote delete → worktree remove → local delete), `check-deploy.sh` (production deployment status + ancestor check), `watchdog-scan.sh` (per-epic staleness + dispatchability data for the janitor to judge), `heartbeat.sh`. Deterministic data + hard postconditions only; judgment stays with the calling skill.
2. **Hooks** (`dodi-dev/hooks/hooks.json` + `dodi-dev/scripts/hook-gate2-guard.sh`, `hook-require-model-pin.sh`): PreToolUse on Bash blocks `gh pr merge` targeting main/master (fail closed if base cannot be determined); PreToolUse on Task/Agent rejects dispatches without an explicit `model` (env escape hatch `DODI_ALLOW_UNPINNED=1`).
3. **Coherence reviewer** (`epic-orchestrator/coherence-reviewer-prompt.md`, fable): alignment-only review, adversarial framing, cumulative drift vs Gate 1, verdicts + affected children + register entries, GATE1_AMENDMENT flag, idempotent writes keyed to merge SHA.
4. **pickup-next**: coherence-pending action (priority 2) + dispatch blocks; eligibility via `dispatch-eligible.sh`; claim via `claim.sh`/`release-claim.sh` with progress-based semantics replacing age/count rules; heartbeat close-out; merge close-out marks coherence-pending; script references replace restated mechanics.
5. **epic-orchestrator + state tables**: merge step gains the seam (merge close-out → coherence-pending; review clears it); `state-transitions.md` epic table gains the coherence row; merge mechanics reference `verify-merge.sh`/`cleanup-branch.sh`.
6. **Relations + register consumers**: `file-ticket` registers blocked-by relations at creation (epic decomposition mode); `assess-epic` verifies/repairs relations and treats the relation graph as canonical after Gate 1; `mature-ticket`/spec-drafter, `write-plan`/plan-writer, `deliver-ticket`, and lane-dispatch prompt gain the register canon summary as required input.
7. **submit-epic-pr + reconcile-tickets**: readiness summary gains mandatory "What Changed Since Signoff"; janitor gains relation hygiene, stalled-epic watchdog (via `watchdog-scan.sh`), daily "waiting on you" digest with re-escalation, deploy-failure and red/conflicted epic-PR detection (via `check-deploy.sh`), progress-based claim expiry (via scripts).
8. **Templates**: new `decision-register-entry.md`; `epic-pr-ready.md` gains the "What Changed Since Signoff" heading; both wired into the templates validator.
9. **AGENTS.md + validators**: AGENTS.md gains the skeleton rule (invariants → code, judgment → prose; scripts outrank Fast-tier workers for pure mechanics; reference-don't-restate), the register convention, and the two lights-out invariants; `validate-phase-skills.sh` gains coherence-reviewer-prompt, script existence/executability/`bash -n` checks, hooks.json parse check.
10. **Metadata bump** to `0.13.0` (three files) + full validation + local plugin update. Setup prerequisites (branch protection, escalation channel test, the two scheduled tasks) documented in the pickup-next/reconcile-tickets setup sections.
