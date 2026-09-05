// Offline driver for dodi-dev/hooks/hooks.js: stub `on` and `$`, run the
// cases from the no-re-entry spec's § 4 test list (DOD-1336).
// The module must make no calls on `$` at all: the stub records every property
// access so that any call becomes a red test.
import { register, normalize, stripRef, isAgentId } from "../../hooks/hooks.js"

const registrations = []
const on = (event, matcherOrHook, maybeHook) => {
  if (maybeHook === undefined) registrations.push({ event, matcher: undefined, hook: matcherOrHook })
  else registrations.push({ event, matcher: matcherOrHook, hook: maybeHook })
}
register(on)

const seen = new Set() // every `$.<noun>` the module touched — must stay empty
const $ = new Proxy({}, { get(_, prop) { seen.add(String(prop)); return undefined } })

const spawnHook = registrations.find((r) => r.event === "agent.spawn")?.hook
const callHook = registrations.find((r) => r.event === "tool.call")?.hook

let failures = 0
const check = (label, cond) => {
  if (cond) console.log(`ok   ${label}`)
  else { failures += 1; console.log(`FAIL ${label}`) }
}

const ID = "a0123456789abcdef"            // a + 16 hex, the runtime's id shape
const SCOPED_ID = "ateam-0123456789abcdef" // a + scope + 16 hex
const send = async (to) => {
  let nextCalled = false
  const e = { tool: "SendMessage", tool_use_id: "toolu_x", to, message: "hi" }
  const res = await callHook($, e, async (ev) => { nextCalled = true; return { result: "sent" } })
  return { nextCalled, deny: res?.deny }
}
const spawn = async (name) => spawnHook($, { subagentType: "general-purpose", name, background: true, fork: false, parentModel: "x" }, async () => ({ model: "sonnet" }))
const expect = async (to, want, label = "") => {
  const r = await send(to)
  const got = r.deny !== undefined ? "deny" : (r.nextCalled ? "allow" : "neither")
  check(`${label}"${to}" ⇒ ${want}`, got === want)
}

// 6 (registrations) — checked first.
check("6a exactly two registrations", registrations.length === 2)
check("6b agent.spawn is unmatched", registrations.some((r) => r.event === "agent.spawn" && r.matcher === undefined))
check("6c tool.call matcher is SendMessage", registrations.some((r) => r.event === "tool.call" && r.matcher?.tool === "SendMessage" && Object.keys(r.matcher).length === 1))

// 1 id-shaped address ⇒ deny, with no registry lookup (the registry evicts a
// finished worker ~30 s after completion; the id still resumes it from disk).
{ const r = await send(ID); check("1 agent id denied", !r.nextCalled && typeof r.deny === "string" && r.deny.includes(ID)) }
await expect(SCOPED_ID, "deny", "1 scoped ")
await expect("a0123456789ABCDEF", "deny", "1b case-folded ")
await expect("A0123456789ABCDEF", "deny", "1b case-folded ")
await expect("a0123456789abcde", "allow", "1c 15-hex not an id ")
await expect("b0123456789abcdef", "allow", "1c wrong leading letter ")
check("1d isAgentId helper", isAgentId(ID) && isAgentId(SCOPED_ID) && !isAgentId("worker"))

// 2 recorded name ⇒ deny
await spawn("worker")
await expect("worker", "deny", "2 spawned name ")

// 3 peer session ⇒ allow
await expect("local_4fec39bd-7e43-4642-acd0-2e0aacff08c1", "allow", "3 peer session ")

// 5 empty to ⇒ allow
await expect("   ", "allow", "5 empty to ")

// 7 address forms
await spawn("code reviewer")
check("7 normalize folds whitespace to dash", normalize("Code  Reviewer") === "code-reviewer")
check("7 stripRef drops a trailing ref", stripRef("worker [3fa9c1]") === "worker" && stripRef(ID) === ID)
for (const [to, want] of [
  ["worker [3fa9c1]", "deny"], ["work", "deny"], ["work [3fa9c1]", "deny"],
  ["Worker", "deny"], ["Code  Reviewer", "deny"], ["code reviewer", "deny"],
  ["codereviewer", "allow"], ["main", "allow"], ["alice@team", "allow"], ["other [3fa9c1]", "allow"],
]) await expect(to, want, "7 ")

// 7b prefix rule mirrors the resolver: main short-circuits; >= 3 chars; unique hit.
await spawn("main-helper")
await expect("main", "allow", "7b ")
await expect("ma", "allow", "7b ")
await expect("main-helper", "deny", "7b ")
await spawn("workbench")
await expect("work", "allow", "7b ambiguous prefix ")
await expect("worke", "deny", "7b unique prefix ")
await expect("worker", "deny", "7b exact ")

// 6d ($ surface) — after all traffic: the module never touched `$`.
check("6d $ surface is empty (no runtime calls)", seen.size === 0)

if (failures) { console.log(`${failures} failure(s)`); process.exit(1) }
console.log("hooks-module tests ok")
