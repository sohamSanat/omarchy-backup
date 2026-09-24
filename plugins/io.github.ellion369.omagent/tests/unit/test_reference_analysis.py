from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from omagent_core.reference_analysis import ANALYZER_VERSION, inspect_reference, reference_cache_key


class ReferenceAnalysisTests(unittest.TestCase):
    def test_fingerprint_changes_when_image_bytes_change(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "reference.png"
            path.write_bytes(b"first")
            first = inspect_reference(path, image_id="reference.png")
            path.write_bytes(b"second")
            second = inspect_reference(path, image_id="reference.png")
        self.assertNotEqual(first.evidence_fingerprint, second.evidence_fingerprint)
        self.assertEqual(first.analyzer_version, ANALYZER_VERSION)
        self.assertIn("subject", first.as_dict())

    def test_cache_key_uses_content_not_mutable_filename_only(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "reference.png"
            path.write_bytes(b"stable")
            key = reference_cache_key(path)
        self.assertIn(ANALYZER_VERSION, key)
        self.assertIn("reference.png", key)


if __name__ == "__main__":
    unittest.main()
