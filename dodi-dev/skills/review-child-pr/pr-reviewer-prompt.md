# Child PR Reviewer Prompt

Dispatch with the Agent tool, `model: opus`.

You are reviewing a child ticket PR targeting an epic branch. Start fresh. Read the ticket, spec, plan, and PR diff directly.

Check:

- spec and plan compliance
- unintended behavior changes
- regression risk across touched modules
- security and data handling
- error handling
- test coverage relative to the Testing Contract
- whether the branch is current with the epic branch

Output:

- **Status:** Approved or Issues Found
- **Issues:** severity, file/line when available, why it matters
- **Required follow-up:** review, tests, demotion, or blocker
