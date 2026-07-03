# Autonomous Ticket Pickup & Linear Status Hygiene Design

## TL;DR

Retire the babysat `epic-orchestrator` session and replace it with a stateless `pickup-next` tick that runs as a **native Claude Code scheduled task**: each run queries Linear, advances exactly one actionable ticket through the existing lane skills, checkpoints, and exits. Close the post-merge gap with a `reconcile-tickets` janitor tick plus a PR↔ticket linking convention, so merge-to-master and production deploys automatically move tickets to their terminal states and clean up branches/worktrees. The human's two gates are unchanged; everything between them becomes heartbeat-driven and runs without anyone at a screen.

## Key Points

- **Leverage the harness, build nothing bespoke.** Claude Code desktop Scheduled Tasks provide the whole runtime: fresh self-contained session per run, cron schedule, per-task permission mode, no-overlap guarantee (next run waits for the previous), optional isolated worktree, desktop notifications. No launchd, no webhooks, no custom daemon. Cloud Routines are the later upgrade path (machine-off operation) once the test harness proves out in a fresh clone.
- **`pickup-next` (new skill, sonnet): one pass, one action, exit.** Query Linear → pick the single highest-priority actionable item per the state-transition tables → run the corresponding lane skill → checkpoint → exit. Linear is the *only* state; nothing survives between ticks except durable writes.
- **`epic-orchestrator` is demoted from resident supervisor to routing logic.** The state-transition tables and merge/evidence rules survive as the tick's routing contract; the long-lived while-loop session dies.
- **The tick only touches epics carrying `epic-signed-off`.** Everything before Gate 1 (intent, decomposition, key specs) stays interactive at the monitor with the human — exactly the PM work Mike wants to do in person. Gate 2 (epic PR merge) remains human-only, always.
- **Status hygiene closes the loop after Gate 2.** Today nothing updates Linear when the epic PR merges to main/master, and nothing cleans up after deploy. Fix: (1) a PR↔ticket linking convention (branch names + magic words) so Linear's native GitHub integration attaches PRs to tickets; (2) epic merge moves the epic and all children to **Merged/Done**; (3) a confirmed production deploy moves them to **Deployed/Released** and triggers branch + worktree cleanup.
- **`reconcile-tickets` (new skill, sonnet): the convergence janitor.** A second, less frequent scheduled task that compares Linear state against GitHub/git reality (PR states, merge commits, deploy signals, stale claims, expired lanes) and fixes drift with evidence-cited writes. Event-driven updates keep things fresh; the janitor guarantees eventual consistency and never invents state — ambiguity becomes an escalation comment, not a guess.
- **Crash safety and retries are explicit.** The tick writes a claim marker on pickup (crash visibility + future multi-machine), lanes keep their checkpoint/RESUMABLE contract, and a per-ticket retry ceiling (3 consecutive RESUMABLE/failed runs) converts loops into `blocked` + escalation instead of infinite spin.
- ⚠ **Deploy-detection is a configurable input, assumed available.** The design assumes some observable production-deploy signal (GitHub deployment status, release tag, or deploy-log endpoint). Which signal exists in Mike's pipeline must be confirmed per-repo before the deploy-cleanup leg activates.
- **Start serial, scale deliberately.** One tick task, one action per run — effectively `maxParallelLanes=1` — until trial data justifies more. Parallelism later means a second scheduled task or dispatching lanes as background agent sessions, not a smarter tick.

---

## Motivation

The 0.11.x architecture already externalized state: transition tables route on Linear labels, lanes checkpoint every boundary, RESUMABLE exits make any session disposable. But the component that *reads* the state and *decides what's next* is still a long-lived interactive session that must stay open, fights context exhaustion, and uses the human as its failure handler. The result: even with two-gate autonomy, someone babysits the loop.

Meanwhile the harness itself has grown first-class support for exactly this shape of work — scheduled tasks with fresh sessions, configurable permissions, and no-overlap semantics. The correct move is to stop treating orchestration as a session and start treating it as a scheduled, stateless tick.

## Scheduling Substrate

**Phase 1 — Desktop Scheduled Task** (ships with this design):

| Property | Value |
| --- | --- |
| Trigger | cron, every ~15 minutes (off-peak minute, e.g. `*/15` offset) |
| Session | fresh per run, prompt is a thin invocation of `dodi-dev:pickup-next` |
| Permission mode | per-task (Auto), respecting the settings allow-list; never grants merge of the epic PR (Gate 2 is procedural, not permission-based) |
| Overlap | harness-guaranteed: next run waits for the previous — ticks are serial by construction on one machine |
| Isolation | worktree-per-run for the tick session itself; lane skills manage their own child worktrees as today |
| Constraint | runs only while the desktop app is open and the machine is awake — acceptable for hive machines |

**Phase 2 — Cloud Routine** (follow-up, out of scope here): same skill, Anthropic-hosted, machine-off operation, 1-hour minimum interval, fresh GitHub clone per run. Gating question: does the repo's Testing Contract harness run in a fresh clone with no local services? Evaluate after the Phase 1 trial.

Rejected alternatives: hand-rolled launchd/cron + `claude -p` (duplicates the harness feature with worse permissions and no UI); Linear webhooks (inbound-endpoint complexity for no latency benefit at this scale); keeping a resident orchestrator with in-session `/loop` (still session-bound, still babysat).

## `pickup-next` Skill Contract

`model: sonnet` — the tick is table-lookup routing; judgment lives inside the lane skills it invokes, which carry their own tier pins per the 0.11.1 dispatch rules.

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| scheduled tick (or manual run) | Linear team/project scope, repo path(s), retry ceiling | one advanced ticket or a clean no-op | claim marker, lane checkpoints (via lane skills), escalation comments | the lane skills (`mature-ticket`, `deliver-ticket`, merge step, `submit-epic-pr`) | PM unreachable, no actionable work (benign), retry ceiling hit, claim conflict |

Algorithm, one pass:

1. **Scan** Linear for epics carrying `epic-signed-off` that are not `epic-pr-open`-and-waiting; skip everything else (pre-Gate-1 epics are human territory).
2. **Select one action** by priority (highest first):
   1. Merge a `ready-to-merge-child` (serial merge slot, evidence-checker rules unchanged).
   2. Run `submit-epic-pr` if all children of an epic are done and no epic PR is open.
   3. Resume a lane that exited RESUMABLE (retry counter below ceiling).
   4. Dispatch `deliver-ticket` for a `ready-to-implement` child with dependencies clear.
   5. Run `mature-ticket` for a child lacking `spec-ready`/`ready-to-implement`.
3. **Claim**: post a claim comment on the chosen ticket (`claimed-by: <host> at <timestamp>, action: <lane>`) before acting. A live unexpired claim by another host skips the ticket.
4. **Act**: run the selected lane skill to its natural exit (checkpoint contract unchanged).
5. **Close out**: update the claim with the exit state; on stop conditions post the scannable escalation comment; exit. Nothing ready → log a one-line no-op and exit silently.

Retry ceiling: the claim comment carries a consecutive-attempt counter per ticket+action. Three consecutive RESUMABLE/failed attempts → mark `blocked`, post an escalation comment with the trail, stop retrying until a human or the janitor clears it.

Escalation path: stop conditions (`QUESTIONS_FOR_HUMAN`, demote-to-spec, blocked, retry ceiling) post the scannable header comment on the ticket as today; the run's terminal state surfaces via the harness (desktop notification + Scheduled section in the sidebar, visible remotely via claude.ai/code and the iOS app). No custom notification plumbing in this release; a Slack ping is a follow-up if the built-in path proves too quiet.

## Linear Status Hygiene: Closing the Merge→Deploy Loop

### The gap

Child merges into the epic branch are tracked (orchestrator-owned `done` transitions). But: nothing updates Linear when the **epic PR merges to main/master** (Gate 2, human-performed, so no agent session is present to record it), and nothing reacts when the merged commit **deploys to production**. Tickets rot in stale states; branches and worktrees accumulate.

### Design

**1. PR↔ticket linking convention (prerequisite, zero-build).** Every branch and PR ties to its ticket so Linear's native GitHub integration attaches PR state to tickets automatically:

- Child branches: `<user>/<TICKET-ID>-<slug>` (Linear's branch-name format); `pickup-ticket` already names branches — align its format.
- PR bodies: magic-word reference (`Closes DODI-123` for children against the epic branch is **not** used — children close on epic merge, not child merge; use non-closing `Part of DODI-123` instead). The epic PR body lists `Closes <epic-id>` plus each child id.

**2. Merge transition (epic PR → main/master).** When Gate 2 happens, the epic and all its children move to **Merged** (or the team's Done state). Mechanism, in order of preference: Linear's GitHub integration auto-transition on PR merge where its rules can express it; the `reconcile-tickets` janitor as the guaranteed backstop (it sees the merged epic PR and cites the merge commit in its transition comment).

**3. Deploy transition + cleanup (production).** ⚠ Assumes a deploy signal exists (see Key Points). When the janitor observes that a merged epic commit is confirmed deployed:

- Move the epic and children **Merged → Deployed/Released** (team-configurable state name; a `deployed` label if the workflow has no such state).
- Delete the epic branch and any surviving child branches (children normally delete at child-merge).
- Prune local worktrees for those branches on the machine the janitor runs on.
- Post a one-line deploy-confirmation comment on the epic citing the deploy signal.

### `reconcile-tickets` Skill Contract

`model: sonnet`. Runs as its own scheduled task (hourly-ish; also invocable manually). One sweep per run:

| Check | Drift detected | Action |
| --- | --- | --- |
| Ticket in delivering/ready-to-merge states | its PR merged or closed | advance or flag per transition tables, cite PR/commit |
| Epic `epic-pr-open` | epic PR merged (Gate 2 happened) | epic + children → Merged, cite merge commit |
| Merged epic | deploy signal confirms production | → Deployed/Released; branch + worktree cleanup |
| Claim comment | older than lease (default 2h) with no live checkpoint progress | clear the claim, restore ticket to its pre-claim state, note the expiry |
| `blocked` from retry ceiling | referenced blocker demonstrably resolved (e.g. dependency merged) | clear `blocked`, reset counter, comment why |
| Anything ambiguous | evidence conflicts or is missing | **never guess** — post an escalation comment describing the conflict |

Janitor rules: every write cites its evidence (PR link, merge SHA, deploy id); it repairs state, it never advances work (it does not dispatch lanes — that is the tick's job); destructive actions are limited to deleting **merged** branches and their worktrees, verified merged by SHA reachability from main/master, never by name.

## Out of Scope

- Cloud Routine migration mechanics (Phase 2) — separate follow-up after the desktop trial; gated on harness-in-fresh-clone.
- Multi-machine claim arbitration beyond the timestamp lease — revisit when a second hive machine actually joins the queue.
- CI-failure triage on the epic PR (`babysit-epic-pr`) and richer post-merge verification — the devops leg remains its own future release; the janitor only does status/cleanup, not diagnosis.
- `decompose-epic` and any pre-Gate-1 automation — deliberately human, per the two-gate philosophy.
- Custom notification channels (Slack/email) — built-in harness notifications first; add only if proven insufficient.

## Versioning

Ships as `0.12.0`: new `pickup-next` and `reconcile-tickets` skills, `epic-orchestrator` demoted to routing documentation consumed by the tick (transition tables retained verbatim), branch/PR linking convention added to `pickup-ticket` and `submit-ticket-pr`/`submit-epic-pr`, scheduled-task setup instructions in the plugin README.
