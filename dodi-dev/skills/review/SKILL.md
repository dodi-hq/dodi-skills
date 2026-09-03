---
name: review
description: Fresh-context code review for any completed change — post-implementation, pre-PR in the epic lane, or child PR — with a fix loop and a Frontier-tier final round
---

# Review

Comprehensive fresh-context, agent-driven code review with a fix loop. One skill, three contexts:

| Context | When | Reviewer reads | Context-specific checks |
| --- | --- | --- | --- |
| **post-implementation** | interactive: after `implement`, before `submit` | spec/plan, diff, project conventions | — |
| **pre-PR** | epic lane: implementation complete, before tests and local readiness | spec, plan, diff in the child worktree | classify findings; demotion rules apply |
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | delta-scoped integration pair — one `opus` integration round + one `fable` integration final (child-pr-integration-prompt.md); Testing Contract coverage; branch currency with the epic branch; local CI conditional — dispatched in parallel unless the `ready-for-child-pr` checkpoint's recorded local-CI head SHA still covers the branch (skip predicate in Process — child-PR) |

## Invocation modes

This skill has **two** modes, and the first thing it does is tell them apart:

| | **Manual** | **Autonomous (Florist)** |
| --- | --- | --- |
| Detected by | `FLORIST_UNIT` unset | `FLORIST_UNIT` set |
| Context | chosen by the caller: post-implementation, pre-PR, or child-PR | chosen by `FLORIST_LANE`: `code-review` is the child-PR gate on the kernel-opened PR; `integrating` is the epic-branch currency check and the coherence verdict. The pre-PR gate is **not** a seat — `implement-ticket` runs it inside the implementing seat |
| Fix loop | in-skill, capped | in-dispatch, capped; fixes are pushed before the digest |
| Result | a clean report, or an escalation to the caller | a stdout digest; the kernel moves the lane |
| Human stop | ask or escalate | `declined` / `blocked` — there is nobody to ask |

**Autonomous mode is governed by `epic-orchestrator/florist-worker-contract.md`** — read it before anything else in that mode. It is the canon for the digest grammar, the decline vocabulary, the env contract, the push rule, the Seat Record, and the writes a worker must never make. This file states only what is specific to the two review seats (§ Florist seats below).

There is no frontmatter `model:` pin (retired in 0.19.0): the kernel seats this session at the unit's delivery tier — the Standard base seat, or the Capable variant when `FLORIST_DELIVERY_TIER=capable` — and a frontmatter pin would override that seat at skill load. In manual mode the invoking session's own tier applies: a deliver lane runs this skill at its Standard router; an interactive post-implementation review runs at whatever the operator's session is. Every reviewer and fix-worker dispatch carries its own explicit pin either way.

## What to Check

| Category | What to Look For |
|----------|------------------|
| **Spec compliance** | Does the code implement what was specified? Nothing missing, nothing extra |
| **Code quality** | Clean, idiomatic, follows project conventions (CLAUDE.md / AGENTS.md, style guides) |
| **Security** | Injection, auth bypass, data leaks, OWASP top 10 |
| **Regression risk** | Does this change break assumptions in callers/consumers? |
| **Error handling** | Silent failures, swallowed exceptions, missing edge cases |
| **API contracts** | If touching APIs — are request/response shapes backwards-compatible? |
| **Documentation** | Docs, README, and config samples updated when behavior changes |
| **Operational concerns** | Logging, error surfacing, flags, rollout/rollback |

## Process — post-implementation and pre-PR (full gate)

1. Identify the spec/plan and the diff (`git diff <base>...HEAD`).
2. Dispatch the reviewer subagent (see review-prompt.md) with the context named.
3. **Review loop** — if the reviewer reports issues, dispatch fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a fresh reviewer. Cap at 5 rounds; if still not clean, stop and escalate with the unresolved findings.
4. **Final round at the Frontier fable seat** — when a round comes back clean, dispatch one last fresh reviewer at the gate's fable seat. Under the gate's **hard** fable-policy this is `model: fable`; under **deferred**/**soft** (AGENTS.md § Fable Availability Policy) it runs at the substituted effective tier (`model: opus`) with the make-up obligation queued (deferred) or the marker recorded (soft). The pre-PR final round is **deferred** by policy. The gate is clean only when this final round — at whatever effective tier the policy produced — reports zero issues; **no gate is ever clean by silence**. If it finds issues, fix them and resume the loop at the per-round tier.
5. On clean:
   - post-implementation → proceed to `dodi-dev:submit`
   - pre-PR → proceed to tests and local readiness

## Process — child-PR (integration pair)

The pre-PR gate already ran the full checklist; the child-PR gate re-reviews the delta, not the checklist. One **integration round** at Capable tier (`model: opus` on Claude Code) plus one **integration final** at Frontier tier (`model: fable` on Claude Code), both delta-aimed at exactly what is new or changed since the pre-PR gate, both reading the whole PR diff (see child-pr-integration-prompt.md).

1. Identify the ticket, spec, plan (with its Testing Contract), and the PR diff.
2. Dispatch the **integration round** (child-pr-integration-prompt.md, `model: opus`). **Conditional local CI:** evaluate the skip predicate from the `ready-for-child-pr` checkpoint — the durable home of the recorded runner head SHAs (this evaluator may run in a fresh context — after a standalone/manual lane's reset at this seam, or any resume — so it reads the recorded SHAs from the durable checkpoint, never from session memory). Skip the local CI dispatch **iff all three hold**: **(a)** the checkpoint records a head SHA for the **local-CI runner specifically** and no commits exist on the child branch after it — a newer test-runner SHA never substitutes (a verify-stage fix re-runs affected groups, not necessarily the local-CI runner); no recorded local-CI SHA ⇒ dispatch; **(b)** that recorded SHA is an ancestor of the current child HEAD (`git merge-base --is-ancestor <recorded-sha> HEAD`; a rebase-style rewrite orphans it — dispatch); **(c)** the epic branch has not moved — any epic-branch sync (merge or rebase) forces the dispatch: the sync-then-rerun rule (Epic Lane Rules) explicitly includes the CI runner. The predicate fails closed: not decidable ⇒ dispatch. On dispatch, dispatch the local CI runner (`submit-ticket-pr/local-ci-runner-prompt.md`) **in parallel** — one message, two Agent calls; they are independent. On skip, record the predicate evaluation (recorded local-CI SHA, ancestry result, epic-head check) in the exit evidence; the checkpoint-recorded verify-stage local-CI digest is then the CI-equivalent evidence (`submit-ticket-pr` § Merge).
3. When the integration round is clean, dispatch the **integration final** — a fresh reviewer, same prompt, `model: fable`.
4. **Fix loop** — findings from either round route to fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a **focused re-round** aimed at the fix delta — tier-conditional per AGENTS.md § Fable Availability Policy (DR-025, epic DOD-1213): on a `needs-capable-delivery` ticket it runs at the gate's **hard** fable seat (`model: fable` on Claude Code — the fix worker is `opus`, so this re-round is the last independent Frontier check before the merge); on a standard-tier ticket it runs at Capable tier (`model: opus` on Claude Code — the `sonnet` fix worker leaves no writer/reviewer collapse to guard against; not a fable seat — no substitution, no make-up). Either way it is the round that re-establishes gate-clean, not a confirmation sweep. Total child-PR rounds cap at 5; cap exhaustion escalates with the unresolved findings — it never merges.
5. The gate is clean only when its closing round reports zero issues. With no fix loop, the closing round is the child-PR **final** — at its fable seat under **hard** policy (`needs-capable-delivery` tickets), or at the substituted effective tier (`model: opus`) under **deferred** policy (standard-tier tickets) with the make-up obligation queued. After a fix loop, it is the **focused re-round** at its tier-conditional seat (step 4) — hard `fable@xhigh` on `needs-capable-delivery` tickets, plain `opus@high` on standard-tier tickets with **no** substitution and **no** make-up. **No gate is ever clean by silence.** On clean, report `ready-to-merge-child`.

## Florist seats (autonomous mode)

### `FLORIST_LANE=code-review` — the child-PR gate

**Entry.** The PR exists: the kernel opened it over the head the `impl-ready` digest named, against `FLORIST_EPIC_BRANCH`. `gh pr list --head "unit/$FLORIST_UNIT" --base "$FLORIST_EPIC_BRANCH" --state open --json number,url,headRefOid` locates it for the record; the review input is git — `git fetch origin "$FLORIST_EPIC_BRANCH"` first (nothing on the kernel side fetches, and sibling merges move the epic head), then `git diff "origin/$FLORIST_EPIC_BRANCH...HEAD"` — so an unauthenticated `gh` is not a blocker. The pre-PR gate baseline is the `thread` SHA in the implementing seat's Seat Record; the conditional-CI predicate (§ Process — child-PR, step 2) reads that record's local-CI head SHA, and fails closed to a dispatch as always.

**Run** § Process — child-PR (integration pair) exactly: integration round → integration final → fix loop with its focused re-round, five rounds total, the conditional local CI in parallel. Fix workers commit on the unit branch. Before the digest: `git push origin "unit/$FLORIST_UNIT"`, then `head=$(git rev-parse HEAD)`, then the Seat Record. Nothing is committed after `head` is read.

| Result | Digest |
| --- | --- |
| The closing round reports zero issues | `clean-final` + `FLORIST-EVIDENCE: kind=thread ref=<Seat Record URL> sha=<head>`. The reviewed SHA must be the branch head **now** — a clean round over any other commit blocks the unit on `sha-mismatch`. The kernel pins the head; the scheduler moves the unit to `integrating` when the epic's integration slot is free |
| The cap is exhausted with findings still open (fixes committed or not) | `findings` + `FLORIST-EVIDENCE: kind=thread ref=<Seat Record URL> sha=<head reviewed>`. The kernel releases the lease at `attempt`+1 and re-dispatches a fresh seat; three such rounds reach `attempt-ceiling`, which **is** the escalation with the unresolved findings — never merge, never exit silently |
| A product, architecture, scope, or spec/plan mismatch finding | `demote` + `FLORIST-EVIDENCE: kind=thread ref=<demotion comment URL> sha=-`, the comment per `epic-orchestrator/state-transitions.md` § Demotion Rules — do not fix it in-loop |
| A **hard** fable gate cannot dispatch | `declined reason=fable-unavailable` |
| `FLORIST_DELIVERY_TIER=capable` but `FLORIST_TIER` seats a Standard session | `declined reason=tier-mismatch` — before any dispatch |
| An operational wall — auth, tooling, a harness, no `LINEAR_API_KEY` | `blocked reason=worker-blocked` |

**Attempts.** `FLORIST_ATTEMPT` > 0 means a prior dispatch recorded `findings`. Read its Seat Record for what was found and fixed, then review the **current** head fresh: a prior round's clean claims cover only the commits it saw.

**Tiers.** Fix workers follow `FLORIST_DELIVERY_TIER` (`capable` → Capable, `model: opus` on Claude Code; otherwise Standard). Gates follow `FLORIST_EPIC_TIER` (unset is treated as `standard`):

| `FLORIST_EPIC_TIER` | Integration round | Integration final | Post-fix focused re-round |
| --- | --- | --- | --- |
| `standard` | Capable (`opus`) | Capable — fable nowhere; no substitution recorded, because no fable seat exists at this tier | Capable |
| `capable` | Capable | Frontier (`fable`): **hard** when `FLORIST_DELIVERY_TIER=capable` (cannot dispatch ⇒ `declined reason=fable-unavailable`); **deferred** otherwise (`opus` substitutes, `tier-degraded(...)` marker, `Kind: FABLE_MAKEUP` register entry on the epic ticket) | per DR-025: Frontier **hard** when `FLORIST_DELIVERY_TIER=capable`, Capable otherwise |

`FLORIST_DELIVERY_TIER` is the kernel's truth behind the `needs-capable-delivery` label; the label itself is a projection this session never reads for routing and never writes.

### `FLORIST_LANE=integrating` — currency and the coherence verdict

**Entry.** The code-review clean final round is pinned to the current head, and the kernel holds the epic's integration slot for this unit: the epic is frozen for this dispatch, and this unit is the only one integrating. Two questions, in order; a sync ends the dispatch, a verdict ends it otherwise.

1. **Currency.** `git fetch origin "$FLORIST_EPIC_BRANCH"`. The branch is current iff `git merge-base --is-ancestor "origin/$FLORIST_EPIC_BRANCH" HEAD`. Not current ⇒ **sync**: `git merge "origin/$FLORIST_EPIC_BRANCH"` — merge, never rebase: the kernel's pins and the PR's recorded SHAs must stay reachable. Resolve only mechanical conflicts; run the local-CI runner at the merged head; push; post the Seat Record (the sync commit, the epic head merged, the runner digest at the merged head); then

   ```
   FLORIST-STATUS: synced head=<sha>
   FLORIST-EVIDENCE: kind=artifact ref=sync:<epic head sha> sha=<head>
   ```

   The kernel returns the unit to `code-review` — the merged delta re-passes review. A conflict needing spec- or contract-level judgment ⇒ `git merge --abort`, then `blocked reason=merge-conflict`. The de-minimis exception in `submit-ticket-pr` § Merge is a human-mode judgment and is **not** available here: a moved epic head always syncs.

2. **Coherence verdict, pre-merge.** Dispatch `epic-orchestrator/coherence-reviewer-prompt.md` over the PR diff against the current epic head — the merge commit does not exist yet, so the reviewed identity is the unit branch head, which is exactly the SHA the kernel merges at. Post the register entry comment on the epic ticket keyed to that head SHA and refresh the `## Decision Register — Canon` section of the epic description — both permitted writes (an ordinary comment, a product field) — then the Seat Record on the unit's ticket (the verdict, the register entry URL, the epic head the diff was judged against). Then

   ```
   FLORIST-STATUS: merge-ready head=<sha>
   FLORIST-EVIDENCE: kind=verdict ref=<OUTCOME>[:<unit>,<unit>] sha=<head>
   FLORIST-EVIDENCE: kind=thread ref=<register entry URL> sha=<head>
   ```

   Verdict mapping, prompt → kernel `ref`: `ALIGNED` → `ALIGNED`; `MINOR_DRIFT` → `MINOR`; `LEGITIMATE_DIVERGENCE` → `LEGITIMATE_DIVERGENCE:<affected unit ids, comma-separated, no spaces>`; `MATERIAL_DRIFT` → `MATERIAL_DRIFT`; a `GATE1_AMENDMENT` or `GATE1_REFRESH` flag **overrides** the verdict — the ref is the flag, the kernel parks the unit on `gate1-ruling`, and the held route recorded in the register entry is what the ruling session performs; `ALREADY_REVIEWED` → the existing entry's outcome for this head (idempotence). The kernel records the verdict, merges at exactly `head`, and realigns the named siblings itself on `LEGITIMATE_DIVERGENCE`. The worker never strips a label, never files the `MATERIAL_DRIFT` corrective (its draft rides the register entry; filing is Gate-1 work), never merges.

   **Tier.** The coherence check is a **hard** fable gate: `FLORIST_EPIC_TIER=capable` ⇒ Frontier (`model: fable` on Claude Code), and `declined reason=fable-unavailable` when it cannot dispatch; `standard`/unset ⇒ Capable (`opus`), nothing recorded.

## Epic Lane Rules

- Reviewers start from fresh context; never rely on the implementation conversation.
- Classify every finding: spec mismatch, implementation issue, test issue, security issue, hygiene issue, or regression risk.
- Product, architecture, scope, or spec/plan mismatch findings demote the ticket per the orchestrator's demotion rules — do not fix them in-loop.
- **Focused re-review** is required when production code changes during verification: a fresh reviewer at Capable tier (`model: opus` on Claude Code) reads the fix delta plus its blast surface (callers/consumers), full checklist (review-prompt.md) scoped to that delta, before the reset seam — a scoped instance of the review fix loop (findings → fix worker → fresh focused round) under the pre-PR loop's cap.
- Child-PR rounds are delta-aimed — exactly what is new or changed since the pre-PR gate — and read the whole PR diff. Aim guides attention, not admissibility: any defect seen anywhere in the diff is a legal finding; the rounds simply do not re-execute the generic checklist the pre-PR gate owns.
- Child-PR context: if the epic branch moved, update the child branch from the epic branch and rerun relevant checks; stop on an unresolved merge conflict requiring judgment.
- Record reviewer status, findings, fixes, reviewed diff range, commands and exit codes, the final clean-round evidence, and the gate's close-out `gate-ledger` line (§ Gate Ledger).

## Catch Attribution

Every posted review-evidence finding — lane checkpoint evidence, review comments, escalations, demotion comments — carries a per-finding tag `caught-by: <gate>/<round>/<tier>`, gate ∈ {spec-review, plan-review, pre-pr, focused-re-review, verify, local-ci, child-pr, epic-integration, coherence}. Reviewer prompts emit the tag per finding — single-gate prompts hard-code their gate token; review-prompt.md serves two epic-lane gates plus the interactive context, so its gate token is supplied by the dispatcher from the invoking context (`pre-pr` | `focused-re-review`; interactive post-implementation runs carry `pre-pr`-equivalent attribution or none). The dispatcher appends round and tier when posting, and itself tags `verify`/local-CI **failures** (runners stay pure — the tag never enters a runner prompt).

- **Round grammar:** `<round>` is an integer counting rounds within that gate's loop for this ticket — a `fable` final is its integer, never "final"; single-shot gates (verify, local-ci, coherence) use `1` per attempt; epic-integration counts rounds within its per-attempt loop like the review gates. `<tier>` is the catching round's model tier alias (e.g. `opus`, `fable`).
- **Tier-degraded suffix (fable substitution):** a fable-seated round run at a substituted tier under a `deferred`/`soft` fable-policy (AGENTS.md § Fable Availability Policy) appends ` tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` to its finding tags — e.g. `caught-by: pre-pr/2/opus tier-degraded(fable@xhigh→opus@high,deferred)`. Effort components are each seat's **declared** effort per the AGENTS.md effort table (the substitute records `max` only when the seat is a declared `Capable@max` case), never a runtime readout. The dispatcher appends it exactly where it appends `<round>/<tier>`; append-only, next-boundary rule unchanged. The substitution is recorded and the obligation (deferred) queued — a gate is never clean by silence. The grammar is forward-only: historical PM comments keep the old two-component form, and aggregation greps must not assume the new arity (a `tier-degraded(` grep matches both).
- **Tagging surfaces (append-only — never edit a posted checkpoint):** tags land in the next boundary's evidence — a verify-stage failure tags in the `ready-for-child-pr` checkpoint evidence; a child-PR-stage local-CI failure (when the conditional dispatches it) tags in the lane's `ready-to-merge-child` exit report.
- No new artifact, no script: the tag is grep-aggregatable from PM comments.

## Gate Ledger

Catch attribution records findings; it is blind to clean rounds, so rounds-to-clean cannot be reconstructed from tags alone. The gate ledger closes that gap: when a looped review gate closes — clean or cap-exhaustion escalation — the dispatcher posts one machine-parseable line in that gate's existing close-out surface:

`gate-ledger: <gate> rounds=<n> findings=<b/a[,b/a...]> outcome=<clean|escalated> final=<tier>@<effort>[ tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)]`

Example: `gate-ledger: spec-review rounds=3 findings=4/2,1/1,0/1 outcome=clean final=fable@xhigh`

- **Covered gates:** the looped in-lane gates — `spec-review`, `plan-review`, `pre-pr`, `child-pr`, and `focused-re-review` when it runs. Single-shot gates (verify, local-ci, coherence) need no ledger — a one-round gate's catch tags already carry its whole signal. The epic-level loops (epic-integration) are a deliberate exclusion for now: the lane gates are where loop-depth tuning has an open question.
- **`findings=`** — one `b/a` pair per round in dispatch order: `b` counts blocking findings (the reviewer's **Issues**, all severities — any Issue blocks gate-clean; severity stays visible in the tagged findings, not the ledger), `a` counts advisory ones (**Recommendations**). Only the spec- and plan-reviewer prompts carry an advisory section, so the code gates read `a=0` by construction — advisory-churn tuning is an artifact-gate signal. When `outcome=clean`, the last pair is the clean closing round (`0/a`).
- **`final=<tier>@<effort>`** — the tier alias of the round that closed the gate, at that seat's declared effort (the effort table's value, or `max` at a declared `Capable@max` seat); a fable-seat substitution appends the same `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` marker as catch attribution, same semantics, same append point.
- **Posting surfaces (same next-boundary, append-only rule as catch tags):** `spec-review` → the `needs-plan` gate-transition comment (with `spec-ready`); `plan-review` → the `ready-to-implement` gate-transition comment; `pre-pr` → the `testing` checkpoint evidence; `focused-re-review` → the `ready-for-child-pr` checkpoint evidence; `child-pr` → the lane's `ready-to-merge-child` exit report. On `outcome=escalated` the gate never reaches its clean-close surface — the line rides the escalation (or demotion) comment instead; the companion `rework-origin:` line is what distinguishes a demotion close from cap exhaustion. A deliberate mid-loop context exit (`RESUMABLE`, refresh-park) records the running round tally in the continuation brief so the successor resumes the count rather than restarting it. Interactive contexts carry the equivalent line in their close-out report, or none — matching the catch-attribution rule.
- **Reviewer prompts stay pure:** the dispatcher counts from the reviewer's returned Issues/Recommendations sections and posts the line — no prompt change, no new artifact, no script. `grep -h "gate-ledger:"` over PM comments is the aggregation; per-phase wall-clock needs no field because the bounding state transitions are PM-timestamped.
- **Rework companion line:** every demotion comment additionally carries `rework-origin: <spec|plan> caught-at=<gate>/<round>/<tier>` (state-transitions.md § Demotion Rules) — origin `spec` when the spec itself is invalidated, `plan` when `spec-ready` is kept and only the plan must be revised: the same split the demotion's label decision already makes. This is the downstream-rework-traced-to-upstream-gap signal.

The ledger exists to make loop depth empirically tunable rather than argued: rounds-to-clean distribution per gate, whether late rounds still surface blocking findings (if `b` hits zero by round 2 across the sample, the cap is fat; if the fable final still catches blockers, it is earning its seat), advisory churn, and how much delivery-lane rework traces to spec/plan gaps.

## Don't Skip This

"Tests pass" is not a review. Tests verify behavior; review verifies intent, quality, and risk.
