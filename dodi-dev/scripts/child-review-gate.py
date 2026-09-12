#!/usr/bin/env python3
"""Validate child-review identity and rollout capability; never infer review truth."""
import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read(path):
    value = json.loads(Path(path).read_text())
    require(isinstance(value, dict), "expected JSON object")
    return value


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def identity(value):
    keys = {"repo", "child_ref", "child_head", "epic_ref", "epic_head", "context_sha256"}
    require(isinstance(value, dict) and set(value) == keys, "incomplete review identity")
    require(all(nonempty(v) for v in value.values()), "empty identity field")
    for key in ("child_head", "epic_head"):
        require(re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", value[key]), f"invalid {key}")
    require(re.fullmatch(r"[0-9a-f]{64}", value["context_sha256"]), "invalid context hash")
    require(value["child_ref"] != value["epic_ref"], "child and epic refs must differ")
    return value


def check(record, current):
    require(type(record.get("schema")) is int and record["schema"] == 1, "unsupported review schema")
    reviewed = identity(record.get("identity"))
    live = identity(current.get("identity"))
    require(reviewed == live, "stale review identity; Frontier renewal required")
    require(current.get("clean_worktree") is True, "worktree is dirty or unknown")
    require(current.get("current_with_epic") is True, "child is not current with epic")
    require(current.get("canon_ready") is True, "prior coherence publication or ruling is pending/unknown")
    require(record.get("correctness") == "Approved", "correctness is not approved")
    coherence = record.get("coherence", {})
    require(isinstance(coherence, dict), "invalid coherence record")
    require(coherence.get("verdict") in {"ALIGNED", "MINOR_DRIFT", "LEGITIMATE_DIVERGENCE"},
            "coherence does not permit action")
    require(coherence.get("flags") == [], "missing flags or unresolved Gate 1 flag")
    executor = record.get("executor", {})
    require(isinstance(executor, dict), "invalid executor record")
    require(executor.get("tier") == "Frontier" and executor.get("policy") == "hard"
            and executor.get("qualified") is True, "qualified hard Frontier evidence required")
    require(all(nonempty(executor.get(k)) for k in ("model", "effort", "evidence")),
            "missing native executor provenance")
    verification = record.get("verification", {})
    require(isinstance(verification, dict), "invalid verification record")
    require(verification.get("status") == "passed"
            and verification.get("head") == live["child_head"]
            and verification.get("local_ci_head") == live["child_head"]
            and nonempty(verification.get("evidence")), "verification does not cover child HEAD")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    check_parser = sub.add_parser("check")
    check_parser.add_argument("review")
    check_parser.add_argument("current")
    context_parser = sub.add_parser("context")
    context_parser.add_argument("snapshot")
    sub.add_parser("require-kernel")
    args = parser.parse_args()
    try:
        if args.command == "require-kernel":
            if os.environ.get("FLORIST_UNIT"):
                require(os.environ.get("FLORIST_CHILD_REVIEW_CONTRACT") == "frontier-pre-pr-v1",
                        "Florist child-review companion is not enabled; blocked reason=worker-blocked")
            print("child-review kernel capability ok")
        elif args.command == "context":
            snapshot = read(args.snapshot)
            required = {"epic_id", "approved_intent", "gate1_signoff", "canon",
                        "register_entries", "siblings", "spec", "plan"}
            require(required <= snapshot.keys(), "incomplete context snapshot")
            require(all(snapshot[k] is not None for k in required), "unknown context input")
            payload = json.dumps(snapshot, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
            print(hashlib.sha256(payload.encode()).hexdigest())
        else:
            check(read(args.review), read(args.current))
            print("child-review coverage current")
    except (ValueError, OSError, TypeError) as exc:
        print(f"child-review gate: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
