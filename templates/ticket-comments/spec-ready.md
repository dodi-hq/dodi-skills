# Spec Ready

Ticket: `<ticket-id>`

## Spec Artifact

- Spec: `<path-or-url>`

## Review Evidence

- Reviewer type: `<product|ux|architect|security|implementation>`
- Final review status: `clean`
- Review artifact or comment: `<path-or-url>`
- Review executors (repeat once per completed round): `review-executor: <gate>/<round> runtime=<claude-code|codex|grok-build> model=<native-dispatch-pin> effort=<native-requested-effort|inherited> source=dispatch`
- Gate ledger: `gate-ledger: spec-review rounds=<n> findings=<b/a[,b/a...]> outcome=clean final=<tier>@<effort>`
- Session tier: `session-tier: tier-degraded(fable@<effort>→<tier>@<effort>,operator-choice)` `<only when this session ran under an operator-choice Frontier-policy substitution — AGENTS.md § Frontier Availability Policy>`

## Human Signoff

- Signoff: `<approved|delegated>`
- Human: `<name-or-contact>`
- Decision summary: `<what was approved or delegated>`

## Assumptions

- `<assumption or none>`

## Next Action

`write-plan`
