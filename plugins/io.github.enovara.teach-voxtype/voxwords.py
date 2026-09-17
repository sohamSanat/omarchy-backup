#!/usr/bin/env python3
"""Engine for the Teach Voxtype plugin (and the teach-voxtype-word skill).

  voxwords.py probe "<Word>" take1.wav [take2.wav ...] [--models M1,M2]
      Transcribe each take with voxtype and print JSON: how many takes each
      model spelled right, every transcript, and each distinct mishearing with
      its count, models, similarity, real-word flag, existing mapping, and
      whether it is suggested for mapping.

  voxwords.py apply "<Word>" [variant ...] [--no-restart]
      Map each variant to the word (voxtype config set text.replacements.<v>),
      add the word to whisper.initial_prompt, restart voxtype, print JSON.

All output is one JSON object on stdout; errors come back as {"status": "error"}.
"""
import argparse
import difflib
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

MODELS = ["large-v3-turbo", "base.en"]
MIN_SIMILARITY = 0.5
DICT_PATHS = [
    "/usr/share/dict/words",
    "/usr/share/dict/american-english",
    "/usr/share/hunspell/en_US.dic",
]
# Progress lines `voxtype transcribe` prints on stdout next to the transcript.
NOISE = re.compile(r"^(Loading audio file:|Audio format:|Processing \d+ samples|No speech detected|VAD:)")


def run(argv):
    return subprocess.run(argv, capture_output=True, text=True)


def default_models():
    """The Whisper model dictation uses, plus base.en when it is installed.

    base.en mishears more, so it surfaces likely future errors, but not every
    machine has it downloaded; only installed models are used.
    """
    configured = run(["voxtype", "config", "get", "whisper.model"]).stdout.strip().strip('"')
    installed = set()
    in_whisper = False
    for line in run(["voxtype", "info", "models"]).stdout.splitlines():
        if line.strip() == "whisper":
            in_whisper = True
            continue
        if in_whisper and line and not line.startswith(" "):
            break
        m = re.match(r"^\s*installed\s+(\S+)", line)
        if in_whisper and m:
            installed.add(m.group(1))
    models = [configured] if configured and configured != "null" else []
    for extra in ("base.en",) + tuple(sorted(installed)):
        if extra in installed and extra not in models:
            models.append(extra)
            break
    return models or MODELS[:1]


def letters(s):
    return re.sub(r"[^a-z]", "", s.lower())


def transcribe(model, wav):
    proc = run(["voxtype", "-q", "--model", model, "transcribe", wav])
    lines = [l.strip() for l in proc.stdout.splitlines()]
    return " ".join(l for l in lines if l and not NOISE.match(l))


def current_replacements():
    out = run(["voxtype", "config", "schema"]).stdout
    mapped, in_block = {}, False
    for line in out.splitlines():
        if line.startswith("Replacements (text.replacements)"):
            in_block = True
            continue
        if in_block:
            m = re.match(r"^\s+(.+?)\s+->\s+(.+)$", line)
            if not m:
                break
            mapped[m.group(1).strip().lower()] = m.group(2).strip()
    return mapped


def dictionary():
    for path in DICT_PATHS:
        if os.path.exists(path):
            with open(path, encoding="utf-8", errors="ignore") as f:
                return {w.split("/", 1)[0].strip().lower() for w in f if w.strip() and not w.strip().isdigit()}
    return None


def near_spellings(text, target):
    words = re.findall(r"[A-Za-z][A-Za-z'’-]*", text)
    span = len(target.split())
    found = []
    for n in range(1, span + 2):
        for i in range(len(words) - n + 1):
            gram = " ".join(words[i:i + n])
            score = difflib.SequenceMatcher(None, letters(gram), letters(target)).ratio()
            if score >= MIN_SIMILARITY:
                found.append((gram, score))
    # A phrase only counts when every word in it belongs to the mishearing. If
    # dropping its first or last word matches the target at least as well
    # ("for inovara" vs "inovara"), that edge word is real context, and mapping
    # the phrase would delete it from every sentence. Keep the shorter one.
    scores = {g: s for g, s in found}

    def trimmed_scores(gram):
        parts = gram.split()
        if len(parts) < 2:
            return []
        subs = [" ".join(parts[1:]), " ".join(parts[:-1])]
        return [difflib.SequenceMatcher(None, letters(sub), letters(target)).ratio() for sub in subs]

    found = [(g, s) for g, s in found if all(t < s for t in trimmed_scores(g))]
    found.sort(key=lambda g: -g[1])
    kept, used = [], set()
    for gram, score in found:
        if letters(gram) in used:
            continue
        used.add(letters(gram))
        kept.append((gram, score))
    return kept


def probe(word, wavs, models):
    mapped = current_replacements()
    words = dictionary()
    heard = defaultdict(lambda: {"count": 0, "models": set(), "similarity": 0.0})
    transcripts = []
    correct = {m: 0 for m in models}

    for wav in wavs:
        for model in models:
            text = transcribe(model, wav)
            transcripts.append({"file": os.path.basename(wav), "model": model, "text": text})
            if re.search(r"\b" + re.escape(word) + r"\b", text, re.I):
                correct[model] += 1
            for gram, score in near_spellings(text, word):
                if letters(gram) == letters(word):
                    continue
                key = gram.lower()
                heard[key]["count"] += 1
                heard[key]["models"].add(model)
                heard[key]["similarity"] = max(heard[key]["similarity"], score)

    variants = []
    for key, info in sorted(heard.items(), key=lambda kv: (-kv[1]["count"], -kv[1]["similarity"])):
        real = None if words is None else all(w in words for w in key.split())
        already = mapped.get(key)
        variants.append({
            "heard": key,
            "count": info["count"],
            "models": sorted(info["models"]),
            "similarity": round(info["similarity"], 2),
            "realWord": real,
            "alreadyMappedTo": already,
            # Real words would be rewritten whenever they are actually said.
            "suggested": real is not True and already is None,
        })

    return {
        "status": "ok",
        "word": word,
        "takes": len(wavs),
        "models": models,
        "correctByModel": correct,
        "variants": variants,
        "transcripts": transcripts,
        "dictionary": words is not None,
    }


def apply(word, variants, restart=True):
    # `voxtype config set text.replacements.<k>` rewrites an inline
    # `replacements = { ... }` under [text] as a [text.replacements] table and
    # drops the entries that were inline. Remember them and put back any that go.
    before = current_replacements()
    mapped = []
    failed = []
    for v in variants:
        key = re.sub(r"\s+", " ", v.strip().lower())
        if not key or letters(key) == letters(word):
            continue
        proc = run(["voxtype", "config", "set", f"text.replacements.{key}", word])
        (mapped if proc.returncode == 0 else failed).append(
            key if proc.returncode == 0 else {"heard": key, "error": (proc.stderr or proc.stdout).strip()})

    after = current_replacements()
    restored = []
    for key, value in before.items():
        if key not in after and run(["voxtype", "config", "set", f"text.replacements.{key}", value]).returncode == 0:
            restored.append(key)

    prompt = run(["voxtype", "config", "get", "whisper.initial_prompt"]).stdout.strip()
    parts = [] if prompt in ("", "null") else [p.strip() for p in prompt.split(",") if p.strip()]
    prompt_changed = word not in parts
    if prompt_changed:
        parts.append(word)
        proc = run(["voxtype", "config", "set", "whisper.initial_prompt", ", ".join(parts)])
        if proc.returncode != 0:
            failed.append({"heard": "whisper.initial_prompt", "error": (proc.stderr or proc.stdout).strip()})

    restarted = False
    if restart and (mapped or prompt_changed):
        restarted = run(["systemctl", "--user", "restart", "voxtype.service"]).returncode == 0

    return {
        "status": "ok" if not failed else "partial",
        "word": word,
        "mapped": mapped,
        "restored": restored,
        "failed": failed,
        "prompt": ", ".join(parts),
        "restarted": restarted,
    }


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("probe")
    p.add_argument("word")
    p.add_argument("wavs", nargs="+")
    p.add_argument("--models", default="", help="comma-separated; default: dictation model plus base.en if installed")
    a = sub.add_parser("apply")
    a.add_argument("word")
    a.add_argument("variants", nargs="*")
    a.add_argument("--no-restart", action="store_true")
    args = ap.parse_args()

    try:
        if args.cmd == "probe":
            models = [m.strip() for m in args.models.split(",") if m.strip()] or default_models()
            wavs = [w for w in args.wavs if os.path.exists(w)]
            if not wavs:
                raise ValueError("no recordings found")
            result = probe(args.word.strip(), wavs, models)
        else:
            result = apply(args.word.strip(), args.variants, restart=not args.no_restart)
    except Exception as exc:
        result = {"status": "error", "message": str(exc)}
    json.dump(result, sys.stdout)
    print()
    sys.exit(0 if result.get("status") != "error" else 1)


if __name__ == "__main__":
    main()
