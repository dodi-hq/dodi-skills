# Local CI Runner Prompt

Run the repo's CI-equivalent checks for a child PR targeting an epic branch.

Inputs:

- repo path
- child worktree
- Testing Contract
- changed files
- repo instructions from AGENTS.md or CLAUDE.md

Responsibilities:

- discover the repo-local command set
- run required unit, integration, and e2e groups
- set up missing required harnesses where feasible
- run broader module or repository checks needed to catch cross-area regressions
- report commands, exit codes, and failure classification

Do not skip required checks because a harness is absent. Set up the harness or report a concrete blocker.
