"""Temporary HOME and PATH helpers for tests that inspect the router."""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path


@contextmanager
def isolated_process_env():
    """Run a child process with empty user configuration and fake binaries."""
    plugin = Path(__file__).resolve().parents[2]
    with tempfile.TemporaryDirectory(prefix="omagent-test-") as directory:
        root = Path(directory)
        home = root / "home"
        fake_bin = root / "bin"
        home.mkdir()
        fake_bin.mkdir()
        env = {
            "HOME": str(home),
            "PATH": f"{fake_bin}:/usr/bin:/bin",
            "LANG": "C.UTF-8",
            "PYTHONPATH": str(plugin),
        }
        yield env, root


def run_router(args: list[str], env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    router = Path(__file__).resolve().parents[2] / "omagent-route"
    return subprocess.run(
        [sys.executable, str(router), *args],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
