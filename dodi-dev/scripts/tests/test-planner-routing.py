#!/usr/bin/env python3
"""Observable planner identity, routing, fallback and compatibility checks."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "planner-routing.py"


class PlannerRoutingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.spec = "docs/specs/TEST-contract.md"
        path = self.root / self.spec
        path.parent.mkdir(parents=True)
        path.write_bytes(b"Approved interface and failure behavior.\n")
        self.record = {
            "schema": 1, "spec_path": self.spec,
            "spec_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "planner_tier": "standard", "reason": "Familiar settled decomposition.",
            "source": "spec-review", "review_ref": "review:approved-1",
        }

    def run_cli(self, *args, env=None):
        clean_env = {k: v for k, v in os.environ.items() if not k.startswith("FLORIST_")}
        return subprocess.run([sys.executable, "-B", str(SCRIPT), *args], cwd=self.root,
                              env={**clean_env, **(env or {})}, text=True, capture_output=True)

    def check(self, record=None, mode="manual", extra=()):
        (self.root / "routing.json").write_text(json.dumps(self.record if record is None else record))
        return self.run_cli("check", "routing.json", self.spec, "--mode", mode, *extra)

    def test_each_selected_tier_overrides_epic_default_and_has_explicit_pin(self):
        expected = {"standard": ("sonnet", "session-default", "none"),
                    "capable": ("opus", "high", "none"),
                    "frontier": ("fable", "xhigh", "deferred")}
        for tier, seat in expected.items():
            for epic in ("standard", "capable"):
                result = self.check({**self.record, "planner_tier": tier}, "autonomous", ("--epic-tier", epic))
                self.assertEqual(result.returncode, 0, result.stderr)
                output = json.loads(result.stdout)
                self.assertEqual(tuple(output[k] for k in ("model_alias", "declared_effort", "frontier_policy")), seat)
                self.assertNotIn("delivery_tier", output)

    def test_unchanged_spec_reuses_after_plan_only_change(self):
        self.assertEqual(self.check().returncode, 0)
        (self.root / "plan.md").write_text("Revised decomposition, same spec.")
        self.assertEqual(self.check().returncode, 0)

    def test_spec_edit_or_other_path_is_stale(self):
        (self.root / self.spec).write_text("Different approved interface.")
        result = self.check()
        self.assertEqual(result.returncode, 2)
        self.assertIn("stale", result.stderr)
        self.assertEqual(self.check({**self.record, "spec_path": "another.md"}).returncode, 2)

    def test_invalid_values_and_incomplete_new_review_never_fallback(self):
        for field, value in (("planner_tier", "fast"), ("planner_tier", "Standard"),
                             ("reason", " "), ("reason", "x" * 2001), ("review_ref", ""), ("source", "epic-tier"),
                             ("schema", True), ("spec_sha256", "bad")):
            self.assertEqual(self.check({**self.record, field: value}).returncode, 2, field)
        for field in self.record:
            record = dict(self.record)
            del record[field]
            self.assertEqual(self.check(record).returncode, 2, field)
        self.assertEqual(self.check({**self.record, "delivery_tier": "standard"}).returncode, 2)

    def test_missing_or_malformed_file_does_not_infer_legacy(self):
        result = self.run_cli("check", "absent.json", self.spec, "--mode", "manual")
        self.assertEqual(result.returncode, 2)
        (self.root / "malformed.json").write_text("{invalid")
        self.assertEqual(self.run_cli("check", "malformed.json", self.spec, "--mode", "manual").returncode, 2)

    def test_explicit_legacy_fallback_retains_prior_policy(self):
        for mode, epic, tier in (("manual", None, "frontier"), ("autonomous", None, "capable"),
                                 ("autonomous", "standard", "capable"), ("autonomous", "capable", "frontier")):
            extra = ("--epic-tier", epic) if epic else ()
            result = self.run_cli("legacy", self.spec, "--review-ref", "approval:old", "--mode", mode, *extra)
            self.assertEqual(result.returncode, 0, result.stderr)
            record = json.loads(result.stdout)
            self.assertEqual(record["planner_tier"], tier)
            self.assertEqual(record["source"], "legacy-policy")
            self.assertIn("legacy", record["reason"])
            self.assertEqual(self.check(record, mode, extra).returncode, 0)
            self.assertEqual(self.check({**record, "planner_tier": "standard"}, mode, extra).returncode, 2)

    def test_conflicting_unsuperseded_records_reject(self):
        other = self.root / "other.json"
        other.write_text(json.dumps(self.record))
        self.assertEqual(self.check(extra=("--also", "other.json")).returncode, 0)
        other.write_text(json.dumps({**self.record, "planner_tier": "capable"}))
        result = self.check(extra=("--also", "other.json"))
        self.assertEqual(result.returncode, 2)
        self.assertIn("conflicting", result.stderr)

    def test_kernel_capability_is_required_only_in_autonomous_mode(self):
        self.assertEqual(self.run_cli("require-kernel").returncode, 0)
        self.assertEqual(self.run_cli("require-kernel", env={"FLORIST_UNIT": "TEST"}).returncode, 2)
        self.assertEqual(self.run_cli("require-kernel", env={"FLORIST_UNIT": "TEST", "FLORIST_PLANNER_ROUTING_CONTRACT": "old"}).returncode, 2)
        self.assertEqual(self.run_cli("require-kernel", env={"FLORIST_UNIT": "TEST", "FLORIST_PLANNER_ROUTING_CONTRACT": "spec-review-planner-v1"}).returncode, 0)


if __name__ == "__main__":
    unittest.main()
