from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from omagent_core.dictation_state import DictationState, DictationStateError, transition
from omagent_core.retrieval import Source, assess_retrieval, grounded_context
from omagent_core.screenshot_policy import ScreenshotPolicyError, validate_screenshot_target, validate_workspace_output
from omagent_core.text import assemble_stream, limit_request


class AnswerIntegrityTests(unittest.TestCase):
    def test_stream_assembly_preserves_fragment_boundaries_and_whitespace(self):
        self.assertEqual(assemble_stream(["Hello", " ", "world\n", "next"]), "Hello world\nnext")
        self.assertEqual(limit_request("x" * 2501)[1], True)

    def test_retrieval_failure_is_explicit_and_grounded_context_requires_sources(self):
        failure = assess_retrieval("current question", [])
        self.assertFalse(failure.usable)
        with self.assertRaises(ValueError):
            grounded_context(failure)
        result = assess_retrieval("current question", [Source("https://example.test/a", "A", "fact", "high")])
        self.assertTrue(result.usable)
        self.assertIn("fact", grounded_context(result))

    def test_retrieval_rejects_non_http_and_empty_sources(self):
        result = assess_retrieval("q", [Source("file:///etc/passwd", "bad", "secret", "high"), Source("https://example.test/empty", "empty", "", "high")])
        self.assertFalse(result.usable)
        self.assertEqual(len(result.warnings), 2)

    def test_screenshot_policy_rejects_unsafe_targets_and_outputs(self):
        with self.assertRaises(ScreenshotPolicyError):
            validate_screenshot_target("file:///etc/passwd", workspace=Path("/tmp"))
        with self.assertRaises(ScreenshotPolicyError):
            validate_screenshot_target("https://evil.test", workspace=Path("/tmp"), allowed_hosts={"localhost"})
        with tempfile.TemporaryDirectory(prefix="omagent-shot-") as directory:
            workspace = Path(directory)
            self.assertEqual(validate_workspace_output(workspace / "shot.png", workspace=workspace), (workspace / "shot.png").resolve())
            with self.assertRaises(ScreenshotPolicyError):
                validate_workspace_output(Path(directory).parent / "outside.png", workspace=workspace)

    def test_dictation_state_follows_backend_transitions(self):
        self.assertEqual(transition(DictationState.IDLE, DictationState.STARTING), DictationState.STARTING)
        self.assertEqual(transition(DictationState.STARTING, DictationState.LISTENING), DictationState.LISTENING)
        with self.assertRaises(DictationStateError):
            transition(DictationState.IDLE, DictationState.LISTENING)


if __name__ == "__main__":
    unittest.main()
