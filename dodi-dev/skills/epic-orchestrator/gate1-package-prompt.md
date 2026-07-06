# Gate 1 Package Prompt

Dispatch with the Agent tool, `model: fable` (Frontier tier). Read-only with respect to code; writes only the package artifact.

You are drafting the epic intent signoff package — the one document the human reads before delegating the entire epic. It must be self-sufficient at the header level: a human who reads nothing below Key Points can approve or redirect.

Inputs:

- epic id, description, and comments
- the assess-epic state map and dependency map
- child ticket list with descriptions
- any existing spec artifacts

Output — the package, following the scannable artifact convention:

```markdown
## TL;DR

2–3 sentences: what this epic delivers and why.

## Key Points

- 5–9 bullets: the key decisions approval will lock in, tradeoffs taken,
  what is in and out of scope, risks, and delegated assumptions —
  prefix every assumption the human is delegating with ⚠.

## Children

- `<ticket-id>` — one-line intent — depends on: `<ids or none>`
  — suffix `⚠ likely capable-tier delivery` for children whose intent reads
  invariant-dense (concurrency/locking, distributed-state reconciliation,
  ordering/idempotence, cross-component state machines)

## Needs Human Input

- children that should carry `needs-human-spec`, with one line of why (or none)
```

Rules:

- YAGNI on the epic scope: flag scope creep across children as a key point, do not silently accept it.
- Every ⚠ assumption must be concrete enough that approval genuinely delegates it ("⚠ soft-delete, not hard-delete" — not "⚠ some data questions").
- The `⚠ likely capable-tier delivery` suffix is advisory cost-profile visibility for the human — the binding classification happens at plan review (`needs-capable-delivery`, see `mature-ticket`). Flag from intent, do not deep-read code to decide.
- Do not apply labels or notify anyone; return the package to the orchestrator.

Report: **Status:** PACKAGE_READY or QUESTIONS_FOR_HUMAN, plus the package (or the blocking questions).

- **Leaf discipline (Claude Code):** do all of this work directly — **never dispatch a sub-agent** (verified harness limitation: a worker that dispatches its own sub-worker and ends its turn is never woken again; the completion notification routes to the top-level session instead). Your final message is the deliverable — it returns to your dispatcher as the Agent tool result. End by writing the digest itself; never SendMessage it.
