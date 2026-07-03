# Ticket Claim

Ticket: `<ticket-id>`

## Claim

- Host: `<hostname>`
- Claimed at: `<ISO-8601 timestamp>`
- Action: `<mature-ticket | deliver-ticket | merge-child | submit-epic-pr>`
- Lease window: `<duration, default 2h>`

## Attempt

- Consecutive attempt: `<n>` of `<retry ceiling>`
- Prior checkpoint: `<link to last checkpoint comment, or none>`

## Exit

- Exit state: `<completed | RESUMABLE | demoted | blocked | released-no-op>`
- Evidence: `<links: checkpoint comments, PR, commits>`
- Exited at: `<ISO-8601 timestamp>`
