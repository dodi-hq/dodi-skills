---
name: drive-epic
description: Use as the resident driver — one long-lived orchestrator session per active epic that boots from durable state, holds the dependency graph and decision-register canon in context, dispatches lanes, and advances on completion events until park or bloat. Also the session-delivered coherence-ruling mode.
model: sonnet
---

# Drive Epic

The resident driver. One long-lived session per active epic. It absorbs `pickup-next`'s machinery and replaces its trigger model: instead of a fresh session per clock tick, one session boots from durable PM/git state, holds the dependency graph and decision-register canon in context, executes lane playbooks **inline and serially** (one in flight at a time; never as nested lane subagents — 0.14.1 leaf-worker contract), and advances on **completion events** — until **park** (no automated action possible) or **bloat** (context degraded). Cron survives only as a slow liveness guard (this skill's step 0) and the daily janitor (`reconcile-tickets`).

**Detect by content and event, never by clock or silence** — the principle that retires the tick and the same one `await-worker.sh` v2 enforces one level down.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| hourly liveness cron, or manual invocation | PM scope, repo path(s), heartbeat location, retry ceiling (default 3), optional humanContact | epic advanced through as many actions as fit before park/bloat, or a clean no-op | driver claim + refreshes, continuation brief, daily heartbeat, everything the lane playbooks write | lane playbooks (`mature-ticket`, `deliver-ticket`) executed **inline** with their phase workers dispatched as this session's own leaves; `submit-ticket-pr` Merge and `submit-epic-pr` inline; state-reader / evidence-checker leaf workers (checker conditional per the `epic-orchestrator` Evidence Rule — the driver's inline-walked lanes are the primary skip case) | PM unreachable, claim yield, retry ceiling, fence trip, tool/auth failure |

## Step 0a — parse the invocation (first step, before anything else)

This skill is invoked by running a session on it with an instruction string. **First, inspect that instruction.** If it begins with `rule-coherence` — i.e. the operator ran the drive-epic skill with the input `rule-coherence <merge-sha> approve|reject|redirect:<scope>` — parse `<merge-sha>` and the flag, then run the **Human-Ruling Resolution Route** (Ruling Mode) below and **stop** — do **not** fall through to the guard or the drive loop. Any other invocation (an epic id, "drive EPIC-123", a bare resume) is a normal driver run: proceed to Step 0 — the guard.

(There is no separate `rule-coherence` skill, command, or shell alias — the spec's intent is "no new skill; a drive-epic ruling mode reusing its claim/fence/routing." The operator delivers a ruling by invoking **this** skill with the `rule-coherence …` instruction; this parse step is the branch.)

## Ruling Mode

Reached when Step 0a parsed a `rule-coherence <merge-sha> approve|reject|redirect:<scope>` invocation. Run the **Human-Ruling Resolution Route** below instead of the guard + drive loop. The ruling mode reuses this skill's claim/fence/routing; it never enters the drive loop.

## Step 0 — the guard

1. **Daily heartbeat.** Post/refresh at the designated heartbeat location (`${CLAUDE_PLUGIN_ROOT}/scripts/heartbeat.sh <heartbeat-location>` — dedupe and update-in-place live in the script); optional mirror on the active epic. Posted on every guard path **and refreshed by the driver inside its own drive loop** — if the scheduler guarantees same-task no-overlap (see the live-test gate), the hourly guard cannot fire while a driver run is live, so a driver run crossing ~24h would otherwise starve the dead-man switch; the in-loop refresh closes that.
2. **Driver-claim check** (`${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh status <epic-id>`).
   - Fresh live claim → exit, one line logged. (A live driver owns the epic; do not interleave.)
   - Stale/absent + **actionable work** → `driver-claim.sh acquire <epic-id> <session-run-id>`; win → this session **becomes** the driver, proceed to Boot; lose → self-close and exit no-op.
   - **No actionable work** — including an epic parked on an unresolved pending-human entry — → exit; the janitor's digest owns the human reminder. The human resolves a pending-human park out-of-band by invoking this skill with a `rule-coherence …` instruction (a session, parsed by Step 0a — not a comment this guard must detect), so there is **no wake edge** here.
   - **Backstop:** an epic that is `coherence-pending` with the set-difference empty **and** no unresolved entry (a ruling session crashed between its `RULING` write and its in-session clear) *is* actionable — boot to evaluate the clear predicate — so a resolved-but-still-labeled epic never strands.
3. **Second signed-off epic in scope → escalate**, never interleave (single-active-epic posture).

Manual sessions run the identical step 0; per-ticket session claims enforce the same discipline for manual *lane* work.

(The wedged-driver probe is **not** a guard step — it re-homed to the daily janitor sweep, since under same-task no-overlap the hourly guard cannot fire against the live driver it would probe. See `reconcile-tickets`.)

## Boot

Once this session is the driver:

1. **Mint the run id** (already minted for the claim); **start the refresher.** Two build paths depending on whether session-pid capture can be pinned from the desk (this is itself coupled to **live-test-gate item 3** — the refresher's orphan detection must watch the *session* process, not the transient shell):
   - **Orphan-aware path (preferred, if the ancestry walk resolves a stable session process):** derive `<session-pid>` by walking the PPID chain up from `$$` (the current Bash shell is transient — `$$` is wrong on its own). The walk: starting at `$$`, repeatedly read `ps -o ppid=,comm= -p <pid>` and step to the parent, stopping at the first ancestor whose `comm` is the session/harness process (not `bash`/`sh`/the `Bash`-tool wrapper) — that ancestor is the wrapper's parent that **survives** a single Bash call and dies with the session. Capture it once at boot:
     ```bash
     session_pid="$$"
     while :; do
       read -r ppid comm < <(ps -o ppid=,comm= -p "$session_pid" 2>/dev/null | awk '{print $1, $2}')
       [[ -z "${ppid:-}" || "$ppid" -le 1 ]] && break
       case "$comm" in *bash|*sh|*zsh) session_pid="$ppid"; continue ;; esac
       session_pid="$ppid"; break
     done
     ```
     Then launch `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh refresh <epic-id> <session-run-id> "$session_pid"` as a background shell; it bumps the claim every ~15m and self-exits on that pid's disappearance/reparenting.
   - **Interim lease-only fallback (buildable now, no orphan self-exit):** if the ancestry walk cannot be confirmed to resolve the true session process from the desk (gate item 3 unverified), launch the refresher in **lease-only mode** — pass a sentinel `<session-pid>` of `0` (or omit orphan watching), so the refresher simply bumps `Refreshed at` every ~15m and never self-exits. A crashed session's claim then decays **by lease alone in ≤45m** — no worse than the per-ticket tier-3 lease behavior, and the takeover reap-before-release adopts it on the next guard hour. This keeps the driver shippable while item 3 is pending; the orphan-aware path is a strict improvement once the walk is confirmed live.

   The refresher's own subcommand supports both: with a real pid it watches PPID; with pid `0` it skips the orphan check and refreshes on the lease cadence only (see the refresh subcommand's pid-`0` branch).
2. **Coherence audit (set-difference).** Fetch all merged child PRs targeting the epic branch (`mergeCommit` oids — the surface `verify-merge.sh` reads, `--limit` above any plausible child count, paged-or-asserted) and all register-entry `Merge SHA:` keys from the epic (a **paged** read — comment-window honesty). **Every merged SHA must hold a register entry.** Any merged-but-unregistered SHA ⇒ treat the epic as `coherence-pending` and queue the review for the unregistered set, **oldest `mergedAt` first**. An unresolved pending-human entry parks the queue — no further reviews until the human resolves it via `rule-coherence`. No merged child PRs ⇒ pass; a stray `coherence-pending` with zero merged PRs clears vacuously.
3. **Takeover reap-before-release** (only if this boot took over a stale driver claim). **First post a one-line takeover note** — a `# Driver Claim`-adjacent bookkeeping comment on the epic (the "takeover/janitor notes" species `comment-species.sh` already classifies as bookkeeping) recording: this session's run id, the predecessor's run id + reaped-claim id (closed `taken-over` by the `acquire` stale-close), and the boot timestamp. This is the audit-trail line spec §41/§47 asks for — the durable "who took over from whom" record; keep it minimal (one line, no state-clock effect since it is bookkeeping). Then read the predecessor's dispatch manifest (per-session filename at the epic worktree's absolute path) and **reap/stop/confirm any non-terminal lane workers first** (`${CLAUDE_PLUGIN_ROOT}/scripts/reap-workers.sh <manifest>`, then stop stragglers via the agent-layer primitive and append reap records) — because whether an in-flight Agent-tool lane survives its dispatcher's death is a live-test-gate item, and re-dispatching beside a still-writing orphan is the concurrency hazard. **Only then** foreign-release (by id) the per-ticket claims bearing the predecessor's session id (`release-claim.sh <ticket> released-no-op --foreign <claim-id>`; the children scan uses the watchdog's nested-query shape).
4. **State-reader.** Dispatch the state-reader worker (`epic-orchestrator/state-reader-prompt.md`, Fast tier) and consume its map; read the register canon and the latest continuation brief; load the state tables (`epic-orchestrator/state-transitions.md`).
5. **Manifest init.** Initialize the dispatch manifest at the epic worktree's **absolute path**: `<epic-worktree-abs>/.dodi/dispatch-manifest-<session-run-id>.jsonl`; create `<epic-worktree-abs>/.dodi/.gitignore` containing `*` on first use (ignores its contents and itself). The driver works against the epic worktree **by absolute path** (cwd resets between Bash calls) and is that worktree's **sole writer** — leaf fix workers dispatched by the walking session write under its ownership (one supervising session still serializes all epic-worktree writes); all lane work happens in per-lane ephemeral worktrees.

## Drive loop

Repeat until park or bloat:

1. **Select** by the priority table (merge → coherence review → epic PR → resume RESUMABLE → deliver-ticket → mature-ticket), same demotion rules and `coherence-pending` blocking scope from `epic-orchestrator/state-transitions.md` — **which now explicitly includes the merge slot: no merge action is eligible while `coherence-pending` is set.** This keeps reviews serial and the register append-ordered; the set-difference audit is the producer-independent backstop.
   - **Merge action** is fail-closed: **apply `coherence-pending` before the merge command** (the irreversible write is the inlined `submit-ticket-pr` merge — `gh pr merge`, not a git push), with the fence verified immediately before it.
   - **Coherence-review action** targets every merged-but-unregistered SHA, **oldest `mergedAt` first, serially, halting after the first pending-human verdict completes its own routing.** Definitions (*pending-human*, *unresolved*, *clean*, *halt*) are in AGENTS.md / the state table and are referenced, not restated. The label clears iff the set-difference is empty ∧ **no register entry over the epic's merged SHAs is unresolved** — register-wide, never batch-scoped; an unresolved pending-human entry gates further remediation, the boot queue, and the guard's actionable-work test until its `RULING` lands (written out-of-band by the human's `rule-coherence` session). Zero merged child PRs clears vacuously.
2. **Claim** the ticket: `${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> <action> <session-run-id>`.
3. **Act.** Execute the selected lane's playbook **natively** — `epic-orchestrator/lanes/mature-playbook.md` or `lanes/deliver-playbook.md` — per `epic-orchestrator/execution-model.md`: walk the playbook's phase sequence in this session, dispatching each phase worker as this session's own **leaf** with its tier pin and fable-policy, awaiting dual-wake, appending each dispatch to the manifest (absolute-path anchored), and recording each progress marker yourself as its boundary is crossed. `execution-model.md` owns the leaf rule, tier pins, dual-wake await, STALLED handling, the `RESUMABLE`/seam/continuation-brief mechanics, and manifest discipline — this step references them and never restates them.
4. **Close out** (prefix-resumable — any close-out is resumable from any prefix by a successor; the SHA-keyed evidence, claim ids, and manifest reap records are the resume keys): **fence** (`driver-claim.sh verify` + refresher-alive check), release the ticket claim (pin the concrete `${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> --session <session-run-id>` — the `--session` filter is how "release own-session by default" is actually enforced: `release-claim.sh`'s no-flag default targets the newest open claim of *any* session, so a driver omitting it could close a foreign successor's claim, the §54 wrong-claim-close shape from the survivor side), post checkpoint evidence, **reap the manifest** (`reap-workers.sh`; stop stragglers; append reap records).
5. **Re-scan** (per-iteration staleness probe): newest comment/history on the epic, **excluding this session's own writes and bookkeeping species** — classification routed through the species-aware `${CLAUDE_PLUGIN_ROOT}/scripts/watchdog-scan.sh` output with an **epic-only scope flag** (the probe is the partition's fifth consumer, not a sixth inline copy), with the own-writes filter applied on top by run id. API authorship cannot discriminate (every plugin session writes as the same key), so "self" is session-run-id-in-body: the driver skips writes it knows it just made; any residual unattributable history event (labels/history carry no body) triggers a benign full re-scan. Human app comments are distinct users and always count. Full state-reader re-scan on external change.

Per-ticket retry ceilings carry over (stagnation-counting, progress-reset) — the driver owns the counter, not `claim.sh`.

## Park and bloat — the only two exits

**No third exit trigger** — a time-based succession rule would recreate the conflicting-rule-set problem.

- **Park:** no automated action possible (human-parked on a pending-human entry, blocked, or empty queue).
- **Bloat:** context degraded — await the in-flight lane's own exit (the driver cannot command a mid-flight checkpoint), then exit; crash recovery is the floor if the exit protocol degrades. At any park evaluation no lane is in flight by construction (awaiting an in-flight lane is itself an available action, reached before park).

Exit protocol, both: **fence**, post the **continuation brief** (format below; repo mirror `continuation-brief.md` for validation), `driver-claim.sh release <epic-id> <claim-id> <parked|bloat-handoff>`, exit. Brief-post failure: retry once, then exit anyway — durable state alone is the proven cold-boot path.

**Continuation brief format** (self-contained, posted as an epic comment under the `# Continuation Brief` header): state map reference with evidence links; chosen next action + one line of why; live concerns from notes; anything in flight that must not be redone (open PRs, running lanes, partial close-outs with their resume keys).

## The Human-Ruling Resolution Route (ruling mode)

Reached via Step 0a when this skill was invoked with the instruction `rule-coherence <merge-sha> approve|reject|redirect:<scope>` (the operator runs the `drive-epic` skill with that instruction — there is no separate command). The answer surface is a **session, not a parsed comment** — no NL parse of PM comments, no comment-authorship discrimination, no wake edge, no automation-key prerequisite. The ruling *is* an automation-authored register write under the existing idempotent SHA-keyed discipline.

**Full lifecycle (both edges pinned):**

1. **Acquire.** The epic is normally parked on the pending-human entry, so no driver contends. If a driver *is* live (it may legitimately be resuming a RESUMABLE lane during the park), **wait until that claim is released or goes stale, then acquire** — bounded, because the driver parks after at most its one in-flight lane. Never "hand off to a pickup" (no channel could deliver the ruling's content to the live driver). A crashed ruling session simply re-runs and re-acquires under the same wait, idempotent under SHA-keyed skip-what-exists. **Fence/refresher posture:** the ruling session starts **no refresher** — its claim freshness bounds it by construction (a sub-lease; a session running past ~45m simply decays and re-runs idempotently), so it fences with `${CLAUDE_PLUGIN_ROOT}/scripts/driver-claim.sh verify` (the three **claim-state** conjuncts only — the fourth, refresher-alive, is n/a here since no refresher was started) immediately **before** the `RULING` write and again immediately **before** the label clear, aborting on ownership loss. This matches spec §107 ("reusing its claim/fence/routing") without contradicting Task B's four-conjunct fence definition (the fourth conjunct is asserted by callers that *run* a refresher; the ruling session does not).
2. **Route.** Read the pending entry named by `<merge-sha>`, route per flag (below), and write the `RULING` as the **last write**.
3. **Clear.** **Evaluate the register-wide clear predicate and clear `coherence-pending` if satisfied, in this same session** — nothing else owns this evaluation now (the async wake edge that used to occasion it is deleted). A guard backstop covers a crash between the `RULING` write and the clear (the guard's actionable-work test).
4. **Exit.** **Release the claim with a `ruled` exit state and exit. The ruling mode never enters the drive loop and never selects from the priority table** — it must not become the driver from the human's terminal, nor idle holding a fresh claim that blocks the guard from booting a real driver.

**Per-flag routing** (the reviewer recorded the routing inputs at review time; the ruling session executes them):

- **GATE1_AMENDMENT.** *approve* ⇒ execute the **held route** recorded in the pending entry (canonization, superseded-by note, affected-children label strips — recorded held/not-yet-performed). *reject* or `redirect:<scope>` ⇒ the **MATERIAL_DRIFT machinery** (corrective ticket, dependents held by relation); `redirect:<scope>` scopes the corrective (judgment fed to the corrective-drafting step), bare `reject` scoped by the contradiction; the corrective's blocked-by relations cover the AMENDMENT's originally-held dependents.
- **GATE1_REFRESH** (its constituent decisions were each already individually canonized, so the register canon itself is what the human rules on). *approve* ⇒ the underlying writes already routed; the `RULING` records the re-approved delta as the new Gate-1 baseline (held route is a no-op by construction). *reject* or *redirect* ⇒ **de-canonize**: post superseding register entries, update the canon summary to remove the rejected decisions, and strip readiness labels on the **per-decision affected-children set the reviewer recorded in the pending entry** (a mechanical durable read) — a MATERIAL_DRIFT corrective only where the scope names rework.

**Ordering and idempotence.** The route ends by writing the `RULING` — the **last write** (fail-closed): a mid-route crash leaves the pending entry unresolved, and the human simply re-invokes drive-epic with the same `rule-coherence <sha> …` instruction, idempotent under SHA-keyed skip-what-exists. The `RULING` is a `decision-register-entry.md` variant with the same `# Decision Register Entry` header and the same `Merge SHA:` key the audit reads; its body records the outcome and the writes performed. *unresolved* ≡ a pending-human entry with no later `RULING` for its SHA — the `<merge-sha>` argument binds it.

## Scheduling migration and prerequisites

- **0.14.0:** create `dodi-drive-epic` (hourly, off-peak minute, permission mode Auto; epic-PR merge in no allow-list). Pause `dodi-pickup-next` (task disabled; manual invocation stays safe — the fence line makes it a no-op beside a live driver). Gate-fail revert order: pause `dodi-drive-epic` **before** resuming `dodi-pickup-next`. `dodi-reconcile-tickets` unchanged in schedule.
- **0.14.1** (gate passed): delete `pickup-next` + its task.
- **Prerequisites** (carried, plus one new term): branch protection on main/master; escalation channel tested end-to-end; `LINEAR_API_KEY` in the session environment; and **coherence rulings are delivered by invoking the `drive-epic` skill with the instruction `rule-coherence <sha> approve|reject|redirect` — a session run, not a chat reply and not a separate command.** (Step 0a parses that instruction and branches to ruling mode.) The operator learns this before the first park.
- Machine-off operation (cloud routines) remains the upgrade path.

## Rules

- Mechanics live in `dodi-dev/scripts/` — run the script and judge its result; never restate a script's mechanism in prose.
- Every worker/lane dispatch carries an explicit model-tier pin per AGENTS.md; a plugin hook also enforces this.
- **Single active epic.** A second signed-off epic in scope is escalated, not interleaved.
- Never merge an epic PR; Gate 2 is procedural and absolute.
- The fence guards every durable-write close-out, every wake, and the merge command. Ownership lost → abort durable writes and exit; read error → brief retry, then exit without durable writes.

## Evidence

- Record per session: run id, guard outcome, boot audit result, actions taken, exit (park/bloat/no-op/ruled), continuation-brief link, driver-claim release state.

## Stop Conditions

- PM unreachable / auth failure — escalate, exit.
- Claim yield (lost the acquire race) — exit no-op.
- Fence trip (ownership lost) — abort durable writes, exit.
- Retry ceiling on a ticket — mark `blocked`, escalate.
- Park or bloat — exit protocol above.
