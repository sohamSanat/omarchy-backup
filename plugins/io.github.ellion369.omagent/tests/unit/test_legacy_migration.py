from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from omagent_core.legacy_migration import migrate_snapshots
from omagent_core.session_store import SessionStore


class LegacyMigrationTests(unittest.TestCase):
    def test_migration_is_idempotent_and_marks_active_records_for_recovery(self):
        with tempfile.TemporaryDirectory(prefix="omagent-migrate-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            snapshots = [
                {"sessionId": "done", "title": "Finished", "runState": "done", "entries": []},
                {"sessionId": "active", "title": "Active", "runState": "running", "runPid": 12, "entries": []},
            ]
            first = migrate_snapshots(store, snapshots)
            self.assertEqual(set(first.imported), {"done", "active"})
            self.assertEqual(first.recovery_required, ["active"])
            second = migrate_snapshots(store, snapshots)
            self.assertEqual(second.imported, [])
            self.assertEqual({item["reason"] for item in second.skipped}, {"already imported"})
            self.assertEqual(store.snapshot("active")["runs"][0]["state"], "recovering")
            store.close()

    def test_malformed_snapshot_is_reported_without_raising(self):
        with tempfile.TemporaryDirectory(prefix="omagent-migrate-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            report = migrate_snapshots(store, [{"title": "missing id"}, "not an object"])
            self.assertFalse(report.ok)
            self.assertEqual(len(report.skipped), 2)
            store.close()


if __name__ == "__main__":
    unittest.main()
