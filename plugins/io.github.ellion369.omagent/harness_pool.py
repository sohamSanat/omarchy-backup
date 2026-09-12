#!/usr/bin/env python3
"""
harness_pool: Quota-aware harness failover for Omagent.

Gate logic:
  - agy (Antigravity CLI) stays the base harness while its 5h AND weekly
    quota usage are both below the trigger threshold (default 95%).
  - When 5h usage >= trigger OR weekly usage >= trigger (or the quota probe
    is unknown, per policy), Omagent fails over to the best-ranked FREE
    model from the cumulative model pool (kilo / opencode / cline).
  - Failover is sticky until the limiting agy window actually resets.

Selection is strict agentic-score order (Terminal-Bench 2.1 anchored);
ties break by configured gateway order. Every pool entry is
provenance-tagged with its provider.

Usage:
  harness_pool.py --check                 Print the current decision as JSON
  harness_pool.py --show-pool             Print the ranked pool table
  harness_pool.py --refresh-pool          Re-enumerate free models, merge into pool
  harness_pool.py --probe-providers       Probe availability of each provider
"""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
PLUGIN_DIR = Path(__file__).resolve().parent
CONFIG_PATH = HOME / ".config/omagent/config.json"
STATE_DIR = HOME / ".local/state/omagent"
POOL_PATH = PLUGIN_DIR / "model_pool.json"
QUOTA_CACHE = STATE_DIR / "quota_cache.json"
HARNESS_STATE = STATE_DIR / "harness_state.json"
CLINE_PROBE_CACHE = STATE_DIR / "cline_probe_cache.json"
MODEL_PROBE_CACHE = STATE_DIR / "model_probe_cache.json"
PROBE_FAIL_CACHE = STATE_DIR / "model_probe_failures.json"
AUDIT_LOG = STATE_DIR / "harness_audit.log"

DEBUG = os.environ.get("OMAGENT_DEBUG") == "1"

DEFAULT_CONFIG = {
    "fallback_harness": "auto",           # "auto" | "agy-only" (disables failover)
    "quota_check": {
        "enabled": True,
        "trigger_usage_pct": 95,          # failover when 5h OR weekly usage >= 95%
        "cache_ttl_s": 60,
        # "trust-agy": switch ONLY on confirmed >=95% usage (strict rule);
        #              unknown/unprobeable quota keeps agy.
        # "fallback": unknown quota switches to the free pool (safe side).
        "unknown_policy": "trust-agy",
    },
    "quota_force_state": None,            # "exhausted" | "healthy" (testing only)
    "tiebreak_order": ["kilo", "opencode", "cline"],
    "allow_unscored_fallback": True,      # use unscored models if no scored one is available
    "pool_refresh": {
        "enabled": True,
        "on_failover": True,              # re-enumerate + verify top pick at every failover transition
        "max_age_s": 86400,               # re-verify the pool if older than 24h during sticky failover
        "probe_timeout_s": 120,           # generous per-model probe budget (correctness > speed)
        "probe_top_n": 0,                 # 0 = walk the ENTIRE ranked pool until one verifies live
        "probe_verified_ttl_s": 1800,     # a verified model is trusted for 30 min
    },
    "verification": {
        "fresh_quota_before_switch": True,  # re-probe quota (cache-bypass) right before leaving agy
        "require_tool_use": True,           # winner must prove agentic tool use, not just chat
        "tool_use_timeout_s": 240,          # budget for the file-writing tool-use probe
        "research_new_models": True,        # best-effort research hints for newly seen free models
        "research_max_new": 3,              # cap research calls per ritual
        "audit_log": True,                  # append every decision to harness_audit.log
    },
}


def dprint(msg: str) -> None:
    if DEBUG:
        print(f"[harness_pool] {msg}", file=sys.stderr)


def load_config(override: dict | None = None) -> dict:
    config = json.loads(json.dumps(DEFAULT_CONFIG))  # deep copy of defaults
    if CONFIG_PATH.is_file():
        try:
            user = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
            if isinstance(user, dict):
                for key, value in user.items():
                    if key in config and isinstance(config[key], dict) and isinstance(value, dict):
                        config[key].update(value)
                    else:
                        config[key] = value
        except Exception as e:
            dprint(f"config parse error: {e}")
    if isinstance(override, dict):
        for key, value in override.items():
            if key in config and isinstance(config[key], dict) and isinstance(value, dict):
                config[key].update(value)
            else:
                config[key] = value
    return config


# =====================================================================
# AGY QUOTA GATE
# =====================================================================


def _fetch_agy_quota(refresh_credentials: bool = False) -> dict:
    """Probes quota-axi for agy's 5h (kind=session) and weekly usage percentages.

    quota-axi window schema (from its agy provider source):
      { id: "gemini_5h", label, kind: "session"|"weekly"|"model"|"unknown",
        resetsAt, percentUsed, percentRemaining }
    Windows exist per model group (gemini_*, claude_gpt_*); the most-used
    group governs the gate (max across groups). Per-model windows are ignored.
    """
    cmd = ["quota-axi", "--provider", "agy", "--json"]
    if not refresh_credentials:
        cmd.append("--no-credential-refresh")
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=25)
        data = json.loads(res.stdout)
        providers = data.get("providers") or []
        if not providers:
            return {"ok": False, "error": "quota-axi returned no providers"}
        prov = providers[0]
        windows = prov.get("windows") or []
        state = prov.get("state") or {}
        status = state.get("status") if isinstance(state, dict) else state
        if not windows:
            if status == "exhausted":
                return {"ok": True, "hourly_used_pct": 100.0, "weekly_used_pct": 100.0, "resets_at": None}
            err = state.get("error") if isinstance(state, dict) else None
            return {"ok": False, "error": err or f"agy quota unavailable (status={status})"}

        def pct_used(w):
            v = w.get("percentUsed")
            if v is None:
                rem = w.get("percentRemaining")
                v = 100.0 - float(rem) if rem is not None else None
            return float(v) if v is not None else None

        hourly = weekly = None
        resets = None
        for w in windows:
            kind = w.get("kind")
            if kind not in ("session", "weekly"):
                continue  # skip per-model and unknown windows
            used = pct_used(w)
            if used is None:
                continue
            if kind == "session":
                hourly = used if hourly is None else max(hourly, used)
            else:
                weekly = used if weekly is None else max(weekly, used)
            r = w.get("resetsAt")
            if r and not resets:
                resets = r
        if hourly is None and weekly is None:
            return {"ok": False, "error": "no session/weekly quota windows with usage data"}
        return {"ok": True, "hourly_used_pct": hourly, "weekly_used_pct": weekly, "resets_at": resets}
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "quota-axi timed out"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def check_agy_quota(config: dict | None = None, force: bool = False) -> dict:
    """Returns {state: healthy|exhausted|unknown, hourly_used_pct, weekly_used_pct, resets_at, detail}.

    force=True bypasses the TTL cache (used for the fresh re-check right
    before actually leaving agy — correctness over speed).
    """
    config = config or load_config()
    qc = config.get("quota_check", {})
    force_state = config.get("quota_force_state")
    if force_state in ("exhausted", "healthy"):
        return {"state": force_state, "hourly_used_pct": None, "weekly_used_pct": None,
                "resets_at": None, "detail": f"forced via quota_force_state={force_state}"}

    ttl = int(qc.get("cache_ttl_s", 60))
    now = time.time()
    if not force:
        try:
            if QUOTA_CACHE.is_file():
                cached = json.loads(QUOTA_CACHE.read_text(encoding="utf-8"))
                if now - cached.get("fetched_at", 0) < ttl:
                    return cached["result"]
        except Exception as e:
            dprint(f"cache read error: {e}")

    trigger = float(qc.get("trigger_usage_pct", 95))
    probe = _fetch_agy_quota(refresh_credentials=False)
    if not probe.get("ok"):
        dprint(f"first probe failed: {probe.get('error')}; retrying with credential refresh")
        probe = _fetch_agy_quota(refresh_credentials=True)

    if probe.get("ok"):
        hourly = probe.get("hourly_used_pct")
        weekly = probe.get("weekly_used_pct")
        exhausted = False
        if hourly is not None and hourly >= trigger:
            exhausted = True
        if weekly is not None and weekly >= trigger:
            exhausted = True
        result = {
            "state": "exhausted" if exhausted else "healthy",
            "hourly_used_pct": hourly,
            "weekly_used_pct": weekly,
            "resets_at": probe.get("resets_at"),
            "detail": f"5h={hourly}% weekly={weekly}% trigger={trigger}%",
        }
    else:
        policy = qc.get("unknown_policy", "fallback")
        result = {
            "state": "unknown",
            "hourly_used_pct": None,
            "weekly_used_pct": None,
            "resets_at": None,
            "detail": f"{probe.get('error', 'probe failed')}; unknown_policy={policy}",
        }

    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        QUOTA_CACHE.write_text(json.dumps({"fetched_at": now, "result": result}, indent=2), "utf-8")
    except Exception as e:
        dprint(f"cache write error: {e}")
    return result


# =====================================================================
# MODEL POOL
# =====================================================================

def load_pool() -> dict:
    if not POOL_PATH.is_file():
        return {"version": 0, "models": []}
    try:
        return json.loads(POOL_PATH.read_text(encoding="utf-8"))
    except Exception as e:
        dprint(f"pool parse error: {e}")
        return {"version": 0, "models": []}


def _enumerate_cli_free_models(binary: str, pattern: str) -> list[str]:
    """Runs `<binary> models` and extracts free-tier model ids matching pattern."""
    try:
        res = subprocess.run([binary, "models"], capture_output=True, text=True, timeout=25)
        ids = []
        for line in res.stdout.splitlines():
            line = line.strip()
            if re.match(pattern, line):
                ids.append(line)
        return ids
    except Exception as e:
        dprint(f"{binary} models enumeration failed: {e}")
        return []


def refresh_pool() -> dict:
    """Re-enumerates free models from kilo/opencode and merges them into the pool.

    New models are added as unscored (agentic_score null) so they are never
    auto-selected until researched and scored in model_pool.json.
    """
    pool = load_pool()
    known = {m["id"] for m in pool.get("models", [])}
    added = []
    seen_kilo: set[str] = set()
    seen_oc: set[str] = set()
    for mid in _enumerate_cli_free_models("kilo", r"^kilo/\S+:free$"):
        seen_kilo.add(mid)
        if mid not in known:
            pool.setdefault("models", []).append({
                "id": mid, "provider": "kilo", "free": True, "auth": "none",
                "agentic_score": None, "tb21": None, "status": "unscored",
                "notes": "Auto-enumerated from `kilo models`; not yet researched.", "sources": [],
            })
            added.append(mid)
    for mid in _enumerate_cli_free_models("opencode", r"^opencode/\S+-free$|^opencode/big-pickle$"):
        seen_oc.add(mid)
        if mid not in known:
            pool.setdefault("models", []).append({
                "id": mid, "provider": "opencode", "free": True, "auth": "none",
                "agentic_score": None, "tb21": None, "status": "unscored",
                "notes": "Auto-enumerated from `opencode models`; not yet researched.", "sources": [],
            })
            added.append(mid)
    # Prune: models that vanished from the provider's live listing are marked
    # `gone` so they never get selected; historical scores are kept for reference.
    seen_map = {"kilo": seen_kilo, "opencode": seen_oc}
    pruned = []
    for m in pool.get("models", []):
        prov = m.get("provider")
        if prov in seen_map and m.get("status") != "gone" and m.get("id") not in seen_map[prov]:
            m["status"] = "gone"
            m["gone_since"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            m["notes"] = "Removed from provider's free listing; excluded from selection."
            pruned.append(m["id"])
    pool["refreshed_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    POOL_PATH.write_text(json.dumps(pool, indent=2) + "\n", "utf-8")
    return {"added": added, "pruned": pruned, "total": len(pool.get("models", []))}


def _load_probe_failures() -> dict:
    """Recent probe failures (model → {failed_at, detail}) so the ritual never
    wastes the dispatch budget re-probing a model that just failed."""
    try:
        if PROBE_FAIL_CACHE.is_file():
            return json.loads(PROBE_FAIL_CACHE.read_text(encoding="utf-8")) or {}
    except Exception as e:
        dprint(f"probe failure cache read error: {e}")
    return {}


def _save_probe_failures(mapping: dict) -> None:
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        PROBE_FAIL_CACHE.write_text(json.dumps(mapping, indent=2), "utf-8")
    except Exception as e:
        dprint(f"probe failure cache write error: {e}")


def _annotate_pool_model(mid: str, **fields) -> None:
    """Persists verification metadata onto a pool entry (honest bookkeeping:
    scores are NEVER auto-written; only probe facts like last_verified_at)."""
    if not mid:
        return
    try:
        pool = load_pool()
        for m in pool.get("models", []):
            if m.get("id") == mid:
                m.update(fields)
                break
        else:
            return
        POOL_PATH.write_text(json.dumps(pool, indent=2) + "\n", "utf-8")
    except Exception as e:
        dprint(f"pool annotate failed for {mid}: {e}")


# =====================================================================
# LIVE VERIFY & RANK (pre-switch ritual step 2)
# =====================================================================

def _probe_model(provider: str, mid: str, chat_timeout: int, tool_timeout: int,
                 require_tool_use: bool) -> tuple[bool, bool, str]:
    """Two-stage verification of one model through its real harness CLI.

    Stage 1 (chat): does the gateway serve this model at all?
    Stage 2 (tool use): can it actually ACT agentically — write a file via
    its own file tools? Chat-only ability is useless for Lane 3 coding runs.

    Returns (chat_ok, tool_ok, detail).
    """
    tool_file = f"/tmp/omagent_tooluse_{os.getpid()}_{int(time.time())}.txt"
    tool_task = (
        f"Use your file editing tools to create the file {tool_file} containing "
        f"exactly the text TOOLUSE_OK. Do not just print it — actually write the file."
    )
    if provider == "kilo":
        chat_cmd = ["kilo", "run", "-m", mid, "Reply with exactly: PROBE_OK"]
        tool_cmd = ["kilo", "run", "-m", mid, tool_task]
    elif provider == "opencode":
        chat_cmd = ["opencode", "run", "-m", mid, "Reply with exactly: PROBE_OK"]
        tool_cmd = ["opencode", "run", "-m", mid, tool_task]
    elif provider == "cline":
        chat_cmd = ["cline", "--auto-approve", "true", "Reply with exactly: PROBE_OK"]
        tool_cmd = ["cline", "--auto-approve", "true", tool_task]
    else:
        return False, False, f"unsupported provider: {provider}"

    try:
        res = subprocess.run(chat_cmd, capture_output=True, text=True, timeout=chat_timeout, cwd="/tmp")
        out = (res.stdout or "") + (res.stderr or "")
        chat_ok = "PROBE_OK" in out
        if not chat_ok:
            return False, False, f"chat probe failed: {out.strip()[:120] or 'no output'}"
    except subprocess.TimeoutExpired:
        return False, False, "chat probe timed out"
    except Exception as e:
        return False, False, f"chat probe error: {e}"

    if not require_tool_use:
        return True, False, "chat verified (tool-use check disabled)"

    try:
        subprocess.run(tool_cmd, capture_output=True, text=True, timeout=tool_timeout, cwd="/tmp")
        tool_ok = False
        try:
            tool_ok = "TOOLUSE_OK" in Path(tool_file).read_text(encoding="utf-8", errors="ignore")
        except Exception:
            tool_ok = False
        return True, tool_ok, (
            "chat + agentic tool-use verified"
            if tool_ok else "chat OK but model failed the agentic tool-use test"
        )
    except subprocess.TimeoutExpired:
        return True, False, "chat OK but tool-use probe timed out"
    except Exception as e:
        return True, False, f"chat OK; tool-use probe error: {e}"
    finally:
        try:
            os.unlink(tool_file)
        except Exception:
            pass


def _verify_and_rank(winner: dict, candidates: list[dict], config: dict) -> tuple[dict, str | None]:
    """Pre-switch ritual step 2: verify the pick live BEFORE committing.

    Walks the ENTIRE ranked pool (probe_top_n=0) until a model passes both
    the chat probe and (optionally) the agentic tool-use probe through its
    real harness CLI. Promotes the first model that fully verifies; never
    trusts a cached verification made under weaker rules.

    Returns (possibly new winner, optional bullet for the card).
    """
    pr = config.get("pool_refresh", {})
    ver = config.get("verification", {})
    chat_timeout = int(pr.get("probe_timeout_s", 120))
    tool_timeout = int(ver.get("tool_use_timeout_s", 240))
    require_tool = bool(ver.get("require_tool_use", True))
    verified_ttl = int(pr.get("probe_verified_ttl_s", 1800))
    total_budget = float(pr.get("probe_total_budget_s", 3600))
    top_n = int(pr.get("probe_top_n", 0))
    now = time.time()

    # Fast path: this exact model was recently verified under the SAME rules
    try:
        if MODEL_PROBE_CACHE.is_file():
            c = json.loads(MODEL_PROBE_CACHE.read_text(encoding="utf-8"))
            if (c.get("model") == winner.get("id")
                    and now - c.get("verified_at", 0) < verified_ttl
                    and (c.get("tool_use") or not require_tool)):
                return winner, None  # sticky continuation, already proven
    except Exception:
        pass

    fail_ttl = int(ver.get("probe_fail_ttl_s", 900))
    ranked = [winner] + [m for m in candidates if m.get("id") != winner.get("id")]
    if top_n > 0:
        ranked = ranked[:top_n]

    failures_map = _load_probe_failures()
    started = time.time()
    failures: list[str] = []
    for m in ranked:
        if time.time() - started > total_budget:
            failures.append("ritual probe budget exhausted")
            break
        provider, mid = m.get("provider"), m.get("id")
        prev_fail = failures_map.get(mid)
        if prev_fail and now - float(prev_fail.get("failed_at", 0)) < fail_ttl:
            age_m = int(max(0, now - float(prev_fail.get("failed_at", 0))) // 60)
            failures.append(f"{mid}: skipped (failed {age_m}m ago: {str(prev_fail.get('detail', '?'))[:60]})")
            dprint(f"verify skipped {mid} (recent failure)")
            continue
        chat_ok, tool_ok, detail = _probe_model(provider, mid, chat_timeout, tool_timeout, require_tool)
        if chat_ok and (tool_ok or not require_tool):
            failures_map.pop(mid, None)  # recovered: forget the failure
            _save_probe_failures(failures_map)
            try:
                STATE_DIR.mkdir(parents=True, exist_ok=True)
                MODEL_PROBE_CACHE.write_text(json.dumps({
                    "model": mid, "provider": provider, "verified_at": time.time(),
                    "tool_use": tool_ok, "detail": detail,
                }, indent=2), "utf-8")
            except Exception:
                pass
            _annotate_pool_model(mid, last_verified_at=time.time(), last_verification=detail)
            if mid == winner.get("id"):
                return winner, f"Verified live before switching: `{mid}` — {detail}"
            # Promoted past a dead top pick: record what failed, on the loser.
            if winner.get("id"):
                _annotate_pool_model(winner["id"], last_probe_failed_at=time.time(),
                                     last_probe_detail="; ".join(failures) or "verification failed")
            return m, (f"Top-ranked model failed verification ({'; '.join(failures) or 'probe failed'}) — "
                       f"promoted `{mid}` (verified: {detail})")
        failures.append(f"{mid}: {detail}")
        failures_map[mid] = {"failed_at": time.time(), "detail": detail}
        _save_probe_failures(failures_map)
        dprint(f"verify rejected {mid}: {detail}")

    return winner, ("**Live verification failed for every ranked free model — "
                    f"keeping ranked order ({'; '.join(failures[-2:])})**")


def _audit_decision(decision: dict, config: dict, t_start: float, extra: dict | None = None) -> None:
    """Appends every harness decision to the audit log (one JSON per line)."""
    if not config.get("verification", {}).get("audit_log", True):
        return
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        rec = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "use_agy": decision.get("use_agy"),
            "provider": decision.get("provider"),
            "model": decision.get("model"),
            "reason": decision.get("reason"),
            "quota_state": (decision.get("quota") or {}).get("state"),
            "duration_s": round(time.time() - t_start, 1),
        }
        if extra:
            rec.update(extra)
        with open(AUDIT_LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec) + "\n")
    except Exception as e:
        dprint(f"audit write failed: {e}")


def _research_model_hint(mid: str, timeout: int = 20) -> str | None:
    """Best-effort research for newly appeared free models.

    Uses DuckDuckGo's Instant Answer API (bot-friendly JSON; the HTML search
    endpoint bot-blocks). The result is a HINT ONLY — it never changes
    agentic_score. Scoring stays a deliberate human/agent research task.
    """
    try:
        import urllib.parse
        import urllib.request
        q = urllib.parse.quote(f"{mid} model agentic coding benchmark")
        url = f"https://api.duckduckgo.com/?q={q}&format=json&no_html=1"
        req = urllib.request.Request(url, headers={"User-Agent": "omagent-harness-pool/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8", errors="ignore"))
        text = data.get("AbstractText") or data.get("Abstract") or ""
        src = data.get("AbstractURL") or ""
        if not text:
            parts = []
            for rt in (data.get("RelatedTopics") or [])[:3]:
                if isinstance(rt, dict) and rt.get("Text"):
                    parts.append(rt["Text"])
            text = " | ".join(parts)
        if text:
            return f"{text[:300]}{' — ' + src if src else ''}"
    except Exception as e:
        dprint(f"research hint failed for {mid}: {e}")
    return None


def _pool_is_stale(pool: dict, config: dict) -> bool:
    max_age = float(config.get("pool_refresh", {}).get("max_age_s", 86400))
    stamp = pool.get("refreshed_at")
    if not stamp:
        return True
    try:
        from datetime import datetime
        age = time.time() - datetime.fromisoformat(str(stamp).replace("Z", "+00:00")).timestamp()
        return age > max_age
    except Exception:
        return True


# =====================================================================
# PROVIDER AVAILABILITY (AUTH PREFLIGHT)
# =====================================================================

def _which(binary: str) -> str | None:
    for path_dir in os.environ.get("PATH", "").split(os.pathsep):
        candidate = Path(path_dir) / binary
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    for extra in (HOME / ".local/bin", Path("/usr/bin"), Path("/usr/local/bin")):
        candidate = extra / binary
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


def _has_cli_credentials(binary: str, auth_file: Path) -> bool:
    if auth_file.is_file():
        try:
            data = json.loads(auth_file.read_text(encoding="utf-8"))
            if isinstance(data, dict) and data:
                return True
        except Exception:
            pass
    try:
        res = subprocess.run([binary, "auth", "list"], capture_output=True, text=True, timeout=15)
        return "0 credentials" not in res.stdout
    except Exception:
        return False


def _cline_available() -> dict:
    """Empirically probes cline's own gateway balance (cached 30 min)."""
    now = time.time()
    try:
        if CLINE_PROBE_CACHE.is_file():
            cached = json.loads(CLINE_PROBE_CACHE.read_text(encoding="utf-8"))
            if now - cached.get("probed_at", 0) < 1800:
                return cached["result"]
    except Exception:
        pass

    providers_file = HOME / ".cline/data/settings/providers.json"
    saved_model = None
    result = {"available": False, "reason": "cline not installed"}
    try:
        if providers_file.is_file():
            data = json.loads(providers_file.read_text(encoding="utf-8"))
            settings = data.get("providers", {}).get("cline", {}).get("settings", {})
            has_auth = bool(settings.get("auth", {}).get("accessToken"))
            saved_model = settings.get("model")
            if not has_auth:
                result = {"available": False, "reason": "cline not authenticated (run `cline auth cline`)"}
            else:
                probe = subprocess.run(
                    ["cline", "--auto-approve", "true", "-c", "/tmp", "Reply with exactly: PROBE_OK"],
                    capture_output=True, text=True, timeout=90,
                )
                out = (probe.stdout or "") + (probe.stderr or "")
                if "Insufficient balance" in out:
                    result = {"available": False, "reason": "cline gateway balance exhausted ($0.00)"}
                elif "PROBE_OK" in out:
                    result = {"available": True, "reason": "cline gateway reachable"}
                else:
                    result = {"available": False, "reason": f"cline probe failed: {out.strip()[:120]}"}
        # Restore any model mutation the probe caused in cline settings
        if providers_file.is_file() and saved_model is not None:
            try:
                data = json.loads(providers_file.read_text(encoding="utf-8"))
                settings = data.get("providers", {}).get("cline", {}).get("settings", {})
                if settings.get("model") != saved_model:
                    settings["model"] = saved_model
                    providers_file.write_text(json.dumps(data, indent=2), "utf-8")
            except Exception:
                pass
    except Exception as e:
        result = {"available": False, "reason": f"cline probe error: {e}"}

    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        CLINE_PROBE_CACHE.write_text(json.dumps({"probed_at": now, "result": result}, indent=2), "utf-8")
    except Exception:
        pass
    return result


def probe_providers() -> dict:
    out = {}
    kilo_auth = HOME / ".local/share/kilo/auth.json"
    oc_auth = HOME / ".local/share/opencode/auth.json"
    out["kilo"] = {
        "binary": bool(_which("kilo")),
        "free_tier": True,
        "account_authed": _has_cli_credentials("kilo", kilo_auth) if _which("kilo") else False,
    }
    out["opencode"] = {
        "binary": bool(_which("opencode")),
        "free_tier": True,
        "account_authed": _has_cli_credentials("opencode", oc_auth) if _which("opencode") else False,
    }
    out["cline"] = dict(_cline_available(), binary=bool(_which("cline")))
    out["agy"] = {"binary": bool(_which("agy"))}
    return out


def provider_available(provider: str, model: dict, probes: dict | None = None) -> bool:
    probes = probes or probe_providers()
    p = probes.get(provider, {})
    if not p.get("binary"):
        return False
    if provider in ("kilo", "opencode"):
        # Free gateway tier needs no account; account-tier models need auth.
        if model.get("auth") == "none":
            return True
        return bool(p.get("account_authed"))
    if provider == "cline":
        return bool(p.get("available"))
    return False


# =====================================================================
# SELECTION
# =====================================================================

def _sticky_state() -> dict:
    try:
        if HARNESS_STATE.is_file():
            return json.loads(HARNESS_STATE.read_text(encoding="utf-8"))
    except Exception:
        pass
    return {}


def _sticky_expired(sticky: dict) -> bool:
    """True when a recorded failover window has reset (with 5m grace)."""
    until = sticky.get("until")
    if not until:
        return False
    try:
        reset_ts = float(until)
    except (TypeError, ValueError):
        try:
            from datetime import datetime, timezone
            reset_ts = datetime.fromisoformat(str(until).replace("Z", "+00:00")).timestamp()
        except Exception:
            return False
    return time.time() > reset_ts + 300


def _save_sticky_state(state: dict) -> None:
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        HARNESS_STATE.write_text(json.dumps(state, indent=2), "utf-8")
    except Exception as e:
        dprint(f"sticky state write error: {e}")


def select_harness(config: dict | None = None, quota: dict | None = None) -> dict:
    """Core decision: which harness/model handles the next Lane 3 task."""
    config = config or load_config()
    qc = config.get("quota_check", {})
    trigger = float(qc.get("trigger_usage_pct", 95))
    unknown_policy = qc.get("unknown_policy", "fallback")
    quota = quota or check_agy_quota(config)
    t_start = time.time()
    ver_cfg = config.get("verification", {})

    agy_model = config.get("coding_model", "gemini-3.8-flash-high")

    # Hard disable switch
    if config.get("fallback_harness") == "agy-only":
        decision = {"use_agy": True, "provider": "agy", "model": agy_model,
                    "reason": "fallback_harness=agy-only", "quota": quota, "bullets": []}
        _audit_decision(decision, config, t_start)
        return decision

    bullets: list[str] = []
    qstate = quota.get("state")
    hourly = quota.get("hourly_used_pct")
    weekly = quota.get("weekly_used_pct")
    resets = quota.get("resets_at")

    if qstate == "healthy":
        _save_sticky_state({})  # clear any sticky fallback
        decision = {"use_agy": True, "provider": "agy", "model": agy_model,
                    "reason": f"agy quota healthy ({quota.get('detail')})", "quota": quota, "bullets": []}
        _audit_decision(decision, config, t_start)
        return decision

    sticky = _sticky_state()
    sticky_active = sticky.get("mode") == "fallback" and not _sticky_expired(sticky)

    if qstate == "unknown":
        if unknown_policy != "fallback" and not sticky_active:
            # Strict rule: fail over ONLY on a confirmed >=trigger% reading.
            # An unprobeable quota (e.g. agy closed) keeps the base harness.
            if sticky.get("mode") == "fallback":
                _save_sticky_state({})  # expired sticky → return to agy
            decision = {"use_agy": True, "provider": "agy", "model": agy_model,
                        "reason": f"quota unprobeable, policy={unknown_policy} → agy (strict ≥{trigger:.0f}% rule); {quota.get('detail')}",
                        "quota": quota, "bullets": []}
            _audit_decision(decision, config, t_start)
            return decision
        bullets.append("**AGY quota unconfirmed — staying on failover pool until next confirmed check**")
    elif qstate == "exhausted":
        which = []
        if hourly is not None and hourly >= trigger:
            which.append(f"5h {hourly:g}%")
        if weekly is not None and weekly >= trigger:
            which.append(f"weekly {weekly:g}%")
        reset_note = f", resets {resets}" if resets else ""
        bullets.append(f"**AGY quota {'/'.join(which) or 'limit'} used ≥{trigger:.0f}%{reset_note} — failover engaged**")
    else:
        bullets.append("**AGY quota unavailable — failover engaged per policy**")

    # ---- Verification: fresh cache-bypassing quota re-check before leaving agy ----
    # A stale cached reading must never strand the user on fallback when agy
    # has actually reset. Correctness over speed: one extra probe.
    if (qstate == "exhausted"
            and ver_cfg.get("fresh_quota_before_switch", True)
            and config.get("quota_force_state") is None):
        fresh = check_agy_quota(config, force=True)
        if fresh.get("state") == "healthy":
            _save_sticky_state({})
            decision = {
                "use_agy": True, "provider": "agy", "model": agy_model,
                "reason": "fresh re-check reversed a stale exhaustion reading",
                "quota": fresh,
                "bullets": ["**Stale quota reading discarded** — fresh probe shows agy healthy; staying on agy"],
            }
            _audit_decision(decision, config, t_start, {"reversed": True})
            return decision
        if fresh.get("state") == "exhausted":
            quota = fresh
            resets = quota.get("resets_at")

    # Rank the free pool: strict score order, provenance-tagged.
    pool = load_pool()
    tiebreak = config.get("tiebreak_order", ["kilo", "opencode", "cline"])
    probes = probe_providers()

    # ---- Pre-switch ritual: re-enumerate the pool right before switching ----
    # Fresh failover transition → always refresh (+prune). Sticky continuation →
    # refresh only when the pool data is older than pool_refresh.max_age_s.
    pr_cfg = config.get("pool_refresh", {})
    sticky_prev = sticky.get("mode") == "fallback"
    if pr_cfg.get("enabled", True):
        fresh_transition = (not sticky_prev) and bool(pr_cfg.get("on_failover", True))
        if fresh_transition or _pool_is_stale(pool, config):
            try:
                r = refresh_pool()
                pool = load_pool()
                n_add, n_prune = len(r.get("added", [])), len(r.get("pruned", []))
                if n_add or n_prune:
                    bullets.append(
                        f"Pool re-scanned before switching: {n_add} new free model(s), {n_prune} removed"
                    )
                # Best-effort research hints for brand-new free models (hints
                # only — never auto-scored; selection stays deliberate).
                new_added = r.get("added") or []
                if new_added and ver_cfg.get("research_new_models", True):
                    max_r = int(ver_cfg.get("research_max_new", 3))
                    hints = []
                    for mid in new_added[:max_r]:
                        hint = _research_model_hint(mid)
                        if hint:
                            hints.append(f"`{mid}`: {clip(str(hint), 140)}")
                    if hints:
                        bullets.append("Research hints for new models (scores pending): " + " ;; ".join(hints[:2]))
            except Exception as e:
                dprint(f"pre-switch pool refresh failed: {e}")

    candidates = [m for m in pool.get("models", [])
                  if m.get("free") and m.get("provider") not in (None, "agy")
                  and m.get("status") != "gone"
                  and provider_available(m["provider"], m, probes)]

    if not candidates:
        bullets.append("**No fallback provider available — run `kilo auth` / `opencode auth login` / `cline auth cline`**")
        decision = {"use_agy": True, "provider": "agy", "model": agy_model,
                    "reason": "no fallback provider available (agy kept as last resort)",
                    "quota": quota, "bullets": bullets, "remedy": True}
        _audit_decision(decision, config, t_start, {"remedy": True})
        return decision

    def rank_key(m):
        score = m.get("agentic_score")
        tb = m.get("tb21")
        score_key = -(score) if isinstance(score, (int, float)) else 1
        tb_key = -(tb) if isinstance(tb, (int, float)) else 1
        t_order = tiebreak.index(m["provider"]) if m["provider"] in tiebreak else len(tiebreak)
        return (score_key, tb_key, t_order)

    candidates.sort(key=rank_key)
    scored = [m for m in candidates if isinstance(m.get("agentic_score"), (int, float))]
    winner = None
    if scored:
        winner = scored[0]
    elif config.get("allow_unscored_fallback", True):
        winner = candidates[0]
        bullets.append("Note: no scored model available; using best unscored free model")

    if not winner:
        bullets.append("**No usable fallback model — check model_pool.json**")
        decision = {"use_agy": True, "provider": "agy", "model": agy_model,
                    "reason": "pool yielded no usable model", "quota": quota, "bullets": bullets}
        _audit_decision(decision, config, t_start)
        return decision

    # ---- Pre-switch ritual step 2: live-verify the winner via its harness ----
    # Probes the top pick through kilo/opencode/cline itself; promotes the next
    # ranked model if the probe fails. Cached ~30 min so sticky follow-ups skip it.
    pre_verify_id = winner.get("id")
    verified_ok = True
    promoted = False
    if pr_cfg.get("enabled", True):
        try:
            winner, verify_note = _verify_and_rank(winner, candidates, config)
            promoted = winner.get("id") != pre_verify_id
            if verify_note:
                bullets.append(verify_note)
                verified_ok = not str(verify_note).startswith("**Live verification failed")
        except Exception as e:
            dprint(f"verify_and_rank failed: {e}")

    # Score text reflects the FINAL winner (may differ from the pre-verify pick
    # if verification promoted a lower-ranked model past a dead top pick).
    score_txt = f", score {winner['agentic_score']}/10" if isinstance(winner.get("agentic_score"), (int, float)) else ""

    bullets.append(
        f"Failing over to `{winner['id']}` ({winner['provider']} gateway{score_txt}) — best free agentic model available"
    )

    _save_sticky_state({
        "mode": "fallback",
        "provider": winner["provider"],
        "model": winner["id"],
        "since": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "until": resets,
    })

    decision = {
        "use_agy": False,
        "provider": winner["provider"],
        "model": winner["id"],
        "harness_label": f"Failover ({winner['provider']})",
        "reason": f"agy quota {qstate}; winner by strict score order",
        "quota": quota,
        "bullets": bullets,
        "verified": verified_ok,
        "promoted_past_dead_pick": promoted,
    }
    _audit_decision(decision, config, t_start, {"verified": verified_ok, "promoted": promoted})
    return decision

# =====================================================================
# DISPATCH ADAPTERS
def ensure_herdr_running() -> bool:
    """Starts the herdr headless server if it isn't running (self-healing).

    Returns True when the server is confirmed running.
    """
    try:
        res = subprocess.run(["herdr", "status"], capture_output=True, text=True, timeout=4)
        if "status: running" in res.stdout:
            return True
        if not _which("herdr"):
            return False
    except Exception:
        pass
    try:
        subprocess.Popen(
            ["herdr", "server"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL, start_new_session=True,
        )
    except Exception as e:
        dprint(f"herdr server start failed: {e}")
        return False
    for _ in range(20):  # up to 10s for readiness
        time.sleep(0.5)
        try:
            res = subprocess.run(["herdr", "status"], capture_output=True, text=True, timeout=3)
            if "status: running" in res.stdout:
                dprint("herdr server auto-started")
                return True
        except Exception:
            pass
    return False


def build_launch_cmd(provider: str, model: str, prompt: str) -> str:
    """Builds the shell command sent into the Herdr pane for the chosen harness."""
    q = shlex.quote
    if provider == "agy":
        return f"agy --model {q(model)} --dangerously-skip-permissions -i {q(prompt)}\n"
    if provider == "opencode":
        return f"opencode run --auto -m {q(model)} {q(prompt)}\n"
    if provider == "kilo":
        return f"kilo run -m {q(model)} {q(prompt)}\n"
    if provider == "cline":
        thinking_flag = "--thinking medium " if "muse-spark" in (model or "") else ""
        model_flag = f"-m {q(model)} " if model else ""
        # --timeout 0: disable the tool-call timeout (free-tier models are slower and large
        #   file writes can exceed the default cline timeout causing session abandonment)
        # --retries 15: more tolerance for transient errors before giving up (default is 6)
        # --compaction basic: keep context lean without slow recursive LLM summarization on flash models
        return f"cline --auto-approve true --timeout 0 --retries 15 --compaction basic {thinking_flag}{model_flag}{q(prompt)}\n"
    raise ValueError(f"unknown provider: {provider}")


# =====================================================================
# RUNTIME WATCHDOG: mid-run error recovery for fallback harnesses
# =====================================================================
# When kilo/opencode/cline die mid-run with a rate-limit or transient error,
# the pane watchdog nudges with 'continue' (kilo/opencode: `run -c 'continue'`
# to resume the session). If the error persists (N nudges) or the pane reports
# hard daily quota exhaustion, we permanently switch to the best available
# model — via _verify_and_rank, so the winner is proven live before dispatch.

RL_PATTERNS = [
    "rate limit", "rate-limit", "ratelimit", "too many requests", "429",
    "quota exceeded", "resource_exhausted", "resource has been exhausted",
    "usage limit", "billing limit reached", "service unavailable (503)",
    "internal server error (500)", "model overloaded", "temporarily unavailable",
    "try again later", "stream reading error", "econnreset", "socket hang up",
    "fetch failed", "context deadline exceeded", "api error: 429", "provider error: 429",
    "process crashed", "terminated unexpectedly", "killed by signal",
    # Cline-specific transient errors
    "tool call timed out", "response was interrupted", "generation stopped unexpectedly",
]
# Phrases that mean the account's daily/hard quota is gone → immediate switch.
DAILY_EXHAUST_PATTERNS = [
    "you have used up your daily limit", "used up your daily limit", "daily limit",
    "per-day limit", "per day limit", "daily quota", "free tier limit",
    "free models limit", "monthly limit", "weekly limit", "exceeded your daily",
    "exceeded your current quota", "insufficient credits", "credit balance",
    "balance is $0.00", "run out of credits", "quota exhausted for model"
]
# Cline tool-level abort patterns: when cline exits the entire session (not just
# a rate limit that can be continued) → treat as persistent error → prompt_switch.
CLINE_ABORT_PATTERNS = [
    "cline has exited",
    "max retries exceeded",
    "too many consecutive mistakes",
    "operation abandoned",
    "task was abandoned",
]

# --- watchdog: reader, classifier, tick, nudge, switch (below) ---

def _pane_read_tail(pane_id: str, lines: int = 40) -> str:
    try:
        res = subprocess.run(
            ["herdr", "pane", "read", pane_id, "--source", "recent-unwrapped",
             "--lines", str(lines), "--format", "text"],
            capture_output=True, text=True, timeout=4,
        )
        if res.returncode == 0:
            return res.stdout or ""
    except Exception:
        pass
    return ""


def _classify_pane_error(text: str) -> str | None:
    """Returns:
      'daily'  – hard quota exhaustion → prompt_switch immediately
      'abort'  – cline session-abort (timeout, max-retries, abandoned) → prompt_switch immediately
      'rate'   – transient error (rate-limit, network) → nudge with 'continue' first
      None     – no error found
    """
    t = (text or "").lower()
    if not t:
        return None
    for pat in DAILY_EXHAUST_PATTERNS:
        if pat in t:
            return "daily"
    # Cline session-abort errors cannot be recovered with 'continue'; switch immediately
    for pat in CLINE_ABORT_PATTERNS:
        if pat in t:
            return "abort"
    for pat in RL_PATTERNS:
        if pat in t:
            return "rate"
    return None


def runtime_watchdog_tick(provider: str, pane_id: str, cfg: dict, state: dict) -> dict:
    """One watchdog iteration across agy, opencode, cline.

    state (persisted by caller): {
        nudges, last_nudge_at, last_output_sample, model, provider
    }
    Returns: {"action": "none"|"nudged"|"prompt_switch", "detail": str, "error": str, ...}
    """
    wc = cfg.get("runtime_watchdog") or {}
    max_nudges = int(wc.get("max_nudges", 2))
    cooldown = int(wc.get("cooldown_s", 15))
    enabled = bool(wc.get("enabled", True))
    if not enabled:
        return {"action": "none", "detail": "disabled"}

    tail = _pane_read_tail(pane_id)
    if not tail.strip():
        return {"action": "none", "detail": "no output"}

    sample = tail.strip()[-250:]
    if sample == state.get("last_output_sample"):
        return {"action": "none", "detail": "output unchanged"}
    state["last_output_sample"] = sample

    err = _classify_pane_error(tail)
    if err is None:
        return {"action": "none", "detail": "no error pattern"}

    now = time.time()
    last_nudge = float(state.get("last_nudge_at") or 0)
    current_model = state.get("model") or "active-model"

    # 1. Hard daily quota exhaustion → prompt user immediately to switch
    if err == "daily":
        _record_model_failure(provider, current_model, "daily quota exhausted (pane watchdog)")
        return {
            "action": "prompt_switch",
            "reason": "daily_limit",
            "error": tail[-300:].strip(),
            "detail": f"daily quota exhausted on {current_model}",
            "model": current_model,
            "provider": provider,
        }

    # 1b. Cline session-abort (tool timeout, max-retries, abandoned) → no point nudging;
    #     cline exited the session entirely. Record failure and prompt user to switch.
    if err == "abort":
        _record_model_failure(provider, current_model,
                              f"cline session aborted (timeout/max-retries/abandonment)")
        return {
            "action": "prompt_switch",
            "reason": "session_aborted",
            "error": tail[-300:].strip(),
            "detail": (
                f"Cline (`{current_model}`) aborted the session mid-task. "
                f"This is a known limitation of free-tier models that are slower than the default "
                f"tool timeout. Switching to a different model will resume with full context."
            ),
            "model": current_model,
            "provider": provider,
        }

    # 2. Transient error (rate limit, network, API error, etc.) -> auto-nudge with 'continue'
    nudges = int(state.get("nudges") or 0)
    if nudges >= max_nudges:
        _record_model_failure(provider, current_model, f"error persisted after {nudges} 'continue' nudges")
        return {
            "action": "prompt_switch",
            "reason": "error_persisted",
            "error": tail[-300:].strip(),
            "detail": f"error persisted after {nudges} 'continue' attempts on {current_model}",
            "model": current_model,
            "provider": provider,
        }

    if last_nudge and (now - last_nudge) < cooldown:
        return {"action": "none", "detail": "cooldown"}

    if not _send_pane_nudge(provider, pane_id):
        return {"action": "none", "detail": "nudge delivery failed; will retry next tick"}

    state["nudges"] = nudges + 1
    state["last_nudge_at"] = now
    return {
        "action": "nudged",
        "detail": f"auto-recovery nudge #{state['nudges']}: sent 'continue' to pane",
        "nudge_num": state["nudges"],
        "error": tail[-200:].strip(),
    }


def _record_model_failure(provider: str, mid: str | None, detail: str) -> None:
    """Persists a runtime failure so selection/ritual avoids this model for a while."""
    if not mid:
        return
    failures_map = _load_probe_failures()
    failures_map[mid] = {"failed_at": time.time(), "detail": detail}
    _save_probe_failures(failures_map)
    _annotate_pool_model(mid, last_probe_failed_at=time.time(), last_probe_detail=detail)


def _send_pane_nudge(provider: str, pane_id: str) -> bool:
    """Sends the resume signal ('continue') into the pane for any harness."""
    is_shell_prompt = False
    try:
        p_proc = subprocess.run(
            ["herdr", "pane", "process-info", "--pane", pane_id],
            capture_output=True, text=True, timeout=2
        )
        if p_proc.returncode == 0:
            p_info = json.loads(p_proc.stdout).get("result", {}).get("process_info", {})
            fg_procs = [p.get("name", "") for p in p_info.get("foreground_processes", [])]
            if fg_procs and all(sh in ("bash", "zsh", "sh") for sh in fg_procs):
                is_shell_prompt = True
    except Exception:
        pass

    if provider in ("kilo", "opencode"):
        nudge_cmd = f"{provider} run --auto -c 'continue'\n" if is_shell_prompt else "continue\n"
    elif provider == "agy":
        nudge_cmd = "agy --continue\n" if is_shell_prompt else "continue\n"
    elif provider == "cline":
        nudge_cmd = "cline --auto-approve true --timeout 0 --retries 15 --compaction basic 'continue'\n" if is_shell_prompt else "continue\n"
    else:
        nudge_cmd = "continue\n"

    try:
        res = subprocess.run(
            ["herdr", "pane", "send-text", pane_id, nudge_cmd],
            capture_output=True, text=True, timeout=5,
        )
        if res.returncode != 0:
            dprint(f"pane nudge rejected: {res.stderr.strip()[:100]}")
            return False
        return True
    except Exception as e:
        dprint(f"pane nudge failed: {e}")
        return False


def switch_provider_model(provider: str, cfg: dict, exclude_model: str | None = None) -> str | None:
    """Picks the best alternative model on the SAME provider and proves it live.

    Walks the ranked free pool for `provider`, skipping the just-failed model
    and models with recent probe failures; returns the first id that passes a
    live chat probe through its real harness CLI. Tool-use verification is
    skipped here — the goal is a working lane right now. Returns None when
    nothing verifiable remains on this provider (the task stays put).
    """
    ver = cfg.get("verification") or {}
    chat_timeout = int(ver.get("probe_chat_timeout_s", 90))
    pool = load_pool()
    failures_map = _load_probe_failures()
    now = time.time()
    fail_ttl = int(ver.get("probe_fail_ttl_s", 900))

    candidates = []
    for m in pool.get("models", []):
        if not m.get("free") or m.get("status") == "gone":
            continue
        if m.get("provider") != provider:
            continue
        if m.get("auth") not in (None, "none"):
            continue
        if exclude_model and m.get("id") == exclude_model:
            continue
        candidates.append(m)

    tiebreak = cfg.get("tiebreak_order") or ["kilo", "opencode", "cline"]
    order = tiebreak.index(provider) if provider in tiebreak else 0

    def rank_key(m):
        score = m.get("agentic_score")
        tb = m.get("tb21")
        return (-(score) if isinstance(score, (int, float)) else 1,
                -(tb) if isinstance(tb, (int, float)) else 0, order)

    candidates.sort(key=rank_key)
    for m in candidates:
        mid = m.get("id")
        prev_fail = failures_map.get(mid)
        if prev_fail and now - float(prev_fail.get("failed_at", 0)) < fail_ttl:
            continue
        chat_ok, _tool_ok, detail = _probe_model(provider, mid, chat_timeout, chat_timeout,
                                                 require_tool_use=False)
        if chat_ok:
            failures_map.pop(mid, None)
            _save_probe_failures(failures_map)
            _annotate_pool_model(mid, last_verified_at=now, last_verification=detail)
            return mid
        failures_map[mid] = {"failed_at": now, "detail": detail}
        _save_probe_failures(failures_map)
        dprint(f"switch candidate rejected: {mid}: {detail}")
    return None


# =====================================================================
# CLI
# =====================================================================
# =====================================================================
# CLI
# =====================================================================

def cmd_check() -> int:
    config = load_config()
    decision = select_harness(config)
    print(json.dumps(decision, indent=2, default=str))
    return 0


def cmd_show_pool() -> int:
    pool = load_pool()
    models = pool.get("models", [])

    def key(m):
        s = m.get("agentic_score")
        return (-(s) if isinstance(s, (int, float)) else 1, -(m.get("tb21") or 0))

    for i, m in enumerate(sorted(models, key=key), 1):
        score = m.get("agentic_score")
        tb = m.get("tb21")
        score_s = f"{score:>4}/10" if isinstance(score, (int, float)) else " unscored"
        tb_s = f"TB2.1 {tb}" if isinstance(tb, (int, float)) else ""
        auth = m.get("auth", "?")
        print(f"{i:>2}. [{m.get('provider','?'):>8}] {m['id']:<55} {score_s}  auth={auth:<7} {tb_s}")
        if m.get("notes"):
            print(f"      {m['notes'][:110]}")
    return 0


def main() -> int:
    args = sys.argv[1:]
    if "--check" in args:
        return cmd_check()
    if "--show-pool" in args:
        return cmd_show_pool()
    if "--refresh-pool" in args:
        print(json.dumps(refresh_pool(), indent=2))
        return 0
    if "--probe-providers" in args:
        print(json.dumps(probe_providers(), indent=2))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
