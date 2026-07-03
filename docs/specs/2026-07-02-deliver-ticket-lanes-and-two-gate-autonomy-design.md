# Deliver-Ticket Lanes & Two-Gate Autonomy Design

## TL;DR

Collapse the per-ticket orchestration hops into a single `deliver-ticket` lane (one worker session per child ticket, up to 2 lanes in parallel), and reduce routine human involvement to exactly two gates: approving epic intent at the start, and manually merging the epic PR into main/master at the end. Every human-facing artifact leads with a scannable TL;DR + key points; everything below that line is written for agents.

## Key Points

- **Two human gates, everything else autonomous.** Gate 1: epic intent (spec direction + child decomposition + key decisions) approved once, up front. Gate 2: the epic PR into main/master is opened by automation but merged only by a human — it is the production entry point and is never auto-merged.
- **Per-child spec signoff is removed by default.** Gate 1 approval records delegation for all children. A `needs-human-spec` label on a specific child restores the old blocking gate for that child only; genuine product ambiguity still stops and asks.
- **Child→epic merges have no human gate** (they never meaningfully did): clean fresh-context review (opus rounds + fable final) plus local CI-equivalent evidence merge automatically, serially.
- **`deliver-ticket` (new skill, sonnet)** runs pickup → implement → review(pre-PR) → create-tests → verify → quality-gate → open child PR → review(child-PR) in one session, ending at `ready-to-merge-child`. Internal gates and worker dispatch discipline are unchanged — the phase skills become the lane's internal steps instead of orchestrator round-trips (~7 round-trips per ticket → 2).
- **Parallelism: `maxParallelLanes` default 2.** Lanes run concurrently only when the dependency map shows no edges and plans predict disjoint file surfaces; any predicted overlap forces serialization. Lanes never touch the epic branch; merges stay orchestrator-owned and strictly serial.
- **Crash-safe via checkpoints.** Lanes post the existing per-state PM comments as they pass through; a dead lane is re-dispatched and resumes from the last durable checkpoint.
- **Scannable artifact convention.** Specs, the Gate 1 package, the epic readiness summary, and human notifications all lead with `## TL;DR` (2–3 sentences) + `## Key Points` (5–9 bullets: decisions, tradeoffs, in/out scope, risks, ⚠-flagged assumptions). Notifications carry only that header plus links.
- **Context is compacted deliberately, at logical stop points.** A deliberate compaction is a voluntary crash + resume: sessions reset at mandatory anchors (orchestrator after each merge and Gate 1; lane at the quality-gate→PR seam), write a continuation brief, and re-dispatch fresh from durable state. Harness auto-compaction becomes a backstop, not the mechanism.
- **Demotion, evidence rules, and Testing Contracts are unchanged.** Judgment surprises still demote to the spec lane; the orchestrator still advances only on evidence-checker citations; the epic PR still requires a green full regression on the integrated head.

---

## Gates Model

### Gate 1 — Epic Intent (blocking)

After `pickup-epic` and `assess-epic`, the orchestrator assembles a **Gate 1 package** and requests human approval via `humanContact`:

- epic TL;DR + key points (drafted at the Frontier tier)
- child ticket list with one-line intent per child and the dependency map
- key decisions and ⚠-flagged assumptions that approval will delegate
- anything already known to need human input

Approval is recorded durably: an `epic-signed-off` label on the epic plus an epic comment quoting what was approved. That comment **is** the recorded delegation required by `mature-ticket` for every child, so children flow spec → plan → implementation without further routine signoff.

Epic-level state gains `awaiting-epic-signoff` between `epic-unassessed` and `epic-active`. An ambiguous or partial human response keeps the epic in `awaiting-epic-signoff`.

Per-child escape hatches (both preserve today's behavior where it still matters):

- A human may label any child `needs-human-spec` (at Gate 1 or any time before implementation) to restore the per-child blocking spec gate for that child.
- The spec drafter's `QUESTIONS_FOR_HUMAN` path is unchanged: genuine product ambiguity stops and asks regardless of delegation.

### Gate 2 — Production Entry (blocking, manual)

Unchanged in mechanics, elevated in status: `submit-epic-pr` opens the epic PR only after the full-regression hard gate, posts a **scannable readiness summary** (TL;DR + key points: what shipped, risks, migrations, coverage, known gaps), and stops. Merging the epic PR is a human action, always — downstream automation deploys merged PRs to production, so this gate is the production control point. No skill may merge, auto-merge, or enable auto-merge on an epic PR.

### Between the gates

Fully autonomous: child specs, plans, implementation, review loops, tests, verification, quality gates, child PRs, and child merges. The human hears about progress through PM comments, and is interrupted only by event-driven exceptions: demotions, blockers, auth/tool failures, `QUESTIONS_FOR_HUMAN`, and the two gates.

## Scannable Artifact Convention

Every human-facing artifact opens with:

```markdown
## TL;DR

2–3 sentences: what this is and what it does.

## Key Points

- 5–9 bullets: decisions made, tradeoffs taken, what is in and out of scope,
  risks, and assumptions — prefix delegated assumptions with ⚠.
```

Rules:

- Applies to: specs (brainstorm and spec-drafter output), the Gate 1 package, the epic readiness summary, and every notification sent to `humanContact`.
- The header must be self-sufficient: a human who reads nothing else can approve or redirect from it.
- Everything below the header is written for agents — completeness there is unconstrained.
- Notifications carry only the header plus links to the full artifacts.
- Spec reviewers verify the header exists and faithfully reflects the body; a stale or missing header is a review finding.

## Deliver-Ticket Lane

New skill `deliver-ticket` (`model: sonnet`). One lane session per child ticket, in that child's worktree.

Inputs: ticket id, clean spec, clean plan (with Testing Contract), epic branch, repo path, child branch/worktree (created via `pickup-ticket` as the lane's first step).

Internal sequence — each step is the existing phase skill's process, executed inside the lane with the same worker dispatch discipline (implementer subagents per task, fresh-context reviewers with opus rounds + one fable final round, haiku test runners, quality gate):

1. `pickup-ticket` — branch + worktree from the epic branch.
2. `implement-ticket` — implementers per task, exact plan adherence.
3. `review` (pre-PR context) — loop capped at 5 rounds + fable final round.
4. `create-tests` — satisfy the Testing Contract.
5. `verify` — test-runner workers per group, digests only.
6. `quality-gate` — horizontal checks.
7. `submit-ticket-pr` (open + body only) — push, open the child PR against the epic branch.
8. `review` (child-PR context) — PR reviewer and local CI runner in parallel.
9. Report `ready-to-merge-child` with the full evidence trail. **The lane never merges.**

Checkpoints: the lane posts the existing per-state PM comments (`implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, `child-pr-reviewing`) as it crosses each boundary. These are the audit trail and the resume contract.

Exit states:

- `ready-to-merge-child` — success; hand off to the orchestrator's merge step.
- demote-to-spec — judgment surprise at any step; the lane comments per the demotion rules and exits. It never redesigns mid-flight.
- blocked — concrete blocker (auth, tooling, harness impossible); comment and exit.

Resume: a dead or expired lane is re-dispatched fresh; it reconstructs position from the checkpoint comments and durable state (commits, branches, PR state) and continues from the last completed boundary. Lane context stays lean because bulk work lives in sub-workers; if a lane's context runs long, it checkpoints and exits `RESUMABLE`, and the orchestrator re-dispatches.

## Parallelism Policy

- `maxParallelLanes`: orchestrator input, default **2**.
- Two children may run concurrently only if: no dependency edge between them in the assess-epic dependency map, and their plans' File Structure sections predict disjoint file surfaces. Any predicted overlap — including shared config, schema, or generated files — forces serialization. When in doubt, serialize.
- Lanes never write to the epic branch. Merges into the epic branch are orchestrator-owned, strictly serial: currency check against the epic head → squash merge → the next merging lane syncs and reruns relevant checks per the existing child-PR rules.
- The spec lane (`mature-ticket`) may run concurrently with delivery lanes; it touches artifacts, not the epic branch. State-advancing PM writes remain one at a time per ticket.
- Read-only workers keep fanning out freely inside every lane.

## Orchestrator Changes

Allowed next actions become:

- Run `pickup-epic`.
- Run `assess-epic`.
- Request Gate 1 signoff (assemble the package, notify, wait).
- Run `mature-ticket` for children lacking readiness (auto-delegated after Gate 1).
- Dispatch `deliver-ticket` for a ready child (up to `maxParallelLanes`).
- Merge a `ready-to-merge-child` lane result (serial).
- Run `submit-epic-pr` when all children are done.
- Stop: human question, blocker, `awaiting-epic-signoff`, `epic-pr-open` (Gate 2).

Externally tracked child states collapse to: spec lane (unchanged) → `ready-to-implement` → `delivering` → `ready-to-merge-child` → `done`. The intermediate delivery states remain visible as checkpoint comments but are no longer orchestrator transitions. `state-transitions.md` gains the lane-boundary table; the inner table is retained as the lane's internal checkpoint contract.

Evidence rule unchanged: `done` only on evidence-checker citations (merge commit present, PM comment posted), never on a lane's claim.

## Context Hygiene: Compaction at Logical Stop Points

Long-running sessions (the orchestrator, delivery lanes) must not drift into harness-forced compaction at arbitrary token thresholds — that summarizes mid-thought and loses state unpredictably. Instead, compact deliberately: **a deliberate compaction is a voluntary crash + resume.** The durable checkpoints and resume contract that make lanes crash-safe are exactly what make a deliberate reset lossless, and the mechanism is harness-neutral (it relies on durable state, not on any harness's compaction behavior).

The judgment call "is now a good time?" is converted into four rules:

1. **The Resumability Test defines a logical stop point.** A point is a legal reset point iff a fresh session, given only durable state (PM labels/comments, artifact links, branches, commits, the run ledger), would choose the same next action. Every checkpoint boundary that passes this test is a candidate.
2. **Mandatory anchors make the common case mechanical.** The orchestrator resets after Gate 1 approval and after every child merge. A lane resets once at its biggest seam — after `quality-gating` is clean, before the PR stage. No judgment needed at these points; they always pass the test.
3. **Emergency valve, never mid-step.** If the harness warns that context is running low between anchors, finish the current step (never abandon a review round, a merge, or a dispatch mid-flight), write a checkpoint comment, and exit `RESUMABLE` for re-dispatch. If a step cannot complete, write an explicit "interrupted at" comment so the resume does not double-execute.
4. **Bias rule for what survives.** Durable state captures decisions but not soft signal — flaky tests noticed, a worker that needed two retries, a module that smells fragile. Sessions keep an append-only **notes** section (epic comment or run ledger entries) and write such observations *as they occur*, not at reset time. When unsure whether an observation is worth persisting: write it. Notes are cheap; lost context is not.

Reset mechanics — the **continuation brief** written at every reset point (and consumed by the re-dispatched session before anything else):

- current state per the transition tables, with evidence links
- the chosen next action and one line of why
- open concerns from the notes section that remain live
- anything in flight that must NOT be redone (e.g. "child PR #42 already open")

Harness-native auto-compaction remains as a backstop only; the goal is that it rarely fires because sessions reset first, at good boundaries, on their own schedule.

## Out of Scope

- `decompose-epic` (drafting child tickets for an epic that has none) — Gate 1 assumes children exist; decomposition drafting is a follow-up skill.
- The devops leg (babysit-epic-pr CI triage, post-merge verification) — separate release.
- Raising `maxParallelLanes` beyond 2 — revisit after observing merge-conflict and rebase-churn rates.
- Cross-epic parallelism.

## Versioning

Ships as `0.11.0`: new `deliver-ticket` skill, orchestrator + state-transitions updates, Gate 1 mechanics in `assess-epic`/`mature-ticket`/`epic-orchestrator`, scannable-artifact convention in `brainstorm`, `mature-ticket` (spec-drafter, spec-reviewer), `submit-epic-pr`, and the ticket-comment templates.
