# Florist Companion Required for Child Review

## TL;DR

The skill sequence requires kernel enforcement before enabling the experiment in Florist. The inspected kernel fences child HEAD but does not validate the pre-opening combined approval, epic base or decision context, or publish staged canon only after a confirmed merge.

## Key Points

- Do not enable this contract by setting a worker environment flag alone.
- Keep implementing, code-review and integrating seats and the existing digest vocabulary.
- The kernel must validate review coverage at PR creation and again in the serial merge slot.
- A changed epic base or semantic decision context invalidates same-HEAD approval.
- Pending-action recovery needs the same pins as the original irreversible action.
- Canon proposals publish only after confirmed merge, with crash-safe recovery.
- Existing implementation-tier routing and epic-to-master behavior remain unchanged.

## Required companion work (separate repository)

Agreed transport: `artifact ref=child-review:<safe-relative-locator> sha=<head>`, with `.dodi/florist-child-review.json` as the recommended untracked worker cache. The resolver validates and immutably ingests this JSON and referenced report/dispatch evidence. A mutable local file alone is not durable approval. The companion can resolve unchanged coverage in the kernel without a provider invocation, but must record explicit reuse and preserve lane/lease/pin/slot checks. Provider seats remain the path for sync or meaningful renewal; count coordinator sessions separately from substantive reviews.

The agreed envelope extends the schema-1 record in `child-review-contract.md` with `reports: {review, dispatch, verification}` containing the full nonempty report texts, and `proposal: {canon, entry, affected: [unit ids]}`. Content-SHA256 receipt ids preserve distinct immutable renewals even at an unchanged identity. The full review report retains every coherence field and explicit per-child routing obligation; the affected-id summary alone never authorizes inferred label changes. Preserve the current canon for a no-change proposal. The base helper accepts extra fields but does not validate this packaging; the companion must do so before accepting evidence.

The companion exports `FLORIST_CHILD_REVIEW_INPUT_COMMAND` (JSON argv array, invoke without a shell) and `FLORIST_CHILD_REVIEW_INPUT_PATH` (`{identity, context}` output). Workers run the read-only source refresh command **before** reading that file and before final/renewal/freshness checks; a cached launch snapshot is not current evidence. The command uses the worker tracker credential plus a minimal exported metadata manifest, never DB/kernel credentials, and writes only the local `.dodi` input. Source/hash schema is shared with the kernel, not reimplemented by each worker. Changed kernel topology, admission, or sibling approval readiness needs redispatch; every action still independently checks authoritative current state, including a fresh barrier/semantic-metadata read after slow external reads. The manifest's sibling lane and accepted contract SHA distinguish known not-yet-approved artifact absences (explicitly hashed) from unreadable expected approved sources (blocking). Refresh errors block without stale-file fallback. See `child-review-contract.md` for invocation and hashing the inner `context` object.

Read-only inspection of the Florist source found these concrete integration points:

- `src/worker/worker-manager.ts`, implementing outcome: `impl-ready` accepts any `thread` row without requiring its SHA to equal HEAD; only artifact and CI rows must match. Require the combined review record at HEAD, Frontier correctness/coherence approval with the original dispatch/report evidence, and its base/context identity. Store the immutable record, not just an opaque URL claimed clean by a worker.
- `src/worker/worker-manager.ts`, code-review outcome: retain `clean-final` and its manager-reserved marker, but allow an explicit validated reuse record tied to the original Frontier report. Do not require a new dispatch on unchanged evidence; reject stale/missing evidence.
- `src/worker/worker-manager.ts`, `applyMergeReady`: preserve the integration slot, gate/lease fences, branch pin and verdict routing. Validate the same review identity again while serialized. Preserve Gate 1 parks and drift escalation; reject pre-merge material drift rather than treating it as merge permission.
- `src/gateway/github.ts`, `createPr` and `mergeChild`, plus pending-action marker/recovery types: currently action markers name `branch` and `expectedHead`. Add target repo/ref, reviewed epic/base and decision-context revision pins, and revalidate against authoritative sources at the action boundary. Revalidate the current base and authoritative relevant approved context immediately before acting, using existing integration serialization/checkpoints. Handle recovery with the same pins. The kernel cannot lock external tracker edits; record the residual check/action race and conservatively invalidate detected drift, without claiming atomicity.
- Use the existing dispatcher-authored native request/report evidence (`source=dispatch`); validate the complete record and preserve its provenance. The kernel cannot independently attest a nested model execution. A worker boolean alone is not evidence, but no signed attestation system is required. Transport must ingest the full record durably from an allowed locator rather than trust an arbitrary `ref` string.
- After confirming `child-merge`, retain the integration barrier through idempotent publication of the staged canon proposal and affected-sibling routing, keyed to the real merge SHA. Recovery must finish this publication before releasing siblings. The pre-merge worker must not update canon. Preserve merged-SHA audit recovery and human ruling semantics. Retain Florist's existing `merge_method=merge`; transfer approval only with the same first-parent/base and merged-tree/child-tree proof as manual delivery, without changing either runtime's merge method.
- `src/worker` spawn environment/config: advertise `FLORIST_CHILD_REVIEW_CONTRACT=frontier-pre-pr-v1` only after the above enforcement is deployed. Router seats and implementation/fix-worker tiers stay as configured; skill leaf dispatches provide the hard Frontier final on **all** epic tiers. Export the capability through the environment allowlist and provide durable review/context inputs. No change to digest token grammar is required; records can ride existing `thread`/`artifact` evidence, but their content must now be checked.

Until that companion is deployed, each delivery seat runs:

`python3 "${CLAUDE_PLUGIN_ROOT}/scripts/child-review-gate.py" require-kernel`

A failure means record the missing capability and emit `blocked reason=worker-blocked` through `florist-digest.sh`, then stop. This guard is a rollout compatibility check, not proof of enforcement. Manual lanes do not need the kernel capability, but retain their own serialized action and live-read obligations. Never revert to Capable coherence or the old stale-review acceptance path to make a dispatch succeed.

Companion acceptance tests must cover: missing/wrong-tier pre-PR review; unchanged reuse in both seats; head/base/context drift; detected freshness loss before action; CI mismatch; pending-action recovery; sync returning `synced` to code-review; Gate 1 flags/material drift blocking; and crash-safe post-merge canon publication before sibling unfreeze. No Florist source changes are included in this plugin change.
