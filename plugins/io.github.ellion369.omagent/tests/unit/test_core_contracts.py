from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from omagent_core.config import ConfigError, load_config
from omagent_core.identity import RunIdentity
from omagent_core.protocol import EventType, ProtocolError, make_event, validate_event


PLUGIN = Path(__file__).resolve().parents[2]


class CoreContractTests(unittest.TestCase):
    def test_config_merges_nested_values_and_rejects_unknown_shape(self):
        with tempfile.TemporaryDirectory(prefix="omagent-config-") as directory:
            path = Path(directory) / "config.json"
            path.write_text(json.dumps({"quality": {"repair_attempts": 3}}), encoding="utf-8")
            config = load_config(path)
        self.assertEqual(config["quality"]["repair_attempts"], 3)
        with self.assertRaises(ConfigError):
            load_config(Path("/does/not/exist"), required=True)

    def test_harness_catalog_is_valid_and_has_one_default_per_harness(self):
        catalog = json.loads((PLUGIN / "config" / "harnesses.json").read_text(encoding="utf-8"))
        self.assertEqual(catalog["schema_version"], 1)
        for harness in catalog["harnesses"]:
            self.assertTrue(harness["id"])
            self.assertTrue(harness["defaultModel"])
            self.assertTrue(harness["models"])

    def test_event_requires_ordered_identity_and_known_kind(self):
        identity = RunIdentity(
            conversation_id="conversation-1",
            run_id="run-1",
            parent_run_id=None,
            attempt_id=None,
            provider_session_id=None,
        )
        event = make_event(identity, 1, EventType.STATUS, {"text": "working"})
        self.assertEqual(validate_event(event), [])
        invalid = dict(event)
        invalid["sequence"] = 0
        with self.assertRaises(ProtocolError):
            validate_event(invalid)


if __name__ == "__main__":
    unittest.main()
