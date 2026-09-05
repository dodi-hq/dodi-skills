---
name: brainstorm
description: Use before any feature, design, or non-trivial change — explores intent, constraints, and design before implementation
---

# Brainstorm

Turn ideas into designs through collaborative dialogue. Understand context, ask questions, propose approaches, get approval, write the spec.

Do NOT write code, scaffold, or invoke implementation skills until the user approves the design.

## Process

1. **Explore context** — dispatch parallel background research subagents (Standard tier — `model: sonnet` on Claude Code) for files, docs, and recent commits; ask the first clarifying question while they run. Keep the main loop in dialogue — don't read 40 files between user messages.
2. **Ask clarifying questions** — one at a time, prefer multiple choice
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — section by section, get approval incrementally
5. **Write spec** — save to `docs/specs/YYYY-MM-DD-<topic>-design.md`, commit. The spec leads with the scannable header: `## TL;DR` (2-3 sentences) then `## Key Points` (5-9 bullets: decisions, tradeoffs, in/out scope, risks, ⚠-flagged assumptions). The header must be self-sufficient — a human who reads nothing else can approve or redirect from it. Everything below is written for agents.
6. **Spec review loop** — dispatch spec-reviewer subagent (see spec-reviewer-prompt.md). If it reports any issues, fix them and dispatch a fresh spec-reviewer again, passing your own applied/declined list as the prior round (the Prior round input in spec-reviewer-prompt.md). Repeat until a review round comes back clean with zero issues. Do not exit the loop on a round that still has findings — the final round must be clean.
7. **User review gate** — ask user to review the written spec before proceeding
8. **Transition** — invoke `dodi-dev:write-plan`

## Research Delegation

Unfamiliar territory gets researched by workers, not by the main loop — external/integration API docs (auth, endpoints, rate limits, webhooks, gotchas), the local test-harness setup, existing integrations, prior art. Dispatch these in parallel where independent.

- Every research dispatch pins Standard tier explicitly (`model: sonnet` on Claude Code). Never let a research worker inherit the session model — the session runs Frontier for design judgment, and a read-and-digest task gains nothing from it.
- Workers return a compact digest (~20 lines) with source links (doc URLs, file paths); no pasted docs or transcripts.
- The main loop interrogates the digests and owns every design conclusion drawn from them — workers report what is, the Frontier loop decides what it means.

## Design Principles

- **One question per message** — don't overwhelm
- **YAGNI ruthlessly** — cut unnecessary features
- **Design for clear boundaries** — each unit has one purpose, a well-defined interface, and can be understood independently
- **Follow existing patterns** — explore the codebase before proposing changes
- **Scale detail to complexity** — a few sentences for simple sections, more for nuanced ones

## Scope Check

If the request spans multiple independent subsystems, decompose into sub-projects first. Each gets its own spec → plan → implementation cycle.
