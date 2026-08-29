# Ready To Implement

Ticket: `<ticket-id>`

## Spec Artifact

- Spec: `<path-or-url>`

## Plan Artifact

- Plan: `<path-or-url>`

## Testing Contract

### Required Test Groups

- Unit: `<required|not-required>`
  - Scope: `<functions/components/modules>`
  - Reason: `<why>`
  - Minimum assertions: `<specific behaviors>`

- Integration: `<required|not-required>`
  - Scope: `<module boundaries/APIs/db/jobs/etc>`
  - Reason: `<why>`
  - Harness: `<existing|setup-required|not-applicable>`
  - Minimum assertions: `<specific flows>`

- E2E: `<required|not-required>`
  - Scope: `<user/business-critical flows>`
  - Reason: `<why>`
  - Harness: `<existing|setup-required|not-applicable>`
  - Minimum assertions: `<specific flows>`

### Critical Flows

- `<flow 1>`
- `<flow 2>`

### Regression Surface

- `<adjacent module or behavior that must not break>`

### Commands

- Unit: `<command or to-be-discovered>`
- Integration: `<command or to-be-discovered>`
- E2E: `<command or to-be-discovered>`
- Broader regression: `<command or to-be-discovered>`

### Harness Requirements

- `<required setup, service, fixture, seed data, browser, env var, mock, account, etc>`

### Non-Required Rationale

- Unit: `<only if not-required>`
- Integration: `<only if not-required>`
- E2E: `<only if not-required>`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

## Dependency State

- `<dependency status>`

## Review Evidence

- Spec review: `<clean evidence>`
- Plan review: `<clean evidence>`
- Gate ledger: `gate-ledger: plan-review rounds=<n> findings=<b/a[,b/a...]> outcome=clean final=<tier>@<effort>`

## Next Action

`pickup-ticket`
