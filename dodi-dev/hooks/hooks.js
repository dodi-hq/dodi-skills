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
