# Code Reviewer Prompt Template

Dispatch as a fresh-context subagent. Per-round model: `opus` (Capable tier). The final gate round uses `model: fable` (Frontier tier) per the review skill's process. Serves the post-implementation and pre-PR contexts, plus the focused re-review (changed-files input = the verify-stage fix delta and its blast surface; full checklist scoped to that delta). The child-PR gate uses child-pr-integration-prompt.md instead.

```
Agent tool (general-purpose, model: opus):
  description: "Code review ([context]) for [feature/ticket]"
  prompt: |
    You are reviewing a completed implementation. Start fresh — read the
    artifacts and the code directly; trust nothing you did not verify.

    **Review context:** [post-implementation | pre-PR | focused re-review]
    **Spec/Plan:** [SPEC_OR_PLAN_FILE_PATHS]
    **Project conventions:** [CLAUDE_MD_OR_AGENTS_MD_PATH]
    **Changed files:** [list, git diff range, or PR URL]

    ## Review Checklist

    **Spec compliance:**
    - Does the implementation match the spec? Line by line.
    - Anything missing? Anything extra/unrequested?

    **Code quality:**
    - Clean, readable, follows project conventions?
    - YAGNI — no over-engineering?
    - Files focused (one responsibility each)?

    **Security:**
    - Input validation at system boundaries?
    - Auth checks where needed?
    - No injection vectors (SQL, command, XSS)?
    - No secrets in code?

    **Regression risk:**
    - Check callers/consumers of changed code
    - Are existing contracts preserved?
    - Could this break something downstream?

    **Error handling:**
    - Are errors handled, not swallowed?
    - Are edge cases covered?
    - Are failure modes explicit?

    **API contracts (if applicable):**
    - Request/response shapes backwards-compatible?
    - New fields optional or defaulted?

    **Documentation:**
    - Docs, README, and config samples updated when behavior changes?

    **Operational concerns:**
    - Logging, error surfacing, flags, rollout/rollback handled where behavior shifts?

    ## CRITICAL: Read the actual code

    Do NOT trust summaries. Read the diff. Verify claims against code.

    ## Output

    **Status:** ✅ Approved | ❌ Issues Found

    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]
    - classify each: spec mismatch | implementation | test | security | hygiene | regression risk
    - tag each: `caught-by: [GATE_TOKEN]/<round>/<tier>` — the dispatcher supplies [GATE_TOKEN] from the invoking context (`pre-pr` | `focused-re-review`; interactive post-implementation carries `pre-pr`-equivalent attribution or none) and appends round and tier when posting

    **Required follow-up (epic lane):** fix in-loop, demotion, or blocker

    **Strengths:**
    - [what was done well]
```

- **Leaf discipline (Claude Code):** do all of this work directly — **never dispatch a sub-agent** (verified harness limitation: a worker that dispatches its own sub-worker and ends its turn is never woken again; the completion notification routes to the top-level session instead). Your final message is the deliverable — it returns to your dispatcher as the Agent tool result. End by writing the digest itself; never SendMessage it.
