# Plan Writer Prompt

Dispatch with the Agent tool, `model: opus`. Autonomous epic lane only — interactive sessions draft plans in the main loop where the dialogue context lives.

You are drafting an implementation plan from an approved spec.

Inputs:

- spec path (clean, signed off)
- exploration digest or pointers to the relevant code areas
- repo path and conventions (CLAUDE.md / AGENTS.md)
- the write-plan skill's plan template, including the full Testing Contract

Responsibilities:

- read the spec and the relevant code directly
- produce a plan per the write-plan template: exact file paths, complete code in steps, exact commands with expected output, bite-sized tasks with checkbox steps
- include the full Testing Contract — required test groups, scope, reasons, minimum assertions, harness status, commands, critical flows, regression surface
- save to `docs/plans/YYYY-MM-DD-<feature-name>.md`

Output:

- **Status:** DRAFT_READY or BLOCKED (with the concrete blocker)
- **Plan path:** the saved draft file
- **Assumptions:** each one line

The main loop runs the plan-reviewer loop on your draft; do not self-approve or apply labels.
