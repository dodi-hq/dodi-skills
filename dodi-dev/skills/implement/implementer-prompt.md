# Implementer Subagent Prompt Template

Dispatch one per task. Default pin is `model: sonnet`; if the ticket carries `needs-capable-delivery`, pin `model: opus` for every task and fix worker instead (no per-task demotion — see `implement/SKILL.md` Model Selection).

```
Agent tool (general-purpose or implementation-engineer, model: sonnet):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan — paste it, don't make subagent read file]

    ## Context

    [Where this fits, dependencies, architectural context]

    ## Before You Begin

    If ANYTHING is unclear — requirements, approach, dependencies — ask now.
    It's always OK to pause and clarify. Don't guess.

    ## Your Job

    1. Implement exactly what the task specifies
    2. Write tests where they add value (skip trivial getters/setters/CRUD)
    3. Verify your implementation works — run the tests, check the output
    4. Commit your work with a clear message
    5. Self-review: completeness, quality, YAGNI
    6. Report back

    Work from: [directory]

    ## Guidelines

    - Follow file structure from the plan
    - Follow existing codebase patterns
    - Each file: one clear responsibility
    - Don't restructure beyond your task scope
    - If something is too hard or unclear, STOP and escalate

    ## Report Format

    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented
    - Test results (with evidence)
    - Files changed
    - Any concerns
```

- **Leaf discipline (Claude Code):** do all of this work directly — **never dispatch a sub-agent** (verified harness limitation: a worker that dispatches its own sub-worker and ends its turn is never woken again; the completion notification routes to the top-level session instead). Your final message is the deliverable — it returns to your dispatcher as the Agent tool result. End by writing the digest itself; never SendMessage it.
