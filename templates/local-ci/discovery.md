# Local CI-Equivalent Discovery

Use this checklist when a repo does not already declare a local CI-equivalent command set.

1. Read `AGENTS.md` and `CLAUDE.md`.
2. Inspect package scripts, Makefiles, CI workflow files, and project docs.
3. Identify commands for:
   - dependency install/check
   - format check
   - lint
   - typecheck or build
   - unit tests
   - integration tests
   - e2e tests
4. Compare commands against the ticket Testing Contract.
5. Set up missing required harnesses when feasible.
6. Record the chosen command set before running it.
7. Report commands, exit codes, and failure classification.

Do not skip a required test group solely because a harness is missing. Set up the harness or report a concrete blocker.
