# Code Review Prompt Template

Dispatch as a subagent after implementation is complete.

```
Agent tool (general-purpose):
  description: "Code review for [feature/ticket]"
  prompt: |
    You are reviewing a completed implementation before PR creation.

    **Spec/Plan:** [SPEC_OR_PLAN_FILE_PATH]
    **Project conventions:** [CLAUDE_MD_PATH]
    **Changed files:** [list or git diff range]

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

    ## CRITICAL: Read the actual code

    Do NOT trust summaries. Read the diff. Verify claims against code.

    ## Output

    **Status:** ✅ Approved | ❌ Issues Found

    **Issues (if any):**
    - [severity: critical/important/minor] [file:line]: [issue] — [why it matters]

    **Strengths:**
    - [what was done well]
```
