# Lane Checkpoint

Ticket: `<child-ticket-id>` · Boundary: `<implementing | implementation-reviewing | testing | verifying | ready-for-child-pr | child-pr-reviewing>`

## Session

- Run id: `<session-run-id>`
- Posted at: `<ISO-8601 timestamp>`

## Evidence

- `<branch / worktree / plan link / commit ids / review evidence / test files / harness evidence / verification evidence (incl. recorded runner head SHAs at the ready-for-child-pr boundary) — per the boundary's row in state-transitions.md>`
- Review executors when this boundary carries review evidence (repeat once per completed round): `review-executor: <gate>/<round> runtime=<claude-code|codex|grok-build> model=<native-dispatch-pin> effort=<native-requested-effort|inherited> source=dispatch`
- At ready-for-child-pr: `<combined correctness/coherence approval, staged proposal, full child/base/context identity and durable coverage record>`
- On unchanged reuse: `review-reuse: <stage> source=<record> child=<sha> epic=<sha> context=<sha256>`; retain original executor/ledger, no invented review round

## Notes

- `<soft observation worth persisting, one line each, or "none">`
