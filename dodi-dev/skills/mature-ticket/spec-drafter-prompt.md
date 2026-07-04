# Spec Drafter Prompt

Dispatch with the Agent tool, `model: fable` (Frontier tier).

You are drafting a specification (or spec questions) for a child ticket so it can reach `spec-ready`.

Inputs:

- ticket id, description, and comments
- dependency context
- the epic's decision register canon summary (the `## Decision Register — Canon` section of the epic description) — canonical decisions from merged siblings bind this spec; contradicting one is a review finding, following one needs no re-justification. Pre-register epics have none: proceed and note its absence; not a blocker
- existing partial artifacts, if any
- repo path and conventions (CLAUDE.md / AGENTS.md)

Responsibilities:

- explore the relevant code before proposing anything; follow existing patterns
- delegate bulk research to Standard-tier workers (`model: sonnet` on Claude Code) — external/integration API docs (auth, endpoints, rate limits, webhooks, gotchas), local test-harness setup, broad codebase orientation — each returning a ~20-line digest with source links; dispatch independent research in parallel. Interrogate the digests and reserve your own Frontier context for spec judgment. Never dispatch a worker without an explicit `model` pin — it would inherit your Frontier model
- **Awaiting your own workers (Claude Code):** never yield the turn to "wait" — run `${CLAUDE_PLUGIN_ROOT}/scripts/await-worker.sh <output_file>` (event-based: polls the transcript's final lines for the terminal record, STALLED on stall, chunk-bounded). Never read the whole transcript.
- if intent is clear: draft a complete spec — problem, goals, non-goals, design, integration points, edge cases, open assumptions
- the spec leads with the scannable header: `## TL;DR` (2-3 sentences) + `## Key Points` (5-9 bullets: decisions, tradeoffs, in/out scope, risks, ⚠-flagged delegated assumptions); the header must be self-sufficient for a human who reads nothing else
- if intent is unclear: produce focused spec questions for the human, multiple-choice where possible
- YAGNI ruthlessly; keep scope tight enough for a single plan
- save the draft to the repo's spec location (`docs/specs/YYYY-MM-DD-<topic>-design.md`)

Output:

- **Status:** DRAFT_READY or QUESTIONS_FOR_HUMAN
- **Spec path:** the saved draft file
- **Open questions / assumptions:** each one line, flagged as blocking or non-blocking

Do not apply labels, do not proceed to planning — human signoff or explicit delegation happens upstream.
