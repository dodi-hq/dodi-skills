---
name: review
description: Fresh-context code review for any completed change — post-implementation, pre-PR in the epic lane, or child PR — with a fix loop and a Frontier-tier final round
---

# Review

Fresh-context review with explicit correctness and coherence evidence. Child delivery follows [Child Review Contract](child-review-contract.md): early Capable feedback, then one combined hard Frontier final after tests and verification, before PR creation. Evidence reuse replaces repeated review of unchanged work.

| Context | When | Reviewer reads | Context-specific checks |
| --- | --- | --- | --- |
| **post-implementation** | interactive: after `implement`, before `submit` | spec/plan, diff, project conventions | — |
| **pre-PR** | epic lane: implementation feedback before dedicated test completion | spec, plan, implementation diff | Capable feedback only; classify findings; demotion rules apply |
| **child-final / child-PR** | completed code/tests before opening, or freshness/renewal after opening | full diff, Testing Contract, verification, epic intent/canon/siblings, current base | combined Frontier final before opening; after opening reuse identical coverage or renew at Frontier per `child-review-contract.md` |

## Invocation modes

This skill has **two** modes, and the first thing it does is tell them apart:

| | **Manual** | **Autonomous (Florist)** |
| --- | --- | --- |
| Detected by | `FLORIST_UNIT` unset | `FLORIST_UNIT` set |
| Context | chosen by the caller: post-implementation, pre-PR, or child-PR | chosen by `FLORIST_LANE`: `code-review` is the child-PR gate on the kernel-opened PR; `integrating` is the serialized coverage/currency check and staged coherence verdict. The pre-PR gate is **not** a seat — `implement-ticket` runs it inside the implementing seat |
| Fix loop | in-skill, capped | in-dispatch, capped; fixes are pushed before the digest |
| Result | a clean report, or an escalation to the caller | a stdout digest; the kernel moves the lane |
| Human stop | ask or escalate | `declined` / `blocked` — there is nobody to ask |

**First step, both modes — run `"${CLAUDE_PLUGIN_ROOT}/scripts/florist-mode.sh"` before anything else.** It prints `mode=manual` or `mode=autonomous …` from the environment itself (`florist-worker-contract.md` § 1, DOD-1326). In autonomous mode, follow the three instructions it prints: read the contract now, run only § Florist seats below for your `FLORIST_LANE`, and close through `florist-digest.sh` and copy its output **verbatim into your final message** — that message is the session's entire stdout, so a digest left in the transcript is silence and narrating one is not emitting it (DOD-1389). A session that skips this step and reaches a manual close-out has silently exited as far as the kernel is concerned.

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

## Process — post-implementation

For interactive work outside the child delivery lane, retain the existing Capable review/fix loop (five rounds maximum) and fresh Frontier final. Before a PR, the final must also assess coherence against the approved design and repository contracts; use proposal-mode coherence responsibilities without inventing an epic or merge SHA. Coherence is hard Frontier. Epic-to-main/master submission remains governed by `submit-epic-pr`, unchanged. Child lanes use the following sequence instead.

## Process — pre-PR (early feedback)

1. Read the approved spec/plan and implementation diff; dispatch a fresh Capable reviewer with `review-prompt.md`.
2. Fix actionable findings at Standard tier, or Capable on `needs-capable-delivery`; repeat Capable feedback only as needed to resolve findings, up to five rounds. Contract defects demote; cap exhaustion escalates.
3. On clean feedback continue to tests, docs-sync and verification. Record the `pre-pr` ledger and reviewed SHA as feedback evidence, **not** PR authorization. There is no Frontier final at this early point.

## Process — child-final (before opening)

Read and execute `child-review-contract.md`. Require settled prior coherence publication/rulings before consuming canon, including on resumed lanes. After all tests, docs-sync, sync and verification are complete, dispatch `child-pr-integration-prompt.md` once at hard Frontier in `pre-open` mode. It owns full code/test correctness and coherence in one leaf with distinct verdicts. Fixes follow existing delivery-tier routing; every changed approval identity needs a fresh hard Frontier renewal, with affected tests and local CI rerun as required. Record `child-pr` correctness and `coherence` evidence on the existing checkpoint/Seat Record, with a single executor provenance record referenced by both scopes.

## Process — child-PR (coverage and renewal)

1. Read the current PR target/head, full approval record, original Frontier report, context snapshot, and CI evidence. Confirm prior coherence publication/rulings are settled, collect live identity and run the coverage helper per `child-review-contract.md`.
2. If coverage is current and complete, return an explicit `review-reuse:` result citing original approval and live checks. No judgment dispatch is required; no gate is clean by silence.
3. Otherwise sync to the epic as necessary, rerun required checks, and run one hard Frontier renewal with `child-pr-integration-prompt.md`. Missing prior full coverage requires a full review, not a delta-only claim. Fixes and renewal use the contract's five-round cap. Keep PR evidence accurate after changes.
4. Local CI reuse requires a durable local-CI runner digest at the current child HEAD and current epic base; missing evidence or any code/base sync triggers CI. The review record cannot substitute for test execution. On clean coverage report `ready-to-merge-child`; the serial merge slot rechecks freshness before acting.

## Florist seats (autonomous mode)

These are provider-seat instructions **when dispatched**. The companion may close unchanged coverage deterministically without a provider session, preserving the same current-identity validation, original review provenance, explicit reuse receipt and kernel lane/slot semantics. It must not forge a worker digest or invent a reviewer round; changed/unknown coverage retains the sync/renewal worker path. See `child-review-contract.md`.

Before any delivery-seat work, run `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/child-review-gate.py" require-kernel`. On failure record the missing companion capability and emit `blocked reason=worker-blocked` through the digest helper. Read `florist-companion.md`; a declared capability is a rollout precondition, not proof that a worker can enforce kernel actions.

### `FLORIST_LANE=code-review` — coverage on the kernel-opened PR

**Entry.** Read the ticket's Seat Record and combined final approval. Fetch the epic branch; use actual local and remote branch/PR state. Resolve the PR by its exact head and target; an unreadable PR or decision context blocks freshness.

**Run** Process — child-PR above. An unchanged record is a valid explicit reuse result, but the seat must still post its own Seat Record and close with `clean-final`. For changed work, fix, verify and renew as prescribed, push, read the current HEAD and post the Seat Record; no later commits. Preserve the original executor record on reuse instead of inventing a new dispatch.

| Result | Digest |
| --- | --- |
| Current combined approval, newly issued or explicitly reused | `clean-final` + `thread` at current HEAD and the `child-review:` artifact locator; the kernel retains its manager-reserved clean-final marker and serial integration-slot routing |
| Renewal cap exhausted with findings | `findings` + `thread`; existing attempt accounting and escalation remain |
| Product, architecture, scope, shared-contract or spec/plan defect | `demote` + demotion `thread`; never redesign in-loop |
| Hard Frontier unavailable after bounded retries | `declined reason=fable-unavailable` |
| Missing companion, auth, tooling, harness or unreadable context | `blocked reason=worker-blocked` |

Use `florist-digest.sh` and place its output verbatim in the final message. `clean-final` retains its existing `thread` SHA=current HEAD rule. Every success also supplies the durable `artifact ref=child-review:<record-locator> sha=<head>` record for companion validation. Fix workers still follow `FLORIST_DELIVERY_TIER`; every combined final/renewal is hard Frontier regardless of `FLORIST_EPIC_TIER`.

### `FLORIST_LANE=integrating` — serialized freshness and pre-merge proposal

The kernel holds the integration slot. Run no canon writes in this worker. Read the current combined approval and independently refresh HEAD, epic base and decision context.

1. **Currency.** Fetch the epic branch and require its current HEAD to be an ancestor of child HEAD. If not current, merge it (never rebase), resolve only mechanical in-scope conflicts and rerun affected checks/local CI. Push, record, and emit `synced head=<sha>` with sync artifact evidence. The kernel returns to code-review for Frontier renewal; there is no de-minimis exception in this seat.
2. **Coverage.** At current base run the coverage check. Identical complete approval is reusable without a new Frontier dispatch. A changed context with unchanged code needs a hard Frontier renewal here; if code/test fixes are needed, commit/verify/push and emit `synced` so code-review owns the renewed correctness approval. Missing evidence needs a full combined review. Never emit a merge verdict from a stale record.
3. **Proposal.** Post the Seat Record carrying the complete coherence proposal, source approval, fresh identity and explicit reuse/renewal evidence. Do **not** update the epic canon or sibling readiness for unmerged work. The companion owns post-merge publication and holds the barrier through it (`florist-companion.md`).
4. **Digest.** For a passing verdict emit `merge-ready head=<sha>`, `verdict` at that HEAD, the `child-review:` artifact and Seat Record `thread`. Map MINOR_DRIFT to kernel token MINOR; preserve LEGITIMATE_DIVERGENCE's explicit sibling list. No `ALREADY_REVIEWED` token: load the actual prior verdict. The kernel must revalidate at the action boundary.
5. Material drift blocks with `blocked reason=spec-mismatch` and the proposed corrective evidence. Gate 1 flags use the existing `merge-ready` flagged verdict park route, never permission to merge; include the staged proposal and held route. A pre-opening flag was already blocked before `impl-ready`. Capacity failure emits `declined reason=fable-unavailable`; other walls use the contract's blocked vocabulary.

All coherence judgment here is hard Frontier on every epic tier. The integration router may check identical evidence at its existing seat; reuse is not a lower-tier coherence judgment.

## Epic Lane Rules

- Reviewers start from fresh artifacts and actual diffs; no success by silence.
- Implementation and fix-worker tiers are unchanged; routine choices within approved task boundaries do not demote.
- Contract defects demote per `state-transitions.md`; implementation/test bugs are fixed in-lane.
- A production-code verification fix receives a fresh reviewer at Capable tier (`model: opus` on Claude Code) reading the fix delta and its affected callers, followed by rerun checks. Before the combined final this is feedback; after it the fix also invalidates approval and requires hard Frontier renewal. No extra automatic pair is introduced.
- Claims of unchanged coverage require `child-review-contract.md`'s live helper result, original complete report, CI evidence and explicit reuse record. A SHA-only clean pass is insufficient.
- Child-PR integration freshness and pre-merge checks follow the same contract. Preserve branch sync, adoption evidence, serial merge ownership and human gates.
- Record actual review rounds and executor provenance, plus reuse evidence separately; do not inflate round counts with deterministic coverage checks.

## Catch Attribution

Every posted review-evidence finding — lane checkpoint evidence, review comments, escalations, demotion comments — carries a per-finding tag `caught-by: <gate>/<round>/<tier>`, gate ∈ {spec-review, plan-review, pre-pr, focused-re-review, verify, local-ci, child-pr, epic-integration, coherence}. Reviewer prompts emit the tag per finding — single-gate prompts hard-code their gate token; review-prompt.md serves two epic-lane gates plus the interactive context, so its gate token is supplied by the dispatcher from the invoking context (`pre-pr` | `focused-re-review`; interactive post-implementation runs carry `pre-pr`-equivalent attribution or none). The dispatcher appends round and tier when posting, and itself tags `verify`/local-CI **failures** (runners stay pure — the tag never enters a runner prompt).

- **Round grammar:** `<round>` is an integer counting rounds within that gate's loop for this ticket — a canonical `fable` Frontier final is its integer, never "final"; single-shot gates (verify, local-ci, coherence) use `1` per attempt; epic-integration counts rounds within its per-attempt loop like the review gates. `<tier>` is the catching round's canonical model tier alias (e.g. `opus`, `fable`), not a native-executor claim.
- **Tier-degraded suffix (Frontier substitution):** a Frontier-seated round run at a substituted tier under a `deferred`/`soft` Frontier policy (AGENTS.md § Frontier Availability Policy) appends ` tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` to its finding tags — e.g. `caught-by: pre-pr/2/opus tier-degraded(fable@xhigh→opus@high,deferred)`. `fable` remains the canonical Frontier alias in this grammar; an Astra Frontier round still uses `.../<round>/fable` and creates no degradation suffix solely because Astra executed it. Effort components are each seat's **declared** effort per the AGENTS.md effort table (the substitute records `max` only when the seat is a declared `Capable@max` case), never a runtime readout. The dispatcher appends it exactly where it appends `<round>/<tier>`; append-only, next-boundary rule unchanged. The substitution is recorded and the obligation (deferred) queued — a gate is never clean by silence. The grammar is forward-only: historical PM comments keep the old two-component form, and aggregation greps must not assume the new arity (a `tier-degraded(` grep matches both).
- **Tagging surfaces (append-only — never edit a posted checkpoint):** tags land in the next boundary's evidence — a verify-stage failure tags in the `ready-for-child-pr` checkpoint evidence; a child-PR-stage local-CI failure (when the conditional dispatches it) tags in the lane's `ready-to-merge-child` exit report.
- No new artifact, no script: the tag is grep-aggregatable from PM comments.

## Native Executor Evidence

Canonical attribution is intentionally portable, so the dispatcher adds one forward-only companion record for every new reviewer round, including clean rounds:

`review-executor: <gate>/<round> runtime=<claude-code|codex|grok-build> model=<native-dispatch-pin> effort=<native-requested-effort|inherited> source=dispatch`

- Copy `model` and `effort` from the actual native dispatch request. Use `inherited` only when that runtime exposes no per-dispatch effort control; never replace a native effort spelling with the canonical Claude effort. `source=dispatch` describes request provenance, not provider attestation.
- If the runtime reports a model or effort override, fallback, or mismatch, put that concern beside the line. An unqualified fallback cannot silently satisfy a Frontier gate.
- Post the record on the round's existing next-boundary evidence surface, with repeats for multi-round gates. The posting map is the Gate Ledger map below; single-shot coherence and epic-integration rounds use their existing register/readiness evidence, and Florist seats carry the records in the Seat Record. Interactive review uses its equivalent close-out surface. This creates no new PM artifact species.
- Historical rounds need no retroactive companion. If an unfinished gate exits through `RESUMABLE`, refresh-park, or a hard capacity park, copy all completed rounds' executor records into the continuation brief beside the running gate-ledger tally.
- The dispatcher owns this record. Reviewer and test-runner prompts stay free of dispatcher accounting.

## Gate Ledger

Catch attribution records findings; it is blind to clean rounds, so rounds-to-clean cannot be reconstructed from tags alone. The gate ledger closes that gap: when a looped review gate closes — clean or cap-exhaustion escalation — the dispatcher posts one machine-parseable line in that gate's existing close-out surface:

`gate-ledger: <gate> rounds=<n> findings=<b/a[,b/a...]> outcome=<clean|escalated> final=<tier>@<effort>[ tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)]`

Example: `gate-ledger: spec-review rounds=3 findings=4/2,1/1,0/1 outcome=clean final=fable@xhigh`

- **Covered gates:** the looped in-lane gates — `spec-review`, `plan-review`, `pre-pr`, `child-pr`, and `focused-re-review` when it runs. Single-shot gates (verify, local-ci, coherence) need no ledger — a one-round gate's catch tags already carry its whole signal. The epic-level loops (epic-integration) are a deliberate exclusion for now: the lane gates are where loop-depth tuning has an open question.
- **`findings=`** — one `b/a` pair per round in dispatch order: `b` counts blocking findings (the reviewer's **Issues**, all severities — any Issue blocks gate-clean; severity stays visible in the tagged findings, not the ledger), `a` counts advisory ones (**Recommendations**). Only the spec- and plan-reviewer prompts carry an advisory section, so the code gates read `a=0` by construction — advisory-churn tuning is an artifact-gate signal. When `outcome=clean`, the last pair is the clean closing round (`0/a`).
- **`final=<tier>@<effort>`** — the tier alias of the round that closed the gate, at that seat's declared effort (the effort table's value, or `max` at a declared `Capable@max` seat); a Frontier-seat substitution appends the same `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` marker as catch attribution, same semantics, same append point.
- **Posting surfaces (same next-boundary, append-only rule as catch tags and executor records):** `spec-review` → the `needs-plan` gate-transition comment (with `spec-ready`); `plan-review` → the `ready-to-implement` gate-transition comment; `pre-pr` → the `testing` checkpoint evidence; `focused-re-review` → the `ready-for-child-pr` checkpoint evidence; `child-pr` → the lane's `ready-to-merge-child` exit report. On `outcome=escalated` the gate never reaches its clean-close surface — the line and completed rounds' executor records ride the escalation (or demotion) comment instead; the companion `rework-origin:` line is what distinguishes a demotion close from cap exhaustion. A deliberate mid-loop context exit (`RESUMABLE`, refresh-park, or hard capacity park) records the running round tally and completed executor records in the continuation brief so the successor resumes the count rather than restarting it. Interactive contexts carry the equivalent line in their close-out report, or none — matching the catch-attribution rule.
- **Reuse accounting:** a combined dispatch is one model invocation with distinct correctness and coherence outputs. Reference its one native executor record from both scopes. Reuse preserves the prior ledger and adds `review-reuse:`; it never creates a new round or pretends a router was a Frontier reviewer.

- **Reviewer prompts stay pure:** the dispatcher counts from the reviewer's returned Issues/Recommendations sections and posts the line — no prompt change, no new artifact, no script. `grep -h "gate-ledger:"` over PM comments is the aggregation; per-phase wall-clock needs no field because the bounding state transitions are PM-timestamped.
- **Rework companion line:** every demotion comment additionally carries `rework-origin: <spec|plan> caught-at=<gate>/<round>/<tier>` (state-transitions.md § Demotion Rules) — origin `spec` when the spec itself is invalidated, `plan` when `spec-ready` is kept and only the plan must be revised: the same split the demotion's label decision already makes. This is the downstream-rework-traced-to-upstream-gap signal.

The ledger exists to make loop depth empirically tunable rather than argued: rounds-to-clean distribution per gate, whether late rounds still surface blocking findings (if `b` hits zero by round 2 across the sample, the cap is fat; if the Frontier final still catches blockers, it is earning its seat), advisory churn, and how much delivery-lane rework traces to spec/plan gaps.

## Don't Skip This

"Tests pass" is not a review. Tests verify behavior; review verifies intent, quality, and risk.
