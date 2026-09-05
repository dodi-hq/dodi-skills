// Offline driver for dodi-dev/hooks/hooks.js: stub `on` and `$`, run the
// seven cases from the no-re-entry spec's § 4 test list, plus the review
// round-1 cases (1b case-folded ids, 7b the resolver-faithful prefix rule)
// (DOD-1336).
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
{ const before = logLines; const r = await send(ID, { list: async () => ({ agents: [{ id: ID }] }) })
  check("4b list non-array fails open", r.nextCalled && r.deny === undefined && logLines === before + 1) }

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

// 1b a case-folded id resolves to the same subagent ⇒ deny
for (const to of ["a0123456789ABCDEF", "A0123456789ABCDEF"]) {
  const r = await send(to)
  check(`1b case-folded id "${to}" denied`, !r.nextCalled && typeof r.deny === "string")
}

// 7b prefix rule mirrors the resolver: "main" routes to the lead, and a prefix
// needs >= 3 characters and exactly one registered name starting with it.
await spawn("main-helper")
for (const [to, want] of [["main", "allow"], ["ma", "allow"], ["main-helper", "deny"]]) {
  const r = await send(to)
  const got = r.deny !== undefined ? "deny" : (r.nextCalled ? "allow" : "neither")
  check(`7b "${to}" ⇒ ${want}`, got === want)
}
await spawn("workbench")
for (const [to, want] of [["work", "allow"], ["worke", "deny"], ["worker", "deny"]]) {
  const r = await send(to)
  const got = r.deny !== undefined ? "deny" : (r.nextCalled ? "allow" : "neither")
  check(`7b "${to}" ⇒ ${want}`, got === want)
}

// 6 ($ surface) — after all traffic.
check("6d $ surface is exactly agent.list + ui.log", seen.size === 2 && seen.has("agent.list") && seen.has("ui.log"))

if (failures) { console.log(`${failures} failure(s)`); process.exit(1) }
console.log("hooks-module tests ok")
