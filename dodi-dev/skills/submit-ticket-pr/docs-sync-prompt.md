# Docs-Sync Worker Prompt Template

Dispatch with the Agent tool at Frontier tier (`model: fable` on Claude Code). One prompt, two seats, distinguished by mode — the executing session performs the gate-policy lookup immediately before writing the pin (AGENTS.md § Fable Availability Policy):

- **child mode** (`submit-ticket-pr` Open): policy **soft** — `opus` substitutes, attributed, no make-up; the epic sweep is the designed backstop.
- **epic-sweep mode** (`submit-epic-pr` attempt start): policy **hard** — fable unavailable ⇒ `pending-capacity` park; the epic PR does not open with an unswept docs surface.

The worker judges whether the diff makes the module-level agent metadata files (`CLAUDE.md` / `AGENTS.md`, per module and sub-module) false, incomplete, or misleading — and makes the smallest true edit when it does. It edits doc files in the worktree; **the walking session commits** (single-writer discipline). "No update needed" is a decision with a recorded reason, never a silent skip.

```
Agent tool (general-purpose, model: fable):
  description: "Docs-sync ([child|epic-sweep]) for [TICKET_OR_EPIC_ID]"
  prompt: |
    You are the docs-sync judge (Frontier tier, or the tier this dispatch pins
    under the gate's fable-policy). For a change about to become a PR:
    module-level CLAUDE.md / AGENTS.md files are ground truth for every future session that
    works in this repo; your job is to decide whether this diff made any of
    them stale — and to fix exactly that, nothing more.

    **Mode:** [child — this ticket's slice | epic-sweep — cross-child coherence:
    catch cumulative drift across children in the same module, and epic-level
    statements (root docs, cross-module contracts) no single child owned]
    **Worktree:** [WORKTREE_PATH]
    **Diff scope:** [child: EPIC_BRANCH...CHILD_HEAD | epic-sweep: BASE...EPIC_HEAD, post-sync]
    **Change intent:** [child: TICKET_SPEC | epic-sweep: EPIC_DESIGN_ARTIFACT + DECISION_REGISTER_CANON_SUMMARY]

    ## Discovery

    For each changed path in the diff, walk upward collecting every CLAUDE.md
    and AGENTS.md between it and the repo root: nearest module doc, sub-module
    docs on the way, and the root doc. That set is your review surface.

    ## Judgment

    Per discovered doc file, judge whether the diff makes any statement in it
    false, incomplete, or misleading — architecture and responsibility
    placement, public contracts and data shapes, invariants, cross-module
    conventions, commands/workflows, module existence.

    - **Update** when the diff moves any of those.
    - **No-op** when the diff is a behavior-preserving fix, test-only,
      comment/typo-level, or an internal refactor with unchanged contracts.
    - **When in doubt ⇒ update.** The review gates downstream catch
      over-eagerness; nothing catches silent staleness.

    ## Editing Rules

    - Smallest true edit: correct the stale statements, add what a future
      session must know, nothing else. No wholesale rewrites, no style passes.
    - Create a new module doc only when the diff introduces a new module that
      peers document — never for coverage's sake.
    - When a module carries both CLAUDE.md and AGENTS.md covering the same
      ground, keep both consistent; the sync itself must not create drift.
    - Doc files only — never touch code, config, or tests.
    - Edit in the worktree; do NOT commit — your dispatcher commits.

    ## Return

    A digest only, leading with exactly one evidence line, verbatim grammar:

        docs-sync: updated <path>[, <path>...]
        docs-sync: no update — <one-line reason>

    Then: per-file rationale (one line each — what became stale, or why the
    file needed nothing). Never paste the diff or full doc contents back.

    **Leaf discipline (Claude Code):** do all of this work directly — never
    dispatch a sub-agent (verified harness limitation: a worker that
    dispatches its own sub-worker and ends its turn is never woken again).
    Your final message is the deliverable — it returns to your dispatcher as
    the Agent tool result. End by writing the digest itself; never
    SendMessage it.
```
