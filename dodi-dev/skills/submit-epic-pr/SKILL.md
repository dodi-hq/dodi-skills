---
name: submit-epic-pr
description: Open an epic PR from the epic branch to main/master and leave it open for existing GitHub Actions and review
model: sonnet
---

# Submit Epic PR

Use when all child tickets under an epic are done and merged into the epic branch.

This skill ends at **Gate 2 — production entry**: merged epic PRs are picked up by automation and deployed to production, so the epic PR is opened by this skill and merged only by a human. Never merge, auto-merge, or enable auto-merge.

## Why a Full Regression Gate Before the PR

The epic PR must prove that all child commits work together, not just individually. Child PRs verify each ticket against the epic branch at its own merge time; they do not prove the final integrated head — including the latest main/master sync — is green. Only a full regression run on the integrated epic head proves that.

Treat GitHub Actions CI as the final safety gate before production, not the first line of defense. A full regression run can exceed an hour; it exists to catch true exceptions, not first-order breakage that a local run would surface. Do not throw a red or untested branch over the wall and leave downstream CI to discover what a local run would have caught. Open the epic PR only after the full regression suite passes locally on the integrated epic head.

## Inputs

- epic id
- epic branch
- base branch: main or master
- child ticket list
- child PR links
- epic readiness evidence

## Process

1. Confirm all child tickets are done.
2. **Attempt start.** Everything from here through PR creation is one **epic-PR attempt**; re-entry after any stop begins a new attempt here (a crash successor with still-current clean-round evidence may instead complete the in-flight attempt — step 3). **Clean-tree check:** `git status --porcelain` in the epic worktree must come back empty before anything else — a takeover-orphaned fix worker may have left uncommitted writes; stop and escalate on an unexplained dirty tree, never commit or discard it blindly. Then update the epic branch with the latest main/master.
3. **Integrated-head review round — loop to clean, before the regression gate.** Dispatch a fresh reviewer at Capable tier (`model: opus` on Claude Code) per round (see `epic-integration-reviewer-prompt.md`), reading the post-sync epic diff vs base, the epic design artifact, the Gate 1 package, and the decision-register canon summary + entries. The reviewer classifies every finding **mechanical** or **judgment**: mechanical ≡ **no runtime-behavior effect** (docs, config samples, comments, formatting/hygiene); anything touching **runtime behavior** — flags, contracts, data shapes — is judgment; **when in doubt ⇒ judgment**. Mechanical findings route to fix workers at Standard tier (`model: sonnet` on Claude Code) writing in the epic worktree under the session walking this skill (single-writer discipline — the same writer as the merge slot), then a **fresh round** re-reviews; loop until a round is clean, with the same cap semantics as the `review` skill's loop (cap 5 rounds; cap exhaustion stops and escalates with the unresolved findings — it **never opens the PR**; the epic lands `blocked`). A **judgment** finding is never fixed in place: file a corrective child ticket through the normal pipeline (its own review gates + coherence registration), stop this attempt, and return the epic to `epic-active` via the not-done child. The clean round's evidence records the **reviewed head SHA**; the head is then **frozen for the attempt** — any head movement after the clean round (late sync, conflict fix, corrective child merged) restarts the attempt at this step. Re-entry after a stop is a **new attempt** with a new round; a crash successor whose recorded clean-round evidence is still current with the head (recorded reviewed SHA = current epic head) may complete the attempt from the recorded state instead (SHA-keyed skip-what-exists), else it re-rounds. (The mechanical-fix path bypasses the coherence set-difference audit **by design**: that audit's domain is merged child PRs; judgment — the decision-bearing class — is forced through that domain as a corrective child, and every mechanical commit is re-reviewed by the fresh clean round before the freeze.)
4. **Fable make-up round (conditional) — after the integrated-head round is clean, before the head freeze.** If the epic has any open `Kind: FABLE_MAKEUP` obligations (deferred-fable substitutions queued during delivery — AGENTS.md § Fable Availability Policy), dispatch **one batched fable round** using `epic-integration-reviewer-prompt.md` with a dispatcher-supplied obligations preamble enumerating them (no new prompt file). Findings carry `caught-by: epic-integration/<round>/fable` and route through the same **mechanical/judgment** classification as the integrated-head round (mechanical → fix worker in place; judgment → corrective child ticket). A make-up-driven fix moves the head and **restarts the attempt at step 3** (the make-up round re-runs with the remaining obligations). Each obligation is marked consumed by keyed reference in the round's output. **This round's own fable-policy is hard:** if fable is unavailable at epic-PR time, `pending-capacity` park — the epic PR does not open with unconsumed make-ups. **Zero open obligations ⇒ skip this step entirely.** The existing `opus` integrated-head round (step 3) is unchanged — it is Capable-tier, not a fable seat; this is a distinct, conditional round beside it.
5. Run `verify` as a full regression suite on the integrated epic head — **the frozen head at the reviewed SHA the clean round recorded**: all required unit, integration, and e2e groups across the merged children — the union of child Testing Contracts — must pass. Dispatch one test-runner worker per group (see `verify/test-runner-prompt.md`) and claim results only from the returned digests (commands + exit codes). This is a hard gate. Do not proceed if any required group fails or a required harness cannot be set up.
6. Prepare the epic readiness summary. It leads with the scannable header — `## TL;DR` (what this epic ships, 2-3 sentences) and `## Key Points` (5-9 bullets: what changed, risks, migrations, coverage, known gaps) — self-sufficient for the human who merges. Immediately after the header, a mandatory **`## What Changed Since Signoff`** section: every decision canonized by coherence reviews that diverged from the Gate 1 package, one line each with its register entry link ("none" if the register recorded no divergence) — the merge decision must see the delta, not just the outcome. Below that: child tickets, child PRs, full-regression evidence (commands, exit codes, run on the post-sync epic head), release notes, and coverage detail.
7. **SHA-equality check — evaluated immediately before push/PR-create:** the clean round's reviewed head SHA = the SHA the regression suite ran against = the current epic head (the PR head). Any mismatch means the head moved after the clean round: do not push — restart the attempt at step 3 (the review round). Then push the epic branch.
8. Open a PR from epic branch to main/master. The PR body carries `Closes <epic-id>` plus the full child ticket id list — the closing reference is what drives the PM system's GitHub integration to transition tickets when Gate 2 merges; the `reconcile-tickets` janitor is the backstop.
9. Leave the PR open.
10. Update the epic ticket with the PR link and readiness summary, and notify `humanContact` that Gate 2 is ready — the notification carries the TL;DR + Key Points and the PR link, nothing more.

## Commands

```bash
git checkout <epic-branch>
git fetch origin <base-branch>
git merge --no-ff origin/<base-branch>

# Full regression on the integrated epic head, via `verify`, before pushing.
# Run the union of child Testing Contract commands; all required unit,
# integration, and e2e groups must pass (exit 0) on this post-sync head.

git push -u origin <epic-branch>
gh pr create --base <base-branch> --head <epic-branch> --title "<epic-id>: <title>" --body-file <pr-body-file>
```

Expected evidence:

- latest base sync output
- full regression evidence: commands, exit codes, and the epic head SHA the suite ran against (post-sync)
- integrated-head review evidence incl. reviewed head SHA
- push output or remote branch URL
- epic PR URL
- epic ticket comment with readiness summary

## Rules

- Never merge or auto-merge epic PRs — Gate 2 is human-owned, always.
- Existing GitHub Actions and main-target review automation take over after PR creation.
- Stop if any child ticket is incomplete or reopened.
- Stop if the full regression suite has any failing required group. Classify the failure (test bug, integration bug, environment/harness, spec/plan mismatch), route the fix, and rerun. Do not open the epic PR on a red suite.
- Full-regression evidence must come from a run on the current epic head after the latest main/master sync. Aggregated per-child evidence does not satisfy this gate.
- Stop on unresolved integrated-head review findings: a **judgment** finding stops the attempt with its corrective child ticket filed (the epic returns to `epic-active` via the not-done child); review-loop cap exhaustion stops as `blocked` + escalation. Never open the PR over unresolved findings.
- Stop if syncing latest main/master introduces conflicts or required fixes; return the epic to `epic-active`.
- Stop if PR creation fails; report the blocker with command output.
