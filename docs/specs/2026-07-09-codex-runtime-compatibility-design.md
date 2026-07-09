# dodi-dev 0.17.0 — First-Class Codex Runtime Compatibility

**Date:** 2026-07-09
**Epic:** DOD-810
**Type:** Compatibility / runtime architecture
**Target repo:** dodi-hq/dodi-skills
**Release:** dodi-dev 0.17.0

## TL;DR

Ship `dodi-dev 0.17.0` as a first-class Codex-compatible release without changing the v0.16 workflow model or reintroducing a second skill tree. Codex already installs the plugin and discovers all 20 skills plus both hooks; this epic closes the runtime gap by packaging the missing policy canon, resolving plugin scripts without an ambient Claude-only variable, mapping semantic model tiers to Codex-native models, adapting worker lifecycle bookkeeping to Codex agent primitives, and adding an explicit setup and validation path for auth, hooks, automations, and upgrades.

The architectural rule is one semantic workflow with small runtime adapters at the mechanics boundary. Claude Code keeps its current behavior; Codex receives explicit equivalents. A compatibility check that cannot establish a required invariant fails closed with a concrete setup blocker — it never silently drops a tier, skips a deterministic script, treats silence as worker success, or starts lights-out operation without a tested wake path.

## Key Points

- **One canonical tree:** preserve `dodi-dev/skills/` as the only skill tree. Runtime differences live in a shipped runtime contract and small adapters, not copied Claude/Codex skill variants.
- **Self-contained policy:** move the model-tier, Fable availability, dispatch, deterministic-skeleton, scheduled-operation, and context-hygiene runtime canon out of repository-only `AGENTS.md` into the installed plugin. `AGENTS.md` becomes maintainer guidance that points to that shipped canon.
- **Root bootstrap:** every skill invocation resolves one concrete `<plugin-root>` from runtime context before calling scripts. Claude Code may use `${CLAUDE_PLUGIN_ROOT}`; Codex derives the root from the absolute installed `SKILL.md` locator. Ordinary shell calls never depend on either variable being globally exported.
- **Native tier map:** semantic tiers remain Frontier / Capable / Standard / Fast. Claude aliases remain `fable` / `opus` / `sonnet` / `haiku`; Codex uses an explicit versioned model-and-reasoning map and records the effective model on every dispatch.
- **Worker adapter:** the execution model remains top-level dispatcher + leaf workers. Claude keeps transcript-backed dual-wake; Codex uses native spawn/wait/close/status results and writes equivalent terminal records into the shared dispatch manifest.
- **Setup is a product surface:** a new `setup-dodi-dev` skill and deterministic preflight script verify runtime version, plugin root, model map, Linear/GitHub auth, hook discovery/trust, Slack escalation delivery, marketplace provenance, and the two required scheduled tasks before autonomous operation is enabled.
- **Direct Linear API remains canonical:** no Linear connector dependency is introduced. Setup makes the `LINEAR_DODI_API_KEY` → `LINEAR_API_KEY` bridge explicit for this environment and verifies scheduled sessions receive the resolved key without printing it.
- **Waterfall rollout:** the children are tightly coupled through shared execution canon and validation surfaces, so the recommended epic mode is waterfall: mature every child against the complete compatibility design, then deliver in dependency order.
- **Out of scope:** changing v0.16 lane semantics, enabling parallel lanes, implementing the full hotfix path, machine-off/cloud operation, or supporting the legacy Homebrew Codex CLI 0.38.

---

*Everything below is written for agents planning and implementing the change.*

## Problem

DOD-796 made the top-level session the permanent owner of every dispatch and flattened the mature and deliver lanes into shared playbooks. That architecture is sound for Codex: Codex has top-level agent spawning, completion notifications, explicit waits, and explicit close operations. The released mechanics around it are still Claude-shaped.

The audit established two different truths:

1. **Packaging works.** In an isolated home, current Codex Desktop tooling added the repository as a marketplace, installed `dodi-dev 0.16.0`, discovered all 20 skills under the `dodi-dev:` namespace, and discovered both plugin hooks.
2. **End-to-end execution does not.** Required runtime policy is outside the installed directory; ordinary skill shell calls see neither `CLAUDE_PLUGIN_ROOT` nor `CODEX_PLUGIN_ROOT`; Codex ignores `model:` skill frontmatter and has no Claude alias models; worker scripts require Claude transcript files; and direct installation creates neither scheduled tasks nor authenticated escalation delivery.

The existing validators prove JSON parity, file presence, shell syntax, and selected script behavior. They do not install the plugin into an isolated Codex home or exercise the runtime contract.

## Goals

1. Make every released skill executable from a clean Codex plugin installation, subject only to documented external credentials and repository permissions.
2. Preserve behavior and durable state semantics across Claude Code and Codex.
3. Keep runtime-specific mechanics explicit, testable, and narrowly scoped.
4. Make autonomous operation impossible to enable until preflight proves its scheduler, wake, auth, hook, and escalation prerequisites.
5. Add release gates that detect future Claude-first drift before merge.

## Non-Goals

- No copied `plugins/dodi-dev/skills` tree.
- No behavioral redesign of sprint/waterfall selection, Fable policy, Gate 1, Gate 2, claim discipline, coherence review, or refresh seams.
- No attempt to make Codex frontmatter switch the current session model; Codex does not provide that contract.
- No replacement of direct Linear GraphQL with MCP or a bundled app.
- No automatic trust grant for hooks. Trust remains an explicit operator action verified by setup.
- No automatic creation of scheduled tasks during plugin installation. Setup performs that mutation only when explicitly invoked and confirmed.
- No support promise for `/opt/homebrew/bin/codex` 0.38.0; the target is the current Codex Desktop/plugin runtime with `codex plugin`, `skills/list`, `hooks/list`, and native multi-agent support.

## Compatibility Baseline

| Surface | Claude Code 0.16 behavior | Codex audit result | 0.17 contract |
| --- | --- | --- | --- |
| Marketplace install | released path | clean install succeeds | retain shared `./dodi-dev` source |
| Skill discovery | canonical tree | 20/20 discovered | install smoke asserts names and count |
| Hook discovery | `hooks/hooks.json` | 2/2 discovered, initially untrusted | setup verifies discovery + trust; live-fire tests verify matchers |
| Plugin root | `${CLAUDE_PLUGIN_ROOT}` | unset in ordinary shell calls | bootstrap concrete `<plugin-root>` per invocation |
| Main-loop model pin | SKILL frontmatter alias | extra field ignored | invocation preflight verifies required session tier where one exists |
| Worker model pin | Agent `model:` alias | aliases absent | resolve semantic tier through Codex model map |
| Worker completion | native wake + transcript backstop | native agent result, no transcript path | runtime adapter produces common manifest terminal records |
| Scheduling | harness-native tasks | plugin installs no tasks | explicit setup creates/verifies guard + janitor |
| Linear auth | `LINEAR_API_KEY` | local secret uses `LINEAR_DODI_API_KEY` | preflight resolves bridge without logging secret |
| Escalation | configured human channel | no packaged route | setup requires and tests one adapter before lights-out |

## Design

### 1. Shipped Runtime Canon

Create `dodi-dev/skills/epic-orchestrator/runtime-policy.md` as the installed single source for behavior needed while a skill runs:

- semantic model tiers and per-runtime mapping rules;
- Fable availability policy and gate table;
- dispatch discipline and leaf-worker contract;
- deterministic-script doctrine;
- decision-register rules;
- lights-out invariants;
- scheduled-operation contract;
- context-hygiene and refresh rules.

`execution-model.md`, lane playbooks, `review`, `submit-epic-pr`, and other consumers reference this shipped file by a path relative to their own `SKILL.md`. Repository-root `AGENTS.md` retains editing rules and points maintainers to the shipped canon instead of carrying a second operative copy.

Add a validator that fails when an installed skill references repository-root `AGENTS.md` for runtime policy, or references a repository-only document. Project-specific `AGENTS.md` / `CLAUDE.md` references remain valid only when they mean the target repository's coding conventions, not dodi-dev's own runtime policy.

### 2. Runtime Context Bootstrap and Script Resolution

Every entry-point skill that calls plugin scripts begins with a shared bootstrap instruction:

1. Read the absolute locator of the invoked `SKILL.md` supplied by the harness.
2. If `${CLAUDE_PLUGIN_ROOT}` is set, verify it contains the invoked skill and use it.
3. Otherwise strip `/skills/<skill-name>/SKILL.md` from the absolute locator and verify the result contains `.codex-plugin/plugin.json` plus `scripts/`.
4. Record that verified absolute path as `<plugin-root>` for the current session.
5. Invoke scripts with the concrete absolute path, for example `"<plugin-root>/scripts/claim.sh"`; never emit an unresolved environment-variable expression into an ordinary shell call.

The bootstrap prose lives once in `runtime-policy.md`; entry points point to it. A new `scripts/runtime-preflight.sh` accepts a candidate root and performs the mechanical verification. The skill derives the candidate because no helper can be called before its own location is known; the script validates rather than discovers it.

Hooks are a separate surface. Codex already resolves `${CLAUDE_PLUGIN_ROOT}` inside discovered plugin-hook commands, while Claude Code exports it. Keep the hook command form unless live-fire compatibility testing disproves it.

### 3. Canonical Runtime Profile

Setup is the only writer of one user-scoped, non-secret runtime profile:

```text
${DODI_RUNTIME_PROFILE:-${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-profile.json}
```

There is no implicit repository-local profile and no search through multiple candidate files. `DODI_RUNTIME_PROFILE` is the sole override; otherwise every skill and scheduled task resolves the same XDG/default path. The parent directory is mode `0700`, the profile is mode `0600`, and the profile stores references to secret sources but never secret values.

Minimum schema:

```json
{
  "schema_version": 1,
  "generated_by": {"plugin_version": "0.17.0", "setup_run_id": "..."},
  "runtime": {"kind": "codex", "version": "...", "model_catalog_sha256": "..."},
  "plugin": {"id": "dodi-dev@dodi-skills", "version": "0.17.0", "root": "...", "marketplace_name": "dodi-skills", "marketplace_root": "..."},
  "models": {"frontier": {"id": "...", "reasoning": "..."}, "capable": {}, "standard": {}, "fast": {}},
  "hooks": {"gate2": {"key": "...", "hash": "...", "trusted": true}, "model_pin": {"key": "...", "hash": "...", "trusted": true}},
  "auth": {"linear_source": "env:LINEAR_API_KEY", "github_host": "github.com"},
  "escalation": {"adapter": "slack", "channel_id": "...", "retry_policy": {"delays_sec": [0, 30, 120]}, "health_policy": {"stale_after_sec": 86400, "re_escalate_after_sec": 86400}},
  "repositories": {"owner/name": {"path": "...", "base_branch": "main", "branch_protection": {"rules_sha256": "...", "required_checks_sha256": "...", "automation_actor": "...", "actor_bypass": false, "actor_can_update_base": false, "verified_at": "..."}, "tasks": {"driver": {"id": "...", "config_sha256": "...", "wake_test_id": "...", "wake_tested_at": "..."}, "janitor": {"id": "...", "config_sha256": "..."}}}},
  "validated_at": "..."
}
```

`setup-dodi-dev` builds the complete next document in memory, writes a same-directory temporary file, applies mode `0600`, parses and validates it, flushes it, then atomically renames it over the profile. A failed write leaves the prior valid profile untouched. Runtime skills are read-only consumers and reject malformed, partially populated, wrong-permission, or unknown-schema profiles.

Renewable operational evidence lives separately at `${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-health.json` (or beside an explicit `DODI_RUNTIME_PROFILE`, with `.health.json` suffix). It is also mode `0600` and atomically replaced. Setup creates the initial record; the Slack adapter and janitor may update only their named health fields. Minimum health fields are adapter/channel, last attempt/success timestamps, last message id/link, consecutive failures, `notification-degraded`, and per-item last-escalated timestamps. The static profile defines the adapter and health policy; the health record reports changing delivery state.

Lookup precedence inside a run is: explicit `DODI_RUNTIME_PROFILE` path → default canonical path → no profile. There is no fallback from an invalid explicit profile to the default because that would hide operator error. No profile is acceptable for purely manual skills that need no adapted mechanic; any Codex tiered dispatch, deterministic plugin script, or scheduled action requires a valid profile.

One narrow bootstrap exception breaks the clean-install cycle: `runtime-preflight.sh bootstrap <candidate-plugin-root>` may run without a profile. Bootstrap mode is read-only, accepts no workflow/ticket id, performs no PM/Git/repository writes, and can only report plugin provenance, runtime capabilities, dependencies, candidate model pairs, hook discovery/trust, and profile-path readiness. `setup-dodi-dev` uses that report to build the first profile. No other script or mode accepts profile absence. The isolated install test covers clean install → root derivation → bootstrap report → first atomic profile creation → normal profile verification.

The profile is invalidated when any of these differ from live state: schema version, installed plugin id/version/root, marketplace root, Codex runtime version, model-catalog fingerprint, resolved hook hash/trust, repository remote/base branch, normalized branch-protection/rules/check fingerprints, automation actor/bypass/update-base posture, scheduled-task identity/configuration fingerprints, successful wake-test identity, or configured Slack adapter/channel/policy. Invalidation returns `SETUP_REQUIRED` and performs no workflow write; only `setup-dodi-dev` repairs the profile. Slack delivery age does **not** invalidate the static profile.

`runtime-preflight.sh verify-profile --repo <owner/name>` is the deterministic verifier. Every skill reads and schema-validates the profile at entry. Scheduled tasks run the verifier at boot. A resident driver rechecks the local profile/plugin/model/hook fingerprints every loop pass, rechecks external branch protection immediately before any child merge, and rechecks scheduler/wake configuration at the daily-heartbeat boundary. Any static mismatch fences workflow writes and exits `SETUP_REQUIRED`; a long-lived driver never carries a stale proof past its stated boundary.

Health is routed rather than treated as static invalidation. A missing/stale/degraded Slack health record blocks the driver from starting a new lane and queues an adapter test/escalation repair. The janitor remains eligible to perform that repair and its read-only waiting-on-you sweep, but performs no destructive cleanup or unrelated PM transition until Slack health succeeds. Successful delivery atomically renews health and clears `notification-degraded`, allowing normal selection to resume without rerunning setup.

### 4. Model Tier Adapter

Semantic tiers remain the durable policy language. Runtime aliases are adapter data.

#### Claude Code

Unchanged:

| Tier | Effective pin |
| --- | --- |
| Frontier | `fable` |
| Capable | `opus` |
| Standard | `sonnet` |
| Fast | `haiku` |

#### Codex

Ship a versioned `dodi-dev/runtime/codex-model-tiers.json` with ordered candidates and reasoning effort. Catalog presence is only candidate discovery: setup probes every resolved model/reasoning pair with a minimal disposable dispatch and records only successful pairs in the runtime profile. Absence or probe failure of a required tier is a blocker. A recognized Frontier-capacity failure during setup returns `SETUP_CAPACITY_WAIT` after the bounded retry, writes no enabled profile, and never substitutes or selects an alternate candidate; per-gate hard/deferred/soft policy begins only on later workflow dispatches with a fully proven profile.

Initial candidate map for the audited runtime:

| Tier | Preferred model | Reasoning | Required distinction |
| --- | --- | --- | --- |
| Frontier | `gpt-5.6-sol` | `xhigh` | fresh-context independence for spec gates; distinct from non-Frontier delivery writers at hard delivery finals |
| Capable | `gpt-5.5` | `xhigh` | review / invariant-dense delivery |
| Standard | `gpt-5.6-terra` | `medium` | ordinary implementation and routing |
| Fast | `gpt-5.6-luna` | `low` | mechanics and read-only classification |

⚠ **Gate 1 assumption:** these are release defaults, not eternal aliases. Candidate ordering may change in later releases without changing semantic tier policy. Setup stores the resolved map with the Codex runtime version and model-catalog fingerprint; a changed catalog invalidates preflight and requires re-resolution.

Every Codex worker manifest entry records semantic tier, effective model id, and reasoning effort. Fable-policy capacity handling applies to the mapped Frontier model. A missing or rejected mapped Frontier dispatch follows the existing hard/deferred/soft table; an arbitrary substitute is forbidden.

Tier success has two proofs:

1. **Dispatch tier:** setup's live probe proves the exact model/reasoning pair is accepted, and each spawn result records that requested pair.
2. **Main-loop tier:** the active runtime supplies an effective model id/reasoning value in session/thread metadata, and the skill compares it to the profile before judgment work. A configured launch profile alone is not evidence of the effective model.

The adapter owns a tested failure classifier. During setup, recognized Frontier capacity produces only `SETUP_CAPACITY_WAIT`. During workflow execution, only structured/runtime-documented capacity or tier-temporarily-unavailable failures for the already-proven Frontier pair enter that gate's hard/deferred/soft Fable handling. Unknown rejection text, invalid model/reasoning, auth, permission, malformed request, or missing attestation returns `SETUP_REQUIRED`/`TIER_UNVERIFIED`; it never substitutes. Tests cover matching, wrong-tier, absent attestation, successful probes, setup capacity wait, per-gate recognized capacity failure, and arbitrary rejection.

Model independence is gate-specific. Spec drafting and final spec review are both intentionally Frontier seats; their independence comes from a fresh-context reviewer, not a different model id. Delivery writers are Standard or Capable, so a hard-policy Frontier delivery final must use a different effective model. Deferred/soft substitution may equal the writer only under the existing degradation attribution and make-up rules.

Codex ignores `model:` in SKILL frontmatter. Therefore:

- frontmatter aliases remain for Claude Code compatibility but are explicitly documented as non-operative on Codex;
- scheduled tasks are configured with the required main-loop Codex model by setup;
- an interactive skill with a required main-loop tier verifies the runtime-attested effective model from harness-supplied session/thread metadata;
- if the attestation is absent or does not match, the skill returns `TIER_UNVERIFIED` **before** asking design questions, producing judgment artifacts, or dispatching phase workers. The only recovery is a fresh task launched with the required setup-verified model and a runtime surface that exposes effective-model attestation; launch configuration or an operator assertion is not tier evidence;
- worker pins remain mechanical through the runtime adapter.

Update `hook-require-model-pin.sh` to validate the runtime-native pin shape. Its matcher must live-fire against Codex agent spawning; if `Task|Agent` does not match, use a broad PreToolUse matcher and make the script no-op for non-dispatch tools based on the normalized payload.

### 5. Worker Lifecycle Adapter

Keep `execution-model.md` semantic and split mechanics into two shipped adapter documents:

- `epic-orchestrator/runtime/claude-worker-adapter.md`
- `epic-orchestrator/runtime/codex-worker-adapter.md`

The shared contract remains:

- only the top-level session dispatches;
- every worker is a leaf;
- every dispatch receives a unique worker id and explicit tier;
- silence is never success;
- terminal evidence is written durably before state advances;
- planned park/reset occurs only at a seam with no worker in flight;
- takeover never redispatches beside a worker that may still write.

#### Claude adapter

Retain native completion + `await-worker.sh` transcript backstop, `stop_reason:end_turn`, transcript mtime checks, and current reap behavior.

#### Codex adapter

Use native agent primitives:

1. Spawn returns `agent_id`; append a dispatch record immediately.
2. Native completion notification is primary.
3. `wait_agent` with a bounded timeout is the foreground fallback. A timeout means `WAITING`, never success and never automatically `STALLED`.
4. A terminal wait result is normalized into `completed`, `errored`, `interrupted`, or `shutdown`; its complete normalized digest/error is persisted atomically before the manifest receives the terminal record.
5. `close_agent` is the stop primitive. Append the pre-close status and the close result.
6. Completed agents are closed after their digest is consumed so they do not exhaust the concurrency limit.

Normalized transition and failure handling:

| Event | Durable action | Allowed next action |
| --- | --- | --- |
| spawn fails before an id is returned | append `spawn-failed` with the tool error | bounded retry/policy handling; no worker exists |
| spawn returns an id, dispatch-record append succeeds | append `dispatched` before consuming any result | wait for that id only |
| spawn returns an id, dispatch-record append fails | immediately call `close_agent`; retry the append with close evidence | continue only after terminal/closed proof; otherwise quarantine worktree + escalate |
| wait transport/tool error | append `wait-error` if possible; re-query the same id | never redispatch; repeated inability to query routes to close, then quarantine if close is unproved |
| wait timeout with status `running` | append/update `waiting` bookkeeping without a terminal verdict | wait again; timeout is neither success nor `STALLED` |
| notification and wait both report terminal | first terminal record wins by worker id; later equivalent events are duplicate bookkeeping | consume one digest exactly once |
| notification and wait report conflicting terminal state or result hash | append `evidence-conflict` with both source records/hashes; consume neither | bounded re-query of the same id, then close; resolve only when two subsequent authoritative reads and close status agree byte-for-byte with one candidate, otherwise `writer-uncertain` quarantine + escalation |
| terminal result has no digest or has an error | append normalized terminal state and error/missing-digest marker | no state advance; retry through the lane policy with a new worker only after reap |
| terminal result exists but terminal-record append fails | retain the tool result in current context and retry durable append | no PM/git state advance; persistent failure quarantines the worktree + escalates |
| close succeeds with terminal status | append close + terminal + reap records | retry or exit per lane policy |
| close fails, returns `running`, or worker becomes unqueryable without terminal proof | append evidence where possible and mark `writer-uncertain` | quarantine worktree, release no successor writer, escalate |
| reap-record append fails | retry while ownership is held | no close-out/state advance; persistent failure quarantines + escalates |

`writer-uncertain` is fail-closed: the ticket cannot be redispatched and the worktree cannot be reused or removed until the compatibility-proven takeover rule establishes that no worker can still mutate it.

Extend the manifest schema:

```json
{"runtime":"codex","session_id":"...","worker_id":"<agent_id>","purpose":"...","tier":"capable","model":"gpt-5.5","reasoning":"xhigh","state":"dispatched","ts":"..."}
{"runtime":"codex","worker_id":"<agent_id>","state":"completed","result_artifact":"<epic-worktree>/.dodi/workers/<session>/<agent_id>.json","result_sha256":"...","ts":"..."}
{"runtime":"codex","worker_id":"<agent_id>","reaped":true,"verdict":"terminal","ts":"..."}
```

For Codex, the complete normalized result artifact stores worker id, terminal state, effective tier/model/reasoning, returned digest or full error, and completion timestamp. It is written as a mode-`0600` same-directory temporary file, parsed, flushed, and atomically renamed before its path/hash are appended to the manifest. Worker digests remain capped by the existing return contract, so this is a compact durable record rather than a transcript. Consumption and PM/git state advance are forbidden until artifact and terminal manifest record both exist and hash-match.

`output_file` becomes Claude-adapter data, not a universal required field. `reap-workers.sh` classifies normalized manifest records first; it reads Codex result artifacts by path/hash and reads transcript files only for Claude records lacking a normalized terminal record.

⚠ **Compatibility gate:** before Codex scheduled delivery is enabled, a live test must determine whether an `agent_id` remains queryable/closable after top-level context refresh, task resume, and crashed-session takeover. If it does, takeover uses the native id. If it does not, the Codex adapter must prove one of these fail-closed alternatives before release:

- the runtime terminates descendants with the parent, confirmed by a durable stop event; or
- the predecessor worktree is quarantined until no writer can remain, with explicit human escalation rather than speculative redispatch.

There is no accepted path where an unaddressable worker may still write while a successor starts another worker in the same worktree.

### 6. Setup, Auth, Scheduling, Gate 2, and Escalation

Add `dodi-dev/skills/setup-dodi-dev/SKILL.md` plus `scripts/runtime-preflight.sh`. This is an explicit operator-run setup path, not an implicit install hook. Release evidence pins the exact Codex Desktop/app-server version and required capabilities used by the live gate. The initial candidate baseline is `0.144.0-alpha.4`; the release does not claim support for it until plugin install, `skills/list`, `hooks/list`, effective-model attestation, native multi-agent spawn/wait/close, and scheduled-task behavior all pass the required live gate.

Preflight reports, without secrets:

- active runtime and version;
- marketplace name, source root, installed plugin id/version, and cache path;
- stale marketplace-name collisions or legacy plugin paths;
- discovered skill names/count and hook names/trust;
- resolved plugin root and executable scripts;
- resolved tier map and model-catalog fingerprint;
- `git`, `gh`, `curl`, `python3`, and required shell capabilities;
- GitHub authentication and repository access;
- target-base branch protection and Gate 2 hook live-fire evidence;
- Linear key availability and a read-only `viewer`/team query;
- configured escalation target and a test-delivery result;
- required scheduled tasks, cadence, model, repository/worktree scope, no-overlap setting, and environment.

#### Linear

Direct GraphQL remains the only plugin-owned PM API. Resolution order is:

1. `LINEAR_API_KEY` already present;
2. an explicitly configured environment file loaded by the scheduled task;
3. `LINEAR_DODI_API_KEY` bridged to `LINEAR_API_KEY` by setup/session bootstrap.

The key is never printed, persisted in a ticket, or copied into plugin files. Missing auth is a concrete blocker.

#### Scheduled tasks

After explicit confirmation, setup creates or updates:

- `dodi-drive-epic`: hourly liveness guard/resident driver, no overlap, Standard main-loop tier, epic PR merge excluded from allowed actions;
- `dodi-reconcile-tickets`: daily after the deployment window, no overlap, Standard main-loop tier.

The setup record includes task identifiers and the tested `refresh-park` successor wake. Plugin installation alone never claims autonomous operation is active.

Setup updates are quiescent. Before replacing an existing valid profile or active task configuration, setup disables new driver/janitor starts, verifies no live driver claim or in-flight worker remains, snapshots the prior profile/task configuration, applies and tests the new profile/tasks, then re-enables them. A failed update restores the prior profile/tasks and re-verifies them; if restoration cannot be proved, both tasks remain disabled and setup escalates rather than running mixed configuration.

#### Gate 2

Gate 2 remains structural, not advisory. Codex scheduled tasks authenticate as a dedicated automation GitHub App/user, never the operator's human `gh` identity. For every repository enabled for lights-out operation, setup identifies the actual `main`/`master` base and verifies through `gh api` that branch rules require a pull request/checks and exclude that automation actor from bypass and every actor/team allowed to update the protected base. Missing/unreadable rules, a shared human credential, or any automation path to update the protected base is a hard setup blocker; the driver and janitor tasks are not created or enabled.

Scheduled-task capability profiles expose no native GitHub merge, auto-merge, ref-update, or raw HTTP mutation tools. Child merges route only through a plugin-owned wrapper that resolves the PR base and refuses `main`/`master`; direct merge commands are not allow-listed. General shell receives only the dedicated restricted automation credential, so even opaque or indirect mutation attempts are denied by server-side branch rules. The Gate 2 hook still guards recognized bypass shapes as immediate feedback and defense-in-depth.

The Gate 2 hook receives the same Codex compatibility treatment as the model-pin hook. Its existing `Bash` matcher and Claude-shaped payload are live-fired. If either does not match current Codex, use a broad PreToolUse matcher and normalize runtime tool name, cwd, command/tool input inside `hook-gate2-guard.sh`. The guard denies every recognized protected-base mutation route: `gh pr merge`, merge/auto-merge via `gh api` REST or GraphQL, native GitHub merge/enable-auto-merge/ref-update tools if present, direct `git push` to the protected base, and equivalent raw API calls. A tool classified as merge-capable whose payload or target base cannot be parsed fails closed. It allows read-only GitHub calls, child-PR creation, child merge into an epic branch, and ordinary non-protected pushes.

The live-fire matrix includes deny cases for protected-base merge, auto-merge enablement, ref update/direct push, raw API merge, and an opaque/indirect shell mutation against a temporary branch carrying equivalent actor restrictions, plus allow cases for child PR open/merge and read-only inspection. Hook absence, untrusted state, payload ambiguity, failed matrix item, missing capability restriction, a shared human credential, or an automation actor able to update/bypass the protected base is a hard lights-out and release blocker; server-side actor restriction is the authoritative second layer.

#### Escalation

The sole 0.17 escalation adapter is the installed Slack plugin targeting one configured dedicated channel. Setup verifies the Slack plugin is enabled for the scheduled-task runtime, sends a low-risk test, records static channel/policy in the profile, and writes the successful message evidence to the operational health record. No configured/tested Slack route means manual workflows remain available and lights-out operation stays disabled.

An escalation attempt sends the artifact's TL;DR + Key Points + links and succeeds only when Slack returns a durable message id/link. Delivery retries at 0, 30, and 120 seconds. Exhaustion writes a `notification-degraded` Linear comment, causes the scheduled task to exit failed so the harness-native task-failure notification fires, and leaves the item queued for the next janitor run. Open human-wait items are re-posted to Slack when their last successful escalation is older than 24 hours; the new message references the prior message id and current age. The janitor clears `notification-degraded` only after a later Slack delivery succeeds. These retry, fallback, evidence, and stale re-escalation semantics are deterministic and adapter-owned.

### 7. Marketplace Upgrade and Local Migration

The audited machine auto-discovers `~/.agents/plugins/marketplace.json` with marketplace name `dodi-skills`, pointing to the obsolete `~/plugins/dodi-dev` layout and resolving version 0.8.2. The repository marketplace has the same name and correctly points to `./dodi-dev`.

Setup detects same-name/different-root collisions before install or upgrade. It reports the exact roots and requires an explicit choice to remove/rename the stale source or use the canonical repository source. It never silently upgrades the wrong package.

Document both current install paths:

```bash
codex plugin marketplace add dodi-hq/dodi-skills --ref main
codex plugin add dodi-dev@dodi-skills
```

and local development:

```bash
codex plugin marketplace add /absolute/path/to/dodi-skills
codex plugin add dodi-dev@dodi-skills
```

The install guide must explain that the audited Homebrew `codex` 0.38.0 lacks plugin commands and that operators should use a supported current Codex runtime rather than treating the old binary's failure as a plugin defect.

### 8. Validation and Release Gates

Add `scripts/validate-codex-compatibility.sh` and focused unit/live tests.

#### Deterministic CI checks

- Parse marketplace and plugin manifests with the current schema.
- Assert canonical source `./dodi-dev` and metadata version `0.17.0` in all version-bearing files.
- Assert exactly one skill tree and no symlinks.
- Assert every runtime-policy reference resolves inside `dodi-dev/`.
- Reject operative references to repository-root `AGENTS.md` and unresolved ambient plugin-root variables in ordinary skill commands.
- Validate runtime-profile/health and Codex model-map schemas plus gate-specific fresh-context/model-diversity rules.
- Test bootstrap-without-profile, first atomic profile creation, setup rollback/quiescence, and every profile drift invalidation field/boundary.
- Test mixed Claude/Codex manifest classification and reaping.
- Test setup/preflight output redacts all key values.

#### Isolated Codex install smoke

Using temporary `HOME` and `CODEX_HOME`:

1. add the repository marketplace;
2. install `dodi-dev@dodi-skills`;
3. assert installed version and source root;
4. call app-server `skills/list` and assert every released skill is enabled with no errors;
5. call `hooks/list` and assert both hooks are discovered from the installed plugin;
6. derive `<plugin-root>` from one installed skill locator and execute a read-only script preflight;
7. create the first atomic runtime profile from bootstrap output, then verify it through normal mode;
8. assert the installed package contains the shipped runtime canon and both worker adapters.

#### Live Codex compatibility gate

Run before release on the supported Codex Desktop runtime:

- hook trust + the complete Gate 2 deny/allow live-fire matrix;
- model-pin hook live-fire against a disposable agent dispatch;
- effective-main-model attestation and all four model/reasoning probes, including wrong/unverifiable/setup-capacity/error classification paths;
- one worker completion and one explicit close path;
- duplicate-equivalent and conflicting-terminal evidence fixtures;
- one simulated context refresh/resume with manifest reconstruction;
- the cross-session worker-addressability test from §5;
- one read-only Linear query through the resolved environment;
- one scheduled guard no-op and one `refresh-park` successor wake;
- one Slack escalation test plus retry/failure/stale re-escalation fixtures.

Every listed live item is required and blocks the release on failure. Gate 2 protection/hook failures, worker takeover uncertainty, tier-map failures, missing auth, scheduler wake failures, and missing escalation delivery may not be converted into a narrower prose support claim.

## Decomposition Sketch

Children are filed only after Gate 1 approval.

| Child | Intent | Hard dependencies | Predicted tier |
| --- | --- | --- | --- |
| C1 — runtime canon, profile contract, root bootstrap + adapter interfaces | Package operative policy, define the canonical runtime profile and common dispatch/manifest interfaces, remove repo-only dependencies, implement verified concrete plugin-root resolution | none | standard |
| C2 — Codex tier map + hook enforcement | Versioned model map, main-loop preflight, native worker pins, capacity mapping, hook live-fire compatibility | C1 | capable |
| C3 — Codex worker lifecycle adapter | Native spawn/wait/close normalization, manifest schema, reaping, takeover safety, cross-session live gate | C1 | capable |
| C4 — setup/preflight + auth/scheduling/Gate 2/escalation migration | Operator setup skill, atomic runtime-profile writer, Linear/GitHub auth and branch-protection checks, hook trust/live-fire, automations, escalation adapter, stale marketplace detection | C2, C3 | capable |
| C5 — Codex install/runtime validation + docs + 0.17.0 release | CI validator, isolated install smoke, required live gate, install guide, metadata bump and reference sweep | C4 | standard |

Recommended native blocked-by graph:

```text
C1 → C2 ┐
 │      ├→ C4 → C5
 └→ C3 ┘
```

Recommended workflow mode: `waterfall`. C2 and C3 implement C1's shared contracts, C4 is forbidden to enable setup until both are proven, and C5 validates the resulting end-to-end path. Maturing the full set before implementation reduces the chance that one adapter silently invents a competing contract.

## Acceptance Criteria

1. A clean supported Codex installation discovers every released skill and hook with no load errors.
2. Invoking any skill from an unrelated target repository can locate and execute required plugin scripts without a globally exported Claude variable.
3. Every runtime policy dependency consumed by an installed skill exists inside the installed plugin.
4. Codex dispatches carry a recorded semantic tier, model id, and reasoning effort; missing mappings fail closed.
5. Final-gate independence is gate-specific on Codex: spec drafting/final review use fresh Frontier contexts; hard delivery finals require a model distinct from the Standard/Capable writer; deferred/soft substitution may equal the writer only with the existing `tier-degraded` attribution and any required `FABLE_MAKEUP` obligation.
6. Codex worker completion, error, close, reap, and takeover paths produce durable manifest evidence without requiring Claude transcripts.
7. No planned reset or takeover can orphan a possibly-writing Codex worker beside a successor writer.
8. Setup bootstraps from no profile, atomically writes one canonical non-secret runtime profile plus renewable health record, detects every specified drift field at its revalidation boundary, and can prove or clearly block Linear, the dedicated restricted GitHub automation actor, base-branch rules, both hooks, effective-model attestation, Slack escalation, and both scheduled tasks without exposing secrets.
9. A scheduled `refresh-park` test boots a successor that reconstructs durable state and resumes at the recorded seam.
10. The existing Claude validators and script tests remain green, and a Claude smoke run shows no behavioral regression.
11. The Codex compatibility validator fails on reintroduced repo-only policy, unresolved script-root expressions, missing skills/hooks, invalid tier maps, or Claude-only worker assumptions in shared canon.
12. Metadata ships as `0.17.0` in all required envelopes, with an install/upgrade guide and the DOD-810 release evidence linked.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Codex model ids change faster than plugin releases | ordered candidate map + runtime catalog fingerprint + setup invalidation |
| Main-loop tier cannot switch on skill invocation | configure scheduled tasks explicitly; interactive preflight blocks judgment work at the wrong tier |
| Agent ids are not durable across task boundaries | mandatory live test; fail-closed quarantine/escalation if addressability is absent |
| Hook discovery succeeds but hooks remain untrusted | setup verifies trust and live-fires both guards before lights-out |
| Runtime adapters drift semantically | one shared execution canon, adapter contract tests, no duplicated lane prose |
| Stale marketplace masks the canonical release | provenance check and explicit same-name collision migration |
| Secret bridge works interactively but not in automation | scheduled-task environment test through a read-only Linear query |
| Compatibility scope turns into workflow redesign | acceptance tests pin v0.16 state transitions and out-of-scope list |

## Rollout

1. Gate 1 approves this spec, the five-child decomposition, `waterfall` mode, and the flagged assumptions.
2. File children with the native blocked-by graph.
3. Mature all five children before delivery.
4. Deliver C1, then C2 and C3, then C4, then C5.
5. Run the isolated Codex install smoke and live compatibility gate on the audited Desktop runtime.
6. Run the existing Claude validation suite and a focused Claude smoke test.
7. Open the epic PR as Gate 2; no automation merges it.
8. After human merge, update the canonical marketplace and run setup against the real user installation, including stale-marketplace migration and scheduled-task verification.

## Gate 1 Delegated Assumptions

- ⚠ The initial Codex model candidates in §4 are approved as release defaults, with catalog-fingerprint invalidation rather than permanent aliases.
- ⚠ `waterfall` is the initial workflow mode because all implementation children share the runtime canon and final compatibility gate.
- ⚠ `setup-dodi-dev` may create/update the two Codex scheduled tasks only after an explicit operator confirmation; plugin installation remains side-effect free.
- ⚠ Direct Linear GraphQL remains canonical, with an explicit `LINEAR_DODI_API_KEY` bridge allowed for this environment.
- ⚠ Slack is the sole 0.17 escalation adapter; lights-out operation requires the Slack plugin and a tested dedicated channel.
- ⚠ Codex scheduled tasks use a dedicated GitHub automation identity that is server-side forbidden from updating or bypassing `main`/`master`; the operator's human GitHub credential is never injected into those tasks.
- ⚠ Scheduled Codex delivery is blocked until the cross-session worker-addressability test selects and proves a safe takeover path.
- ⚠ Legacy Codex CLI 0.38.0 is unsupported; current Codex Desktop/plugin tooling is the release target.
