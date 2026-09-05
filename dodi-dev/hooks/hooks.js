// dodi-dev no-re-entry guard — a Claude Code function-hook module.
//
// A dispatched worker is a one-shot leaf (AGENTS.md § Dispatch Discipline;
// epic-orchestrator/execution-model.md § 1). This module refuses a SendMessage
// whose target is a subagent this session spawned, so a dispatcher cannot
// re-enter a parked worker.
//
// How a target is recognised (mirrors the 2.1.261 resolver, read from the binary):
//   - An id-shaped address (`a` + optional scope + 16 hex, tested raw and after
//     the resolver's own fold) is routed ONLY to a subagent — live, or resumed
//     from its transcript on disk after the ~30 s registry eviction that follows
//     completion. It is never a teammate, a peer session, or "main". So every
//     id-shaped address is denied, without consulting the live registry: the
//     registry forgets a finished worker exactly when the dispatcher would be
//     tempted to re-enter it.
//   - A named spawn (Agent({ name })) is recorded at agent.spawn and denied by
//     exact normalised name or by a unique prefix of at least 3 characters.
//   - "main" is routed to the lead before any name matching; it passes through.
//
// The module makes no calls on `$`: nothing to fail open from, nothing that can
// throw out of the hook. Loaded only when CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1
// (or the harness rollout flag) — see AGENTS.md § Deterministic Skeleton.

const REF_SUFFIX = /^(.*\S)\s*\[[^\]]+\]$/
// The resolver's agent-id shape: `a`, optional `<scope>-`, then 16 hex digits.
const AGENT_ID = /^a(?:[\w-]{1,63}-)?[0-9a-f]{16}$/

// Mirrors the runtime resolver's folding of registry names (and of ids on its
// second resolution attempt).
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

// True when the resolver would treat `s` as an agent id (raw or folded).
export function isAgentId(s) {
  return AGENT_ID.test(s) || AGENT_ID.test(normalize(s))
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
  on("tool.call", { tool: "SendMessage" }, ($, e, next) => {
    const raw = String(e.to ?? "").trim()
    if (!raw) return next(e)
    const name = stripRef(raw)
    const n = normalize(name)
    // Any fold of "main" (bare or with a [ref]) reaches the lead or a peer
    // session: the resolver's exact-fold pass over its candidate index — which
    // always carries "main" — runs before prefix matching, and registerName
    // refuses every name that folds to "main", so no subagent can be reached
    // by any spelling of it.
    if (n === "main") return next(e)
    // Prefix matching mirrors the resolver: at least 3 characters, and exactly
    // one registered name starting with it.
    const prefixHits = n.length >= 3 ? [...spawnedNames].filter((s) => s.startsWith(n)).length : 0
    const isOwn =
      isAgentId(raw) ||
      isAgentId(name) ||
      (n.length > 0 && (spawnedNames.has(n) || prefixHits === 1))
    if (!isOwn) return next(e)
    return { deny: `dodi-dev no-re-entry rule: "${raw}"${DENY_TAIL}` }
  })
}
