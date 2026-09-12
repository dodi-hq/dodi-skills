#!/usr/bin/env python3
"""Validate a spec-bound planner handoff; never assess complexity or approval."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys


SEATS = {
    "standard": ("sonnet", "session-default", "none"),
    "capable": ("opus", "high", "none"),
    "frontier": ("fable", "xhigh", "deferred"),
}
FIELDS = {"schema", "spec_path", "spec_sha256", "planner_tier", "reason", "source", "review_ref"}


def spec_identity(spec_path):
    path = Path(spec_path)
    if (not spec_path or path.is_absolute() or path.as_posix() != spec_path
            or ".." in path.parts or not path.resolve().is_relative_to(Path.cwd().resolve())):
        raise ValueError("spec path must be a canonical repository-relative path")
    return hashlib.sha256(path.read_bytes()).hexdigest()


def legacy_tier(mode, epic_tier):
    return "capable" if mode == "autonomous" and epic_tier != "capable" else "frontier"


def validate(record, spec_path, mode, epic_tier):
    if not isinstance(record, dict) or set(record) != FIELDS:
        raise ValueError("incomplete or unknown planner-routing fields")
    if type(record["schema"]) is not int or record["schema"] != 1:
        raise ValueError("planner-routing schema must be 1")
    for key in FIELDS - {"schema"}:
        if not isinstance(record[key], str) or not record[key].strip():
            raise ValueError(f"{key} must be a nonempty string")
    if len(record["reason"]) > 2000:
        raise ValueError("planner reason must be concise (at most 2000 characters)")
    if record["planner_tier"] not in SEATS or record["source"] not in ("spec-review", "legacy-policy"):
        raise ValueError("invalid planner tier or source")
    if record["spec_path"] != spec_path or not re.fullmatch(r"[0-9a-f]{64}", record["spec_sha256"]):
        raise ValueError("invalid spec identity")
    if record["spec_sha256"] != spec_identity(spec_path):
        raise ValueError("stale planner routing: spec content changed")
    if record["source"] == "legacy-policy" and record["planner_tier"] != legacy_tier(mode, epic_tier):
        raise ValueError("legacy fallback does not match the previous writer policy")
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("require-kernel")
    check = sub.add_parser("check")
    check.add_argument("record")
    check.add_argument("spec_path")
    check.add_argument("--also", action="append", default=[])
    legacy = sub.add_parser("legacy")
    legacy.add_argument("spec_path")
    legacy.add_argument("--review-ref", required=True)
    for command in (check, legacy):
        command.add_argument("--mode", choices=("manual", "autonomous"), required=True)
        command.add_argument("--epic-tier", choices=("standard", "capable"))
    args = parser.parse_args()
    try:
        if args.command == "require-kernel":
            if os.environ.get("FLORIST_UNIT") and os.environ.get("FLORIST_PLANNER_ROUTING_CONTRACT") != "spec-review-planner-v1":
                raise ValueError("missing planner transport capability; blocked reason=worker-blocked")
            print("planner transport available" if os.environ.get("FLORIST_UNIT") else "manual mode: kernel not required")
            return 0
        if args.command == "legacy":
            record = {
                "schema": 1, "spec_path": args.spec_path,
                "spec_sha256": spec_identity(args.spec_path),
                "planner_tier": legacy_tier(args.mode, args.epic_tier),
                "reason": "Approved legacy spec has no planner classification; retaining the previous writer policy.",
                "source": "legacy-policy", "review_ref": args.review_ref,
            }
            validate(record, args.spec_path, args.mode, args.epic_tier)
            print(json.dumps(record, sort_keys=True))
        else:
            record = validate(json.loads(Path(args.record).read_text()), args.spec_path, args.mode, args.epic_tier)
            for other_path in args.also:
                other = validate(json.loads(Path(other_path).read_text()), args.spec_path, args.mode, args.epic_tier)
                if other != record:
                    raise ValueError("conflicting planner-routing records; establish the authoritative review")
            alias, effort, policy = SEATS[record["planner_tier"]]
            print(json.dumps({"planner_tier": record["planner_tier"], "model_alias": alias,
                              "declared_effort": effort, "frontier_policy": policy,
                              "source": record["source"], "spec_sha256": record["spec_sha256"]}, sort_keys=True))
        return 0
    except (ValueError, OSError, TypeError) as exc:
        print(f"planner-routing: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
