# No-Re-Entry Rule for Dispatched Workers — Design Spec

Status: draft for spec review. Ticket: to be filed after spec signoff (`dodi-dev:file-ticket`). Origin: 2026-09-05 subscription-window burn audit (hive session handoff; full audit in the hive project memory `project_token_window_burn_2026_09_05.md`). Claude Code build verified against: 2.1.261 (the installed build; the earliest build that recognizes `modules` in a hooks file is not established).

## TL;DR

A dispatched worker becomes a **one-shot leaf**: its life is exactly one turn, and the dispatcher never re-enters it afterwards — no `SendMessage`, no continuation of any kind. Every fix round dispatches a **fresh leaf** that revises the artifact on disk from the reviewer's findings, and the next fresh reviewer sees which findings the writer declined. On Claude Code the rule is enforced by a **function hook** (a `hooks/hooks.js` module, loaded only when `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` is set or the harness's own rollout flag is on) that denies `SendMessage` to any subagent this session spawned; on every runtime, and whenever the module is not loaded, it is doctrine in `AGENTS.md` and `execution-model.md`.

## Key Points

- **Decision — "never", not "never after N minutes idle".** A hard rule is one sentence, mechanically checkable, and also caps per-worker context growth (each leaf restarts from the file). The idle-threshold variant needs timestamp tracking for a fast case that rarely occurs because reviewers run between rounds.
- **Decision — enforcement by function hook on Claude Code, doctrine everywhere.** The hook asks the harness the exact question (`$.agent.list()`: is the target one of this session's own subagents?), so no manifest lookup and no id-shape guessing. Grok Build and Codex get the prose rule only. **Precondition:** in 2.1.261 hooks modules load only when `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` is set or the harness's own rollout flag is on; both are off on this machine today, and when off the loader skips the module with a debug-only line. The doctrine records the flag as a hive-machine setting, and the only proof the guard is live is a live deny.
- **Decision — the module is declared from the Claude plugin manifest, not from `hooks/hooks.json`.** `.claude-plugin/plugin.json` names a second hooks file, `hooks/function-hooks.json`, that carries only `modules`. `hooks/hooks.json` (the file Grok Build also reads) stays byte-identical, so no cross-runtime tolerance question arises.
- **Decision — fix rounds revise in place, and declines travel forward.** The revision-round leaf receives the artifact path, the reviewer findings verbatim, and the original brief; it edits the existing file and never rewrites from scratch, marking each finding applied or declined-with-reason. The next reviewer receives that block and re-raises a decline only by rebutting its reason. A cold read of a 2,400-line plan is ~40k tokens; re-waking its author cost ~10× that per round.
- **Decision — no model-typable escape hatch; address matching mirrors the runtime resolver.** Unnamed dodi-dev workers are addressable only by agent id, so exact id match is the load-bearing check. Named spawns are matched by the resolver's own normalization and by prefix, as the resolver does. The trailing `[ref]` token is a hash the hook cannot reproduce and is stripped, not matched. The only override is operator-side (disable the module).
- **Decision — the hook fails open, loudly where it can.** If `$.agent.list()` throws, the hook logs one transcript line and lets the call through rather than breaking peer-session handoffs. Flag off, an older loader, or a crashed hooks worker also leave the rule prose-only; the live verification in § 4 is how a machine proves the guard is on.
- **In scope:** `AGENTS.md` §§ Dispatch Discipline and Deterministic Skeleton (including the flag bullet); `execution-model.md` §§ 1 and 6; both drafter prompts (revision-round input and output); both reviewer prompts (prior-round input and decline handling); fix-loop wording in `write-plan`, `implement`, `brainstorm`, `mature-playbook.md`; new `hooks/hooks.js` + `hooks/function-hooks.json` + a `hooks` entry in `.claude-plugin/plugin.json`; a `node`-driven test script; validator check; five-file version bump to `0.20.0` (also clears the pre-existing 0.19.0/0.19.1 skew that fails `validate-plugin-metadata.sh` on main today).
- **Out of scope:** migrating `hook-require-model-pin.sh` to a function hook; plan-length cap; Capable-tier interim review rounds; main-thread context cap; a resident-drafter agent definition with a 1h cache TTL; any `promptCacheTtl` / `subagentPromptCacheTtl` setting. Each is its own ticket if wanted.
- **Risk and ⚠ assumptions:** the function-hook API is EARLY ACCESS and undocumented; the hook is kept to one `agent.spawn` observer, one `tool.call` matcher, and two `$` calls, and the test stubs `$` so a surface change is a red test. ⚠ In-process teammates are assumed absent from `$.agent.list()` (plan: live check). ⚠ A fork's runtime-allocated name does not reach `e.name` at `agent.spawn`, so a fork is denied by id only (dodi-dev spawns no forks).

## Problem

Verified against the 2026-09-05 audit and this repo at `d8bd09e`:

- **The doctrine has a one-directional gap.** `AGENTS.md:93` and `execution-model.md:7` say a worker's final message "returns to its dispatcher as the Agent-tool result (never `SendMessage`)". That governs the worker's *output*. Nothing says the dispatcher may not *re-enter* a parked worker, and both drafter prompts (`spec-drafter-prompt.md:21`, `plan-writer-prompt.md:23`) repeat only the output half.
- **The fix-loop wording invites reuse.** `write-plan/SKILL.md:151` says "Fix issues, re-dispatch until approved (max 5 iterations)"; `implement/SKILL.md:40` says NEEDS_CONTEXT ⇒ "re-dispatch". Neither says *fresh*. The KPR-434 mature-ticket session read this as "keep the plan writer resident and `SendMessage` it the findings each round", and recorded that as a win ("2–5 tool uses per round vs a cold re-read").
- **The economics are backwards.** Subagents get a 5-minute prompt-cache TTL on subscription (main thread gets 1 hour). The resident plan writer idled through four gaps > 5 min while parallel reviewers ran, and each re-entry rewrote its full prefix cold: 374k / 439k / 465k / 475k tokens = 1.75M cache-write tokens, 79% of that worker's writes and ~36% of the whole session's. Context peaked at 501k. The 13 one-shot reviewers had no such cost.
- **Prose alone loses.** The session had the leaf rule in context and still re-entered, because the local argument ("reuse saves the re-read") was plausible. Per `AGENTS.md` § Deterministic Skeleton, an invariant becomes code.
- **The doctrine on hooks is about to be wrong.** `AGENTS.md:114` says hooks "also run on Grok Build". True for command hooks; a JS hooks module has no Grok path. Adding one without amending that bullet leaves the doctrine contradicting itself.
- **The loader is gated.** In 2.1.261 the hooks-module loader reads `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS`, falling back to an internal rollout flag that defaults off; when off it logs `hooks modules not loaded: rollout flag … is off` at debug level only. A repeatedly crashing hooks worker also turns function hooks off for the session with a log line. Neither state is visible to the model or in the transcript, so a guard could ship and never run without anyone noticing.

## Goals

1. One sentence of doctrine, on every runtime, that closes the re-entry gap: a dispatched worker is one-shot; the dispatcher never re-enters it.
2. Every fix loop in the skills reads unambiguously as *fresh leaf per round*, with a defined input contract for the revision round and for the reviewer that follows it.
3. On Claude Code with the module loaded, a `SendMessage` to a session-spawned subagent is refused by the harness with a reason that names the alternative, under every address form the resolver routes to that subagent.
4. The rule is testable offline (stubbed `$`), checked by the existing validator, and its live state on a machine is provable.

## Non-Goals

- No change to which tier any seat runs at, to review-round counts, or to plan length.
- No change to `hook-require-model-pin.sh`, `hook-gate2-guard.sh`, or `hooks/hooks.json` (all three stay byte-identical).
- No cache-TTL configuration anywhere (`promptCacheTtl`, `subagentPromptCacheTtl`, `ENABLE_PROMPT_CACHING_1H`, agent-definition `experimental.cacheTtl`).
- No named resident-drafter agent definition. If a deliberate resident worker is ever wanted, it ships as its own agent definition with a 1h TTL pin — its own ticket.
- No blocking of `SendMessage` to peer sessions, teammates, cloud sessions, or `main`. Cross-session handoffs stay allowed.
- No Grok Build or Codex enforcement mechanism.
- No new validator check that every worker template carries the one-shot sentence; all 15 templates already say "never SendMessage it", and only the two writer seats of a revision loop (the drafter prompts) get the re-entry sentence.
- No repo-side setting of the rollout flag (settings files in this repo are not how hive machines are configured); the flag is doctrine plus a machine setting.

## Design

### 1. Doctrine

**`AGENTS.md` § Dispatch Discipline** — extend the "Leaf-worker dispatch contract" bullet (line 93) with a second clause in the same register as the existing text. The numbers stay in this spec and the ticket; the doctrine carries the rule and the shape of the reason:

> **One-shot.** A dispatched worker's life is exactly one turn. When its turn ends its context is gone for good: the dispatcher never re-enters it — not by `SendMessage`, not by any continuation — and a fix round is a **fresh leaf** given the artifact path and the findings. Verified 2026-09-05: a worker parked across a review round outlives its prompt cache and is re-woken cold at its full prefix, an order of magnitude above a fresh leaf's read of the same artifact, and its context only grows across rounds. On Claude Code the `hooks/hooks.js` module refuses the `SendMessage` when loaded (§ Deterministic Skeleton); on every runtime the rule is the contract.

**`AGENTS.md` § Deterministic Skeleton** — the hooks bullet (line 114) is split so it stays true after this change, and gains the precondition:

> - **Command hooks** (`hooks/hooks.json`) are Claude-Code-specific defense-in-depth and also run on Grok Build (Claude tool-name matchers are aliased: `Bash` → `run_terminal_command`, `Task` → `spawn_subagent`; hook scripts accept both `tool_input` and `toolInput`). **Function-hook modules** (`hooks/hooks.js`, declared from `.claude-plugin/plugin.json` via `hooks/function-hooks.json`) run on Claude Code only, and only when `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` is set in the session environment — set it in the user settings `env` block on every hive machine (as of 2.1.261 the loader is behind a rollout gate that defaults off and skips the module silently). A session without the flag, an older loader, or a crashed hooks worker all fall back to the prose rule. `dodi-dev/scripts/tests/test-hooks-module.sh` proves the module offline; only a refused `SendMessage` in a live session proves the gate is open on a machine. On Codex the prose rules plus server-side branch protection carry the same invariants.

The opening sentence's parenthetical list of plugin hooks gains "no-re-entry guard".

**`execution-model.md` § 1 Leaf rule** — add the one-shot clause as a second paragraph (this file is the single canon both playbooks reference; the playbooks do not restate it). **§ 6 Manifest discipline** gains one sentence: a manifest entry is never a handle to resume a worker — it exists for wake attribution and reaping only.

**Drafter prompt templates** — the "Leaf discipline" bullet in `spec-drafter-prompt.md` and `plan-writer-prompt.md` gains one sentence after "never SendMessage it":

> You will not be re-entered: when your turn ends, your context is gone. Everything a successor needs must be on disk (the artifact) or in your digest.

### 2. Revision-round contract

**Drafter side.** Both drafter prompts gain a **Revision round** block under `Inputs:`, present only when the dispatcher is running a fix round:

```
Revision round (fix rounds only):
- artifact path — the existing draft on disk; you are revising it, not redrafting
- review findings — verbatim from the reviewer's digest, one per line, each tagged `caught-by: <kind>/<round>/<tier>` (the dispatcher fills the round and tier before handing them over)
- round number — N of the loop cap
- the original brief above still applies; canon and conventions are unchanged
```

One bullet under `Responsibilities:`:

> In a revision round: read the artifact and the findings, edit in place, and leave sections no finding touches byte-identical. Do not rewrite from scratch. If a finding is wrong, decline it with one line of reason instead of applying it — the dispatcher carries declines into the next review round.

`Output:` gains one field; the status vocabulary is unchanged (`DRAFT_READY` covers a revised draft):

> - **Findings:** in a revision round, each finding as `applied` or `declined: <reason>`

**Reviewer side.** `brainstorm/spec-reviewer-prompt.md` and `write-plan/plan-reviewer-prompt.md` gain a **Prior round** input block after the spec/plan path lines:

```
**Prior round (rounds ≥ 2):** the previous writer's Findings block — each earlier finding marked applied or declined with a reason.
```

and one rule under `## What to Check`:

> Prior-round declines: a declined finding is closed unless you rebut its reason. To re-raise one, quote the decline and say why it is wrong; a re-raise without a rebuttal is not a finding. Verify each `applied` finding actually landed in the artifact.

**Dispatcher side.** Fix-loop wording is made explicit at each site, using the anchor phrases the verification greps for:

| File | Today | After |
|------|-------|-------|
| `write-plan/SKILL.md:151` | "Fix issues, re-dispatch until approved (max 5 iterations)" | "Dispatch a **fresh plan-writer** in revision mode (plan path + findings + round), then a **fresh reviewer** carrying the writer's Findings block as prior round; repeat until approved (max 5 iterations). Never re-enter the previous writer or reviewer." Interactive sessions, which draft in the main loop, apply the fixes in the main loop as today and pass their own applied/declined list as the prior round. |
| `implement/SKILL.md:40` | "Provide missing context, re-dispatch" | "Provide missing context, dispatch a **fresh implementer**"; the adjacent BLOCKED row (more context, more capable model, smaller task) gains the same "dispatch a fresh implementer" wording |
| `brainstorm/SKILL.md:19` | "fix them and dispatch a fresh spec-reviewer again" | already fresh; add "pass your own applied/declined list as the prior round" so the interactive dispatcher supplies the input the reviewer prompt now reads |
| `mature-playbook.md` rows 12 and 14 | "findings ⇒ another round" | "findings ⇒ **fresh revision-round** drafter/writer, then fresh reviewer with the prior-round block" |
| `mature-playbook.md` § Process (lines 41, 43) | "Run spec/plan review until the final round is clean" | add "each round dispatches **fresh workers** per `execution-model.md` § 1; the reviewer receives the writer's Findings block" |
| `review/SKILL.md` | already "fresh reviewer" / "fix workers" | unchanged |

### 3. Function hook

**Wiring.** Three files, none of them the Grok-visible `hooks/hooks.json`:

- `dodi-dev/.claude-plugin/plugin.json` gains `"hooks": "./hooks/function-hooks.json"` (the manifest schema requires the `./` prefix) (the manifest's `hooks` field accepts a path to an additional hooks file, relative to the plugin root, parsed by the same loader as `hooks/hooks.json`; its `modules` join the same module list).
- `dodi-dev/hooks/function-hooks.json` is `{ "modules": ["hooks.js"] }` — `modules` names exactly one path relative to the file that declares it; the loader refuses a second module anywhere in the plugin, and accepts a hooks file that carries only `modules`.
- `dodi-dev/hooks/hooks.js` is the module: plain ES-module JavaScript, no build step. The loader scans the source before loading to whitelist what it hooks and calls on `$`, so every `$` call is written literally.

The Grok envelope (`.grok-plugin/plugin.json`) and Codex envelope are untouched and never see the module.

**Load gate.** The loader reads `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS`; unset, it falls back to an internal rollout flag that is off in 2.1.261. Off means the module is skipped with a debug-level line and nothing else. Function hooks run in a separate hooks worker; if that worker crashes repeatedly the harness logs "function hooks are off for this session" and stops running them. Both states fail open to the prose rule. The flag is a per-machine setting (user settings `env` block), recorded in doctrine (§ 1), not in this repo.

**Behaviour.**

```js
/** @type {import('claude-code').Register} */
export const register = (on) => {
  const spawnedNames = new Set()

  // Observe: record the address a named spawn is routable by.
  on("agent.spawn", ($, e, next) => {
    if (e.name) spawnedNames.add(normalize(e.name))
    return next(e)
  })

  // Enforce: a SendMessage to one of this session's own subagents is refused.
  on("tool.call", { tool: "SendMessage" }, async ($, e, next) => {
    const raw = String(e.to ?? "").trim()
    if (!raw) return next(e)
    const name = stripRef(raw)                 // "worker [3fa9c1]" → "worker"; the ref is a hash, not an id
    let agents
    try {
      agents = await $.agent.list()
    } catch (err) {
      $.ui.log(`dodi-dev no-re-entry hook: $.agent.list() failed (${err}); allowing SendMessage`)
      return next(e)
    }
    const ids = new Set(agents.map((a) => a.id))
    const n = normalize(name)
    const isOwn =
      ids.has(raw) || ids.has(name) ||
      (n.length > 0 && [...spawnedNames].some((s) => s === n || s.startsWith(n)))
    if (!isOwn) return next(e)
    return {
      deny:
        `dodi-dev no-re-entry rule: "${raw}" is a subagent this session dispatched. ` +
        `A dispatched worker is a one-shot leaf and is never re-entered. ` +
        `Dispatch a fresh Agent with the artifact path and the findings instead ` +
        `(AGENTS.md § Dispatch Discipline; execution-model.md § 1).`,
    }
  })
}
```

Helpers, mirroring the runtime resolver as read from the 2.1.261 binary (the plan re-reads and pins both; if the resolver differs, the resolver wins):

- `stripRef(s)`: applies `/^(.*\S)\s*\[[^\]]+\]$/` and returns group 1, else `s`. The bracketed token is a short hex hash used to disambiguate peer sessions; it is never an agent id (ids are `a` + optional scope + 16 hex) and the hook cannot recompute it, so any trailing bracketed token is dropped. The plan's re-read of the resolver pins the exact width if it wants a tighter pattern; the wider one is safe because an id never ends in `]`.
- `normalize(s)`: NFKC, strip control and format characters, trim, lower-case, then whitespace runs → `-`. This is the resolver's own folding of registry names.
- Prefix: the resolver reports "'X' matches N agents by prefix", i.e. a typed name that is a prefix of a registered name reaches it; the hook matches the same way.

Why the id check carries the load: the Agent-tool spawn path registers a name only when the call passes `name`. dodi-dev prompts never do, so every dodi-dev worker is addressable by id alone and `ids.has(raw)` is the check that fires in practice. The name path exists so a named spawn cannot be used as a bypass.

Notes on the API as verified in the 2.1.261 binary's embedded `claude-code.d.ts` and its tool schemas:

- `on("tool.call", matcher, hook)` fires before the engine runs a tool; the hook returns `next(e)` to allow or `{ deny: reason }` to refuse, and the model reads the reason as the tool's error result.
- `$.agent.list()` returns `AgentInfo[]` — `{ id, description, type, status }` — for every local-agent task of the session in any status. Completed agents are included, which is exactly the parked case. Peer sessions are not in it.
- `AgentInfo` has no `name`; a named spawn (`Agent({ name })`) is addressable by that name, so the `agent.spawn` observer records `e.name`. A hot reload of the plugin re-runs `register` and drops the `Set`; id matching still holds.
- The matcher form `{ tool: "SendMessage" }` narrows `e` to the tool's arguments spread beside `tool` and `tool_use_id`; `SendMessage`'s target argument is `to` (confirmed in this build's schema). The extracted `claude-code.d.ts` has an empty `BuiltinToolInputs` table (it is filled by `/plugin-types` per session), so the plan regenerates the types with `/plugin-types` and logs `Object.keys(e)` once on the first live run rather than trusting the dump. That probe is removed before release: the shipped module has exactly the two hooks and two `$` calls test 6 asserts, and no per-`SendMessage` transcript line.
- `$.ui.log` writes a dim transcript line the user can see and the model does not; it is the fail-open trace.
- The harness already skips a hook that throws and runs what is beneath it. The `try/catch` therefore buys only the log line; it must not be relied on for anything else, and it must not be removed as redundant.

**Fail-open rationale.** The function-hook surface is early access. A thrown `$.agent.list()` most likely means the surface moved; refusing every `SendMessage` in that state would break peer handoffs, which the rule explicitly permits. The log line makes that state visible; the test script (§ 4) makes it loud offline; the live deny (§ 4) is the only proof the gate is open on a given machine.

**No escape hatch.** Unlike `DODI_ALLOW_UNPINNED`, there is no env or prompt token that lifts this deny: an escape the model can type is not an escape, and the address matching covers every form the resolver routes to a subagent. An operator who needs a resident worker removes the `hooks` entry from the Claude manifest or ships a deliberate agent definition — out of scope here.

### 4. Tests and validation

**`dodi-dev/scripts/tests/test-hooks-module.sh`** — runs a `.mjs` driver under `node` (v26 on the dev machine; `bun` is absent) that imports `hooks.js`, passes a stub `on` that captures registrations, and drives the captured hooks with a stub `$`:

1. `SendMessage` to a listed id (`a` + 16 hex) ⇒ result has `deny` mentioning the address.
2. `SendMessage` to a name recorded by a prior `agent.spawn` event ⇒ `deny`.
3. `SendMessage` to `local_…` (a peer session id absent from the list) ⇒ `next(e)` was called, no `deny`.
4. Stub `$.agent.list()` rejects ⇒ `next(e)` called and `$.ui.log` called once.
5. Empty `to` ⇒ `next(e)`.
6. The module registers exactly two hooks: `agent.spawn` (unmatched) and `tool.call` with matcher `{ tool: "SendMessage" }`; across the whole run the stub `$` saw calls on exactly `agent.list` and `ui.log` and nothing else.
7. Address forms, with `worker` and `code reviewer` spawned (recorded as `worker`, `code-reviewer`) and one listed id: `worker [3fa9c1]` ⇒ `deny`; `work` and `work [3fa9c1]` (prefix) ⇒ `deny`; `Worker`, `Code  Reviewer`, and `code reviewer` (normalization) ⇒ `deny`; `codereviewer`, `main`, a teammate-style name, and `other [3fa9c1]` ⇒ `next(e)`.

**`scripts/validate-phase-skills.sh`** — beside the existing `hooks.json` JSON-parse check (line 236): parse `hooks/function-hooks.json`, assert every `modules` entry resolves to an existing regular file beside it, assert `.claude-plugin/plugin.json`'s `hooks` path resolves to that file, and syntax-check the module with `node --check` when `node` is present (Node ≥ 22.7 detects ESM syntax on a bare `.js`; skip with a notice when `node` is absent). `scripts/validate-plugin-metadata.sh` needs no change: it parses the manifests and compares versions without a field whitelist.

**Manual, plan-time:** `claude plugin validate` on the plugin directory shows the scan result for the module (expected: hooks `agent.spawn`, `tool.call`; calls `agent.list`, `ui.log`). `/plugin-types` regenerates `claude-code.d.ts` with the build's real `SendMessage` input type. With `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` set, `claude --debug` must not print `hooks modules not loaded`, and the live checks in § Verification must pass, including the teammate and fork checks for the two ⚠ assumptions.

### 5. Release

Bump all five version files to `0.20.0` (doctrine plus a new hook surface is a minor). This also clears the current skew: `d8bd09e` bumped only the two Claude files to 0.19.1 and was never tagged (`git tag` ends at `v0.19.0`), so the Codex and Grok envelopes still read 0.19.0 and `scripts/validate-plugin-metadata.sh` fails on main today with `AssertionError: ('0.19.1', '0.19.0')`. The release commit message says so; the validator passing is the after-check. Tag `v0.20.0`, bare version in the commit message, per `AGENTS.md` § Editing Rules.

## Integration points

- `AGENTS.md` § Dispatch Discipline (line 93) and § Deterministic Skeleton (lines 107, 114).
- `dodi-dev/skills/epic-orchestrator/execution-model.md` §§ 1, 6.
- `dodi-dev/skills/mature-ticket/spec-drafter-prompt.md`, `dodi-dev/skills/write-plan/plan-writer-prompt.md`.
- `dodi-dev/skills/brainstorm/spec-reviewer-prompt.md`, `dodi-dev/skills/write-plan/plan-reviewer-prompt.md`.
- `dodi-dev/skills/write-plan/SKILL.md`, `dodi-dev/skills/implement/SKILL.md`, `dodi-dev/skills/brainstorm/SKILL.md`, `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md`.
- `dodi-dev/.claude-plugin/plugin.json` (`hooks` field), new `dodi-dev/hooks/function-hooks.json`, new `dodi-dev/hooks/hooks.js`.
- `dodi-dev/scripts/tests/test-hooks-module.sh` (new, with its `.mjs` driver), `scripts/validate-phase-skills.sh`; `scripts/validate-plugin-metadata.sh` unchanged.
- Five version files.
- Hive machines: `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` in the user settings `env` block (operator action, recorded in doctrine, not a repo change).

## Edge cases

- **Peer sessions, teammates, `main`.** Not in `$.agent.list()` (teammates: ⚠ assumption, live-verified in the plan); allowed. A named subagent that shares a peer session's bare name is denied (subagent match wins). Acceptable: names are the dispatcher's own choice, and the runtime itself routes a bare name to the in-session subagent first.
- **Completed vs running workers.** Both are denied; the list holds every local-agent task of the session. A running worker is not a re-entry target either — under the leaf rule the dispatcher awaits its digest.
- **Plugin-spawned agents** (`$.agent.spawn` from another plugin) are listed and therefore denied as targets too. No dodi-dev flow messages them.
- **Forks** (`subagent_type: fork`, forked skills) get a runtime-allocated registered name without the call passing `name`, and that name does not reach `e.name` at `agent.spawn`, so a fork is denied by id only — address it by the id `ListAgents` shows. dodi-dev spawns no forks, so this is not load-bearing.
- **Hot reload** drops `spawnedNames`; id-based denial continues. Names are only the addressable form for named spawns, which dodi-dev prompts do not use today.
- **Address forms.** Bare name, `name [ref]`, name prefix, case and whitespace variants, and raw id all resolve to the same subagent at the runtime and are all denied (§ 3 helpers, test 7).
- **Grok Build / Codex.** No function hooks; the doctrine text and the fix-loop wording are the whole rule. Grok's harness depth limit already blocks nested dispatch, and neither runtime has a peer-messaging tool. `hooks/hooks.json` is unchanged, so Grok's loader sees nothing new.
- **Interactive sessions.** The hook fires for any session with the plugin loaded, including a human-driven brainstorm that wants to continue a research agent. The deny reason names the alternative; this is the intended trade (Key Points, decision 5).
- **Module not loaded** — older loader (unknown `modules` key ignored, command hooks still load), rollout flag off, or hooks worker crashed: all fail open to the prose rule with at most a debug-level line. This is why the flag is doctrine and the live deny is the proof.

## Open assumptions

- ⚠ In-process teammates are absent from `$.agent.list()` — read from the 2.1.261 binary: teammates are a distinct task type and the Agent tool's teammate branch never fires `agent.spawn`; the plan's live check confirms rather than discovers.
- ⚠ A fork's runtime-allocated name does not reach `e.name` at `agent.spawn` (read from the binary); a fork is denied by id only. Not load-bearing: dodi-dev spawns no forks.

## Verification

- `bash dodi-dev/scripts/tests/test-hooks-module.sh` passes all seven cases.
- `bash scripts/validate-phase-skills.sh`, `bash scripts/validate-plugin-metadata.sh` (fails on main today, passes after the bump), `bash scripts/validate-ticket-comment-templates.sh` pass.
- Anchor-phrase check: `grep -c "fresh plan-writer" dodi-dev/skills/write-plan/SKILL.md` ≥ 1; `grep -c "fresh implementer" dodi-dev/skills/implement/SKILL.md` ≥ 1; `grep -c "fresh revision-round" dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md` = 2; `grep -c "fresh workers" dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md` ≥ 1; `grep -c "prior round" dodi-dev/skills/brainstorm/SKILL.md` ≥ 1 and the same for `dodi-dev/skills/write-plan/SKILL.md`.
- `git diff --stat main -- dodi-dev/hooks/hooks.json dodi-dev/scripts/hook-require-model-pin.sh dodi-dev/scripts/hook-gate2-guard.sh` is empty.
- Live, with `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` and the updated plugin: `claude --debug` shows no `hooks modules not loaded` line; `claude plugin validate` lists the module's hooks and calls as § 4 expects; dispatch a Standard-tier agent, let it finish, then `SendMessage` it by id and by name prefix — both refused with the rule text; `SendMessage` to a peer session and to a teammate succeed.
- `git tag` shows `v0.20.0` on the bump commit; all five version files read `0.20.0`.
