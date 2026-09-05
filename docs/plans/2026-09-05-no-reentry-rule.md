# No-Re-Entry Rule for Dispatched Workers — Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Ticket:** DOD-1336. **Spec:** `docs/specs/2026-09-05-no-reentry-rule-design.md` (approved 2026-09-05). **Branch:** the `dodi-dev:pickup` worktree for DOD-1336, with the spec and plan commits cherry-picked from `spec/no-reentry-rule` (Task 0); PR to `main`. **Release:** 0.20.0.

**Goal:** Make every dispatched worker a one-shot leaf — doctrine on all runtimes, a function-hook `SendMessage` guard on Claude Code, and fresh-leaf fix rounds with a revision-round contract — shipped as dodi-dev 0.20.0.

**Architecture:** Three independent units. (1) Doctrine and prompt text: `AGENTS.md`, `execution-model.md`, two drafter prompts, two reviewer prompts, four fix-loop sites. (2) The guard: `dodi-dev/hooks/hooks.js`, an ES module exporting `register(on)`, declared from the Claude plugin manifest through `dodi-dev/hooks/function-hooks.json`; `hooks/hooks.json` untouched. (3) Tests and release: a `node`-driven offline test with a stubbed `$`, a validator addition, the five-file version bump, tag.

**Tech Stack:** Markdown doctrine; plain ES-module JavaScript (no build, no dependencies) run by the Claude Code hooks worker; bash test scripts driven by `node` v26; Python-in-bash validators as the repo already uses.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `dodi-dev/hooks/hooks.js` — `register`, the `agent.spawn` observer, the `tool.call` guard, `normalize`, `stripRef`
  - Reason: the guard is the only mechanical enforcement of the rule; its matching must mirror the runtime resolver and must fail open on API drift, and a wrong shipped `$` surface would be refused by the loader's source scan
  - Minimum assertions: the seven cases in Task 5 (id deny; recorded-name deny; peer allow; list-throw ⇒ allow + one log line; empty `to` ⇒ allow; exactly two registrations and exactly `agent.list` + `ui.log` on `$`; address forms per the spec's test 7)

- Integration: `required`
  - Scope: plugin loading — `.claude-plugin/plugin.json` `hooks` → `hooks/function-hooks.json` → `hooks/hooks.js`; validator coverage of that chain
  - Reason: the module is declared through a manifest path the repo has never used; a wrong relative path loads nothing, silently
  - Harness: `existing` (`scripts/validate-phase-skills.sh`, extended in Task 6) plus `claude plugin validate` (manual, Task 8)
  - Minimum assertions: validator resolves the manifest chain and syntax-checks the module; `claude plugin validate` lists hooks `agent.spawn`, `tool.call` and calls `agent.list`, `ui.log`

- E2E: `required`
  - Scope: a live Claude Code session with `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` and the updated plugin
  - Reason: the loader is behind a rollout flag and skips silently; the live deny is the only proof the guard is on, and the two ⚠ assumptions (teammates, forks) can only be checked live
  - Harness: `setup-required` (flag in user settings `env`; fresh session after `plugin update`)
  - Minimum assertions: `SendMessage` to a finished subagent by id ⇒ refused with the rule text; by name prefix (a named spawn) ⇒ refused; to a peer session ⇒ delivered; to a teammate ⇒ delivered; `claude --debug` shows no `hooks modules not loaded` line

### Critical Flows

- Dispatcher runs a plan-review fix round: fresh writer in revision mode edits the plan in place, returns `Findings` (applied/declined); fresh reviewer receives the block, closes declines it does not rebut.
- Dispatcher tries to `SendMessage` a finished worker on Claude Code with the module loaded: refused, told to dispatch a fresh Agent.
- Cross-session handoff (`SendMessage` to a `local_…` peer) still delivers.

### Regression Surface

- `dodi-dev/hooks/hooks.json`, `hook-require-model-pin.sh`, `hook-gate2-guard.sh` — byte-identical (Task 9 checks).
- `scripts/validate-phase-skills.sh` seat registry and tier/effort checks on the four edited prompt templates — still pass (the edits add lines, never touch the tier parenthetical).
- `test-hooks-payload.sh` and the other ten `dodi-dev/scripts/tests/*.sh` — still pass (`test-validate-phase-skills.sh` needs the Task 6 Step 0 tmp-tree change to keep passing).
- Grok Build and Codex envelopes — unchanged except the version field.

### Commands

- Unit: `bash dodi-dev/scripts/tests/test-hooks-module.sh`
- Integration: `bash scripts/validate-phase-skills.sh && claude plugin validate dodi-dev`
- E2E: manual, Task 8 (a live session; steps listed)
- Broader regression: `for t in dodi-dev/scripts/tests/test-*.sh; do bash "$t" || exit 1; done && bash scripts/validate-plugin-metadata.sh && bash scripts/validate-ticket-comment-templates.sh`

### Harness Requirements

- `node` ≥ 22.7 on PATH (v26.7.0 on the dev machine; `bun` is absent and not needed).
- For E2E: Claude Code ≥ 2.1.261; `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` in `~/.claude/settings.json` `env`; the plugin updated to the branch build and a fresh session; a second local Claude session for the peer check; a coordinator-mode teammate for the teammate check.

### Non-Required Rationale

- Unit: required.
- Integration: required.
- E2E: required.

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `AGENTS.md` | modify | doctrine: one-shot clause (§ Dispatch Discipline), hooks split + flag (§ Deterministic Skeleton) |
| `dodi-dev/skills/epic-orchestrator/execution-model.md` | modify | canon: one-shot paragraph (§ 1), manifest-is-not-a-handle (§ 6) |
| `dodi-dev/skills/mature-ticket/spec-drafter-prompt.md` | modify | revision-round input, in-place rule, `Findings` output, re-entry sentence |
| `dodi-dev/skills/write-plan/plan-writer-prompt.md` | modify | same as above for the plan writer |
| `dodi-dev/skills/brainstorm/spec-reviewer-prompt.md` | modify | prior-round input, decline rule |
| `dodi-dev/skills/write-plan/plan-reviewer-prompt.md` | modify | prior-round input, decline rule |
| `dodi-dev/skills/write-plan/SKILL.md` | modify | fix loop: fresh plan-writer / fresh reviewer / prior round |
| `dodi-dev/skills/implement/SKILL.md` | modify | NEEDS_CONTEXT and BLOCKED rows: fresh implementer |
| `dodi-dev/skills/brainstorm/SKILL.md` | modify | step 6: pass applied/declined list as prior round |
| `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md` | modify | rows 12/14 and § Process lines 41/43 |
| `dodi-dev/.claude-plugin/plugin.json` | modify | `hooks` field → `hooks/function-hooks.json`; version |
| `dodi-dev/hooks/function-hooks.json` | create | `{ "modules": ["hooks.js"] }` |
| `dodi-dev/hooks/hooks.js` | create | the guard module |
| `dodi-dev/scripts/tests/test-hooks-module.sh` | create | bash entry: syntax check + runs the driver |
| `dodi-dev/scripts/tests/hooks-module-driver.mjs` | create | node driver with stub `on` / `$`; the seven cases |
| `scripts/validate-phase-skills.sh` | modify | manifest-chain + `node --check` |
| `dodi-dev/scripts/tests/test-validate-phase-skills.sh` | modify | its tmp tree gains `dodi-dev/.claude-plugin` so the new check can read the manifest |
| `.claude-plugin/marketplace.json`, `dodi-dev/.codex-plugin/plugin.json`, `dodi-dev/.grok-plugin/plugin.json`, `.grok-plugin/marketplace.json` | modify | version 0.20.0 |

---

### Task 0: Worktree

**Files:** none.

- [ ] **Step 1:** The ticket worktree exists (created by `dodi-dev:pickup` for DOD-1336 from `main`). All later tasks run inside it. Confirm and record its path:

Run: `git worktree list | grep -i 1336`
Expected: one line naming the worktree path and its branch.

- [ ] **Step 2:** Bring the spec and plan commits into the ticket branch from `spec/no-reentry-rule` (they were committed there during the design session).

Run (inside the worktree):
```bash
git cherry-pick $(git log --reverse --format=%H main..spec/no-reentry-rule) && git log --oneline -3
```
Expected: the spec and plan commits (two or more, the last plan-review fix rounds included) on top of `d8bd09e`, the first being `spec: no-re-entry rule …`.

- [ ] **Step 3:** Confirm the working tree is clean and the three byte-identical files have no drift.

Run: `git status --short | wc -l && git diff --stat main -- dodi-dev/hooks/hooks.json dodi-dev/scripts/hook-require-model-pin.sh dodi-dev/scripts/hook-gate2-guard.sh`
Expected: `0` and an empty diff.

---

### Task 1: Doctrine — `AGENTS.md`

**Files:**
- Modify: `AGENTS.md:93` (Leaf-worker dispatch contract bullet), `AGENTS.md:107` (Deterministic Skeleton opening sentence), `AGENTS.md:114` (hooks bullet)

- [ ] **Step 1:** In the bullet that begins `- **Leaf-worker dispatch contract (verified 2026-07-05 on Claude Code).**`, replace its final sentence `The leaf rule is unchanged on every runtime.` with:

```markdown
The leaf rule is unchanged on every runtime. **One-shot.** A dispatched worker's life is exactly one turn. When its turn ends its context is gone for good: the dispatcher never re-enters it — not by `SendMessage`, not by any continuation — and a fix round is a **fresh leaf** given the artifact path and the findings. Verified 2026-09-05: a worker parked across a review round outlives its prompt cache and is re-woken cold at its full prefix, an order of magnitude above a fresh leaf's read of the same artifact, and its context only grows across rounds. On Claude Code the `hooks/hooks.js` module refuses the `SendMessage` when loaded (§ Deterministic Skeleton); on every runtime the rule is the contract.
```

- [ ] **Step 2:** In § Deterministic Skeleton's opening paragraph, change `and as plugin hooks (Gate 2 merge guard, dispatch-pin enforcement).` to `and as plugin hooks (Gate 2 merge guard, dispatch-pin enforcement, no-re-entry guard).`

- [ ] **Step 3:** Replace the bullet that begins `- Hooks are Claude-Code-specific defense-in-depth and also run on Grok Build` (the whole bullet, one line) with:

```markdown
- **Command hooks** (`hooks/hooks.json`) are Claude-Code-specific defense-in-depth and also run on Grok Build (Claude tool-name matchers are aliased: `Bash` → `run_terminal_command`, `Task` → `spawn_subagent`; hook scripts accept both `tool_input` and `toolInput`). **Function-hook modules** (`hooks/hooks.js`, declared from `.claude-plugin/plugin.json` via `hooks/function-hooks.json`) run on Claude Code only, and only when `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` is set in the session environment — set it in the user settings `env` block on every hive machine (as of 2.1.261 the loader is behind a rollout gate that defaults off and skips the module silently). A session without the flag, an older loader, or a crashed hooks worker all fall back to the prose rule. `dodi-dev/scripts/tests/test-hooks-module.sh` proves the module offline; only a refused `SendMessage` in a live session proves the gate is open on a machine. On Codex the prose rules plus server-side branch protection carry the same invariants.
```

- [ ] **Step 4:** Verify.

Run: `grep -c "One-shot\." AGENTS.md; grep -c "no-re-entry guard" AGENTS.md; grep -c "CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1" AGENTS.md; grep -c "^- Hooks are Claude-Code-specific" AGENTS.md`
Expected: `1`, `1`, `1`, `0`.

- [ ] **Step 5:** Commit.

```bash
git add AGENTS.md
git commit -m "doctrine: one-shot leaf clause and function-hook split (DOD-1336)"
```

---

### Task 2: Canon — `execution-model.md`

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/execution-model.md` § 1 (after line 9), § 6 (heading line 42, paragraph line 44)

- [ ] **Step 1:** In § 1 Leaf rule, after the paragraph beginning `This is permanent architecture, not an interim workaround.`, add a new paragraph:

```markdown
**One-shot.** A dispatched worker's life is exactly one turn. When its turn ends its context is gone for good: the dispatcher never re-enters it — not by `SendMessage`, not by any continuation — and a fix round is a **fresh leaf** given the artifact path and the findings (the revision-round input block in the drafter prompts). Rationale: a worker parked across a review round outlives its prompt cache and is re-woken cold at its full prefix, an order of magnitude above a fresh leaf's read of the same artifact, and its context only grows across rounds. On Claude Code the plugin's `hooks/hooks.js` module refuses the `SendMessage` when loaded (AGENTS.md § Deterministic Skeleton names the load precondition); on every runtime the rule is the contract.
```

- [ ] **Step 2:** In § 6 Manifest discipline, append to the existing paragraph (same paragraph, after `Wakes for reaped entries are ignored (§3).`):

```markdown
 A manifest entry is never a handle to resume a worker — it exists for wake attribution and reaping only (§ 1, one-shot).
```

- [ ] **Step 3:** Verify.

Run: `grep -c "^\*\*One-shot\.\*\*" dodi-dev/skills/epic-orchestrator/execution-model.md; grep -c "never a handle to resume" dodi-dev/skills/epic-orchestrator/execution-model.md`
Expected: `1`, `1`.

- [ ] **Step 4:** Commit.

```bash
git add dodi-dev/skills/epic-orchestrator/execution-model.md
git commit -m "execution-model: one-shot paragraph, manifest is not a resume handle (DOD-1336)"
```

---

### Task 3: Drafter and reviewer prompts

**Files:**
- Modify: `dodi-dev/skills/mature-ticket/spec-drafter-prompt.md` (Inputs list ending line 15, Responsibilities line 21, Output lines 30–32)
- Modify: `dodi-dev/skills/write-plan/plan-writer-prompt.md` (Inputs list ending line 17, Responsibilities line 23, Output lines 30–32)
- Modify: `dodi-dev/skills/brainstorm/spec-reviewer-prompt.md` (line 11 and the `## What to Check` table)
- Modify: `dodi-dev/skills/write-plan/plan-reviewer-prompt.md` (line 12 and the `## What to Check` table)

- [ ] **Step 1:** In **both** drafter prompts, append this block to the `Inputs:` list (after its last `- ` item, before the blank line preceding `Responsibilities:`). Same text in both files:

```markdown
- **Revision round (fix rounds only):**
  - artifact path — the existing draft on disk; you are revising it, not redrafting
  - review findings — verbatim from the reviewer's digest, one per line, each tagged `caught-by: <kind>/<round>/<tier>` (the dispatcher fills the round and tier before handing them over)
  - round number — N of the loop cap
  - the original brief above still applies; canon and conventions are unchanged
```

- [ ] **Step 2:** In **both** drafter prompts, edit the `- **Leaf discipline (Claude Code):**` bullet: after `End by writing the digest itself; never SendMessage it.` append ` You will not be re-entered: when your turn ends, your context is gone. Everything a successor needs must be on disk (the artifact) or in your digest.`

- [ ] **Step 3:** In **both** drafter prompts, add this bullet to `Responsibilities:` immediately after the Leaf discipline bullet:

```markdown
- **Revision round:** read the artifact and the findings, edit in place, and leave sections no finding touches byte-identical. Do not rewrite from scratch. If a finding is wrong, decline it with one line of reason instead of applying it — the dispatcher carries declines into the next review round.
```

- [ ] **Step 4:** In **both** drafter prompts, add to the `Output:` list, after the `- **Status:**` line:

```markdown
- **Findings:** in a revision round, each finding as `applied` or `declined: <reason>`
```

- [ ] **Step 5:** In `spec-reviewer-prompt.md`, after the line `    **Spec to review:** [SPEC_FILE_PATH]` add:

```markdown
    **Prior round (rounds ≥ 2):** the previous writer's Findings block — each earlier finding marked applied or declined with a reason.
```

In `plan-reviewer-prompt.md`, after the line `    **Spec for reference:** [SPEC_FILE_PATH]` add the same line (same 4-space indent, inside the fenced prompt).

- [ ] **Step 6:** In **both** reviewer prompts, add a row to the `## What to Check` table (last row):

```markdown
    | Prior-round declines | A declined finding is closed unless you rebut its reason. To re-raise one, quote the decline and say why it is wrong; a re-raise without a rebuttal is not a finding. Verify each `applied` finding actually landed in the artifact |
```

- [ ] **Step 7:** Verify.

Run:
```bash
for f in dodi-dev/skills/mature-ticket/spec-drafter-prompt.md dodi-dev/skills/write-plan/plan-writer-prompt.md; do echo "$f: $(grep -c 'Revision round' $f) $(grep -c 'You will not be re-entered' $f) $(grep -c '^- \*\*Findings:\*\*' $f)"; done
for f in dodi-dev/skills/brainstorm/spec-reviewer-prompt.md dodi-dev/skills/write-plan/plan-reviewer-prompt.md; do echo "$f: $(grep -c 'Prior round (rounds' $f) $(grep -c 'Prior-round declines' $f)"; done
bash scripts/validate-phase-skills.sh
```
Expected: each drafter line `2 1 1` (Revision round appears in Inputs and Responsibilities); each reviewer line `1 1`; validator prints its usual OK output with exit 0.

- [ ] **Step 8:** Commit.

```bash
git add dodi-dev/skills/mature-ticket/spec-drafter-prompt.md dodi-dev/skills/write-plan/plan-writer-prompt.md dodi-dev/skills/brainstorm/spec-reviewer-prompt.md dodi-dev/skills/write-plan/plan-reviewer-prompt.md
git commit -m "prompts: revision-round contract, prior-round declines, no re-entry (DOD-1336)"
```

---

### Task 4: Fix-loop wording in the skills

**Files:**
- Modify: `dodi-dev/skills/write-plan/SKILL.md:151`
- Modify: `dodi-dev/skills/implement/SKILL.md:40-41`
- Modify: `dodi-dev/skills/brainstorm/SKILL.md:19`
- Modify: `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md:12,14,41,43`

- [ ] **Step 1:** `write-plan/SKILL.md` — replace the line `2. Fix issues, re-dispatch until approved (max 5 iterations)` with:

```markdown
2. Dispatch a **fresh plan-writer** in revision mode (plan path + findings + round — the Revision round block in plan-writer-prompt.md), then a **fresh reviewer** carrying the writer's Findings block as prior round; repeat until approved (max 5 iterations). Never re-enter the previous writer or reviewer (`execution-model.md` § 1, one-shot). Interactive sessions, which draft in the main loop, apply the fixes in the main loop and pass their own applied/declined list as the prior round.
```

- [ ] **Step 2:** `implement/SKILL.md` — replace the two table rows:

```markdown
| **NEEDS_CONTEXT** | Provide missing context, dispatch a **fresh implementer** |
| **BLOCKED** | Assess: provide more context, use more capable model, break task smaller, or escalate to human — any retry is a fresh implementer, never a re-entry |
```

- [ ] **Step 3:** `brainstorm/SKILL.md` — in step 6, replace `If it reports any issues, fix them and dispatch a fresh spec-reviewer again.` with `If it reports any issues, fix them and dispatch a fresh spec-reviewer again, passing your own applied/declined list as the prior round (the Prior round input in spec-reviewer-prompt.md).`

- [ ] **Step 4:** `mature-playbook.md` — in the phase table:
  - row `Spec review loop`: replace `findings ⇒ another round (loop capped, final must be clean)` with `findings ⇒ **fresh revision-round** drafter, then fresh reviewer with the prior-round block (loop capped, final must be clean)`
  - row `Plan review loop`: replace `findings ⇒ another round;` with `findings ⇒ **fresh revision-round** writer, then fresh reviewer with the prior-round block;`

- [ ] **Step 5:** `mature-playbook.md` § Process — replace:
  - `- Run **spec review** until the final round is clean; a missing or stale scannable header is a review finding.` with `- Run **spec review** until the final round is clean; each round dispatches **fresh workers** per `execution-model.md` § 1, and the reviewer receives the writer's Findings block as prior round. A missing or stale scannable header is a review finding.`
  - `- Run **plan review** until the final round is clean.` with `- Run **plan review** until the final round is clean; each round dispatches **fresh workers** per `execution-model.md` § 1, and the reviewer receives the writer's Findings block as prior round.`

- [ ] **Step 6:** Verify (the spec's anchor-phrase check).

Run:
```bash
grep -c "fresh plan-writer" dodi-dev/skills/write-plan/SKILL.md; grep -c "fresh implementer" dodi-dev/skills/implement/SKILL.md; grep -c "fresh revision-round" dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md; grep -c "fresh workers" dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md; grep -c "prior round" dodi-dev/skills/brainstorm/SKILL.md; grep -c "prior round" dodi-dev/skills/write-plan/SKILL.md; bash scripts/validate-phase-skills.sh >/dev/null && echo validator-ok
```
Expected: `1`, `2`, `2`, `2`, `1`, `1`, `validator-ok`.

- [ ] **Step 7:** Commit.

```bash
git add dodi-dev/skills/write-plan/SKILL.md dodi-dev/skills/implement/SKILL.md dodi-dev/skills/brainstorm/SKILL.md dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md
git commit -m "skills: fix loops dispatch fresh leaves with the prior-round block (DOD-1336)"
```

---

### Task 5: The guard module and its offline test

**Files:**
- Create: `dodi-dev/hooks/hooks.js`
- Create: `dodi-dev/hooks/function-hooks.json`
- Modify: `dodi-dev/.claude-plugin/plugin.json`
- Create: `dodi-dev/scripts/tests/hooks-module-driver.mjs`
- Create: `dodi-dev/scripts/tests/test-hooks-module.sh`

- [ ] **Step 1:** Pin the resolver's name normalization before writing code. The spec records it as read from the 2.1.261 binary; confirm it against the installed build so the module mirrors the resolver rather than the spec:

Run:
```bash
bin="$(readlink -f "$(which claude)")"; strings -n 8 "$bin" | grep -oE 'normalize\("NFKC"\)\.replace\([^;]{0,200}' | head -3
```
Expected: the first hit is the resolver's fold and reads `normalize("NFKC").replace(/[\p{Cc}\p{Cf}]/gu,(t)=>/\s/.test(t)?t:"").trim().toLowerCase().replace(/\s+/g,"-")` (minified variable names may differ). The binary carries two other, unrelated `normalize("NFKC")` folds; the one to match is the one ending `.trim().toLowerCase().replace(/\s+/g,"-")`. If that fold differs from Step 2's `normalize` (for example whitespace collapsed rather than replaced with `-`), write `normalize` to match what the binary shows and adjust test case 7 accordingly; the resolver wins.

- [ ] **Step 2:** Create `dodi-dev/hooks/hooks.js`:

```js
// dodi-dev no-re-entry guard — a Claude Code function-hook module.
//
// A dispatched worker is a one-shot leaf (AGENTS.md § Dispatch Discipline;
// epic-orchestrator/execution-model.md § 1). This module refuses a SendMessage
// whose target is a subagent this session spawned, so a dispatcher cannot
// re-enter a parked worker. Peer sessions, teammates and "main" are not in
// $.agent.list() and pass through.
//
// Loaded only when CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 (or the harness rollout
// flag) — see AGENTS.md § Deterministic Skeleton. Fails open: a thrown
// $.agent.list() logs one line and allows the call.
//
// Keep every call on `$` literal: the loader scans this source to whitelist
// what the module hooks and calls.

const REF_SUFFIX = /^(.*\S)\s*\[[^\]]+\]$/

// Mirrors the runtime resolver's folding of registry names.
export function normalize(s) {
  return String(s)
    .normalize("NFKC")
    .replace(/[\p{Cc}\p{Cf}]/gu, (t) => (/\s/.test(t) ? t : ""))
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "-")
}

// "worker [3fa9c1]" → "worker". The bracketed token is a disambiguation hash
// for peer sessions, never an agent id, so it is dropped.
export function stripRef(s) {
  const m = REF_SUFFIX.exec(s)
  return m ? m[1] : s
}

const DENY_TAIL =
  " is a subagent this session dispatched. A dispatched worker is a one-shot leaf and is never re-entered. " +
  "Dispatch a fresh Agent with the artifact path and the findings instead " +
  "(AGENTS.md § Dispatch Discipline; execution-model.md § 1)."

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
    const name = stripRef(raw)
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
      ids.has(raw) ||
      ids.has(name) ||
      (n.length > 0 && [...spawnedNames].some((s) => s === n || s.startsWith(n)))
    if (!isOwn) return next(e)
    return { deny: `dodi-dev no-re-entry rule: "${raw}"${DENY_TAIL}` }
  })
}
```

- [ ] **Step 3:** Create `dodi-dev/hooks/function-hooks.json`:

```json
{
  "modules": ["hooks.js"]
}
```

- [ ] **Step 4:** Edit `dodi-dev/.claude-plugin/plugin.json` — add the `hooks` field (version is bumped in Task 7):

```json
{
  "name": "dodi-dev",
  "description": "Dev workflow, local epic orchestration, and PR lifecycle skills",
  "version": "0.19.1",
  "author": {
    "name": "Dodi HQ",
    "email": "may@dodihome.com"
  },
  "hooks": "hooks/function-hooks.json"
}
```

- [ ] **Step 5:** Create `dodi-dev/scripts/tests/hooks-module-driver.mjs`:

```js
// Offline driver for dodi-dev/hooks/hooks.js: stub `on` and `$`, run the
// seven cases from the no-re-entry spec's § 4 test list (DOD-1336).
// The stub AgentInfo carries `status` because the runtime emits it (the
// generated claude-code.d.ts may omit it); the module reads only `id`.
import { register, normalize, stripRef } from "../../hooks/hooks.js"

const registrations = []
const on = (event, matcherOrHook, maybeHook) => {
  if (maybeHook === undefined) registrations.push({ event, matcher: undefined, hook: matcherOrHook })
  else registrations.push({ event, matcher: matcherOrHook, hook: maybeHook })
}
register(on)

const seen = new Set() // every `$.<noun>.<verb>` path the module touched
let logLines = 0
const make$ = ({ list }) => {
  const rec = (path, fn) => (...args) => { seen.add(path); return fn(...args) }
  return {
    agent: { list: rec("agent.list", list) },
    ui: { log: rec("ui.log", () => { logLines += 1 }) },
  }
}

const spawnHook = registrations.find((r) => r.event === "agent.spawn")?.hook
const callHook = registrations.find((r) => r.event === "tool.call")?.hook

let failures = 0
const check = (label, cond) => {
  if (cond) console.log(`ok   ${label}`)
  else { failures += 1; console.log(`FAIL ${label}`) }
}

const ID = "a0123456789abcdef"            // a + 16 hex, the runtime's id shape
const listed = async () => [{ id: ID, description: "Write plan", type: "general-purpose", status: "completed" }]
const send = async (to, { list = listed } = {}) => {
  let nextCalled = false
  const e = { tool: "SendMessage", tool_use_id: "toolu_x", to, message: "hi" }
  const res = await callHook(make$({ list }), e, async (ev) => { nextCalled = true; return { result: "sent" } })
  return { nextCalled, deny: res?.deny }
}
const spawn = async (name) => spawnHook(make$({ list: listed }), { subagentType: "general-purpose", name, background: true, fork: false, parentModel: "x" }, async () => ({ model: "sonnet" }))

// 6 (registrations) — checked first, before any $ traffic.
check("6a exactly two registrations", registrations.length === 2)
check("6b agent.spawn is unmatched", registrations.some((r) => r.event === "agent.spawn" && r.matcher === undefined))
check("6c tool.call matcher is SendMessage", registrations.some((r) => r.event === "tool.call" && r.matcher?.tool === "SendMessage" && Object.keys(r.matcher).length === 1))

// 1 listed id ⇒ deny
{ const r = await send(ID); check("1 listed id denied", !r.nextCalled && typeof r.deny === "string" && r.deny.includes(ID)) }

// 2 recorded name ⇒ deny
await spawn("worker")
{ const r = await send("worker"); check("2 spawned name denied", !r.nextCalled && !!r.deny) }

// 3 peer session ⇒ allow
{ const r = await send("local_4fec39bd-7e43-4642-acd0-2e0aacff08c1"); check("3 peer session allowed", r.nextCalled && r.deny === undefined) }

// 4 list throws ⇒ allow + one log line
{ const before = logLines; const r = await send(ID, { list: async () => { throw new Error("surface moved") } })
  check("4 list throw fails open", r.nextCalled && r.deny === undefined && logLines === before + 1) }

// 5 empty to ⇒ allow
{ const r = await send("   "); check("5 empty to allowed", r.nextCalled && r.deny === undefined) }

// 7 address forms
await spawn("code reviewer")
check("7 normalize folds whitespace to dash", normalize("Code  Reviewer") === "code-reviewer")
check("7 stripRef drops a trailing ref", stripRef("worker [3fa9c1]") === "worker" && stripRef(ID) === ID)
for (const [to, want] of [
  ["worker [3fa9c1]", "deny"], ["work", "deny"], ["work [3fa9c1]", "deny"],
  ["Worker", "deny"], ["Code  Reviewer", "deny"], ["code reviewer", "deny"],
  ["codereviewer", "allow"], ["main", "allow"], ["alice@team", "allow"], ["other [3fa9c1]", "allow"],
]) {
  const r = await send(to)
  const got = r.deny !== undefined ? "deny" : (r.nextCalled ? "allow" : "neither")
  check(`7 "${to}" ⇒ ${want}`, got === want)
}

// 6 ($ surface) — after all traffic.
check("6d $ surface is exactly agent.list + ui.log", seen.size === 2 && seen.has("agent.list") && seen.has("ui.log"))

if (failures) { console.log(`${failures} failure(s)`); process.exit(1) }
console.log("hooks-module tests ok")
```

- [ ] **Step 6:** Create `dodi-dev/scripts/tests/test-hooks-module.sh` and make it executable:

```bash
#!/usr/bin/env bash
# Offline test for the no-re-entry function-hook module (dodi-dev/hooks/hooks.js).
# Needs node >= 22.7 (ESM syntax detection on a bare .js).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MODULE="$HERE/../../hooks/hooks.js"
DRIVER="$HERE/hooks-module-driver.mjs"

command -v node >/dev/null || { echo "test-hooks-module: node not found — concrete blocker" >&2; exit 2; }
test -f "$MODULE"
node --check "$MODULE"
node "$DRIVER"
```

Run: `chmod +x dodi-dev/scripts/tests/test-hooks-module.sh`

- [ ] **Step 7:** Verify.

Run: `bash dodi-dev/scripts/tests/test-hooks-module.sh`
Expected: a list of `ok …` lines ending in `hooks-module tests ok`, exit 0. Every case line begins `ok`; no `FAIL`.

- [ ] **Step 8:** Commit.

```bash
git add dodi-dev/hooks/hooks.js dodi-dev/hooks/function-hooks.json dodi-dev/.claude-plugin/plugin.json dodi-dev/scripts/tests/hooks-module-driver.mjs dodi-dev/scripts/tests/test-hooks-module.sh
git commit -m "hooks: no-re-entry function-hook guard with offline test (DOD-1336)"
```

---

### Task 6: Validator coverage

**Files:**
- Modify: `scripts/validate-phase-skills.sh` (after the `# Hooks configuration parses.` check, line 236)
- Modify: `dodi-dev/scripts/tests/test-validate-phase-skills.sh` (lines 6–7 comment, line 18 copy list) — its tmp tree must now include `dodi-dev/.claude-plugin`, which the new check reads

- [ ] **Step 0:** In `dodi-dev/scripts/tests/test-validate-phase-skills.sh`, replace the line

```bash
cp -R "$REPO_ROOT/dodi-dev/skills" "$REPO_ROOT/dodi-dev/scripts" "$REPO_ROOT/dodi-dev/hooks" "$tmp/dodi-dev/"
```

with

```bash
cp -R "$REPO_ROOT/dodi-dev/skills" "$REPO_ROOT/dodi-dev/scripts" "$REPO_ROOT/dodi-dev/hooks" "$REPO_ROOT/dodi-dev/.claude-plugin" "$tmp/dodi-dev/"
```

and change the comment line `# Copy-tree-and-mutate: the validator reads only dodi-dev/skills, dodi-dev/scripts,` / `# dodi-dev/hooks, and its own repo-relative paths — no templates/, no git state.` to `# Copy-tree-and-mutate: the validator reads only dodi-dev/skills, dodi-dev/scripts,` / `# dodi-dev/hooks, dodi-dev/.claude-plugin (the function-hook chain), and its own repo-relative paths — no templates/, no git state.`

- [ ] **Step 1:** Insert after `python3 -c 'import json; json.load(open("dodi-dev/hooks/hooks.json"))'`:

```bash
# Function-hook module chain: manifest hooks path -> function-hooks.json -> module file.
python3 - <<'PY'
import json, os
manifest = json.load(open("dodi-dev/.claude-plugin/plugin.json"))
hooks_path = manifest.get("hooks")
assert hooks_path == "hooks/function-hooks.json", f"plugin.json hooks must point at hooks/function-hooks.json, got {hooks_path!r}"
fh = json.load(open(os.path.join("dodi-dev", hooks_path)))
modules = fh.get("modules")
assert isinstance(modules, list) and len(modules) == 1, f"function-hooks.json must name exactly one module, got {modules!r}"
mod = os.path.join("dodi-dev", os.path.dirname(hooks_path), modules[0])
assert os.path.isfile(mod) and not os.path.islink(mod), f"module not a regular file: {mod}"
print(f"function-hook chain ok: {mod}")
PY
if command -v node >/dev/null; then
  node --check dodi-dev/hooks/hooks.js
else
  echo "notice: node not found; skipping syntax check of dodi-dev/hooks/hooks.js" >&2
fi
```

- [ ] **Step 2:** Also add `hooks-module-driver.mjs`'s companion to the per-test list if one exists — it does not; the repo runs tests individually. Instead add the new test to the regression command in this plan's Testing Contract only (no repo change).

- [ ] **Step 3:** Verify, including the negative path and the validator's own self-test.

Run:
```bash
bash scripts/validate-phase-skills.sh | grep -F "function-hook chain ok"
cp dodi-dev/hooks/function-hooks.json /tmp/fh.bak && printf '{ "modules": ["missing.js"] }\n' > dodi-dev/hooks/function-hooks.json
bash scripts/validate-phase-skills.sh >/dev/null 2>&1 && echo "UNEXPECTED PASS" || echo "negative path rejected"
mv /tmp/fh.bak dodi-dev/hooks/function-hooks.json && git status --short dodi-dev/hooks/
bash dodi-dev/scripts/tests/test-validate-phase-skills.sh
```
Expected: `function-hook chain ok: dodi-dev/hooks/hooks.js`; `negative path rejected`; an empty `git status` line (file restored); `validate-phase-skills tests ok`.

- [ ] **Step 4:** Commit.

```bash
git add scripts/validate-phase-skills.sh dodi-dev/scripts/tests/test-validate-phase-skills.sh
git commit -m "validate-phase-skills: check the function-hook module chain (DOD-1336)"
```

---

### Task 7: Version bump to 0.20.0

**Files:**
- Modify: `.claude-plugin/marketplace.json:12`, `dodi-dev/.claude-plugin/plugin.json:4`, `dodi-dev/.codex-plugin/plugin.json:3`, `dodi-dev/.grok-plugin/plugin.json:4`, `.grok-plugin/marketplace.json:12`

- [ ] **Step 1:** Confirm the pre-existing failure the bump clears.

Run: `bash scripts/validate-plugin-metadata.sh 2>&1 | tail -1`
Expected: `AssertionError: ('0.19.1', '0.19.0')`.

- [ ] **Step 2:** Set every `"version"` value in the five files to `"0.20.0"`.

Run:
```bash
for f in .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json dodi-dev/.grok-plugin/plugin.json .grok-plugin/marketplace.json; do perl -pi -e 's/"version": "0\.19\.[01]"/"version": "0.20.0"/' "$f"; done
grep -n '"version"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json dodi-dev/.grok-plugin/plugin.json .grok-plugin/marketplace.json
```
Expected: five lines, each `"version": "0.20.0"`.

- [ ] **Step 3:** Verify all three validators.

Run: `bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh >/dev/null && bash scripts/validate-ticket-comment-templates.sh >/dev/null && echo all-validators-ok`
Expected: `plugin metadata ok: 0.20.0` then `all-validators-ok`.

- [ ] **Step 4:** Commit with the bare version in the message.

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json dodi-dev/.grok-plugin/plugin.json .grok-plugin/marketplace.json
git commit -m "0.20.0: no-re-entry rule — one-shot leaves, fresh-leaf fix rounds, function-hook SendMessage guard (DOD-1336)

Also clears the 0.19.1/0.19.0 skew: d8bd09e bumped only the two Claude files
and was never tagged, so validate-plugin-metadata.sh failed on main."
```

---

### Task 8: Live verification (E2E) and the two ⚠ assumptions

**Files:** none in the repo. Findings are recorded in the PR body (Task 9).

- [ ] **Step 1:** Enable the loader on this machine. Add to `~/.claude/settings.json` (merge into an existing `env` block if present):

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_FUNCTION_HOOKS": "1"
  }
}
```

- [ ] **Step 2:** Validate the plugin from the branch checkout.

Run: `claude plugin validate dodi-dev 2>&1 | tail -20`
Expected: no errors; the hooks-module scan lists hooks `agent.spawn`, `tool.call` and calls `agent.list`, `ui.log`. If the output shows a different call set, the source scan disagrees with the module — fix the module, never the expectation.

- [ ] **Step 3:** Load the branch build and start a fresh session. Follow the repo's release process memory: point the marketplace at this checkout (or `claude plugin update` once the PR is merged for the post-merge re-check), then start a new `claude` session in any project with the plugin enabled.

Run (in that session's terminal, before starting): `claude --debug 2>&1 | grep -F "hooks modules not loaded"` for the first few seconds of startup, or check the debug log after startup.
Expected: no match. A match means the flag did not reach the session — fix settings before continuing.

- [ ] **Step 4:** In the fresh session, run the live cases and record each result verbatim (the deny text or the delivery confirmation):
  1. Dispatch `Agent` with `model: sonnet`, `description: "probe"`, prompt "Reply with the single word done." Wait for completion. Note its agent id.
  2. `SendMessage` to that id. Expected: refused; the error text begins `dodi-dev no-re-entry rule:`.
  3. Dispatch `Agent` with `model: sonnet`, `name: "probe-named"`, same prompt. After completion, `SendMessage` to `probe-nam` (a prefix). Expected: refused with the rule text.
  4. Open a second `claude` session on this machine; from the first, `ListAgents`, then `SendMessage` to that session's name. Expected: delivered (the other session shows the message).
  5. Teammate (⚠ assumption): start a coordinator-mode team with one teammate, `SendMessage` the teammate by name. Expected: delivered. If it is refused, the assumption is false — stop, record the deny text, and demote to the spec lane (the hook would need a teammate exclusion).
  6. Fork (⚠ assumption): dispatch `Agent` with `subagent_type: "fork"`, let it finish, then `ListAgents` and `SendMessage` it by the name the listing shows. Expected: refused (by id if the name was not recorded, by name if it was). Record which path denied it; either satisfies the rule.

- [ ] **Step 5:** Remove nothing — the module ships as written (no probes were added). Confirm: `git status --short` is empty.

---

### Task 9: PR, merge gate, tag

**Files:** none.

- [ ] **Step 1:** Regression pass on the branch.

Run: `for t in dodi-dev/scripts/tests/test-*.sh; do bash "$t" >/dev/null || { echo "FAIL $t"; exit 1; }; done && bash scripts/validate-plugin-metadata.sh && bash scripts/validate-phase-skills.sh >/dev/null && bash scripts/validate-ticket-comment-templates.sh >/dev/null && git diff --stat main -- dodi-dev/hooks/hooks.json dodi-dev/scripts/hook-require-model-pin.sh dodi-dev/scripts/hook-gate2-guard.sh && echo regression-ok`
Expected: `plugin metadata ok: 0.20.0`, an empty diff stat, `regression-ok`.

- [ ] **Step 2:** Push and open the PR against `main` (title `0.20.0: no-re-entry rule for dispatched workers (DOD-1336)`). Body: link the spec and DOD-1336, list the Task 8 live results verbatim including the teammate and fork outcomes, and note the flag requirement for hive machines and the untagged-0.19.1 skew this clears. End the body with the generated-with line the repo uses.

Run: `git push -u origin HEAD && gh pr create -R dodi-hq/dodi-skills --base main --title "0.20.0: no-re-entry rule for dispatched workers (DOD-1336)" --body-file <path to body>`
Expected: a PR URL.

- [ ] **Step 3:** Human merge gate. Merge is May's call; do not merge.

- [ ] **Step 4:** After merge, tag the version-bump commit on `main` and push the tag.

Run: `git checkout main && git pull --ff-only origin main && git tag v0.20.0 && git push origin v0.20.0 && git tag | tail -2`
Expected: `v0.19.0`, `v0.20.0`.

- [ ] **Step 5:** Post-merge: `claude plugin update dodi-dev` on this machine, fresh session, repeat Task 8 Step 4 cases 1–2 once. Record in DOD-1336 and move it to Done.
