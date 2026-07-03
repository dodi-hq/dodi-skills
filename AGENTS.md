# dodi-skills - Codex Instructions

## Project Shape

- This repository publishes Dodi developer workflow skills.
- There is one canonical skill tree, `dodi-dev/skills/*/SKILL.md`, served to both runtimes.
- The plugin directory `dodi-dev/` carries two metadata envelopes: `.claude-plugin/plugin.json` (Claude Code) and `.codex-plugin/plugin.json` (Codex).
- Marketplace entries point at the same directory: `.claude-plugin/marketplace.json` (Claude) and `.agents/plugins/marketplace.json` (Codex), both with source `./dodi-dev`.
- There is no mirror tree. Never reintroduce a copied skill tree; drift is a release bug.

## Editing Rules

- Skills are harness-neutral: one SKILL.md must read correctly on both Claude Code and Codex.
- Write harness-specific mechanics (model aliases, Agent tool) as the Claude form plus the tier name, e.g. "Capable tier (`model: opus` on Claude Code)". Codex maps tiers per the table below.
- If a released skill changes, bump the version in all three metadata files in the same change.
- Preserve each skill's frontmatter with `name` and `description`.
- Keep workflow instructions concrete and command-oriented.
- Prefer adding supporting prompt files beside the owning skill when the prompt is too long for `SKILL.md`.
- Skills must never reference files that exist only in this repository (e.g. `docs/specs/...`); policy a skill needs at runtime ships inside the skill's own directory.

## Model Tiers

Every skill and worker dispatch declares a model tier. Two levers: `model:` in SKILL.md frontmatter (switches the main-loop model for the rest of the turn when the skill is invoked) and the Agent tool's `model` parameter (pinned directly in worker prompt templates so it is mechanical, not advisory).

| Tier | Claude alias | Used for |
|------|--------------|----------|
| Frontier | `fable` | Spec drafting/review, plan writing/review, the final pre-PR review round |
| Capable | `opus` | Per-round code review, PR review |
| Standard | `sonnet` | Orchestration routing, writing code, writing tests, fixing findings, PR bodies, failure triage, quality gate, research digests (API docs, harness/codebase orientation) |
| Fast | `haiku` | Git mechanics, state classification, command/test runners, read-only state digests |

- Aliases only — never full model IDs; aliases track model upgrades.
- Aliases are Claude Code vocabulary. On Codex, map tiers to the closest local equivalents (Frontier/Capable → highest-reasoning configuration, Standard → default coding model, Fast → small fast model); a skill that names a Claude alias means that tier.
- Pick tiers by capability match, never by cost — the goal is intelligence-effectiveness; dollars and token counts fall where they fall. Use Frontier wherever judgment quality compounds downstream (specs, plans, review gates). Use lower tiers only where frontier intelligence adds nothing to the output (git mechanics, test execution, state digests) — they are faster and lower-latency, which is itself effectiveness.
- The review pipeline intentionally mixes tiers for reviewer diversity, not thrift: `opus` per-round and a fresh `fable` final gate have different failure modes, so the final round is a genuinely independent check rather than one more identical pass. When a task smells like judgment, escalate the tier — never economize on it.
- Judgment-heavy interactive skills (brainstorm, write-plan) omit `model:` and inherit the session model — run those sessions on the Frontier model. Mechanical interactive skills (pickup, file-ticket, submit) pin `sonnet`. In the autonomous epic lane, `mature-ticket`'s `fable` pin persists for the rest of the turn into the spec/plan work it chains into.
- Never set `CLAUDE_CODE_SUBAGENT_MODEL` on hive machines — it outranks every per-dispatch pin.

## Dispatch Discipline

The main loop is a router and conversation surface. Bulk reads, test runs, and evidence checks go to workers that return compact digests — for responsiveness in interactive skills, and for context longevity in autonomous epic runs (an orchestrator that reads raw diffs/logs/PM dumps compacts and loses state).

- Delegate any step that pulls more than ~200 lines of file/log/PM content into the main loop, or runs longer than ~1 minute.
- Every worker dispatch pins a model tier explicitly (the Agent tool's `model` parameter on Claude Code). A dispatch that omits the pin silently inherits the session model — in spec/plan sessions that is Frontier, which is a defect, not a default. Research and read-and-digest workers (external/integration API docs, local test-harness orientation, codebase exploration, prior-art lookups) pin `sonnet`: writing a trustworthy digest is comprehension work above the Fast tier, but the judgment about what the digest means stays in the Frontier main loop.
- Worker return contract: `STATUS` (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED, or Approved / Issues Found for reviewers) + `EVIDENCE` (commit ids, file paths, command + exit code, log path) + details capped at ~20 lines. No transcripts, no pasted logs.
- **Async-worker await contract.** Agent-tool workers launch asynchronously regardless of flags, and completion notifications do not reliably reach a session that is itself a subagent (a lane or a dispatched drafter). Never yield the turn to "wait" for a worker — a yielded turn with no notification is a stall. On Claude Code: poll the worker's `output_file` from inside a single long-timeout Bash call until the file's mtime has been stable for more than 60 seconds, then read only the final JSONL entries for the result — never the whole transcript (it overflows context). Sessions dispatched directly by the top-level harness may rely on completion notifications; sessions running as workers themselves must poll.
- Parallel dispatch for read-only workers (explorers, reviewers, evidence checkers) is always allowed. `deliver-ticket` lanes may run in parallel across independent children (no dependency edge, disjoint predicted file surfaces; when in doubt, serialize). Within a lane, implementers never run in parallel. Merges into the epic branch and PM state advances stay one at a time.

## Scannable Artifacts

Every human-facing artifact — specs, the Gate 1 signoff package, the epic readiness summary, notifications — leads with:

- `## TL;DR` — 2-3 sentences.
- `## Key Points` — 5-9 bullets: decisions, tradeoffs, in/out scope, risks; prefix delegated assumptions with ⚠.

The header must be self-sufficient: a human who reads nothing else can approve or redirect. Everything below is written for agents. Notifications carry only the header plus links. Spec reviewers treat a missing or stale header as a blocking finding.

## Deterministic Skeleton

**Anything with an invariant becomes code; anything with a judgment stays prose.** Mechanical operations ship as scripts in `dodi-dev/scripts/` (worker await, claims, dispatch eligibility, merge verification, branch cleanup, deploy checks, watchdog data, heartbeat) and as plugin hooks (Gate 2 merge guard, dispatch-pin enforcement).

**Path resolution:** scripts live at the **plugin root**, not under any skill directory. Skills reference them as `${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh` — the installed plugin root (a versioned directory under the plugin cache), two levels up from a skill's own directory. Never resolve a script path relative to the skill that names it.

- Skills **reference scripts, never restate their mechanics** — a skill re-describing a script's logic in prose is a review finding; that is how the layers diverge.
- A script outranks a Fast-tier worker for pure mechanics: zero-variance beats low-latency. Fast-tier workers remain for read-and-classify work that needs a model.
- A script failure with a clear cause is a result to act on; a script that cannot run (missing env, missing binary) is a concrete blocker — never improvise the mechanism inline.
- Hooks are Claude-Code-specific defense-in-depth; on Codex the prose rules plus server-side branch protection carry the same invariants.

## Decision Register

Each epic ticket is the master decision register for its epic. Coherence reviews append entry comments (verdict, decisions, affected children, keyed to the merge SHA) and maintain the **canon summary** (current canonical decisions, supersede chains collapsed) as a `## Decision Register — Canon` section of the **epic description** — PM systems like Linear have no comment pinning, and the description is always rendered at the top and API-writable. Spec drafters, plan writers, and lanes consume the canon section as required input; contradicting a canon decision is a review finding. Entry comments are append-only — supersede by reference, never edit history; only the canon section is maintained in place.

## Lights-Out Invariants

- **Healthy-quiet and stalled must never look the same.** Every guard label, claim, and relation is a new way to sit still silently; the janitor's watchdog, digest, and the tick's heartbeat exist to break that symmetry.
- **Failure-to-self-correct must always become a human ping.** Needs-human events go to the dedicated escalation channel with re-escalation on staleness — never only to routine run notifications.

## Scheduled Operation

Post-Gate-1 delivery runs as **scheduled ticks**, not resident sessions. `pickup-next` (the heartbeat) and `reconcile-tickets` (the janitor) each run as a harness-native scheduled task — never a hand-rolled cron/daemon wrapper around a headless CLI.

- Ticks are stateless: a fresh session per run, with the PM system and git as the only memory. Anything a run needs must be reconstructible from durable state.
- One action per tick. `pickup-next` advances exactly one ticket per run, then exits; the next tick picks up what's next. A no-op run is success.
- Claim discipline: a tick (or a manual orchestrator session) posts a claim comment before acting on a ticket, skips live claims from other hosts, and closes the claim with its exit state. A retry ceiling (default 3 consecutive failed/`RESUMABLE` attempts) converts loops into `blocked` + escalation.
- The janitor repairs state (merge/deploy transitions, stale claims, branch/worktree cleanup) but never advances work and never guesses — ambiguous evidence becomes an escalation comment.
- Gate 2 is procedural and absolute: no scheduled run merges, auto-merges, or enables auto-merge on an epic PR, regardless of permission mode.

## Context Hygiene

Long-running sessions compact deliberately — a deliberate compaction is a voluntary crash + resume against durable state, never a harness-forced mid-thought summary.

- A legal reset point passes the Resumability Test: a fresh session, given only durable state, would choose the same next action.
- Mandatory anchors: orchestrator after Gate 1 approval and after every child merge; lanes at the quality-gate→PR seam.
- Never reset mid-step; finish the step, write the continuation brief (state + evidence links, next action + why, live concerns, in-flight work that must not be redone), then reset.
- Soft observations (flaky tests, retried workers, fragile modules) are appended to notes as they occur — when unsure, write it down.

## Verification

- Run repository validation scripts:

  ```bash
  scripts/validate-plugin-metadata.sh
  scripts/validate-phase-skills.sh
  scripts/validate-ticket-comment-templates.sh
  ```

- Validate runtime templates when they change:

  ```bash
  python3 - <<'PY'
  import json
  from pathlib import Path
  for line in Path('templates/run-ledger/record.jsonl').read_text().splitlines():
      json.loads(line)
  print('jsonl ok')
  PY
  ```
