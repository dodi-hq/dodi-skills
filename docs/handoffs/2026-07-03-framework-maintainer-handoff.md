# Framework Maintainer Thread — Handoff (2026-07-03)

## TL;DR

This is the continuation brief for the **dodi-skills framework-maintainer thread** (the session Mike uses to evolve the plugin itself, distinct from the dev-track worker sessions). State: **0.13.5 shipped, pushed, and installed**; the autonomous loop (pickup-next tick + reconcile-tickets janitor + coherence gate + decision register + deterministic skeleton) is fully built and field-patched through five same-day point releases, but the **scheduled tasks are not yet created** — that's the immediate next step, now on the laptop, where both dev tracks live. Auto-memory is machine-local, so this doc carries everything the laptop session needs; re-seed memory from the Working Agreements and Watch List below.

## Key Points

- **Current release: 0.13.5** (commit 5aba258). 0.13.0 shipped the coherence gate, decision register, native blocked-by relations, lights-out hardening, and the scripts+hooks skeleton; 0.13.1–0.13.5 were same-day field patches from live epic runs (details below).
- **Immediate next step:** create the two scheduled tasks on the laptop (runbook below), supervised for the first few ticks, scoped to DOD-650 only.
- **Pre-flight blockers:** `LINEAR_API_KEY` env bridge in `~/.linear.env` (scripts require that exact name; machines define `LINEAR_DODI_API_KEY`), branch protection on dodi_v2 main/master (structural Gate 2), plugin at 0.13.5 on the laptop.
- **Honest risk:** `claim.sh` / `dispatch-eligible.sh` / `watchdog-scan.sh` are syntax-checked but have never fired against live Linear GraphQL. First tick failure → capture error text → same-day 0.13.6.
- **The field loop is the operating model:** worker sessions keep observation files, flag patch candidates; this thread verifies, fixes, ships a point release within hours. Five cycles today prove the loop.
- **Mike's standing decrees** (never re-litigate): intelligence-effectiveness over cost, two human gates only, Frontier review gates untouchable on spend grounds, scannable artifacts everywhere.

---

## Role of this thread

Maintainer of the `dodi-dev` plugin (repo `dodi-hq/dodi-skills`, github). Receives field feedback from dev-track worker sessions (relayed by Mike), verifies against the repo, ships point releases. Does NOT do product dev work in dodi_v2 — that belongs to the worker sessions running the skills.

## Working Agreements (re-seed memory from this section)

- **Intelligence-effectiveness, never cost.** Mike, verbatim: "the dollars (and token counts) will fall where they fall." Tier choices are capability matching. Never justify a design choice on token-cost grounds. Tier gradient: `fable → opus → sonnet → haiku → script` — a script outranks a Fast-tier worker for pure mechanics.
- **Frontier review gates are untouchable on spend grounds** (reaffirmed 2026-07-03): the multiple fable passes per child (pre-PR final, child-PR, coherence) exist to catch defects at the earliest, cheapest point. Only legitimate trigger to revisit: redundancy-of-coverage (two passes catching the same defect class) — remedy is re-aiming for diversity, never removal.
- **Two human gates only:** Gate 1 epic intent (`epic-signed-off` + delegation comment), Gate 2 epic-PR merge into main/master (human-only, always — merged PRs auto-deploy to production). Everything between is autonomous with event-driven escalation.
- **Scannable artifacts:** every human-facing artifact leads with `## TL;DR` + `## Key Points`; Mike reads only the header.
- **Release process:** bump version in all three metadata files (`dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`), run the three validators (`scripts/validate-*.sh`, POSIX grep only), commit/push to main, then `claude plugin marketplace update dodi-skills && claude plugin update dodi-dev@dodi-skills` (NOT `install` — it won't upgrade in place). Restart/fresh session to apply. Long-running sessions don't get new hooks until reset.
- **Never** set `CLAUDE_CODE_SUBAGENT_MODEL` on hive machines. Never let skills reference repo-only files (validator-enforced); plugin scripts are referenced as `${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh`.
- **Drift rule:** skills reference scripts, never restate their mechanics — restating is a review finding.

## Release history today (what each patch fixed, all field-driven)

- **0.13.0** (908aa74): coherence gate (`coherence-pending` seam, fable adversarial reviewer, cumulative-drift → GATE1_REFRESH), decision register on the epic ticket, native blocked-by relations, lights-out hardening (watchdog, waiting-on-you digest, heartbeat, deploy/PR failure detection, progress-based retry/claims), deterministic skeleton: 10 scripts in `dodi-dev/scripts/` + 2 PreToolUse hooks (Gate 2 merge guard fail-closed; dispatch-pin enforcement, escape hatch `DODI_ALLOW_UNPINNED=1`).
- **0.13.1** (ae66e6b): script paths resolve via `${CLAUDE_PLUGIN_ROOT}`, not skill-relative.
- **0.13.2** (5db18fe): hook message self-contained (tier table inline); implementer default (sonnet) surfaced in deliver-ticket; pre-register-epic fallback (proceed + note absence); await rule echoed into spec-drafter/plan-writer prompts; all await prose names `await-worker.sh`.
- **0.13.3** (067b293): canon summary lives in a `## Decision Register — Canon` section of the **epic description** — Linear has no comment pinning (GUI or API); entry comments stay append-only.
- **0.13.4** (b49a3b0): first-cycle codifications — register bootstrap gradient (depth ∝ artifact quality, never fabricate), loop-side ALREADY_REVIEWED check (SHA-keyed register query before re-review; crash recovery = resume missing writes), `coherence-pending` blocking scope (canon-consuming dispatches only; operator housekeeping exempt), corrective-vs-follow-up boundary (corrective = reviewer-filed, dependents-build-on-the-gap; else normal funnel).
- **0.13.5** (5aba258): `cleanup-branch.sh` squash proof — the old fallback refused every squash-merged branch (three-dot diff never empty); now thread verify-merge.sh's SHA as 5th arg, accepted only when reachable AND patch-id matches the branch's net diff (plain reachability let a wrong SHA delete an unmerged branch — caught in synthetic tests). `submit-ticket-pr` gained the docs-only de-minimis carve-out for the epic-moved rule.

## Field evidence so far (both live epics)

- Coherence verdicts: 3 cycles, all ALIGNED — DOD-722 *earned* (GATE1_AMENDMENT held for Mike + 4 silent judgment calls surfaced that 5 review rounds missed), DOD-741 clean, DOD-725 clean (5 adversarial cases argued and defeated, register 31 canon decisions). Distribution feeds the future sampling question — too early at n=3.
- `verify-merge.sh` caught a literally-silent `gh pr merge` on first live use.
- Lane tier data: DOD-741 (hard resume) completed at sonnet, no smoking gun. Hold the lane pin.
- Effectiveness audit: every fable call caught a real defect or ruled a genuine ambiguity; haiku evidence-checker matched Frontier-quality verification at 62k tokens; the win is context isolation as much as pricing.
- DOD-650 state: 10 children Done, continuation brief on the epic, **DOD-727/730 named next** (mature-ticket) — a textbook clean anchor for the first tick.

## Laptop setup runbook (immediate next step)

1. Plugin: `claude plugin marketplace add dodi-hq/dodi-skills` (if needed) → `claude plugin update dodi-dev@dodi-skills` → confirm 0.13.5.
2. Env bridge in laptop `~/.linear.env`: `export LINEAR_API_KEY="$LINEAR_DODI_API_KEY"`.
3. Branch protection on dodi_v2 main/master (GitHub-side, once): required human review before merge.
4. In a fresh desktop session, create two scheduled tasks:
   - **dodi-pickup-next**, cron `4,19,34,49 * * * *`: "Invoke the dodi-dev:pickup-next skill for exactly one pass, then exit. Inputs: PM scope = Linear epic DOD-650 only; repo path = <laptop path to dodi_v2>; retryCeiling = 3; humanContact = Mike (escalations as Linear comments on the epic + scannable header). Fresh session each run: reconstruct everything from Linear/git durable state per the skill. One action per run. A no-op is success."
   - **dodi-reconcile-tickets**, cron once daily shortly after the nightly deploy: "Invoke the dodi-dev:reconcile-tickets skill for one sweep, then exit. Inputs: PM scope = all active dodi epics; repo path = <laptop path to dodi_v2>; production environment = <GitHub deploy env name>; claim lease window = 2h. Produce the waiting-on-you digest every run."
   - Set permission mode **Auto** on both tasks after creation.
5. Supervised phase: watch the first 2–3 ticks in the Scheduled sidebar. First tick should claim DOD-727 or 730 and run mature-ticket. Scope stays DOD-650-only until the loop proves out; the 733 track stays manual (single-active-epic posture). Launching in degraded-escalation mode (desktop notifications + Linear comments); wiring Slack is the exit condition for true walk-away.

## Watch list / open items

- **First live fire of the PM scripts** (claim/dispatch-eligible/watchdog/heartbeat) — expect a possible 0.13.6.
- **Gate 2 hook false-positive**: blocks any Bash command whose *text* contains "gh pr merge" (comments/strings included), fail-closed. Annoying-but-safe; tighten matcher if field sessions hit it.
- **Triple-fable coverage-diversity check at DOD-650 epic end** — diversity re-aim only, never spend reduction (see Working Agreements).
- **0.14 candidates:** Frontier-findings flywheel (every fable finding asked "is this greppable?" → becomes a deterministic gate check — best idea on the table); orchestrator-side "check `${CLAUDE_PLUGIN_ROOT}/scripts/` before writing PM API calls inline" one-liner; parallel lens-diverse plan review (3 fable lenses — field-proven pattern, candidate to codify in write-plan); Cloud Routine migration (gated on: does the dodi_v2 harness run in a fresh clone?).
- **Codex tolerance of the shared plugin dir** (`.claude-plugin` + `.codex-plugin`) — still unverified; fallback is a CI-diffed mirror.
- **Pending on Mike:** DOD-650 amended-description approval → label clear → follow-up filings; PR #373 merge word (Gate 2); Slack escalation channel authorization.
- **Devops leg** (babysit-epic-pr CI triage, post-merge verification) and **decompose-epic** — future releases, unscheduled.

## Reference docs (this repo)

- Specs: `docs/specs/2026-07-02-autonomous-pickup-and-ticket-hygiene-design.md` (0.12.0), `docs/specs/2026-07-03-epic-coherence-gate-design.md` (0.13.0, includes lights-out hardening + skeleton).
- Plans: `docs/plans/2026-07-03-*.md`. Earlier architecture: the 0.11.0 lanes/two-gate spec and plan (2026-07-02).
- The state machine: `dodi-dev/skills/epic-orchestrator/state-transitions.md`.
