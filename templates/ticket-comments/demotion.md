# Workflow Demotion

Ticket: `<ticket-id>`

## Current State

`<state>`

## Demotion Target

`<needs-spec|awaiting-human-spec|needs-plan>`

## Triggering Evidence

- `<review finding, test failure, worker report, or command output>`

## Rework Origin

`rework-origin: <spec|plan> caught-at=<gate>/<round>/<tier>`

`gate-ledger: <gate> rounds=<n> findings=<b/a[,b/a...]> outcome=escalated final=<tier>` `<only when the demotion closes a looped review gate>`

## Why Automation Cannot Continue

`<reason>`

## Human Question

`<specific decision needed>`

## Artifacts To Revise

- Spec: `<path-or-url-or-none>`
- Plan: `<path-or-url-or-none>`
- PR: `<url-or-none>`
