# Decision Register Entry

Child: `<child-ticket-id>` · Merge SHA: `<merge-sha>`

## Session

- Run id: `<session-run-id>`

## Verdict

`<ALIGNED | MINOR_DRIFT | MATERIAL_DRIFT | LEGITIMATE_DIVERGENCE | RULING>` `<+ GATE1_AMENDMENT / GATE1_REFRESH if flagged>`

## Decisions Recorded

- `<one-paragraph decision statement with evidence links>`

## Affected Children

- `<ticket-id>`: `<labels stripped>` — `<one line why>` (or "none")

## Held Route (GATE1_AMENDMENT only — the not-yet-performed writes the approve branch executes)

- `<canonization / superseded-by note / affected-children label strips the human's approve ruling will perform, recorded held; "n/a" unless GATE1_AMENDMENT>`

## Per-Decision Affected Children (GATE1_REFRESH only — which children's specs consumed EACH superseded decision)

- `<decision>` → `<child-ticket-id, ...>` (recorded by the reviewer so the reject route strips the rejected SUBSET mechanically; "n/a" unless GATE1_REFRESH)

## Supersedes

- `<design point superseded, with superseded-by note link>` (or "none")

## Ruling (RULING variant only — the durable resolution record for a pending-human entry)

- Resolves Merge SHA: `<merge-sha of the pending-human entry>`
- Outcome: `<approve | reject | redirect:<scope>>`
- Writes performed: `<the routed writes — held route executed, or MATERIAL_DRIFT corrective / de-canonization — with links>`

## Canon Summary

Updated: `<yes/no — the "Decision Register — Canon" section of the epic description>`
