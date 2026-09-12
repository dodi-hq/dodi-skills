#!/usr/bin/env python3
"""Regression checks for stale approvals, tier fallback and rollout refusal."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "child-review-gate.py"
spec = importlib.util.spec_from_file_location("child_review_gate", SCRIPT)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class ChildReviewGateTests(unittest.TestCase):
    def setUp(self):
        self.identity = dict(repo="example/repo", child_ref="unit/child", child_head="a" * 40,
                             epic_ref="epic/example", epic_head="b" * 40, context_sha256="c" * 64)
        self.record = dict(schema=1, identity=self.identity, correctness="Approved",
                           coherence=dict(verdict="ALIGNED", flags=[]),
                           executor=dict(tier="Frontier", policy="hard", qualified=True,
                                         model="native-model", effort="native-effort", evidence="report:1"),
                           verification=dict(head="a" * 40, local_ci_head="a" * 40,
                                             status="passed", evidence="ci:1"))
        self.current = dict(identity=copy.deepcopy(self.identity), clean_worktree=True,
                            current_with_epic=True, canon_ready=True)

    def test_unchanged_and_reused_approval(self):
        gate.check(self.record, self.current)
        gate.check(self.record, copy.deepcopy(self.current))

    def test_each_identity_change_invalidates_even_at_same_child_head(self):
        for key in self.identity:
            with self.subTest(key=key):
                current = copy.deepcopy(self.current)
                current["identity"][key] = "d" * len(self.identity[key])
                with self.assertRaises(ValueError):
                    gate.check(self.record, current)

    def test_missing_fields_and_legacy_head_only_review_fail_closed(self):
        for field in self.record:
            with self.subTest(field=field):
                record = copy.deepcopy(self.record)
                del record[field]
                with self.assertRaises(ValueError):
                    gate.check(record, self.current)

    def test_no_lower_tier_or_soft_substitution(self):
        for field, value in [("tier", "Capable"), ("policy", "soft"),
                             ("qualified", False), ("evidence", ""), ("model", "")]:
            record = copy.deepcopy(self.record)
            record["executor"][field] = value
            with self.assertRaises(ValueError):
                gate.check(record, self.current)

    def test_drift_flags_and_unresolved_correctness_block(self):
        for verdict in ["MATERIAL_DRIFT", "ALREADY_REVIEWED", "GATE1_REFRESH"]:
            self.record["coherence"]["verdict"] = verdict
            with self.assertRaises(ValueError):
                gate.check(self.record, self.current)
        self.record["coherence"] = dict(verdict="ALIGNED", flags=["GATE1_AMENDMENT"])
        with self.assertRaises(ValueError):
            gate.check(self.record, self.current)
        self.record["coherence"]["flags"] = []
        self.record["correctness"] = "Issues Found"
        with self.assertRaises(ValueError):
            gate.check(self.record, self.current)

    def test_ci_head_and_dirty_or_stale_base_block(self):
        self.record["verification"]["local_ci_head"] = "d" * 40
        with self.assertRaises(ValueError):
            gate.check(self.record, self.current)
        self.record["verification"]["local_ci_head"] = "a" * 40
        for key in ("clean_worktree", "current_with_epic", "canon_ready"):
            current = copy.deepcopy(self.current)
            current[key] = False
            with self.assertRaises(ValueError):
                gate.check(self.record, current)

    def test_kernel_capability_required_but_not_in_manual_mode(self):
        env = {k: v for k, v in os.environ.items() if not k.startswith("FLORIST_")}
        for unit, capability, expected in [(None, None, 0), ("child", None, 2),
                                           ("child", "old", 2),
                                           ("child", "frontier-pre-pr-v1", 0)]:
            case = dict(env)
            if unit:
                case["FLORIST_UNIT"] = unit
            if capability:
                case["FLORIST_CHILD_REVIEW_CONTRACT"] = capability
            result = subprocess.run([sys.executable, str(SCRIPT), "require-kernel"],
                                    env=case, capture_output=True, text=True)
            self.assertEqual(expected, result.returncode, result.stderr)

    def test_context_hash_key_order_stable_content_sensitive_and_missing_rejected(self):
        snapshot = dict(epic_id="epic", approved_intent="intent", gate1_signoff="yes",
                        canon="no prior canon", register_entries=[], siblings=[], spec="é", plan="plan")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "context.json"
            def digest(value):
                path.write_text(json.dumps(value))
                return subprocess.run([sys.executable, str(SCRIPT), "context", str(path)],
                                      capture_output=True, text=True)
            first = digest(snapshot)
            self.assertEqual(0, first.returncode)
            reordered = dict(reversed(list(snapshot.items())))
            self.assertEqual(first.stdout, digest(reordered).stdout)
            changed = dict(snapshot, canon="new decision")
            self.assertNotEqual(first.stdout, digest(changed).stdout)
            del changed["canon"]
            self.assertEqual(2, digest(changed).returncode)


if __name__ == "__main__":
    unittest.main()
