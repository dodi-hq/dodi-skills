---
name: file-ticket
description: Use after brainstorming to create a ticket in the project tracker with full context from the design session
model: sonnet
---

# File Ticket

Create a ticket in the project tracker with context from the brainstorm/design session.

## Process

1. Gather from the session:
   - **Title** — concise, action-oriented
   - **Description** — what needs to be built and why
   - **Spec reference** — path to the design spec (if written)
   - **Priority** — infer from context (default: normal)
   - **Type** — feature, bugfix, refactor, or **hotfix** (declared only at filing time — never inferred; see § Hotfix)

2. Create the ticket using available tools (Linear MCP, GitHub Issues, etc.)

3. **Epic decomposition:** when filing an epic's children, register the hard sequencing edges implied by the decomposition as native blocked-by relations at creation time (Linear issue relations, or the tracker's equivalent). The relation graph — not comment prose — is what dispatch eligibility queries; Gate 1 approval canonizes it. Relations carry hard sequencing only; soft coupling signals (predicted file overlap) belong in the assessment — they feed the sprint/waterfall mode decision — not the graph.

4. Confirm with the user — show ticket ID and title

## Ticket Content

The ticket description should include:
- Summary of what was decided during brainstorming
- Link/path to the design spec
- Key constraints or decisions worth highlighting
- NOT the full spec (that lives in the spec file)

## Hotfix (declared, never derived)

`hotfix` is a Type declared **only at filing time** — nothing ever infers it. A ticket filed as `hotfix` carries a `hotfix` label. The label routes the ticket **outside the epic machinery**: the resident driver (`drive-epic`) never selects a `hotfix`-labeled ticket, and a `hotfix` label on an epic child is an escalation. Hotfix work runs on the manual single-ticket path (`pickup`), following the operator-run point-release precedent.

The full minimal-gate hotfix path — entry criteria (prod-broken / time-critical), minimal gates (verify + one review + the human deploy word, the Gate-2 equivalent), and the mandatory auto-filed debt ticket carrying hotfix context for the proper fix — is a follow-up standalone release; 0.16.0 ships only the declaration slot and the route-around.

## Notes

- This skill is tracker-agnostic — use whatever MCP tools are available
- If no tracker tools are available, output the ticket content for the user to create manually
- The ticket ID becomes the branch name in `dodi-dev:pickup`
