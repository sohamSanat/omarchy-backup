from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover - environment capability probe
    Image = None

from omagent_core.visual_qa import evaluate_visual_evidence, hash_distance, image_signature


class VisualQATests(unittest.TestCase):
    @unittest.skipIf(Image is None, "Pillow is not installed")
    def test_near_duplicate_render_is_blocked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = root / "first.png"
            second = root / "second.png"
            Image.new("RGB", (320, 180), (240, 240, 240)).save(first)
            Image.new("RGB", (320, 180), (241, 240, 240)).save(second)
            result = evaluate_visual_evidence([second], recent_runs=[{"rendered": [str(first)]}])
            self.assertFalse(result.passed)
            self.assertIn("template convergence", " ".join(result.blocking))
            self.assertLessEqual(hash_distance(image_signature(first), image_signature(second)), 6)

    @unittest.skipIf(Image is None, "Pillow is not installed")
    def test_product_family_reuse_is_not_treated_as_unrelated_duplicate(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = root / "first.png"
            second = root / "second.png"
            Image.new("RGB", (320, 180), (240, 240, 240)).save(first)
            Image.new("RGB", (320, 180), (240, 240, 240)).save(second)
            result = evaluate_visual_evidence(
                [second],
                recent_runs=[{"product_family": "acme", "rendered": [str(first)]}],
                product_family="acme",
            )
        self.assertTrue(result.passed)

    @unittest.skipIf(Image is None, "Pillow is not installed")
    def test_no_rendered_evidence_is_unavailable(self):
        result = evaluate_visual_evidence([])
        self.assertFalse(result.available)
        self.assertFalse(result.passed)
        self.assertIn("no rendered evidence", result.errors[0])


if __name__ == "__main__":
    unittest.main()
