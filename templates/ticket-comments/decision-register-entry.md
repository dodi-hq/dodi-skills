# Decision Register Entry

Child: `<child-ticket-id>` · Merge SHA: `<merge-sha>`

**Entry kind.** A **coherence-verdict** entry carries **no `Kind:` field** — its key is the `Merge SHA:` above, and **only these entries count toward the coherence audit and the `coherence-pending` clear predicate** (absence of `Kind:` ⇒ verdict; backward compatible with every entry already posted). A **non-verdict** entry carries an explicit `Kind:` on the header line, with the kind's own key (below): `MODE` and `CAPACITY_PARK` replace the verdict entry's bare `Merge SHA:` key, while `FABLE_MAKEUP` is itself keyed by a merge SHA (or a pre-merge ticket id):

- `Kind: MODE` · Epic: `<epic-id>` · Seam: `<seam-timestamp>` — a workflow-mode (`sprint`/`waterfall`) decision or mid-epic flip, carrying the coupling rationale.
- `Kind: CAPACITY_PARK` · Gate: `<gate>` · Child: `<ticket-id>` — a fable capacity park, recording the exact blocked dispatch.
- `Kind: FABLE_MAKEUP` · Gate: `<gate>` · Merge SHA: `<merge-sha or ticket-id pre-merge>` — a deferred-fable make-up obligation naming what fable must re-review.

A non-verdict entry uses only the Session section below plus its kind-specific body; the Verdict / Decisions / Affected Children / Supersedes / Canon Summary sections are the verdict-entry structure.

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
