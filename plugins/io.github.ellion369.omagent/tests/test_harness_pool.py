#!/usr/bin/env python3
"""Offline regression tests for harness_pool decision and launch behavior."""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

PLUGIN = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PLUGIN))
import harness_pool as hp  # noqa: E402


BASE_POOL = {
    "version": 1,
    "models": [
        {"id": "kilo/unsupported-free", "provider": "kilo", "free": True, "auth": "none", "agentic_score": 9.9, "tb21": 99.0, "status": "active"},
        {"id": "opencode/big-pickle", "provider": "opencode", "free": True, "auth": "none", "agentic_score": 8.1, "tb21": 61.8, "status": "active"},
        {"id": "cline/glm-5.3-flash", "provider": "cline", "free": True, "auth": "none", "agentic_score": 7.0, "tb21": None, "status": "active"},
    ],
}
PROBES = {
    "kilo": {"binary": True, "free_tier": True, "account_authed": False},
    "opencode": {"binary": True, "free_tier": True, "account_authed": False},
    "cline": {"binary": True, "available": True, "reason": "fixture"},
    "agy": {"binary": True},
}
HEALTHY = {"state": "healthy", "hourly_used_pct": 40.0, "weekly_used_pct": 8.0, "resets_at": None, "detail": "fixture"}
EXHAUSTED = {"state": "exhausted", "hourly_used_pct": 96.0, "weekly_used_pct": 10.0, "resets_at": "2026-09-09T18:42:00Z", "detail": "fixture"}


class HarnessPoolTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory(prefix="hp_test_")
        root = Path(self.temp_dir.name)
        self.originals = {name: getattr(hp, name) for name in ("STATE_DIR", "HARNESS_STATE", "QUOTA_CACHE", "POOL_PATH", "CLINE_PROBE_CACHE", "AUDIT_LOG", "MODEL_PROBE_CACHE", "PROBE_FAIL_CACHE", "probe_providers", "check_agy_quota", "refresh_pool", "_verify_and_rank", "_probe_model", "_annotate_pool_model")}
        hp.STATE_DIR = root
        hp.HARNESS_STATE = root / "harness_state.json"
        hp.QUOTA_CACHE = root / "quota_cache.json"
        hp.POOL_PATH = root / "model_pool.json"
        hp.CLINE_PROBE_CACHE = root / "cline_probe.json"
        hp.AUDIT_LOG = root / "audit.log"
        hp.MODEL_PROBE_CACHE = root / "model_probe.json"
        hp.PROBE_FAIL_CACHE = root / "probe_failures.json"
        hp.POOL_PATH.write_text(json.dumps(BASE_POOL), encoding="utf-8")
        hp._sticky_state = lambda: {}
        hp._save_sticky_state = lambda _state: None
        hp.probe_providers = lambda _providers=None: dict(PROBES)
        hp.check_agy_quota = lambda _config, force=False: dict(EXHAUSTED)
        hp.refresh_pool = lambda: {"added": [], "pruned": []}
        self.config = json.loads(json.dumps(hp.DEFAULT_CONFIG))
        self.config["pool_refresh"]["enabled"] = False
        self.config["quota_check"]["unknown_policy"] = "trust-agy"

    def tearDown(self) -> None:
        for name, value in self.originals.items():
            setattr(hp, name, value)
        self.temp_dir.cleanup()

    def test_healthy_quota_keeps_agy(self):
        hp.check_agy_quota = lambda _config, force=False: dict(HEALTHY)
        decision = hp.select_harness(self.config)
        self.assertTrue(decision["use_agy"])
        self.assertEqual(decision["provider"], "agy")

    def test_unsupported_kilo_is_never_selected(self):
        decision = hp.select_harness(self.config, dict(EXHAUSTED))
        self.assertFalse(decision["use_agy"])
        self.assertEqual(decision["provider"], "opencode")
        self.assertNotEqual(decision["provider"], "kilo")

    def test_all_supported_providers_down_keeps_agy_as_remedy(self):
        hp.probe_providers = lambda _providers=None: {"opencode": {"binary": False}, "cline": {"binary": True, "available": False}, "agy": {"binary": True}}
        decision = hp.select_harness(self.config, dict(EXHAUSTED))
        self.assertTrue(decision["use_agy"])
        self.assertTrue(decision["remedy"])

    def test_probe_workspace_is_disposable_and_drops_host_credentials(self):
        with hp._isolated_probe_workspace() as (env, home, workspace):
            self.assertNotEqual(env["HOME"], str(Path.home()))
            self.assertTrue(home.is_dir())
            self.assertTrue(workspace.is_dir())
            self.assertTrue(env["HOME"].startswith(str(home)))
            self.assertNotIn("GEMINI_API_KEY", env)
            self.assertNotIn("AWS_ACCESS_KEY_ID", env)
            self.assertNotIn("NETRC", env)
            self.assertEqual(env["OMAGENT_PROBE"], "1")

    def test_model_probe_retries_transient_failures_with_a_bound(self):
        calls = []

        def probe(*args):
            calls.append(args[0])
            if len(calls) == 1:
                return False, False, "temporary gateway timeout"
            return True, True, "chat + agentic tool-use verified"

        original_probe = hp._probe_model
        hp._probe_model = probe
        try:
            result = hp._probe_model_with_retries("opencode", "opencode/model", 1, 1, True, attempts=2)
        finally:
            hp._probe_model = original_probe
        self.assertEqual(calls, ["opencode", "opencode"])
        self.assertEqual(result[:2], (True, True))

    def test_selection_never_refreshes_the_mutable_model_pool(self):
        self.config["pool_refresh"]["enabled"] = True
        hp._verify_and_rank = lambda winner, _candidates, _config: (winner, None)
        original_refresh = hp.refresh_pool
        calls = []
        hp.refresh_pool = lambda: calls.append(True)
        try:
            decision = hp.select_harness(self.config, dict(EXHAUSTED))
        finally:
            hp.refresh_pool = original_refresh
        self.assertEqual(calls, [])
        self.assertFalse(decision["use_agy"])
        self.assertEqual(decision["provider"], "opencode")

    def test_live_selection_verification_does_not_annotate_the_model_pool(self):
        self.config["pool_refresh"]["enabled"] = True
        original_probe = hp._probe_model
        hp._probe_model = lambda *_args: (True, True, "chat + agentic tool-use verified")
        original_annotate = hp._annotate_pool_model
        hp._annotate_pool_model = lambda *_args, **_kwargs: (_ for _ in ()).throw(AssertionError("selection must not annotate the pool"))
        try:
            decision = hp.select_harness(self.config, dict(EXHAUSTED))
        finally:
            hp._probe_model = original_probe
            hp._annotate_pool_model = original_annotate
        self.assertFalse(decision["use_agy"])
        self.assertEqual(decision["provider"], "opencode")

    def test_all_live_probes_failed_blocks_fallback_dispatch(self):
        self.config["pool_refresh"]["enabled"] = True
        hp._verify_and_rank = lambda _winner, _candidates, _config: (None, "**Live verification failed for every ranked free model**")
        decision = hp.select_harness(self.config, dict(EXHAUSTED))
        self.assertTrue(decision["use_agy"])
        self.assertEqual(decision["provider"], "agy")
        self.assertTrue(decision["remedy"])

    def test_launch_commands_keep_auto_approval_and_reject_kilo(self):
        self.assertTrue(hp.build_launch_cmd("opencode", "opencode/big-pickle", "task").startswith("opencode run --auto"))
        self.assertTrue(hp.build_launch_cmd("cline", "x", "task").startswith("cline --auto-approve true"))
        self.assertNotIn("--auto", hp.build_launch_cmd("opencode", "opencode/big-pickle", "task", auto_approve=False))
        self.assertNotIn("--auto-approve", hp.build_launch_cmd("cline", "x", "task", auto_approve=False))
        with self.assertRaises(ValueError):
            hp.build_launch_cmd("kilo", "kilo/model", "task")


if __name__ == "__main__":
    unittest.main()
