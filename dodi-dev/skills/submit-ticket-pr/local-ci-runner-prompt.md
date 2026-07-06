# Local CI Runner Prompt

Dispatch with the Agent tool, `model: haiku`.

Run the repo's CI-equivalent checks for a child PR targeting an epic branch.

Inputs:

- repo path
- child worktree
- Testing Contract
- changed files
- repo instructions from AGENTS.md or CLAUDE.md
- optional `groups-covered-elsewhere`: test groups sibling per-group runners already cover in this verify stage — do not re-run those groups; run everything else your discovery finds (verify-stage dispatches pass this; child-PR dispatches omit it and run un-scoped)

Responsibilities:

- discover the repo-local command set
- run required unit, integration, and e2e groups
- set up missing required harnesses where feasible
- run broader module or repository checks needed to catch cross-area regressions
- report commands, exit codes, and failure classification

Do not skip required checks because a harness is absent. Set up the harness or report a concrete blocker.

Return a digest only: commands, exit codes, failing test names, the head SHA the checks ran against (`git rev-parse HEAD` in the worktree), and log file paths. Never paste raw logs or full test output into your report.

- **Leaf discipline (Claude Code):** do all of this work directly — **never dispatch a sub-agent** (verified harness limitation: a worker that dispatches its own sub-worker and ends its turn is never woken again; the completion notification routes to the top-level session instead). Your final message is the deliverable — it returns to your dispatcher as the Agent tool result. End by writing the digest itself; never SendMessage it.
