# DOD-814 Codex Setup, Preflight, Auth, Scheduling, Gate 2, and Escalation Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute Tasks 1-13 in order. DOD-814 is C4 only: consume landed C1/C2/C3 contracts, and do not add C5 release/install documentation, isolated-release validators, release evidence, metadata `0.17.0` changes, or final release signoff while resolving a failure.

## TL;DR

DOD-814 implements the setup and safety layer that turns the C1-C3 Codex runtime contracts into an operator-confirmed, fail-closed installation flow. The work is deliberately invariant-heavy: profile/health writes, Linear register mutation, scheduler enablement, Gate 2 denial, Slack escalation, and marketplace migration all require durable evidence before lights-out operation can start.

## Key Points

- Preserve C1-C3 ownership exactly: DOD-814 writes and verifies setup state, but it does not redefine profile paths, model tiers, worker lifecycle states, or quarantine proof.
- `setup-dodi-dev inspect` remains fully read-only; runtime id selection, register creation, marketplace migration, Slack tests, task mutation, and lights-out enablement are separate confirmation-bound mutation classes.
- The stable lock never wraps external waiting. Task disablement, scheduler terminal waits, and C3 `reap-recover` happen before lock acquisition; the locked section only rechecks evidence and commits profile/health/register state.
- Direct Linear GraphQL, Slack delivery, and marketplace mutation all use explicit intent/observation/adoption taxonomies so lost responses remain uncertain or adopted exactly once, never duplicated by guess.
- `runtime-preflight.sh verify-profile` must emit C2's exact proof shape with no C4-only fields; boundary evidence is stored outside that stdout.
- GitHub server-side denial remains authoritative for Gate 2, while hook live-fire stays defense-in-depth and scoped to protected-base/rules mutations.
- Harness-native driver/janitor tasks are scope-qualified, no-overlap/successor-wake proven, and left disabled on any ambiguous acceptance, cleanup, or rollback result.
- C5 release/install docs, final isolated validation, release evidence bundle, metadata `0.17.0`, and release signoff remain out of scope.

**Goal:** Implement one explicit, fail-closed Codex setup path that transactionally binds runtime profile/health/register state, verifies auth, hooks, GitHub Gate 2, scheduled tasks, and Slack escalation, and enables lights-out work only after C1-C3-compatible quiescence and live proof.

**Architecture:** Keep `setup-dodi-dev` as a thin operator conversation surface over deterministic Bash/Python helpers. One stable-lock state engine owns proposal hashing, runtime-id selection, profile/health transactions, recovery, rollback, health replay, and health classification; direct Linear, scheduler, and Slack adapters own their external action/observation boundaries and persist only redacted evidence. Extend C1's `runtime-preflight.sh` in place so C2 receives the exact same-invocation proof it already consumes, and use C3 `reap-recover` over every repository worktree and profile-bound task scope before any mutating or enabling transition. Client hooks remain defense-in-depth while dedicated-actor server-side denial is the authoritative Gate 2 control.

**Tech Stack:** Bash 3.2-compatible command surfaces, Python 3 standard library for strict JSON, RFC 8785-compatible canonicalization, hashing, path/permission checks, locking, and action normalization, JSON Schema draft 2020-12 with the landed test-only `jsonschema` harness, direct Linear GraphQL through `linear-api.sh`, `gh api`, supported Codex Desktop/plugin hooks and harness-native task/Slack actions, Git worktree plumbing, and existing repository validators.

**Source of truth:** `docs/specs/2026-07-09-codex-setup-preflight-auth-scheduling-escalation-design.md` at epic push `f21b3af`, constrained by `docs/specs/2026-07-09-codex-runtime-compatibility-design.md` at `baf219a` and the DOD-810 Decision Register canon. Landed DOD-811, DOD-812, and DOD-813 implementations are executable dependencies; their approved specs/plans at epic pushes `978cad7`, `5d084b5`, and `a3124f4` explain ownership but are not permission to recreate missing contracts.

**Scope boundaries:**

- C4 consumes C1's selected profile/health/lock derivation, closed schemas, register hashes, manifest states, bootstrap result, runtime policy, and adapter boundaries. It adds the sole production writers and verifier, but no alternate path, schema, hash rule, state, or authority.
- C4 consumes C2's installed map order, exact model/reasoning candidates, `validate-map`, `resolve-tier`, `verify-main-loop`, `verify-attestation`, Frontier-capacity classifier, proof allowlist, model-pin hook hash/result, and Standard scheduled-task pair. It does not choose or reorder candidates, inspect free-form capacity failures, extend C2 proof stdout, or redefine tier/attestation policy.
- C4 consumes C3 `reap-recover`, selected takeover mode, `QUIESCENT`, quarantine, manifest, and no-write/slot evidence over the complete repository-worktree/profile-bound task scope. It does not query, close, reap, release quarantine, or fabricate lifecycle evidence independently.
- C4 may normalize current-runtime GitHub, hook, scheduler, Slack, and marketplace action observations only after their redacted schemas are captured. Unknown runtime versions, fields, actions, acceptance states, pagination, or authority semantics are blockers, not compatibility fallbacks.
- C4 preserves v0.16 top-level-only dispatch, leaf workers, one mutable lane, one driver writer, review/Fable/claim/coherence semantics, manual epic Gate 2, and current Claude behavior.
- C4 does not add `validate-codex-compatibility.sh`, `validate-codex-install.sh`, release/install guides, final compatibility bundles, release signoff, or any `0.17.0` metadata edit. C5 owns those surfaces.
- Implementation may start only after C1/C2/C3 implementation commits are ancestors of the C4 branch. A missing or incompatible executable dependency returns DOD-814 to the spec/epic decision lane; the implementer must not copy behavior from plans.

**File surface:**

- Create: `dodi-dev/skills/setup-dodi-dev/SKILL.md`
- Create: `dodi-dev/scripts/runtime-auth.sh`
- Create: `dodi-dev/scripts/runtime-register.sh`
- Create: `dodi-dev/scripts/runtime-state.sh`
- Create: `dodi-dev/scripts/codex-scheduler-adapter.sh`
- Create: `dodi-dev/scripts/slack-escalation-adapter.sh`
- Create: `dodi-dev/scripts/tests/test-runtime-auth.sh`
- Create: `dodi-dev/scripts/tests/test-runtime-register.sh`
- Create: `dodi-dev/scripts/tests/test-runtime-state.sh`
- Create: `dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh`
- Create: `dodi-dev/scripts/tests/test-slack-escalation-adapter.sh`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/pre-c4-baseline.txt`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/c4-contract-freeze.md`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/auth/cases.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/auth/secret-canaries.txt`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/register/discovery-observations.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/register/chains/valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/register/chains/invalid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/state/cases.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/c3/reap-recover-observations.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/github/observations.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/hooks/gate2-observations.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/scheduler/observations.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/slack/observations.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/marketplace/observations.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/runtime-version.txt`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/native-action-schemas.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/linear-evidence.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/github-gate2-evidence.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/hook-evidence.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/scheduler-evidence.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/slack-evidence.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/marketplace-evidence.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/state-recovery-evidence.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/evidence-hashes.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/live/live-gate-evidence.md`
- Modify: `dodi-dev/scripts/runtime-preflight.sh`
- Modify: `dodi-dev/scripts/hook-gate2-guard.sh`
- Modify only if live-fire requires the Gate 2 matcher change: `dodi-dev/hooks/hooks.json`
- Modify: `dodi-dev/runtime/adapter-contracts.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Modify: `dodi-dev/skills/drive-epic/SKILL.md`
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md`
- Modify: `dodi-dev/skills/epic-orchestrator/execution-model.md`
- Modify: `scripts/validate-runtime-contracts.sh`
- Modify: `scripts/validate-phase-skills.sh`
- Explicitly unchanged: C1 JSON schemas and path/hash/state definitions; C2 model-map/schema, tier/capacity adapters, model-pin semantics, and attestation policy; C3 lifecycle adapter, manifest/quarantine vocabulary, result/digest artifacts, takeover behavior, `reap-workers.sh`, and `await-worker.sh`; lane playbooks/review prompts/labels; all five metadata envelopes; C5 validator/docs/evidence surfaces.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `runtime-auth precedence and parser; Linear register discovery/hash-chain/idempotency; stable-lock profile/health transaction engine; verify-profile binding/replay; health classifier; GitHub/hook/scheduler/Slack/marketplace observation normalizers`
  - Reason: `C4 owns several crash-safe, append-only, externally observed state machines. Every ambiguous input, lock/flush/rename seam, duplicate response, strict-prefix race, lease transition, and fail-closed matrix row needs deterministic coverage.`
  - Minimum assertions: `all approved success statuses and exits are exact; malformed/unknown schema/runtime/action/field/status fails closed; inspect writes nothing; secret canaries never reach stdout/stderr/artifacts; runtime-id selection precedes register discovery and survives restart; register issue/comment lost-response recovery never duplicates; profile/health pair mismatch remains non-runnable; rollback rebuilds from the current register; C2 proof contains no extra fields; all local worktrees and profile-bound task scopes are included in C3 quiescence; GitHub/hook/scheduler/Slack/marketplace ambiguous evidence blocks enablement; every health truth-table row classifies exactly.`

- Integration: `required`
  - Scope: `C1 profile/health/register/bootstrap contracts; C2 same-invocation verifier consumer and Standard pair; C3 reap-recover/quarantine evidence; direct Linear helper; installed setup/driver/janitor policy; Gate 2 hook; runtime validators`
  - Reason: `A locally correct helper is insufficient if it emits a proof C2 rejects, writes outside C1's lock/generation boundary, ignores a C3 worktree/task source, or lets installed workflow prose bypass the adapter.`
  - Harness: `setup-required`
  - Minimum assertions: `landed dependency commits and executable contracts are present; C2's production commands accept the C4 proof only in the same invocation; C3 returns QUIESCENT only for complete scope; setup inspect/proposal is read-only and confirmation-hash-bound; setup/repair/rollback keep tasks disabled until exact fingerprints pass; installed skills link rather than restate mechanics; Claude fixtures/regressions stay green; metadata remains 0.16.0 and C5 files stay absent.`

- E2E: `required`
  - Scope: `disposable Linear register, dedicated scheduled GitHub actor and equivalent protected branch, supported Codex hook trust/live-fire, disposable harness-native driver/janitor tasks, Slack test obligation, profile/health crash recovery, and rollback with a post-snapshot obligation`
  - Reason: `GitHub authority, hook discovery/trust, scheduler no-overlap/wake, Slack durable ids, and current-runtime action schemas cannot be established by fixtures or prose.`
  - Harness: `setup-required`
  - Minimum assertions: `confirmed disposable register creation/search/append/replay passes; scheduled actor is denied every protected-base/rules mutation and allowed only read/child flows; both exact hooks are discovered/trusted and their deny/allow matrices live-fire; exactly one disposable driver and janitor shape prove boot, Standard attestation, no overlap, successor wake, failure notification, and cleanup; Slack delivery is register-before-send/delivered-after-send; one mid-pair-rename recovery and one rollback preserve current obligations; no production task is enabled without a separate operator confirmation.`

### Critical Flows

- `Installed skill locator -> C1 bootstrap ROOT_READY -> read-only inspect -> redacted proposal hash -> separately confirmed runtime-id selection -> rediscovery under that stable id -> register adoption/creation confirmation -> disabled transactional profile/health generation -> verify-profile -> separately confirmed task and lights-out enablement.`
- `Every configured repository remote -> canonical root -> git worktree list --porcelain -> every .dodi manifest and worker-quarantine.jsonl + every profile-bound managed task/run/claim -> C3 reap-recover actions executed by the top-level session -> QUIESCENT before mutation/reuse/enablement.`
- `C2 operation/nonce/repo -> runtime-preflight.sh verify-profile -> at most one strict-prefix replay retry -> one stable locked generation/register/catalog read -> exact PROFILE_VERIFIED object -> caller re-read race check; no reusable receipt.`
- `Escalation event -> append/adopt ESCALATION_OBLIGATION -> project pending + acquire event lease -> SEND_SLACK -> validate durable message id/link/channel/time -> append/adopt ESCALATION_DELIVERED -> project only that event delivered.`
- `Task update or rollback -> disable every affected fingerprint -> await terminal task state -> C3 quiescence -> snapshot -> mutate/restore static state -> replay current register -> verify exact fingerprints -> explicit re-enable or remain disabled.`
- `Dedicated scheduled actor -> complete readable classic/ruleset/admin/bypass normalization -> server-side denied mutation matrix + allowed child/read matrix -> Gate 2 hook live-fire -> no automated epic-base merge path even if the hook is bypassed.`

### Regression Surface

- `C1 canonical profile/health/lock paths, closed schemas, exact profile-byte/projection/register hashes, manifest states, bootstrap exits, and direct Linear authority.`
- `C2 model pairs/order, same-invocation proof allowlist, capacity semantics, model-pin output, attestation, and Standard scheduled-task requirement.`
- `C3 spawn/await/result/close/reap, digest ready/claim/ack, quarantine release, takeover mode, and Claude worker classification.`
- `v0.16 top-level leaf dispatch, serial mutable lanes, driver claim/retry/context seams, Fable policy, review gates, coherence rulings, and human Gate 2.`
- `Existing Claude hooks and manual workflows, existing shell tests/validators, plugin metadata synchronized at 0.16.0, and absence of C5 files.`

### Commands

- Unit: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; dodi-dev/scripts/tests/test-runtime-auth.sh && dodi-dev/scripts/tests/test-runtime-register.sh && dodi-dev/scripts/tests/test-runtime-state.sh && dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh && dodi-dev/scripts/tests/test-slack-escalation-adapter.sh`
- Integration: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; scripts/validate-runtime-contracts.sh && scripts/validate-phase-skills.sh && scripts/validate-plugin-metadata.sh && scripts/validate-ticket-comment-templates.sh`
- E2E: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; scripts/validate-runtime-contracts.sh --require-codex-setup-live`
- Broader regression: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done` plus the Task 13 ownership/redaction battery.

### Harness Requirements

- `bash 3.2+, python3, git, gh, jq, curl, rg, mktemp, stat, shasum or sha256sum, the landed requirements-dev.txt venv, and a filesystem that supports advisory locking, chmod, fsync, and atomic same-directory rename.`
- `Create/reuse the C1 test environment: python3 -m venv /tmp/dodi-runtime-contracts-venv && /tmp/dodi-runtime-contracts-venv/bin/python -m pip install --requirement requirements-dev.txt.`
- `Deterministic tests use isolated temporary HOME/XDG_CONFIG_HOME/repos/worktrees, stubbed direct-API/action observations, synthetic credentials/canaries, and no production profile, task, register, repository, or Slack channel.`
- `Live gates require the parent-supported Codex Desktop/plugin runtime, an explicitly trusted development installation, operator and dedicated restricted scheduled GitHub identities, a disposable repository or equivalent protected branch, a disposable Linear team/project issue location, the installed Slack plugin and dedicated low-risk channel, and explicit confirmation before each external mutation class.`
- `Current-runtime scheduler/hook/Slack/GitHub/C3 schemas must be captured and redacted before normalization. Missing or ambiguous authority/action evidence is a concrete blocker, not a skipped E2E test.`

### Non-Required Rationale

- Unit: `not applicable (required).`
- Integration: `not applicable (required).`
- E2E: `not applicable (required); C5 later repeats the release matrix in an isolated install, but C4 must prove its own implementation against the supported runtime before handoff.`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.
- Fixture success never substitutes for required live proof, and a development live gate never enables production tasks without the final separately confirmed proposal.
- Every external test mutation is preceded by the required proposal-bound confirmation and followed by durable evidence and cleanup; unknown cleanup acceptance blocks final enablement.

---

## Tasks

### Task 1: Reconcile landed C1-C3 contracts and freeze the C4 baseline

**Files:**
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/pre-c4-baseline.txt`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-setup/c4-contract-freeze.md`
- Inspect only: all landed C1/C2/C3 files named in the source specs and sibling plans

- [ ] **Step 1:** Fetch the epic branch, fast-forward/rebase the C4 branch according to the lane's normal git policy, and prove the executable C1/C2/C3 implementation surfaces are present. Do not infer readiness from documentation commits alone; record the exact implementation commits from the landed files rather than using hard-coded future SHAs.

```bash
set -euo pipefail
git fetch origin epic-DOD-810
for path in \
  dodi-dev/scripts/runtime-preflight.sh \
  dodi-dev/runtime/runtime-profile.schema.json \
  dodi-dev/runtime/runtime-health.schema.json \
  dodi-dev/runtime/runtime-register-record.schema.json \
  dodi-dev/runtime/dispatch-manifest-record.schema.json \
  dodi-dev/scripts/codex-tier-adapter.sh \
  dodi-dev/scripts/codex-capacity-classifier.sh \
  dodi-dev/runtime/codex-model-tiers.json \
  dodi-dev/scripts/hook-require-model-pin.sh \
  dodi-dev/scripts/tests/fixtures/codex-tier/verifier/verify-profile-output.valid.json \
  dodi-dev/scripts/codex-worker-adapter.sh \
  dodi-dev/scripts/tests/fixtures/codex-worker/live/takeover-mode.json \
  dodi-dev/scripts/tests/fixtures/codex-worker/live/native-tool-schemas.redacted.json
do
  test -e "$path"
  commit="$(git log -1 --format=%H -- "$path")"
  test -n "$commit"
  git merge-base --is-ancestor "$commit" HEAD
  printf '%s %s\n' "$commit" "$path"
done
```

Expected: every listed dependency path exists, each printed commit is a non-empty 40-character SHA, every ancestry check exits `0`, and the printed table identifies the landed executable dependency surfaces. Any nonzero result blocks implementation before C4 files are created.

- [ ] **Step 2:** Verify the exact dependency surface exists and is executable/parseable.

```bash
set -euo pipefail
test -x dodi-dev/scripts/runtime-preflight.sh
test -x dodi-dev/scripts/codex-tier-adapter.sh
test -x dodi-dev/scripts/codex-capacity-classifier.sh
test -x dodi-dev/scripts/codex-worker-adapter.sh
test -x dodi-dev/scripts/reap-workers.sh
for file in dodi-dev/runtime/runtime-profile.schema.json dodi-dev/runtime/runtime-health.schema.json dodi-dev/runtime/runtime-register-record.schema.json dodi-dev/runtime/dispatch-manifest-record.schema.json dodi-dev/runtime/codex-model-tiers.json; do python3 -m json.tool "$file" >/dev/null; done
scripts/validate-runtime-contracts.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
```

Expected: every file check exits `0`; the runtime validator accepts both landed C2 and C3 live evidence. If the validator uses separate invocations after landing, run its documented equivalent and record the exact commands in the implementation evidence.

- [ ] **Step 3:** Freeze exact paths, schemas, statuses, exit codes, operation names, C2 proof fields, C3 `reap-recover` request/result shape, selected takeover mode, and hook observation fields in `dodi-dev/scripts/tests/fixtures/runtime-setup/c4-contract-freeze.md`, then write the baseline commit file. The freeze note is an implementation input and must be staged with the baseline.

```bash
python3 - <<'PY'
import hashlib
import json
import re
import subprocess
from pathlib import Path

def git_last(path):
    return subprocess.check_output(['git', 'log', '-1', '--format=%H', '--', path], text=True).strip()

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def flatten(obj, prefix=''):
    if isinstance(obj, dict):
        out = []
        for key, value in sorted(obj.items()):
            out.extend(flatten(value, f'{prefix}.{key}' if prefix else key))
        return out
    if isinstance(obj, list):
        if not obj:
            return [prefix + '[]']
        out = []
        for value in obj:
            out.extend(flatten(value, prefix + '[]'))
        return out
    return [prefix]

def read_json_or_jsonl(path):
    text = Path(path).read_text()
    if path.endswith('.jsonl'):
        return [json.loads(line) for line in text.splitlines() if line.strip()]
    return json.loads(text)

def schema_version(data):
    direct = data.get('schema_version') or data.get('version')
    if direct:
        return direct
    field = data.get('properties', {}).get('schema_version', {})
    if 'const' in field:
        return field['const']
    if 'enum' in field:
        return ','.join(map(str, field['enum']))
    return ''

surfaces = {
    'C1': [
        'dodi-dev/scripts/runtime-preflight.sh',
        'dodi-dev/runtime/runtime-profile.schema.json',
        'dodi-dev/runtime/runtime-health.schema.json',
        'dodi-dev/runtime/runtime-register-record.schema.json',
        'dodi-dev/runtime/dispatch-manifest-record.schema.json',
        'dodi-dev/runtime/adapter-contracts.md',
    ],
    'C2': [
        'dodi-dev/scripts/codex-tier-adapter.sh',
        'dodi-dev/scripts/codex-capacity-classifier.sh',
        'dodi-dev/runtime/codex-model-tiers.json',
        'dodi-dev/scripts/hook-require-model-pin.sh',
        'dodi-dev/scripts/tests/fixtures/codex-tier/verifier/verify-profile-output.valid.json',
        'dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-hook-payload.redacted.json',
    ],
    'C3': [
        'dodi-dev/scripts/codex-worker-adapter.sh',
        'dodi-dev/scripts/tests/fixtures/codex-worker/live/takeover-mode.json',
        'dodi-dev/scripts/tests/fixtures/codex-worker/live/native-tool-schemas.redacted.json',
        'dodi-dev/scripts/tests/fixtures/codex-worker/live/cross-session-observations.redacted.jsonl',
        'dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md',
    ],
}
for group, paths in surfaces.items():
    for path in paths:
        if not Path(path).exists():
            raise SystemExit(f'missing {group} surface: {path}')

schema_meta = []
for path in [
    'dodi-dev/runtime/runtime-profile.schema.json',
    'dodi-dev/runtime/runtime-health.schema.json',
    'dodi-dev/runtime/runtime-register-record.schema.json',
    'dodi-dev/runtime/dispatch-manifest-record.schema.json',
]:
    data = json.loads(Path(path).read_text())
    schema_meta.append((path, data.get('$id', ''), schema_version(data)))

c2_proof_path = Path('dodi-dev/scripts/tests/fixtures/codex-tier/verifier/verify-profile-output.valid.json')
c2_proof = json.loads(c2_proof_path.read_text())
c2_fields = flatten(c2_proof)
if not c2_fields:
    raise SystemExit(f'{c2_proof_path} exposes no proof fields')

hook_payload_path = Path('dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-hook-payload.redacted.json')
hook_fields = flatten(json.loads(hook_payload_path.read_text()))

takeover_path = Path('dodi-dev/scripts/tests/fixtures/codex-worker/live/takeover-mode.json')
takeover = json.loads(takeover_path.read_text())
takeover_mode = takeover.get('mode') or takeover.get('selected_mode')
if takeover_mode not in {'addressable', 'parent-termination', 'quarantine-only'}:
    raise SystemExit('takeover-mode.json must name addressable, parent-termination, or quarantine-only')
c3_schema_path = Path('dodi-dev/scripts/tests/fixtures/codex-worker/live/native-tool-schemas.redacted.json')
c3_fields = flatten(json.loads(c3_schema_path.read_text()))

status_values = set()
operation_values = set()
exit_codes = set()
for root in [
    Path('dodi-dev/scripts/tests/fixtures/runtime-contracts'),
    Path('dodi-dev/scripts/tests/fixtures/codex-tier'),
    Path('dodi-dev/scripts/tests/fixtures/codex-worker'),
]:
    for path in list(root.rglob('*.json')) + list(root.rglob('*.jsonl')):
        try:
            data = read_json_or_jsonl(str(path))
        except json.JSONDecodeError:
            continue
        stack = [data]
        while stack:
            item = stack.pop()
            if isinstance(item, dict):
                for key, value in item.items():
                    if key in {'status', 'state', 'outcome'} and isinstance(value, str):
                        status_values.add(value)
                    if key in {'operation', 'command', 'op', 'phase'} and isinstance(value, str):
                        operation_values.add(value)
                    if key in {'exit', 'exit_code'} and isinstance(value, int):
                        exit_codes.add(str(value))
                    elif isinstance(value, (dict, list)):
                        stack.append(value)
            elif isinstance(item, list):
                stack.extend(item)

for path in [
    'dodi-dev/scripts/runtime-preflight.sh',
    'dodi-dev/scripts/codex-tier-adapter.sh',
    'dodi-dev/scripts/codex-capacity-classifier.sh',
    'dodi-dev/scripts/codex-worker-adapter.sh',
]:
    text = Path(path).read_text(errors='ignore')
    exit_codes.update(re.findall(r'(?:^|[ ;])exit[ ]+([0-9]+)', text, flags=re.MULTILINE))
    exit_codes.update(re.findall(r'sys[.]exit[(]([0-9]+)[)]', text))
    for value in re.findall(r'\b(bootstrap|verify-profile|validate-map|resolve-tier|verify-main-loop|verify-attestation|prepare-intent|persist-result|reap-recover|digest|close|spawn|await)\b', text):
        operation_values.add(value)
    for token in re.findall(r'\b[A-Z][A-Z0-9_]{2,}\b', text):
        if token.endswith(('READY', 'VERIFIED', 'UNVERIFIED', 'REQUIRED', 'INVALID', 'UNCERTAIN', 'QUIESCENT')):
            status_values.add(token)
if 'bootstrap' not in operation_values:
    raise SystemExit('runtime-preflight bootstrap operation was not frozen')

lines = ['# DOD-814 C4 Contract Freeze', '', '## Surface Hashes']
for group, paths in surfaces.items():
    lines += ['', f'### {group}']
    for path in paths:
        lines.append(f'- `{path}` | commit `{git_last(path)}` | sha256 `{sha(path)}`')
lines += ['', '## Schema Metadata']
for path, schema_id, version in schema_meta:
    lines.append(f'- `{path}` | id `{schema_id}` | version `{version}`')
lines += ['', '## C2 Proof Fields', '', f'- Source: `{c2_proof_path}`']
lines += [f'- `{field}`' for field in c2_fields]
lines += ['', '## C2 Hook Observation Fields', '', f'- Source: `{hook_payload_path}`']
lines += [f'- `{field}`' for field in hook_fields]
lines += ['', '## C3 Reap-Recover Fields', '', f'- Selected takeover mode: `{takeover_mode}` from `{takeover_path}`', f'- Native schema source: `{c3_schema_path}`']
lines += [f'- `{field}`' for field in c3_fields]
lines += ['', '## Observed Operation Values']
lines += [f'- `{value}`' for value in sorted(operation_values)]
lines += ['', '## Observed Status Values']
lines += [f'- `{value}`' for value in sorted(status_values)]
lines += ['', '## Observed Exit Codes']
lines += [f'- `{value}`' for value in sorted(exit_codes, key=int)]
lines += ['', '## C4 Blocking Rule', '', 'Any mismatch between this freeze and landed executable behavior blocks DOD-814 implementation and returns to the spec/epic decision lane.', '']

out = Path('dodi-dev/scripts/tests/fixtures/runtime-setup/c4-contract-freeze.md')
out.write_text('\n'.join(lines))
text = out.read_text()
print('contract freeze resolved')
PY
printf 'DOD_813_BASE=%s\n' "$(git rev-parse HEAD)" > dodi-dev/scripts/tests/fixtures/runtime-setup/pre-c4-baseline.txt
git diff --check
```

Expected: the contract-freeze note contains per-surface commits and SHA-256 hashes, C1 schema metadata from `properties.schema_version.const`, fixture-derived C2 proof fields, C2 hook observation fields, C3 selected takeover mode/native fields, observed operation values, observed status values, and observed exit codes; the baseline file contains one `DOD_813_BASE=<40-lowercase-hex>` line; `git diff --check` exits `0`. A contract mismatch blocks DOD-814; do not add a C4 compatibility branch.

- [ ] **Step 4:** Commit the frozen baseline before C4 implementation.

```bash
git add dodi-dev/scripts/tests/fixtures/runtime-setup/pre-c4-baseline.txt dodi-dev/scripts/tests/fixtures/runtime-setup/c4-contract-freeze.md
git commit -m "test: freeze DOD-814 runtime baseline"
```

### Task 2: Add redacted fixture families and fail-first C4 tests

**Files:**
- Create: `dodi-dev/scripts/tests/test-runtime-auth.sh`
- Create: `dodi-dev/scripts/tests/test-runtime-register.sh`
- Create: `dodi-dev/scripts/tests/test-runtime-state.sh`
- Create: `dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh`
- Create: `dodi-dev/scripts/tests/test-slack-escalation-adapter.sh`
- Create: every non-live file under `dodi-dev/scripts/tests/fixtures/runtime-setup/` listed in File surface

- [ ] **Step 1:** Add runtime-versioned JSON/JSONL fixture cases for every C4 fail-closed matrix row. Each case must declare `case_id`, `runtime_version`, `input`, `expected_status`, `expected_exit`, and `must_not_contain`; external observations also declare `action_id`, `input_sha256`, `authority_predicate`, and `acceptance`.
- [ ] **Step 2:** Cover valid and invalid auth precedence/files; register discovery/genesis/chain/fork/gap/lost response; profile/health generations and every transaction crash seam; C3 complete-scope/quarantine/unresolved evidence; GitHub classic/ruleset/bypass/admin pages; hook payloads; scheduler collisions/no-overlap/wake/failure; Slack unknown/duplicate/retry/repair; marketplace symlink/same-name collisions; and unknown schema/runtime/action/field cases.
- [ ] **Step 3:** Put only synthetic canaries in `auth/secret-canaries.txt`. Make each test recursively scan captured stdout, stderr, temp transactions, task observations, profile/health output, and generated evidence, and fail if a canary or derived prefix/suffix/hash appears where prohibited.
- [ ] **Step 4:** Make each test fail because its production script/operation is absent, then end with one exact success line after implementation: `runtime auth tests ok`, `runtime register tests ok`, `runtime state tests ok`, `codex scheduler adapter tests ok`, or `slack escalation adapter tests ok`.
- [ ] **Step 5:** Verify fixture syntax independently of implementation.

```bash
set -euo pipefail
find dodi-dev/scripts/tests/fixtures/runtime-setup -type f \( -name '*.json' -o -name '*.jsonl' \) -print0 | while IFS= read -r -d '' file; do
  if [[ "$file" == *.jsonl ]]; then
    while IFS= read -r line; do [[ -z "$line" ]] || printf '%s\n' "$line" | python3 -m json.tool >/dev/null; done < "$file"
  else
    python3 -m json.tool "$file" >/dev/null
  fi
done
bash -n dodi-dev/scripts/tests/test-runtime-auth.sh dodi-dev/scripts/tests/test-runtime-register.sh dodi-dev/scripts/tests/test-runtime-state.sh dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh dodi-dev/scripts/tests/test-slack-escalation-adapter.sh
echo 'DOD-814 fixtures parse ok'
```

Expected: `DOD-814 fixtures parse ok`; exit `0`. Focused tests must fail before their production scripts exist; record that fail-first evidence.

- [ ] **Step 6:** Commit tests and fixtures.

```bash
git add dodi-dev/scripts/tests/test-runtime-auth.sh dodi-dev/scripts/tests/test-runtime-register.sh dodi-dev/scripts/tests/test-runtime-state.sh dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh dodi-dev/scripts/tests/test-slack-escalation-adapter.sh dodi-dev/scripts/tests/fixtures/runtime-setup
git commit -m "test: add DOD-814 setup contract fixtures"
```

### Task 3: Implement the secret-safe Linear auth boundary

**Files:**
- Create: `dodi-dev/scripts/runtime-auth.sh`
- Test: `dodi-dev/scripts/tests/test-runtime-auth.sh`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/auth/cases.jsonl`
- Test canaries: `dodi-dev/scripts/tests/fixtures/runtime-setup/auth/secret-canaries.txt`

- [ ] **Step 1:** Implement exact commands `runtime-auth.sh check [--env-file <absolute-path>]` and `runtime-auth.sh exec [--env-file <absolute-path>] -- <absolute-plugin-owned-command> [args...]`. Reject every command outside the verified plugin root allowlist; never use `eval`, `source`, or a shell-expanded environment file.
- [ ] **Step 2:** Parse only exact `LINEAR_API_KEY=<bytes>` and `LINEAR_DODI_API_KEY=<bytes>` assignments from an operator-selected absolute regular file owned by the current user and mode `0600`. Reject duplicate keys, malformed/blank selected values, extra keys, links, wrong owner/mode, relative paths, command substitution, expansion, and unequal canonical/legacy values.
- [ ] **Step 3:** Apply precedence exactly: process canonical, file canonical, process legacy bridged in the child, file legacy bridged in the child. Remove `LINEAR_DODI_API_KEY` from the child environment and never mutate the parent environment.
- [ ] **Step 4:** Make `check` perform a direct Linear `viewer` query through the allowlisted helper and emit one compact JSON document containing only `schema_version`, `status: AUTH_READY`, `source_class`, `permission_state`, and the one-way viewer/runtime identity. Failures emit no stdout, one redacted named reason on stderr, and exit `2` for invocation/dependency or `3` for unsafe/unverified auth.
- [ ] **Step 5:** Verify.

```bash
bash -n dodi-dev/scripts/runtime-auth.sh dodi-dev/scripts/tests/test-runtime-auth.sh
dodi-dev/scripts/tests/test-runtime-auth.sh
```

Expected: final line `runtime auth tests ok`; exit `0`; no secret canary or secret-derived prefix/suffix/hash appears in captured output or artifacts.

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/scripts/runtime-auth.sh dodi-dev/scripts/tests/test-runtime-auth.sh dodi-dev/scripts/tests/fixtures/runtime-setup/auth
git commit -m "feat: add runtime auth boundary"
```

### Task 4: Implement direct Linear register discovery, mutation, and replay

**Files:**
- Create: `dodi-dev/scripts/runtime-register.sh`
- Test: `dodi-dev/scripts/tests/test-runtime-register.sh`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/register/discovery-observations.jsonl`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/register/chains/valid.jsonl`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/register/chains/invalid.jsonl`

- [ ] **Step 1:** Implement strict operations with these exact CLI shapes. Every command emits one compact JSON object on success/classified blocker, diagnostics only on stderr, and uses exits `0` classified/success, `2` malformed local input/dependency, `3` setup/auth/register prerequisite blocker, `4` unsafe remote evidence, and `5` safe-output/persistence failure.

```text
runtime-register.sh discover --runtime-id <id> --team-key <key> --transaction <dir> --lock-context <file>
runtime-register.sh replay --runtime-id <id> --issue-id <linear-issue-id> --transaction <dir> --lock-context <file>
runtime-register.sh create --intent <runtime-init-intent.json> --transaction <dir> --lock-context <file>
runtime-register.sh append-obligation --intent <obligation-intent.json> --transaction <dir> --lock-context <file>
runtime-register.sh append-delivered --intent <delivered-intent.json> --transaction <dir> --lock-context <file>
```

All inputs are mode `0600` JSON files owned by the current user. Require a previously selected `--runtime-id` for all discovery/mutation operations, invoke Linear only through `runtime-auth.sh exec -- <plugin-root>/scripts/linear-api.sh`, paginate active and archived issues/comments, and validate every record against C1's schema plus canonical hash-chain semantics. Register replay/mutation must run inside the state engine's inherited, validated stable-lock context; the adapter never invents or recursively acquires a second lock.
- [ ] **Step 2:** Emit only the exact classifications below.

| Operation | Statuses |
| --- | --- |
| `discover` | `REGISTER_FOUND`, `REGISTER_ABSENT`, `REGISTER_DUPLICATE`, `REGISTER_COLLISION`, `REGISTER_INVALID` |
| `replay` | `REGISTER_REPLAYED`, `REGISTER_DUPLICATE`, `REGISTER_COLLISION`, `REGISTER_INVALID` |
| `create` | `REGISTER_CREATED`, `REGISTER_CREATE_ADOPTED`, `REGISTER_CREATE_UNCERTAIN`, `REGISTER_CREATE_BLOCKED` |
| `append-obligation` / `append-delivered` | `REGISTER_APPENDED`, `REGISTER_APPEND_ADOPTED`, `REGISTER_APPEND_UNCERTAIN`, `REGISTER_APPEND_BLOCKED` |

A valid replay/create/append result includes issue id, comment id, sequence, record hash, prior hash, runtime id, and unresolved obligations; it excludes raw GraphQL payloads and credential-derived material. `REGISTER_APPEND_BLOCKED` is used for duplicate event id with different payload, broken predecessor, fork, gap, unknown record type, unreadable tip, or schema/hash mismatch. `REGISTER_APPEND_UNCERTAIN` is used only after a flushed intent when remote acceptance cannot be proved by exact replay.

| Status family | Exit |
| --- | --- |
| `REGISTER_FOUND`, `REGISTER_ABSENT`, `REGISTER_REPLAYED`, `REGISTER_CREATED`, `REGISTER_CREATE_ADOPTED`, `REGISTER_APPENDED`, `REGISTER_APPEND_ADOPTED` | `0` |
| malformed local input, missing mode/permission, invalid intent shape, missing dependency | `2` |
| auth/setup/runtime-id/register prerequisite missing | `3` |
| `REGISTER_DUPLICATE`, `REGISTER_COLLISION`, `REGISTER_INVALID`, `REGISTER_CREATE_BLOCKED`, `REGISTER_APPEND_BLOCKED` | `4` |
| `REGISTER_CREATE_UNCERTAIN`, `REGISTER_APPEND_UNCERTAIN`, safe-output failure, local persistence failure after unknown remote acceptance | `5` |

- [ ] **Step 3:** Require a flushed transaction intent before issue/comment mutation. Bind it to runtime id, expected team, mutation nonce, operation, exact genesis or successor hash, prior tip sequence/hash/comment id, event id when present, and expected issue id when appending, with no credential/message body. On transport loss, malformed response, or local post-send persistence failure, perform bounded exact replay and adopt one exact matching create/comment as `REGISTER_CREATE_ADOPTED` or `REGISTER_APPEND_ADOPTED`; never issue a second mutation while acceptance is unknown.
- [ ] **Step 4:** Enforce one immutable `RUNTIME_INIT` description at sequence `0` and only `ESCALATION_OBLIGATION`/`ESCALATION_DELIVERED` comments afterward. Reject edited genesis, unknown species, gaps, forks, duplicate sequence, reused event id with different payload, record after a broken predecessor, unreadable pagination, and a local cursor ahead of remote truth.
- [ ] **Step 5:** Verify deterministic behavior.

```bash
bash -n dodi-dev/scripts/runtime-register.sh dodi-dev/scripts/tests/test-runtime-register.sh
dodi-dev/scripts/tests/test-runtime-register.sh
```

Expected: final line `runtime register tests ok`; exit `0`; exact duplicate mutations are adopted idempotently, ambiguous acceptance never retries a write, and invalid chains produce no usable tip.

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/scripts/runtime-register.sh dodi-dev/scripts/tests/test-runtime-register.sh dodi-dev/scripts/tests/fixtures/runtime-setup/register
git commit -m "feat: implement Linear runtime register"
```

### Task 5: Implement the stable-lock runtime state transaction engine

**Files:**
- Create: `dodi-dev/scripts/runtime-state.sh`
- Test: `dodi-dev/scripts/tests/test-runtime-state.sh`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/state/cases.jsonl`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/c3/reap-recover-observations.jsonl`

- [ ] **Step 1:** Implement exact operations `inspect`, `begin`, `select-runtime-id`, `record-observation`, `apply`, `recover`, `rollback`, `replay-health`, `classify-health`, `acquire-attempt-lease`, and `complete-attempt`. Resolve profile/health/lock only through C1's canonical logic; no repository-local search, invalid override fallback, snapshot read fallback, or second lock is allowed.
- [ ] **Step 2:** Make `inspect` fully read-only and emit one redacted canonical proposal covering every spec-listed provenance/auth/register/hook/GitHub/Slack/task/quiescence/mutation/blocker field plus `proposal_sha256`. Hash the exact canonical proposal bytes. `begin` and every mutation class require a matching explicit confirmation hash; changed discovery invalidates confirmation.
- [ ] **Step 3:** During read-only proposal construction, invoke landed C2 `validate-map`, prepare candidate probes in installed-map order, and normalize only exact model/reasoning/runtime/catalog observations. Setup never substitutes or reorders candidates. Store only successful exact pairs in a staged profile; recognized exhausted Frontier capacity returns `SETUP_CAPACITY_WAIT`, writes no enabled generation, and leaves every task disabled. Unknown rejection or a non-Frontier probe failure is a blocker, not free-form classification.
- [ ] **Step 4:** Make `select-runtime-id` the first separately confirmed mutation when no profile exists. Flush a mode-`0600` selection record in a mode-`0700` transaction directory before any register search, include it in later proposal/transaction hashes, and reuse it after restart.
- [ ] **Step 5:** Build complete repository/profile quiescence scope before state, task, marketplace-root, rollback, or enablement mutation: resolve every configured remote to its canonical repository root; parse `git worktree list --porcelain`; find every C3 manifest and `worker-quarantine.jsonl` under each worktree; add every profile/transaction/proposed-task fingerprint, managed execution, scheduler observation, and live claim. Reject unreadable, duplicate, conflicting, or out-of-scope evidence.
- [ ] **Step 6:** Invoke landed C3 `reap-recover` for each selected worktree/manifest. The top-level caller performs returned native actions and records observations until C3 returns `QUIESCENT` or a blocker. Active quarantine may support disable/rollback/evidence preservation only; it never authorizes reuse, delete, enablement, lights-out, or a successor writer.
- [ ] **Step 7:** Implement apply/rollback ordering without holding the stable lock over external waits. First, outside the stable lock, disable every affected profile-bound managed task, wait for terminal task status, run complete C3 quiescence/recovery, and record redacted scheduler/C3 observations in the transaction. Only after those external actions finish may `runtime-state.sh` acquire the stable lock. Under the lock, recheck task disablement, absence of live C4 attempt leases, proposal hash, plugin root, current profile/health bytes, and quiescence observation freshness; then snapshot prior state, replay/register through the inherited lock context, stage complete files, validate, fsync, rename profile, fsync, rename health, fsync, and verify. Transaction metadata and staged/prior files are `0600`; directories are `0700`; each state transition is flushed. Crash injection after every boundary must select the same deterministic next action after restart.
- [ ] **Step 8:** Implement strict-prefix `replay-health` without recursive lock acquisition. Reject ahead/fork/gap/hash-invalid/wrong-generation/wrong-register health. Implement rollback by restoring only still-compatible prior static profile/task definitions and rebuilding health from the current register tip; never activate snapshot health or discard post-snapshot obligations.
- [ ] **Step 9:** Implement event-specific mode-`0600` attempt leases beside health. Never hold the stable lock over Slack network actions. Validate lease event/setup/profile/task/run/attempt/expiry binding; elapsed time makes a send retryable but never delivered.
- [ ] **Step 10:** Implement `classify-health` exactly: `SETUP_REQUIRED > degraded > stale > healthy`, retry delays `[0,30,120]`, `stale_after_sec=86400`, `re_escalate_after_sec=86400`, strict null-attempt rules, per-event delivery matching, and no mutable global degradation flag.
- [ ] **Step 11:** Verify lock, permissions, crash, concurrency, replay, rollback, quiescence, proposal, C2 probe, capacity, and health cases.

```bash
bash -n dodi-dev/scripts/runtime-state.sh dodi-dev/scripts/tests/test-runtime-state.sh
dodi-dev/scripts/tests/test-runtime-state.sh
```

Expected: final line `runtime state tests ok`; exit `0`; the mid-pair-rename fixture remains `SETUP_REQUIRED` until deterministic recovery; rollback retains obligations added after its snapshot; incomplete proof ends `ROLLBACK_INCOMPLETE` with tasks disabled.

- [ ] **Step 12:** Commit.

```bash
git add dodi-dev/scripts/runtime-state.sh dodi-dev/scripts/tests/test-runtime-state.sh dodi-dev/scripts/tests/fixtures/runtime-setup/state dodi-dev/scripts/tests/fixtures/runtime-setup/c3
git commit -m "feat: add transactional runtime state"
```

### Task 6: Extend C1 preflight with the exact C2-compatible profile proof

**Files:**
- Modify: `dodi-dev/scripts/runtime-preflight.sh`
- Modify: `dodi-dev/scripts/tests/test-runtime-state.sh`
- Consume unchanged: `dodi-dev/scripts/codex-tier-adapter.sh`

- [ ] **Step 1:** Add the exact command:

```text
runtime-preflight.sh verify-profile --repo <owner/name> --operation <operation> --operation-nonce <nonce>
```

Accept only C2 operations `resolve-tier`, `verify-main-loop`, `verify-attestation` and C4 operations `driver-entry`, `driver-loop`, `child-merge`, `daily-heartbeat`, `setup-apply`, `repair`. Do not add an optional boundary argument.

- [ ] **Step 2:** Preserve `bootstrap` behavior and exits byte-for-byte except for shared internal refactoring proven by existing tests. `verify-profile` may perform one strict-prefix replay through `runtime-state.sh` while holding no lock, then acquire the stable lock for one final profile/health/register/runtime/catalog read. On one final-read race, release and retry once; a second race blocks.
- [ ] **Step 3:** On success emit exactly one C2-compatible JSON object with `PROFILE_VERIFIED`, schema version, operation, nonce, repo, canonical profile path/hash/setup id, health path/hash/profile/projection binding, register issue/cursor/tip binding, Codex runtime/version/catalog fingerprint, and stable-read/lock evidence. Compare field names against the landed C2 validator and reject any extra field; C4 task/hook/escalation diagnostics belong in transaction evidence, not stdout.
- [ ] **Step 4:** Emit no partial stdout on failure. Use exit `2` for invalid invocation/dependency and exit `3` with `SETUP_REQUIRED` plus one redacted named reason for binding, permissions, schema, fingerprint, race, health, register, runtime, catalog, or boundary failure. Never produce a receipt, HMAC, environment bypass, assumed proof, or production test-verifier path.
- [ ] **Step 5:** Add same-invocation integration cases using landed C2 commands.

```bash
set -euo pipefail
dodi-dev/scripts/tests/test-runtime-preflight.sh
dodi-dev/scripts/tests/test-runtime-state.sh
dodi-dev/scripts/tests/test-codex-tier-adapter.sh
```

Expected: existing bootstrap tests remain green; state tests end `runtime state tests ok`; C2 adapter tests end their landed exact success line; all production C2 operations invoke C4 verification in the same command and reject stale/cached/extra-field proofs.

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/scripts/runtime-preflight.sh dodi-dev/scripts/tests/test-runtime-state.sh
git commit -m "feat: verify runtime profile generation"
```

### Task 7: Normalize dedicated GitHub authority and complete Gate 2 enforcement

**Files:**
- Create: `dodi-dev/scripts/codex-scheduler-adapter.sh` (GitHub posture/action normalization shared with Task 8)
- Modify: `dodi-dev/scripts/hook-gate2-guard.sh`
- Modify only if live-fire requires: `dodi-dev/hooks/hooks.json`
- Test: `dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/github/observations.jsonl`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/hooks/gate2-observations.jsonl`

- [ ] **Step 1:** Add scheduler-adapter operations that prepare and normalize read-only `gh api` actions for operator identity, scheduled app/machine identity, repository selection/role/permissions, actual default base, all classic protection, all applicable org/repo rulesets, required PR/check rules, bypass principals, base update paths, and protection/rules administration. Paginate every source and hash one deterministic normalized posture.
- [ ] **Step 2:** Block shared human identity, mutable broad token, unreadable/partial `403`/`404`, unsupported rule type, admin/owner/custom-permission ambiguity, bypass membership, base write/update, protection administration, missing PR/check protection, or actor/repository mismatch. The profile stores identity/posture/fingerprint only, never a GitHub credential.
- [ ] **Step 3:** Expand `hook-gate2-guard.sh` normalization for current-runtime tool/event identity, cwd, command/tool input, repo, PR/ref, and target base. Deny `gh pr merge` into `main`/`master`, REST/GraphQL/native merge or enable-auto-merge targeting the protected base, direct git/ref updates to the protected base, raw API ref-update/merge calls against the protected base, opaque indirect shell mutations whose parsed target is the protected base, and protection/ruleset creation/edit/disable/delete. Allow read-only calls, child PR creation, child merge into an epic branch, ordinary non-protected pushes, and unrelated API mutations that are not protected-base ref/merge or protection/rules mutations.
- [ ] **Step 4:** Keep the narrowest proven hook matcher. Change only the Gate 2 matcher in `hooks.json` if the live matrix proves `Bash` misses a mutation family; a broad matcher must positively no-op unrelated tools and fail closed on recognized/dispatch-like mutation payloads. Preserve C2's model-pin entry and both concrete command roots.
- [ ] **Step 5:** Make scheduled capability configuration omit native merge/auto-merge/ref/rule mutation and arbitrary authenticated raw HTTP. Require the plugin-owned child-merge wrapper to reject `main` and `master`; server-side denial remains authoritative even when hook invocation is absent.
- [ ] **Step 6:** Verify deterministic matrices.

```bash
bash -n dodi-dev/scripts/codex-scheduler-adapter.sh dodi-dev/scripts/hook-gate2-guard.sh dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh
python3 -m json.tool dodi-dev/hooks/hooks.json >/dev/null
dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh
```

Expected: final line `codex scheduler adapter tests ok`; exit `0`; every recognized protected-base/rules mutation is denied, every approved child/read case is allowed, and unknown mutation authority/payload blocks lights-out.

- [ ] **Step 7:** Commit. Include `hooks.json` only when live evidence required its change.

```bash
git add dodi-dev/scripts/codex-scheduler-adapter.sh dodi-dev/scripts/hook-gate2-guard.sh dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh dodi-dev/scripts/tests/fixtures/runtime-setup/github dodi-dev/scripts/tests/fixtures/runtime-setup/hooks
git add dodi-dev/hooks/hooks.json  # only if the supported-runtime live-fire required it
git commit -m "feat: enforce Codex Gate 2 setup"
```

### Task 8: Implement harness-native scheduled-task normalization and proof

**Files:**
- Modify: `dodi-dev/scripts/codex-scheduler-adapter.sh`
- Modify: `dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/scheduler/observations.jsonl`

- [ ] **Step 1:** Add exact adapter phases for `discover`, `prepare-create`, `prepare-update`, `prepare-disable`, `prepare-enable`, `observe`, `fingerprint`, and `evaluate-live`. Scripts emit compact action JSON; only the top-level setup session invokes the named harness-native action and returns a mode-`0600` redacted observation. The adapter never starts cron, a daemon, or a headless CLI wrapper.
- [ ] **Step 2:** Define one scope as `(repo, epic worktree, profile path, scheduled automation identity)` and one deterministic scope id. Accept exactly one `dodi-drive-epic` and one `dodi-reconcile-tickets` task per configured scope; same-name tasks outside scope, duplicate ids, unprovable scope, or unknown update acceptance are blockers.
- [ ] **Step 3:** Fingerprint task id/name, schedule/time zone, enabled state, runtime/plugin/profile generation, repo/worktree, exact instruction hash, C2-verified Standard model/reasoning, environment-source references, allowed capabilities, GitHub actor, no-overlap mode, and failure-notification behavior. Exclude secret values and reject any execution that reports a different actor/profile/model/config.
- [ ] **Step 4:** Pin `dodi-drive-epic` to hourly/off-peak liveness-guard/resident-driver semantics and `dodi-reconcile-tickets` to daily-after-deploy repair-only semantics. Both start with `verify-profile`, then C2 `verify-main-loop` Standard, before PM/Git/worker actions; neither has epic merge capability.
- [ ] **Step 5:** Enforce transaction ordering: disable every affected task fingerprint, wait for terminal execution status, consume complete C3 quiescence, snapshot exact prior task config, prepare/observe mutation, re-list and hash actual state, run disposable probes, remove probes, and enable only after separate final confirmation. Timeout, duplicate, unknown acceptance, restore ambiguity, failed cleanup, no-overlap/wake/failure/Gate 2 failure leaves every affected profile-bound managed task disabled.
- [ ] **Step 6:** Verify boot/no-overlap/successor-wake/failure fixture cases. The successor-wake fixture must use a mode-`0600` durable `refresh-park` seam and distinct context id; in-memory continuation or operator manual start is not valid.

```bash
dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh
```

Expected: final line `codex scheduler adapter tests ok`; exit `0`; exact duplicate/collision/unknown/no-overlap/wake/failure cases match the spec and no fixture performs PM, branch, or worker mutation.

- [ ] **Step 7:** Commit.

```bash
git add dodi-dev/scripts/codex-scheduler-adapter.sh dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh dodi-dev/scripts/tests/fixtures/runtime-setup/scheduler
git commit -m "feat: adapt Codex scheduled tasks"
```

### Task 9: Implement register-backed Slack delivery and repair

**Files:**
- Create: `dodi-dev/scripts/slack-escalation-adapter.sh`
- Test: `dodi-dev/scripts/tests/test-slack-escalation-adapter.sh`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/slack/observations.jsonl`

- [ ] **Step 1:** Implement exact phases `prepare`, `observe`, `repair`, and `classify`. Require profile adapter `slack`, one channel id, retry delays `[0,30,120]`, `stale_after_sec=86400`, and `re_escalate_after_sec=86400`; reject alternate adapter/channel/policy or missing installed-plugin evidence.
- [ ] **Step 2:** Under the stable lock, replay the register, append/adopt exactly one `ESCALATION_OBLIGATION`, project it pending, and acquire its event-specific lease; then release the stable lock before emitting `SEND_SLACK`. The action contains only artifact `## TL;DR`, `## Key Points`, safe links, event id, attempt number, and configured channel; never a prompt, credential, native payload, or arbitrary environment value.
- [ ] **Step 3:** After every Slack observation, call `runtime-state.sh complete-attempt` under the stable lock before any retry/exhaustion decision. `complete-attempt` validates the lease event/setup/profile/task/run/attempt binding and writes the health attempt count, `last_attempt_at`, and redacted last-error class for success, timeout, wrong channel, malformed/missing id/link, transport failure, and unknown acceptance. It then clears or expires only that sidecar lease. A malformed or missing lease blocks projection as `SETUP_REQUIRED`; elapsed time alone never increments attempts.
- [ ] **Step 4:** Accept delivery success only when the redacted observation matches the action/event/channel/attempt and carries durable Slack message id, permalink/link, and timestamp. After `complete-attempt`, append/adopt one `ESCALATION_DELIVERED` and project only that obligation delivered. Timeout, wrong channel, malformed/missing id/link, transport failure, and unknown acceptance remain unresolved and may duplicate on retry but never falsely deliver.
- [ ] **Step 5:** After exhaustion, keep the register obligation unresolved, derive degraded health from completed-attempt state, prepare a redacted `notification-degraded` ticket comment, and exit failed so harness-native failure notification fires. Janitor repair selects each event independently; aggregate success never clears another event.
- [ ] **Step 6:** Implement 24-hour human-wait re-escalation as a new obligation referencing the prior durable message id and age. Empty obligations stay healthy unless an open human-wait item is due.
- [ ] **Step 7:** Verify.

```bash
bash -n dodi-dev/scripts/slack-escalation-adapter.sh dodi-dev/scripts/tests/test-slack-escalation-adapter.sh
dodi-dev/scripts/tests/test-slack-escalation-adapter.sh
```

Expected: final line `slack escalation adapter tests ok`; exit `0`; every send has a prior obligation, every observation records exactly one completed attempt or a setup blocker, the crash fixture after successful `complete-attempt` persistence but before `ESCALATION_DELIVERED` append resumes as unresolved retry/repair without false delivery, every delivery has a later matching delivered record, and all due/wait/exhausted/expired-lease cases match `runtime-state.sh classify-health`.

- [ ] **Step 8:** Commit.

```bash
git add dodi-dev/scripts/slack-escalation-adapter.sh dodi-dev/scripts/tests/test-slack-escalation-adapter.sh dodi-dev/scripts/tests/fixtures/runtime-setup/slack
git commit -m "feat: add durable Slack escalation"
```

### Task 10: Add marketplace migration and the thin setup conversation surface

**Files:**
- Create: `dodi-dev/skills/setup-dodi-dev/SKILL.md`
- Modify: `dodi-dev/scripts/runtime-state.sh`
- Modify: `dodi-dev/scripts/tests/test-runtime-state.sh`
- Test fixtures: `dodi-dev/scripts/tests/fixtures/runtime-setup/marketplace/observations.jsonl`

- [ ] **Step 1:** Add marketplace observation normalization to `runtime-state.sh inspect`: combine supported Codex marketplace listing, direct supported config inspection, and installed cache/plugin provenance; canonicalize symlinks and roots; classify exactly one source as healthy and same-name/different-root, stale `~/plugins/dodi-dev`, unreadable, duplicate, relative-unresolvable, or CLI/config disagreement as `MARKETPLACE_COLLISION`/blocking ambiguity.
- [ ] **Step 2:** Add proposal-bound marketplace transaction actions `prepare-migration`, `observe-migration`, `prepare-rollback`, and `observe-rollback`. Require separate confirmation and an explicit operator choice to remove/rename the stale source or select the canonical repository source. `prepare-migration` snapshots exact config/provenance/cache roots before mutation and emits only the supported runtime action; `observe-migration` accepts success only after re-listing source/cache provenance and seeing exactly one canonical root. `prepare-rollback` emits a supported restore action only from the exact snapshot captured by the same transaction; `observe-rollback` accepts success only after re-listing provenance and proving the exact prior config/root/cache identity is restored. If exact rollback is unsupported, ambiguous, or stale, preserve both snapshots, keep every affected task disabled, and report manual repair. Unknown migration, rollback, or cleanup acceptance keeps tasks disabled.
- [ ] **Step 3:** Create `setup-dodi-dev/SKILL.md` with frontmatter and modes exactly `inspect`, `apply --repo OWNER/NAME`, `repair --repo OWNER/NAME`, `rollback --transaction ID`, and `status --repo OWNER/NAME`. Always start with C1 bootstrap against the one derived installed root; link installed runtime policy and exact script operations rather than restating schema, hash, lock, register, scheduler, Slack, or C3 mechanics.
- [ ] **Step 4:** Make the skill present one redacted proposal whose human-facing output leads with `## TL;DR` and `## Key Points`, then request separate confirmation for runtime-id selection, marketplace migration, register creation, Slack test delivery, scheduled-task create/update, and final lights-out enablement. It must re-run inspect after each mutation and invalidate confirmation when the proposal hash changes. Discovery performs no marketplace, trust, PM, Git, Slack, task, profile, health, or runtime-id mutation.
- [ ] **Step 5:** Keep harness-native orchestration in the top-level setup session: consume adapter action JSON, invoke the named current-runtime action, and write only the redacted observation to its transaction input. Do not claim a script called Codex automation/Slack tools directly; do not dispatch workers from setup.
- [ ] **Step 6:** Verify setup references and marketplace tests.

```bash
set -euo pipefail
dodi-dev/scripts/tests/test-runtime-state.sh
grep -q '^name: setup-dodi-dev$' dodi-dev/skills/setup-dodi-dev/SKILL.md
for mode in inspect apply repair rollback status; do grep -q "$mode" dodi-dev/skills/setup-dodi-dev/SKILL.md; done
! rg -n 'docs/specs/|docs/plans/' dodi-dev/skills/setup-dodi-dev
echo 'setup skill contract ok'
```

Expected: state tests end `runtime state tests ok`; marketplace fixtures prove healthy/collision/migration/rollback/unknown-acceptance cases; `setup skill contract ok`; exit `0`; no installed skill references repository-only docs or duplicates script mechanics.

- [ ] **Step 7:** Commit.

```bash
git add dodi-dev/skills/setup-dodi-dev/SKILL.md dodi-dev/scripts/runtime-state.sh dodi-dev/scripts/tests/test-runtime-state.sh dodi-dev/scripts/tests/fixtures/runtime-setup/marketplace
git commit -m "feat: add explicit Dodi runtime setup"
```

### Task 11: Wire installed consumers and register C4 validation

**Files:**
- Modify: `dodi-dev/runtime/adapter-contracts.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Modify: `dodi-dev/skills/drive-epic/SKILL.md`
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md`
- Modify: `dodi-dev/skills/epic-orchestrator/execution-model.md`
- Modify: `scripts/validate-runtime-contracts.sh`
- Modify: `scripts/validate-phase-skills.sh`

- [ ] **Step 1:** Mark C4 register/state/verifier/scheduler/escalation operations implemented in `adapter-contracts.md`, linking command contracts and ownership. Preserve C1 path/schema/hash authority, C2 tier/attestation authority, and C3 lifecycle/quarantine authority.
- [ ] **Step 2:** Update installed runtime policy/execution model with concise links for setup/profile generation, complete C3 quiescence, Gate 2, task, and escalation boundaries. Do not copy script algorithms, add workflow states, or alter lane/review/Fable/claim semantics.
- [ ] **Step 3:** Require `drive-epic` boot/loop/child-merge/heartbeat verification at the approved operation boundaries, exact task identity, Standard main-loop verification, and healthy routing before lane selection. `stale`/`degraded` block new lanes; only setup repair and janitor escalation repair/read-only waiting-on-you sweep remain allowed.
- [ ] **Step 4:** Route `reconcile-tickets` escalation through the Slack adapter and register ordering, keep its repair-only role, and bind its scheduled identity/fingerprint. Remove any prose that treats direct channel delivery or a mutable global degradation flag as authority.
- [ ] **Step 5:** Extend `validate-runtime-contracts.sh` default mode to validate C4 deterministic fixtures, operation ordering, schema ownership, exact proof fields, reference graph, secret canaries, permissions, metadata/C5 fences, and allow the live directory to be absent or explicitly pending. Add `--require-codex-setup-live` to hash/validate Task 12 evidence and require every live matrix family.
- [ ] **Step 6:** Extend `validate-phase-skills.sh` to require `setup-dodi-dev`, all five new executable C4 helpers, all five new executable C4 tests, Bash syntax, installed references, and no duplicated mechanics/repo-only docs. Keep existing skill/script checks and C1-C3 validators intact.
- [ ] **Step 7:** Verify deterministic integration.

```bash
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
```

Expected: runtime validator exits `0` without requiring Task 12 live artifacts; `phase skills ok`; `plugin metadata ok: 0.16.0`; `ticket comment templates ok`.

- [ ] **Step 8:** Commit.

```bash
git add dodi-dev/runtime/adapter-contracts.md dodi-dev/skills/epic-orchestrator/runtime-policy.md dodi-dev/skills/drive-epic/SKILL.md dodi-dev/skills/reconcile-tickets/SKILL.md dodi-dev/skills/epic-orchestrator/execution-model.md scripts/validate-runtime-contracts.sh scripts/validate-phase-skills.sh
git commit -m "docs: wire Codex setup boundaries"
```

### Task 12: Execute and retain the supported-runtime C4 live gates

**Files:**
- Create: every file under `dodi-dev/scripts/tests/fixtures/runtime-setup/live/` listed in File surface
- Modify only if evidence requires: `dodi-dev/hooks/hooks.json`

- [ ] **Step 1:** Before mutation, capture the supported runtime version and redacted native action schemas for hook discovery/trust, GitHub identity/actions, scheduler list/create/update/disable/enable/run/wake/failure, Slack send/result, marketplace list/mutate/restore, and landed C3 recovery actions. Record only names, field/status shapes, authority predicates, and hashes; omit secrets, prompts, message bodies beyond synthetic test content, and raw native payloads.
- [ ] **Step 2:** Run read-only Linear auth/viewer/team discovery, then separately confirm a disposable runtime id and register creation. Prove active+archived exact-id search, immutable genesis, obligation/delivered append/replay, and a safely injected lost-response adoption path. Record redacted action/result hashes in `linear-evidence.redacted.jsonl`.
- [ ] **Step 3:** With the dedicated scheduled GitHub credential and equivalent protected temporary branch/repository, retain denial evidence for direct push/ref update, merge, auto-merge, REST/GraphQL/native merge, and protection/rules mutation; retain allowed read inspection, child PR creation, and child merge into an epic branch. Cleanup uses only the operator credential after evidence is durable.
- [ ] **Step 4:** Discover both exact hook entries from the installed root, require explicit operator trust of exact hashes, and live-fire C2's model-pin matrix plus C4's complete Gate 2 deny/allow matrix. If the narrow matcher misses a native mutation family, update only the Gate 2 matcher, rerun all deterministic tests, and repeat live-fire.
- [ ] **Step 5:** Separately confirm disposable scheduler probes using production-shaped Standard driver/janitor configuration. Prove boot verification before other work, no overlap at a durable barrier, a distinct-context successor reading only a mode-`0600` `refresh-park` seam, native failure notification, scheduled Gate 2 denial, exact config observation, and probe removal. Unknown removal acceptance blocks the gate.
- [ ] **Step 6:** Separately confirm one low-risk Slack test through the production path. Retain obligation-before-send, action/event/channel binding, durable message id/permalink/time, delivered-after-send, and current health evidence. Also exercise safe unknown-response/retry/degraded/repair normalization without claiming fixture evidence is a real delivery.
- [ ] **Step 7:** In an isolated disposable marketplace configuration, separately confirm one marketplace migration and one rollback action. Retain action schemas, before/migration/rollback provenance fingerprints, snapshot hashes, exact restore proof, and cleanup state in `marketplace-evidence.redacted.jsonl`. If the supported runtime cannot restore exactly, preserve both snapshots and record the manual-repair blocker; do not mark the live gate clean.
- [ ] **Step 8:** In an isolated disposable profile/home, crash after profile rename and before health rename, restart setup, and prove deterministic recovery with tasks disabled. Snapshot, append a later register obligation, roll back static state, and prove rebuilt health retains the later obligation.
- [ ] **Step 9:** Write `live-gate-evidence.md` with runtime version, disposable scope identifiers/hashes, confirmation ids/hashes, commands/action families, outcomes, cleanup state, and blockers. Generate `evidence-hashes.json` over every other live artifact; include `hash_manifest_excludes_self: true` and do not self-hash.
- [ ] **Step 10:** Validate live evidence.

```bash
set -euo pipefail
python3 -m json.tool dodi-dev/scripts/tests/fixtures/runtime-setup/live/native-action-schemas.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/runtime-setup/live/evidence-hashes.json >/dev/null
for file in dodi-dev/scripts/tests/fixtures/runtime-setup/live/*.jsonl; do while IFS= read -r line; do [[ -z "$line" ]] || printf '%s\n' "$line" | python3 -m json.tool >/dev/null; done < "$file"; done
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
scripts/validate-runtime-contracts.sh --require-codex-setup-live
```

Expected: every artifact parses and hash-verifies; the live-required validator exits `0`; all seven live families (Linear, GitHub, hooks, scheduler, Slack, marketplace, state) are present and clean. Any unrecognized schema/action, failed denial, missing durable delivery, scheduler overlap/wake failure, marketplace restore uncertainty, cleanup uncertainty, or C3 quiescence gap leaves DOD-814 blocked and production tasks disabled.

- [ ] **Step 11:** Commit redacted implementation evidence only. This is C4 evidence, not C5's final isolated-release bundle.

```bash
git add dodi-dev/scripts/tests/fixtures/runtime-setup/live
git add dodi-dev/hooks/hooks.json  # only if Task 12 proved the matcher change necessary
git commit -m "test: capture DOD-814 live setup evidence"
```

### Task 13: Run complete regression, redaction, and ownership audit

**Files:**
- Verify only: all planned C4 files
- Verify unchanged: all C1 schemas/path definitions, C2 map/capacity/attestation files, C3 lifecycle/reaper/quarantine files, metadata envelopes, C5 surfaces

- [ ] **Step 1:** Run syntax, focused, repository, live, and complete shell regression.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
bash -n dodi-dev/scripts/runtime-auth.sh dodi-dev/scripts/runtime-register.sh dodi-dev/scripts/runtime-state.sh dodi-dev/scripts/runtime-preflight.sh dodi-dev/scripts/codex-scheduler-adapter.sh dodi-dev/scripts/slack-escalation-adapter.sh dodi-dev/scripts/hook-gate2-guard.sh
dodi-dev/scripts/tests/test-runtime-auth.sh
dodi-dev/scripts/tests/test-runtime-register.sh
dodi-dev/scripts/tests/test-runtime-state.sh
dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh
dodi-dev/scripts/tests/test-slack-escalation-adapter.sh
scripts/validate-runtime-contracts.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
scripts/validate-runtime-contracts.sh --require-codex-setup-live
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
```

Expected: every command exits `0`; focused tests print their exact `tests ok` lines; all landed C1-C3 live requirements remain valid; metadata output remains `plugin metadata ok: 0.16.0`.

- [ ] **Step 2:** Audit the declared C4 file surface against the frozen baseline.

```bash
set -euo pipefail
DOD_813_BASE="$(sed -n 's/^DOD_813_BASE=//p' dodi-dev/scripts/tests/fixtures/runtime-setup/pre-c4-baseline.txt)"
test -n "$DOD_813_BASE"
git cat-file -e "$DOD_813_BASE^{commit}"
git diff --check "$DOD_813_BASE"...HEAD
git diff --name-only "$DOD_813_BASE"...HEAD | sort
test -z "$(git diff --name-only "$DOD_813_BASE"...HEAD -- dodi-dev/runtime/runtime-profile.schema.json dodi-dev/runtime/runtime-health.schema.json dodi-dev/runtime/runtime-register-record.schema.json dodi-dev/runtime/dispatch-manifest-record.schema.json dodi-dev/runtime/codex-model-tiers.schema.json dodi-dev/runtime/codex-model-tiers.json dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/codex-capacity-classifier.sh dodi-dev/scripts/codex-worker-adapter.sh dodi-dev/scripts/reap-workers.sh dodi-dev/scripts/await-worker.sh)"
test -z "$(git diff "$DOD_813_BASE"...HEAD -- .claude-plugin/plugin.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .claude-plugin/marketplace.json .agents/plugins/marketplace.json)"
```

Expected: no whitespace errors; changed files are limited to the declared C4 surface; all C1-C3 owned implementation files and metadata diffs are empty, except C4's approved modifications to `runtime-preflight.sh`, Gate 2 hook, installed contract/policy consumers, and validators.

- [ ] **Step 3:** Run C5-absence, version, production-state, and secret audits.

```bash
set -euo pipefail
test ! -e scripts/validate-codex-compatibility.sh
test ! -e scripts/validate-codex-install.sh
test ! -d docs/guides
test ! -d docs/release
test "$(python3 -c 'import json; print(json.load(open("dodi-dev/.codex-plugin/plugin.json"))["version"])')" = "0.16.0"
! git diff --name-only "$DOD_813_BASE"...HEAD | rg '(^|/)(runtime-profile|runtime-health)\.json$|worker-quarantine\.jsonl$|\.env$'
! rg -n 'LINEAR_(DODI_)?API_KEY=[^<[:space:]]|xox[baprs]-|github_pat_|gh[pousr]_' dodi-dev scripts --glob '!dodi-dev/scripts/tests/fixtures/runtime-setup/auth/secret-canaries.txt'
echo 'C4 ownership and redaction audit ok'
```

Expected: `C4 ownership and redaction audit ok`; exit `0`; no release surface, metadata bump, production state, or real credential-like value exists.

- [ ] **Step 4:** Review fail-closed invariants from code and evidence: inspect is read-only; runtime id is selected before register discovery; confirmation binds unchanged proposal; one stable lock owns state; strict-prefix replay never recurses; current register survives rollback; all worktrees/tasks reach C3 quiescence; profile proof matches C2 exactly; scheduled actor cannot reach Gate 2; task overlap/wake/cleanup are proven; Slack obligation precedes send and delivery follows durable result; unknown acceptance never advances.
- [ ] **Step 5:** Record implementation commits, exact commands/exits, live evidence hashes, final file list, and any deliberately disabled production state for plan review. Do not self-approve, update Linear, apply labels, assemble C5 release evidence, or enable production tasks without the operator's separate final setup confirmation.
- [ ] **Step 6:** Commit only a narrow C4 correction if Task 13 exposed a confirmed implementation defect. If no file changed, do not create an empty commit.

```bash
changed_file_list="$(mktemp)"
trap 'rm -f "$changed_file_list"' EXIT
git diff --cached --name-only > "$changed_file_list"
git diff --name-only >> "$changed_file_list"
git ls-files --others --exclude-standard >> "$changed_file_list"
sort -u "$changed_file_list" -o "$changed_file_list"
if ! test -s "$changed_file_list"; then
  echo "no Task 13 correction commit needed"
else
  python3 - "$changed_file_list" <<'PY'
import sys
from pathlib import Path
allowed_exact = {
    'dodi-dev/scripts/runtime-auth.sh',
    'dodi-dev/scripts/runtime-register.sh',
    'dodi-dev/scripts/runtime-state.sh',
    'dodi-dev/scripts/runtime-preflight.sh',
    'dodi-dev/scripts/codex-scheduler-adapter.sh',
    'dodi-dev/scripts/slack-escalation-adapter.sh',
    'dodi-dev/scripts/hook-gate2-guard.sh',
    'dodi-dev/hooks/hooks.json',
    'dodi-dev/runtime/adapter-contracts.md',
    'dodi-dev/skills/epic-orchestrator/runtime-policy.md',
    'dodi-dev/skills/drive-epic/SKILL.md',
    'dodi-dev/skills/reconcile-tickets/SKILL.md',
    'dodi-dev/skills/epic-orchestrator/execution-model.md',
    'dodi-dev/scripts/tests/test-runtime-auth.sh',
    'dodi-dev/scripts/tests/test-runtime-register.sh',
    'dodi-dev/scripts/tests/test-runtime-state.sh',
    'dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh',
    'dodi-dev/scripts/tests/test-slack-escalation-adapter.sh',
    'scripts/validate-runtime-contracts.sh',
    'scripts/validate-phase-skills.sh',
}
allowed_prefixes = {
    'dodi-dev/skills/setup-dodi-dev/',
    'dodi-dev/scripts/tests/fixtures/runtime-setup/',
}
paths = [line.strip() for line in Path(sys.argv[1]).read_text().splitlines() if line.strip()]
bad = [
    path for path in paths
    if path not in allowed_exact and not any(path.startswith(prefix) for prefix in allowed_prefixes)
]
if bad:
    raise SystemExit("refusing to stage non-C4 correction files:\n" + "\n".join(bad))
print("\n".join(paths))
PY
  while IFS= read -r path; do git add -- "$path"; done < "$changed_file_list"
  git commit -m "fix: close DOD-814 setup validation gaps"
fi
```

## Handoff Assumptions And Blockers

- DOD-811, DOD-812, and DOD-813 implementations land before C4 execution; the first implementation task records their exact merged baseline and blocks on any missing/incompatible contract.
- C1 supplies the canonical profile/health/register/manifest schemas, path derivation, stable lock, root bootstrap, and adapter contracts; C4 extends only the approved verifier/writer surfaces.
- C2 supplies callable map validation/tier verification, exact proof consumer fields, supported Standard pair, structured capacity classification, and model-pin live evidence; C4 stores successful exact pairs but does not choose policy.
- C3 supplies a supported live takeover mode and `reap-recover` actions whose evidence can establish complete-scope `QUIESCENT` or a durable quarantine blocker. Any unresolved possibly-writing identity keeps scheduled delivery disabled.
- The parent-supported Codex runtime exposes redacted, authoritative hook, scheduler, Slack, GitHub permission, and C3 recovery observations sufficient to distinguish success, denial, duplicate, unknown acceptance, terminal state, no overlap, and successor wake. Missing authority blocks implementation rather than narrowing the contract.
- Direct Linear GraphQL supports paginated active/archived issue search, immutable issue description reads, comment pagination, issue/comment creation, and exact re-read needed for lost-response recovery. A duplicate/fork/gap/unreadable register blocks setup and Slack.
- The operator can provide distinct human and restricted scheduled GitHub identities, an equivalent protected disposable branch/repository, a disposable Linear register location, and a dedicated low-risk Slack channel for confirmed live gates; no production task is used as an implementation probe.
- The plan-reviewer must classify delivery tier before `ready-to-implement`. Expected classification is `capable` because C4 implements concurrent lock/transaction, append-only remote reconciliation, idempotent external mutation, authority, scheduling, and degradation invariants; the reviewer owns the final `standard|capable` decision and `needs-capable-delivery` label.
- C5 consumes C4 deterministic/live evidence later but owns isolated-install/release validation, install/release guides, the final compatibility bundle, metadata `0.17.0`, and release signoff.
- No plan-time architecture blocker is known. Any need for a competing C1 field/path/hash/state, changed C2 proof or model policy, fabricated C3 quiescence, alternate escalation authority, or automated epic Gate 2 path returns to DOD-810/DOD-814 design review.
