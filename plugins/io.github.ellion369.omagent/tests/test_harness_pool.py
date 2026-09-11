#!/usr/bin/env python3
"""Sandboxed regression suite for harness_pool.select_harness decision table.
All persistent state is redirected to a tmp dir; no network calls. Every
sandbox() call resets all monkeypatches to the originals first, so no state
leaks between tests."""
import json
import sys
import tempfile
from pathlib import Path

PLUGIN = Path("/home/soham/.config/omarchy/plugins/io.github.ellion369.omagent")
sys.path.insert(0, str(PLUGIN))
import harness_pool as hp  # noqa: E402

# Preserve pristine originals so each test starts un-patched
ORIGINALS = {name: getattr(hp, name) for name in (
    "check_agy_quota", "_verify_and_rank", "probe_providers",
    "_sticky_state", "_save_sticky_state")}

TMP = Path(tempfile.mkdtemp(prefix="hp_test_"))
hp.STATE_DIR = TMP
hp.HARNESS_STATE = TMP / "harness_state.json"
hp.QUOTA_CACHE = TMP / "quota_cache.json"
hp.POOL_PATH = TMP / "model_pool.json"
hp.CLINE_PROBE_CACHE = TMP / "cline_probe.json"
hp.AUDIT_LOG = TMP / "audit.log"

BASE_POOL = {"version": 1, "models": [
    {"id": "kilo/poolside/laguna-s-2.1:free", "provider": "kilo", "free": True, "auth": "none",
     "agentic_score": 9.2, "tb21": 70.2, "status": "active"},
    {"id": "opencode/big-pickle", "provider": "opencode", "free": True, "auth": "none",
     "agentic_score": 8.1, "tb21": 61.8, "status": "active"},
    {"id": "kilo/muse-spark-1.3:free", "provider": "kilo", "free": True, "auth": "none",
     "agentic_score": 7.0, "tb21": None, "status": "active"},
]}
PROBES = {"kilo": {"binary": True, "free_tier": True, "account_authed": False},
          "opencode": {"binary": True, "free_tier": True, "account_authed": False},
          "cline": {"binary": True, "available": False, "reason": "balance $0.00"},
          "agy": {"binary": True}}
EXH = {"state": "exhausted", "hourly_used_pct": 96.0, "weekly_used_pct": 10.0,
       "resets_at": "2026-09-09T18:42:00Z", "detail": "test"}
HEALTHY = {"state": "healthy", "hourly_used_pct": 40.0, "weekly_used_pct": 8.0,
           "resets_at": None, "detail": "test"}
UNKNOWN = {"state": "unknown", "hourly_used_pct": None, "weekly_used_pct": None,
           "resets_at": None, "detail": "test"}

PASS = FAIL = 0


def sandbox(quota, *, config_overrides=None, sticky=None, fresh_quota=None,
            verify_override=None, probes=None, pool=None):
    """Resets all patches, then applies this test's overrides."""
    for name, fn in ORIGINALS.items():
        setattr(hp, name, fn)
    hp.POOL_PATH.write_text(json.dumps(pool or BASE_POOL))
    if hp.HARNESS_STATE.exists():
        hp.HARNESS_STATE.unlink()
    hp._sticky_state = lambda: (sticky or {})
    saved = {}
    hp._save_sticky_state = lambda s: saved.update({"sticky": s})
    hp.probe_providers = lambda: (probes or PROBES)
    if fresh_quota is not None:
        hp.check_agy_quota = lambda c, force=False: fresh_quota
    if verify_override is not None:
        hp._verify_and_rank = verify_override
    cfg = json.loads(json.dumps(hp.DEFAULT_CONFIG))
    cfg["pool_refresh"]["enabled"] = False  # keep tests offline/deterministic
    for k, v in (config_overrides or {}).items():
        cfg[k] = v
    return hp.select_harness(cfg, quota), saved


def check(name, cond, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print(f"  PASS {name}")
    else:
        FAIL += 1
        print(f"  FAIL {name} {detail}")


print("1. healthy -> agy, sticky cleared")
d, s = sandbox(HEALTHY)
check("use_agy", d["use_agy"] is True)
check("model", d["model"] == "gemini-3.8-flash-high")
check("sticky cleared", s.get("sticky") == {})

print("2. 5h 96% -> failover to top-ranked kilo/laguna")
d, s = sandbox(EXH)
check("failover", d["use_agy"] is False)
check("winner", d["model"] == "kilo/poolside/laguna-s-2.1:free", d.get("model"))
check("sticky saved", s.get("sticky", {}).get("model") == "kilo/poolside/laguna-s-2.1:free")
check("sticky until=reset", s.get("sticky", {}).get("until") == "2026-09-09T18:42:00Z")

print("3. weekly 97% only -> failover")
w = dict(EXH, hourly_used_pct=50.0, weekly_used_pct=97.0)
d, _ = sandbox(w)
check("failover", d["use_agy"] is False and "weekly" in " ".join(d["bullets"]))

print("4. unknown + trust-agy + no sticky -> agy (strict rule)")
d, _ = sandbox(UNKNOWN, config_overrides={"quota_check": {"unknown_policy": "trust-agy"}})
check("use_agy", d["use_agy"] is True and "strict" in d["reason"])

print("5. unknown + fallback policy -> failover (safe side)")
d, _ = sandbox(UNKNOWN, config_overrides={"quota_check": {"unknown_policy": "fallback"}})
check("failover", d["use_agy"] is False)

print("6. sticky continuation + unknown quota -> stays on pool")
d, _ = sandbox(UNKNOWN, sticky={"mode": "fallback", "provider": "kilo",
                                "model": "kilo/poolside/laguna-s-2.1:free"},
               config_overrides={"quota_check": {"unknown_policy": "trust-agy"}})
check("stays failed over", d["use_agy"] is False)

print("7. stale exhaustion reversed by fresh healthy probe -> agy")
d, _ = sandbox(EXH, fresh_quota=HEALTHY)
joined = (d["reason"] + " " + " ".join(d["bullets"])).lower()
check("reversed", d["use_agy"] is True and "reversed" in joined)

print("8. expired sticky + unknown + trust-agy -> return to agy")
d, s = sandbox(UNKNOWN, sticky={"mode": "fallback", "until": "2020-01-01T00:00:00Z"},
               config_overrides={"quota_check": {"unknown_policy": "trust-agy"}})
check("back to agy", d["use_agy"] is True)
check("sticky wiped", s.get("sticky") == {})

print("9. all providers down -> agy + remedy")
down = {k: dict(v, binary=False) for k, v in PROBES.items()}
d, _ = sandbox(EXH, probes=down)
check("agy last resort", d["use_agy"] is True and d.get("remedy") is True)

print("10. unscored pool -> best-by-tiebreak + honest note")
unscored_pool = {"version": 1, "models": [
    dict(m, agentic_score=None, tb21=None) for m in BASE_POOL["models"]]}
d, _ = sandbox(EXH, pool=unscored_pool)
check("tiebreak pick", d["model"] == "kilo/poolside/laguna-s-2.1:free", d.get("model"))
check("unscored note", any("unscored" in b for b in d["bullets"]))

print("11. audit log one line per decision")
n_lines = len(hp.AUDIT_LOG.read_text().strip().splitlines()) if hp.AUDIT_LOG.exists() else 0
check("audit lines >= 10", n_lines >= 10, f"got {n_lines}")

print("12. verify promotion wiring (dead top pick -> next ranked)")
def fake_verify(winner, candidates, config):
    nxt = next(m for m in candidates if m["id"] == "opencode/big-pickle")
    return nxt, "Top-ranked model failed verification (probe dead) — promoted `opencode/big-pickle` (score 8.1/10)"
d, _ = sandbox(EXH, fresh_quota=EXH, verify_override=fake_verify,
               config_overrides={"pool_refresh": {"enabled": True, "on_failover": True, "max_age_s": 86400}})
check("promoted winner", d["model"] == "opencode/big-pickle", d.get("model"))
check("promoted flag", d.get("promoted_past_dead_pick") is True)
check("verify note in bullets", any("failed verification" in b for b in d["bullets"]))

print("13. dispatch adapters (shlex quoting)")
q = hp.build_launch_cmd("kilo", "kilo/poolside/laguna-s-2.1:free", "task one")
check("kilo cmd", q == "kilo run -m kilo/poolside/laguna-s-2.1:free 'task one'\n", repr(q))
check("opencode cmd", hp.build_launch_cmd("opencode", "opencode/big-pickle", "t").startswith("opencode run -m opencode/big-pickle"))
check("cline cmd", hp.build_launch_cmd("cline", "x", "t").startswith("cline --auto-approve true"))
check("agy cmd", hp.build_launch_cmd("agy", "gemini-3.8-flash-high", "t").startswith("agy --model gemini-3.8-flash-high"))

print(f"\n{'=' * 46}\nRESULT: {PASS} passed, {FAIL} failed  (sandbox: {TMP})")
sys.exit(1 if FAIL else 0)
