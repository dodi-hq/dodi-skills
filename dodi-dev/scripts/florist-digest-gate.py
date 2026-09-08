#!/usr/bin/env python3
"""Stop-hook gate: an autonomous Florist seat may not end its turn without the
digest in its FINAL message.

Why the final message and not "somewhere in the session" (DOD-1389, field
evidence 2026-09-08): the kernel spawns `claude -p`, whose stdout is the last
assistant message and nothing else. Two of three smoke-#3 dispatches DID run
`florist-digest.sh` and got a valid digest back in a Bash result — then closed
with prose *about* it ("...emitted `clean-final delivery-tier=standard` as the
last output"). The digest never reached stdout, so the kernel saw silence: a
dead lease, a reap, an attempt burned, and a successor redoing pushed work.

So the check is mechanical and narrow: does the final assistant message carry a
line the kernel's parser (dodi-florist `src/worker/digest.ts`) would accept as a
submission? If not, the Stop is blocked with the reason — and, when the session
already produced a digest earlier in its transcript, with those exact lines to
paste back. Bounded: after DODI_DIGEST_GATE_MAX blocks the session is allowed to
end, because a gate that can trap a worker forever is worse than the reap it
prevents.

Manual mode (no FLORIST_UNIT) is untouched: no digest is ever emitted there.
"""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import sys

# Mirrors of the kernel parser (dodi-florist src/worker/digest.ts). Kept in step
# by hand and by test-florist-digest-gate.sh; a gate that accepts what the kernel
# rejects would hand back a burned attempt with a clean conscience.
STATUS_RE = re.compile(r"^FLORIST-STATUS:\s+(\S+)((?:\s+\S+=\S+)*)\s*$")
EVIDENCE_RE = re.compile(r"^FLORIST-EVIDENCE:\s+kind=(\S+)\s+ref=(\S+)\s+sha=(\S+)\s*$")
OUTCOMES = {
    "artifact-ready", "findings", "clean-final", "impl-ready",
    "synced", "merge-ready", "demote", "blocked", "declined",
}
EVIDENCE_KINDS = {"pr", "ci", "artifact", "thread", "verdict"}

DEFAULT_MAX_BLOCKS = 3


def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def digest_key(value):
    return hashlib.sha256(value.encode()).hexdigest()


def state_home():
    """Owner-local, 0700, absolute — the clean-park posture, minus the locking:
    this record is a per-session block counter, written by one process."""
    path = Path(os.environ.get("DODI_DIGEST_GATE_HOME", str(Path.home() / ".dodi/florist-digest-gate")))
    if not path.is_absolute():
        raise ValueError("DODI_DIGEST_GATE_HOME must be absolute")
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.is_symlink() or path.stat().st_uid != os.getuid():
        raise ValueError("state directory must belong to this user")
    return path.resolve()


def blocks_so_far(session_id):
    if not session_id:
        return 0
    path = state_home() / ("gate-" + digest_key(session_id) + ".json")
    if not path.exists():
        return 0
    record = json.loads(path.read_text())
    count = record.get("blocks")
    return count if isinstance(count, int) and count >= 0 else 0


def record_block(session_id, count):
    if not session_id:
        return
    path = state_home() / ("gate-" + digest_key(session_id) + ".json")
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps({"session_id": session_id, "blocks": count, "updated_at": stamp()}, indent=2) + "\n")
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)


def strings(node):
    """Every string reachable in a transcript record, in document order."""
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for value in node.values():
            yield from strings(value)
    elif isinstance(node, list):
        for value in node:
            yield from strings(value)


def read_transcript(path):
    records = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
            except ValueError:
                continue  # a partially flushed tail line is not evidence of anything
            if isinstance(record, dict):
                records.append(record)
    return records


def final_assistant_text(records):
    """The text `claude -p` prints: the last main-thread assistant message.
    Sidechain records are a dispatched subagent's, never this session's stdout."""
    for record in reversed(records):
        if record.get("type") != "assistant" or record.get("isSidechain"):
            continue
        content = (record.get("message") or {}).get("content")
        if isinstance(content, str):
            return content
        blocks = content if isinstance(content, list) else []
        return "\n".join(
            b.get("text", "") for b in blocks if isinstance(b, dict) and b.get("type") == "text"
        )
    return None


def valid_status(line):
    match = STATUS_RE.match(line)
    return bool(match and match.group(1) in OUTCOMES)


def valid_evidence(line):
    match = EVIDENCE_RE.match(line)
    return bool(match and match.group(1) in EVIDENCE_KINDS)


def classify(text):
    """('ok', None) when the kernel would read a submission out of this message,
    else (code, offending line)."""
    lines = text.splitlines()
    if any(valid_status(line) for line in lines):
        for line in lines:
            if line.startswith("FLORIST-EVIDENCE:") and not valid_evidence(line):
                return "malformed-evidence", line
        return "ok", None
    for line in lines:
        if line.startswith("FLORIST-STATUS:"):
            return "malformed-status", line
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith(("FLORIST-STATUS:", "FLORIST-EVIDENCE:")) and stripped != line:
            return "indented", line
    return "absent", None


def recover_digest(records, final_text):
    """The digest this session already produced — typically the Bash result from
    florist-digest.sh — so the block can hand back the exact lines to paste."""
    groups, current = [], None
    for record in records:
        if record.get("isSidechain"):
            continue
        for blob in strings(record):
            if "FLORIST-" not in blob:
                continue
            for line in blob.splitlines():
                if valid_status(line):
                    current = [line]
                    groups.append(current)  # the group grows in place as evidence follows
                elif current is not None and valid_evidence(line):
                    current.append(line)
                elif line.strip():
                    current = None
    if not groups:
        return None
    recovered = groups[-1]  # last digest wins, as the kernel's parser does
    # A digest already in the final message is not a recovery hint.
    if final_text and recovered[0] in final_text.splitlines():
        return None
    return recovered


def reason_for(code, offending, recovered, unit, lane, repeated):
    root = os.environ.get("CLAUDE_PLUGIN_ROOT", "${CLAUDE_PLUGIN_ROOT}")
    head = (
        f"FLORIST DIGEST GATE — unit {unit}, lane {lane}. Your FINAL message is the only thing the "
        "kernel reads: this session runs under `claude -p`, whose stdout is the last assistant message "
        "and nothing else. "
    )
    if code == "absent":
        body = (
            "It carries no `FLORIST-STATUS:` line, so this dispatch is silence to the kernel — the lease "
            "runs to TTL, the reap settles an attempt against the unit, and the next worker redoes work "
            "you already pushed."
        )
    elif code == "malformed-status":
        body = (
            f"Its status line does not parse, so it is not a submission: {offending!r}. The grammar is "
            "`FLORIST-STATUS: <outcome> [key=value ...]` with an outcome the kernel knows."
        )
    elif code == "malformed-evidence":
        body = (
            f"An evidence row does not parse and would be dropped: {offending!r}. The grammar is "
            "`FLORIST-EVIDENCE: kind=<pr|ci|artifact|thread|verdict> ref=<ref> sha=<sha|->`."
        )
    else:  # indented
        body = (
            f"The digest is indented, and the parser matches at column 0 only: {offending!r}. Emit the "
            "lines flush left, outside any list item, quote, or code fence."
        )
    if recovered:
        fix = (
            "You already produced a valid digest in this session. Describing it is not emitting it. "
            "End your next message with exactly these lines, flush left and last:\n\n"
            + "\n".join(recovered)
        )
    else:
        fix = (
            f"Run `{root}/scripts/florist-digest.sh <outcome> [key=value ...] "
            "[--evidence kind=<k> ref=<r> sha=<s|->]...` for this lane, then paste its output verbatim as "
            "the last lines of your next message. A wall closes the same way: `blocked reason=<reasonId>` "
            "or `declined reason=<reasonId>` through the same script."
        )
    tail = ""
    if repeated:
        tail = (
            " This Stop was already blocked for the same reason. Emit the digest lines themselves as your "
            "next message — no summary, no explanation around them."
        )
    return head + body + " " + fix + tail


def hook_stop(payload):
    unit = os.environ.get("FLORIST_UNIT")
    if not unit:
        return  # manual mode: a digest is never emitted here
    try:
        event = json.loads(payload)
        if not isinstance(event, dict):
            return
    except ValueError:
        return
    transcript = event.get("transcript_path")
    if not transcript or not Path(transcript).is_file():
        return  # no evidence to judge: fail open, never trap a session on an unreadable transcript
    try:
        records = read_transcript(transcript)
        text = final_assistant_text(records)
        code, offending = classify(text or "")
        if code == "ok":
            return
        session_id = event.get("session_id") or os.environ.get("CLAUDE_CODE_SESSION_ID") or ""
        limit = int(os.environ.get("DODI_DIGEST_GATE_MAX", DEFAULT_MAX_BLOCKS))
        seen = blocks_so_far(session_id)
        if seen >= limit:
            return  # bounded: an unbreakable gate is worse than the reap it prevents
        record_block(session_id, seen + 1)
        recovered = recover_digest(records, text)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"florist-digest-gate: {exc}", file=sys.stderr)
        return  # defense in depth, not an invariant: a broken gate never blocks a worker
    reason = reason_for(
        code, offending, recovered, unit, os.environ.get("FLORIST_LANE", "?"),
        repeated=bool(event.get("stop_hook_active")) or seen > 0,
    )
    print(json.dumps({"decision": "block", "reason": reason}))


def main(argv):
    if len(argv) != 3 or argv[1] != "hook-stop":
        print("usage: florist-digest-gate.py hook-stop <payload>", file=sys.stderr)
        return 2
    hook_stop(argv[2])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
