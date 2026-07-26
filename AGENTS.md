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
- Tag every release as `vX.Y.Z` on its version-bump commit and push the tag; keepur-team projects pin against these tags. Also include the bare version string (e.g. `0.16.0`) in the release commit message so releases stay findable with `git log --grep`.
- Preserve each skill's frontmatter with `name` and `description`.
- Keep workflow instructions concrete and command-oriented.
- Prefer adding supporting prompt files beside the owning skill when the prompt is too long for `SKILL.md`.
- Skills must never reference files that exist only in this repository (e.g. `docs/specs/...`); policy a skill needs at runtime ships inside the skill's own directory.

## Model Tiers

Every skill and worker dispatch declares a model tier. Two levers: `model:` in SKILL.md frontmatter (switches the main-loop model for the rest of the turn when the skill is invoked) and the Agent tool's `model` parameter (pinned directly in worker prompt templates so it is mechanical, not advisory).

| Tier | Claude alias | Used for |
|------|--------------|----------|
| Frontier | `fable` | Spec drafting/review, plan writing/review, the final pre-PR review round, the child-PR integration final (fable seats — each subject to the Fable Availability Policy below; a `deferred`/`soft` seat may run at a substituted tier, attributed) |
| Capable | `opus` | Per-round code review, PR review, integrated-head epic review, delivery (implementers + fix workers) on `needs-capable-delivery` tickets |
| Standard | `sonnet` | Orchestration routing, writing code, writing tests, fixing findings, PR bodies, failure triage, research digests (API docs, harness/codebase orientation) |
| Fast | `haiku` | Git mechanics, state classification, command/test runners, read-only state digests |

- Aliases only — never full model IDs; aliases track model upgrades.
- Aliases are Claude Code vocabulary. On Codex, map tiers to the closest local equivalents (Frontier/Capable → highest-reasoning configuration, Standard → default coding model, Fast → small fast model); a skill that names a Claude alias means that tier.
- Pick tiers by capability match, never by cost — the goal is intelligence-effectiveness; dollars and token counts fall where they fall. Use Frontier wherever judgment quality compounds downstream (specs, plans, review gates). Use lower tiers only where frontier intelligence adds nothing to the output (git mechanics, test execution, state digests) — they are faster and lower-latency, which is itself effectiveness.
- The review pipeline intentionally mixes tiers for reviewer diversity, not thrift: `opus` per-round and a fresh `fable` final gate have different failure modes, so the final round is a genuinely independent check rather than one more identical pass. The delivery lane runs two `fable` rounds per ticket with deliberately diverse aims — the pre-PR final judges the full gate, the child-PR integration final judges the integration delta — and seam-only material still sees both tiers (`opus` integration round + `fable` integration final). (This two-`fable`-rounds invariant holds unconditionally only where each gate's fable-policy is **hard**; under a `deferred`/`soft` substitution a round may run at `opus`, the declared and attributed exception — see § Fable Availability Policy.) When a task smells like judgment, escalate the tier — never economize on it.
- Every posted review-evidence finding carries `caught-by: <gate>/<round>/<tier>` — grammar and tagging surfaces are pinned in the `review` skill (§ Catch Attribution); per-gate catch rates are grep-aggregatable from PM comments. Each looped in-lane review gate additionally closes with a `gate-ledger:` line — rounds-to-clean, per-round blocking/advisory counts, closing tier — and demotion comments carry a `rework-origin:` trace (`review` § Gate Ledger), so review-loop depth is tuned from evidence, not argued.
- **Per-ticket delivery-tier routing (`needs-capable-delivery`):** the plan reviewer classifies every plan's delivery tier (standard | capable) as a required output; `mature-ticket` applies the label alongside `ready-to-implement`. A labeled ticket pins **every implementer and fix worker** in its delivery lane at `opus` — no per-task demotion: on invariant-dense tickets (concurrency/locking protocols, distributed-state reconciliation, ordering/idempotence invariants, cross-component state machines) the Standard tier reliably gets the structure right and misses the invariants, so the bugs live in tasks that look structural. Escalation is pre-routed at plan review, never improvised mid-lane; a mid-flight judgment surprise still demotes to the spec lane. The review pipeline is unchanged either way, preserving the invariant that **the final gate is a different model from the writer** (the writer is never `fable`) — which holds unconditionally only for **hard**-policy gates; under a `deferred`/`soft` substitution the effective final-gate tier may equal the writer's (e.g. a `needs-capable-delivery` ticket's `opus` writer reviewed by an `opus`-substituted pre-PR final), the declared exception the `tier-degraded` marker records, never a silent violation.
- Judgment-heavy interactive skills (brainstorm, write-plan) omit `model:` and inherit the session model — run those sessions on the Frontier model. Mechanical interactive skills (pickup, file-ticket, submit) pin `sonnet`. The manual `mature-ticket` wrapper's `fable` frontmatter pin covers its own main loop only; in the autonomous epic lane the driver walks `lanes/mature-playbook.md` natively and looks up each dispatch's tier per the gate-policy table (§ Fable Availability Policy).
- Never set `CLAUDE_CODE_SUBAGENT_MODEL` on hive machines — it outranks every per-dispatch pin.

## Fable Availability Policy

Fable (Frontier) tokens are scarce; every fable-seated gate pre-declares how scarcity is handled — never a silent downgrade, never improvised mid-lane. Policy is **per-gate** (the tier table above is tier-keyed; this table is gate-keyed). Skills reference this table the way they reference tier pins; the executing session performs the lookup immediately before writing a dispatch's pin (`epic-orchestrator/execution-model.md` § 2).

| Policy | Meaning | Gates |
|--------|---------|-------|
| **hard** | park-and-wait; no substitution ever | spec authoring (drafter); the **final** spec-review round; coherence checks; the capable-tier child-PR final round (`needs-capable-delivery` tickets); the fable make-up round itself (hard by construction — the debt collector cannot be substituted, else deferred collapses to soft); and the epic docs-sync sweep in `submit-epic-pr` (last docs look before Gate 2 — module docs are canon for every future session) |
| **deferred** | `opus` substitutes now; a fable make-up is queued as a durable obligation, batched at the dedicated make-up round in `submit-epic-pr` | the standard-tier child-PR final round; the pre-PR final round (all tiers — the child-PR gate still guards the merge, hard on capable tier); plan writing; the **final** plan-review round |
| **soft** | `opus` substitutes; no make-up | the **non-final** spec-review and plan-review rounds; post-clean-pass confirmation sweeps; Gate 1 package drafting (the human reads the package at signoff — the human gate is the catch); and the child docs-sync step in `submit-ticket-pr` (the epic docs-sync sweep is the backstop) |

A fable seat without a row is a defect. Focused post-fix re-rounds inherit their gate's policy (the child-PR post-fix re-round is hard on capable-tier, deferred on standard-tier — it establishes gate-clean). The deliberate asymmetry — spec-review final **hard**, plan-review final **deferred** — is because the spec is the canon everything downstream consumes, while plan defects still face the pre-PR/child-PR review chain and the make-up round's consequence surface.

**Mechanics:**

- **Detection:** fable unavailability is detected at dispatch time — a dispatch failure matching a capacity/tier-unavailable signature, then bounded retry (2 retries, spaced), then the policy applies. Never guessed in advance.
- **hard → `pending-capacity` park:** epic label `pending-capacity` + a `Kind: CAPACITY_PARK` register entry recording gate, ticket, and the exact blocked dispatch; the driver exits via the park protocol. Unlike pending-human it has a **wake edge** — the guard probes for capacity return and reboots (`drive-epic` Step 0). A mid-lane park resumes the lane from its durable seams (`execution-model.md` § 5 — now shared by both lanes, since two of the hard gates, spec authoring and the final spec-review round, live in the mature lane). Persistent capacity flapping is counted by the standard retry ceiling → `blocked` + escalation, so an epic never loops park↔probe forever. Manual (non-driver) lane sessions do not park — they stop and report to the operator, who is present by definition.
- **deferred → substitute + queue:** dispatch the same worker prompt pinned `opus`; record a `Kind: FABLE_MAKEUP` obligation keyed by gate + merge SHA (or ticket id pre-merge) naming what fable must re-review — for review gates the original scope, for plan writing/review the consequence surface (the affected child's merged diff, since re-reviewing a consumed plan post-implementation has no value). Consumed at the make-up round in `submit-epic-pr`.
- **soft → substitute, record only:** no obligation queued.
- **Attribution (never silent):** every substitution extends the catch-attribution line with a `tier-degraded(fable→<tier>,<policy>)` marker (`review` § Catch Attribution). No gate is ever clean by silence; the marker feeds evidence-based reclassification of these bucket assignments.
- **Hook interplay:** `hook-require-model-pin.sh` is unchanged — a substitution still carries an explicit pin (`model: opus`); the policy check happens in skill prose immediately before the pin is written.

## Dispatch Discipline

The main loop is a router and conversation surface. Bulk reads, test runs, and evidence checks go to workers that return compact digests — for responsiveness in interactive skills, and for context longevity in autonomous epic runs (an orchestrator that reads raw diffs/logs/PM dumps compacts and loses state).

- Delegate any step that pulls more than ~200 lines of file/log/PM content into the main loop, or runs longer than ~1 minute.
- Every worker dispatch pins a model tier explicitly (the Agent tool's `model` parameter on Claude Code). A dispatch that omits the pin silently inherits the session model — in spec/plan sessions that is Frontier, which is a defect, not a default. Research and read-and-digest workers (external/integration API docs, local test-harness orientation, codebase exploration, prior-art lookups) pin `sonnet`: writing a trustworthy digest is comprehension work above the Fast tier, but the judgment about what the digest means stays in the Frontier main loop.
- Worker return contract: `STATUS` (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED, or Approved / Issues Found for reviewers) + `EVIDENCE` (commit ids, file paths, command + exit code, log path) + details capped at ~20 lines. No transcripts, no pasted logs.
- **Leaf-worker dispatch contract (verified 2026-07-05).** Agent-tool workers launch asynchronously regardless of flags — no blocking dispatch mode exists — and completion wake-ups reliably reach only the top-level session: a session that is itself a subagent and ends its turn with a child in flight is **never re-invoked**; the child's completion routes to the top-level session instead. Therefore **only the top-level session dispatches workers** (the resident driver, a scheduled janitor or guard run, or an interactive main loop), and **every dispatched worker is a leaf** — it does its work directly, never dispatches sub-agents, and ends by writing its digest, which returns to the dispatcher as the Agent tool result (never SendMessage). `await-worker.sh` remains the top-level dispatcher's content-based backstop (final-lines terminal-record check, STALLED on stall, chunk-bounded); it is not a license for nested dispatch — in-turn polling is the only way a nested dispatcher survives, nothing can enforce it, and the field failure rate of relying on it was 5/5.
- Parallel dispatch for read-only workers (explorers, reviewers, evidence checkers) is always allowed. `deliver-ticket` playbooks execute inline in the top-level session and therefore serially (one lane in flight; parallel lane dispatch remains a future release — `epic-orchestrator/execution-model.md` §7 pins the isolation invariants it must preserve). Within a playbook, implementers never run in parallel. Merges into the epic branch and PM state advances stay one at a time.

## Scannable Artifacts

Every human-facing artifact — specs, the Gate 1 signoff package, the epic readiness summary, notifications — leads with:

- `## TL;DR` — 2-3 sentences.
- `## Key Points` — 5-9 bullets: decisions, tradeoffs, in/out scope, risks; prefix delegated assumptions with ⚠.

The header must be self-sufficient: a human who reads nothing else can approve or redirect. Everything below is written for agents. Notifications carry only the header plus links. Spec reviewers treat a missing or stale header as a blocking finding.

## Deterministic Skeleton

**Anything with an invariant becomes code; anything with a judgment stays prose.** Mechanical operations ship as scripts in `dodi-dev/scripts/` (worker await, claims, driver claims, comment-species classification, worker reaping, dispatch eligibility, merge verification, branch cleanup, deploy checks, watchdog data, heartbeat) and as plugin hooks (Gate 2 merge guard, dispatch-pin enforcement).

**Path resolution:** scripts live at the **plugin root**, not under any skill directory. Skills reference them as `${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh` — the installed plugin root (a versioned directory under the plugin cache), two levels up from a skill's own directory. Never resolve a script path relative to the skill that names it.

- Skills **reference scripts, never restate their mechanics** — a skill re-describing a script's logic in prose is a review finding; that is how the layers diverge.
- A script outranks a Fast-tier worker for pure mechanics: zero-variance beats low-latency. Fast-tier workers remain for read-and-classify work that needs a model.
- A script failure with a clear cause is a result to act on; a script that cannot run (missing env, missing binary) is a concrete blocker — never improvise the mechanism inline.
- Hooks are Claude-Code-specific defense-in-depth; on Codex the prose rules plus server-side branch protection carry the same invariants.

## Decision Register

Each epic ticket is the master decision register for its epic. Coherence reviews append entry comments (verdict, decisions, affected children, keyed to the merge SHA) and maintain the **canon summary** (current canonical decisions, supersede chains collapsed) as a `## Decision Register — Canon` section of the **epic description** — PM systems like Linear have no comment pinning, and the description is always rendered at the top and API-writable. Spec drafters, plan writers, and lanes consume the canon section as required input; contradicting a canon decision is a review finding. Entry comments are append-only — supersede by reference, never edit history; only the canon section is maintained in place.

## Lights-Out Invariants

- **Healthy-quiet and stalled must never look the same.** Every guard label, claim, and relation is a new way to sit still silently; the janitor's watchdog, digest, and the driver's heartbeat exist to break that symmetry.
- **Failure-to-self-correct must always become a human ping.** Needs-human events go to the dedicated escalation channel with re-escalation on staleness — never only to routine run notifications. Pending-human **coherence rulings are delivered by invoking the `drive-epic` skill with the instruction `rule-coherence <sha> approve|reject|redirect`** — a session run (drive-epic's Step 0a parses that instruction into ruling mode), never a separate command and never a chat reply. (AGENTS.md is the cross-runtime doctrine carrier: the Slack ping governs outbound notification, this governs the answer surface — a session, not a chat reply.)

## Scheduled Operation

Post-Gate-1 delivery runs as a **resident driver** (`drive-epic`) — one long-lived orchestrator session per active epic, booted by a slow hourly liveness guard and advancing on completion events — with cron demoted to that guard plus the daily janitor (`reconcile-tickets`). Each runs as a harness-native scheduled task — never a hand-rolled cron/daemon wrapper around a headless CLI.

- The driver boots from durable state: it reconstructs the dependency graph and decision-register canon from the PM system and git — the only memory — then holds them in context for the run. Anything a run needs must be reconstructible from durable state.
- The driver runs a drive loop: select by the priority table, execute the selected lane playbook **inline** — dispatching each phase worker as its own leaf, never a nested lane subagent (per the leaf-worker dispatch contract, a nested lane strands at its first dispatch) — close out, re-select — advancing as many actions as fit before **park** (no automated action possible), **refresh-park** (planned, count-based context refresh), or **bloat** (context degraded).
- Claim discipline: the driver (or a manual orchestrator session) posts a claim comment before acting on a ticket, skips live claims from other **sessions** (session-scoped foreignness, driver-claim-topped liveness hierarchy), and closes the claim with its exit state. A retry ceiling (default 3 consecutive failed/`RESUMABLE` attempts) converts loops into `blocked` + escalation.
- The janitor repairs state (merge/deploy transitions, stale claims, branch/worktree cleanup) but never advances work and never guesses — ambiguous evidence becomes an escalation comment.
- Gate 2 is procedural and absolute: no scheduled run merges, auto-merges, or enables auto-merge on an epic PR, regardless of permission mode.
- Layering rule: **claims serialize tickets; worktrees serialize files; nothing serializes runs; the driver is the epic worktree's only writer** — leaf fix workers dispatched by the walking session write under its ownership (one supervising session still serializes all epic-worktree writes).

## Context Hygiene

Long-running sessions compact deliberately — a deliberate compaction is a voluntary crash + resume against durable state, never a harness-forced mid-thought summary.

- A legal reset point passes the Resumability Test: a fresh session, given only durable state, would choose the same next action.
- Mandatory anchors: orchestrator after Gate 1 approval; lanes at the verify→PR seam. In the resident driver, every durable lane-progress seam — each child-merge close-out, and each completion-anchored deliver checkpoint / mature state boundary — is a **durable-brief anchor point** (register + continuation brief kept current so a crash resumes from the latest seam, not a stale boot brief), not an *unplanned* reset. An actual context reset happens only at park, the *planned* refresh-park (itself a planned `RESUMABLE` exit at a durable seam — the one exception this close-out-≠-reset rule carves out), or bloat. (A mandatory *unplanned* reset per merge would recreate the one-action tick the resident model replaces.)
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
