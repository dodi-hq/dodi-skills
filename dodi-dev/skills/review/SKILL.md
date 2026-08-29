---
name: review
description: Fresh-context code review for any completed change — post-implementation, pre-PR in the epic lane, or child PR — with a fix loop and a Frontier-tier final round
model: sonnet
---

# Review

Comprehensive fresh-context, agent-driven code review with a fix loop. One skill, three contexts:

| Context | When | Reviewer reads | Context-specific checks |
| --- | --- | --- | --- |
| **post-implementation** | interactive: after `implement`, before `submit` | spec/plan, diff, project conventions | — |
| **pre-PR** | epic lane: implementation complete, before tests and local readiness | spec, plan, diff in the child worktree | classify findings; demotion rules apply |
| **child-PR** | epic lane: after `submit-ticket-pr` opens a PR against the epic branch | ticket, spec, plan, PR diff | delta-scoped integration pair — one `opus` integration round + one `fable` integration final (child-pr-integration-prompt.md); Testing Contract coverage; branch currency with the epic branch; local CI conditional — dispatched in parallel unless the `ready-for-child-pr` checkpoint's recorded local-CI head SHA still covers the branch (skip predicate in Process — child-PR) |

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
4. **Fix loop** — findings from either round route to fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a **focused re-round at the gate's fable seat** aimed at the fix delta — it inherits the child-PR final's fable-policy (**hard** on `needs-capable-delivery`, **deferred** on standard-tier), since it is the round that re-establishes gate-clean, not a confirmation sweep. Total child-PR rounds cap at 5; cap exhaustion escalates with the unresolved findings — it never merges.
5. The gate is clean only when the child-PR final round reports zero issues — at its fable seat under **hard** policy (`needs-capable-delivery` tickets), or at the substituted effective tier (`model: opus`) under **deferred** policy (standard-tier tickets) with the make-up obligation queued; **no gate is ever clean by silence**. On clean, report `ready-to-merge-child`.

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
