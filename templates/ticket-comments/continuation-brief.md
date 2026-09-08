# Continuation Brief

Epic: `<epic-ticket-id>` · Session run id: `<session-run-id>` · Exit: `<RESUMABLE | parked | bloat-handoff | refresh-park>`

Ticket / lane: `<ticket-id> / <deliver | mature | between-lanes>`

Durable surface: `<remote>/<branch>` · SHA: `<commit-sha>` · Last completed seam: `<checkpoint-or-state-boundary>`

Cleanup: `<pending | complete | incomplete>` · Evidence: `<clean-park-receipt-or-close-out-links>`

## State Map Reference

- `<link to the latest state-reader map / register canon / relevant checkpoints>`

## Chosen Next Action

- `<the next action a fresh successor should select, and one line of why>`

## Live Concerns

- `<flaky tests, retried workers, fragile modules — one line each, or "none">`

## In Flight (must not be redone)

- `<open PRs, running lanes, partial close-outs with their resume keys (claim ids, SHA-keyed evidence, manifest reap records), or "none">`
- Completed review executors beside the running gate-ledger tally (repeat once per completed round, or "none"): `review-executor: <gate>/<round> runtime=<claude-code|codex|grok-build> model=<native-dispatch-pin> effort=<native-requested-effort|inherited> source=dispatch`
