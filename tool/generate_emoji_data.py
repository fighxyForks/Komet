#!/usr/bin/env python3
"""Generate assets/emoji_data.json from Unicode emoji-test + CLDR annotations.

Sources (Unicode License — https://www.unicode.org/license.txt):
  - https://www.unicode.org/Public/emoji/16.0/emoji-test.txt
  - CLDR annotations (en/ru) via unicode-org/cldr-json
  - Merged with assets/emoji_keywords.json (existing RU/EN tokens)

Unicode Emoji version embedded in the asset: 16.0
"""

from __future__ import annotations

import json
import re
import sys
import urllib.request
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "emoji_data.json"
EXISTING_KEYWORDS = ROOT / "assets" / "emoji_keywords.json"

EMOJI_TEST_URL = "https://www.unicode.org/Public/emoji/16.0/emoji-test.txt"
CLDR_EN = "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/en/annotations.json"
CLDR_RU = "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/ru/annotations.json"
CLDR_EN_DER = "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-derived-full/annotationsDerived/en/annotations.json"
CLDR_RU_DER = "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-derived-full/annotationsDerived/ru/annotations.json"

UNICODE_EMOJI_VERSION = "16.0"

SKIN_TONES = ("\U0001f3fb", "\U0001f3fc", "\U0001f3fd", "\U0001f3fe", "\U0001f3ff")

GROUP_MAP = {
    "Smileys & Emotion": "smileysPeople",
    "People & Body": "smileysPeople",
    "Animals & Nature": "animalsNature",
    "Food & Drink": "foodDrink",
    "Travel & Places": "travelPlaces",
    "Activities": "activity",
    "Objects": "objects",
    "Symbols": "symbols",
    "Flags": "flags",
}

CATEGORIES = [
    "smileysPeople",
    "animalsNature",
    "foodDrink",
    "activity",
    "travelPlaces",
    "objects",
    "symbols",
    "flags",
]

LINE_RE = re.compile(
    r"^([0-9A-F ]+)\s*;\s*fully-qualified\s*#\s*(\S+)\s+E([0-9.]+)\s+(.*)$"
)
WORD_RE = re.compile(r"[0-9a-zа-яё\-]+", re.IGNORECASE | re.UNICODE)


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=120) as resp:
        return resp.read()


def parse_annotations(blob: bytes) -> dict[str, list[str]]:
    data = json.loads(blob.decode("utf-8"))
    inner = data["annotations"]["annotations"]
    out: dict[str, list[str]] = {}
    for cp, meta in inner.items():
        tokens: list[str] = []
        for key in ("default", "tts"):
            vals = meta.get(key) or []
            if isinstance(vals, str):
                vals = [vals]
            for v in vals:
                tokens.extend(WORD_RE.findall(v.lower()))
        if tokens:
            out[cp] = tokens
    return out


def has_skin_tone(emoji: str) -> bool:
    return any(t in emoji for t in SKIN_TONES)


def strip_skin_tones(emoji: str) -> str:
    for t in SKIN_TONES:
        emoji = emoji.replace(t, "")
    return emoji


def version_to_int(v: str) -> int:
    parts = v.split(".")
    major = int(parts[0])
    minor = int(parts[1]) if len(parts) > 1 else 0
    return major * 10 + minor


def tokenize_blob(text: str) -> list[str]:
    return WORD_RE.findall(text.lower())


def main() -> int:
    cache = Path("/tmp/emoji-src")
    cache.mkdir(parents=True, exist_ok=True)

    def cached(name: str, url: str) -> bytes:
        path = cache / name
        if path.exists() and path.stat().st_size > 0:
            return path.read_bytes()
        data = fetch(url)
        path.write_bytes(data)
        return data

    test_txt = cached("emoji-test.txt", EMOJI_TEST_URL).decode("utf-8")
    en = parse_annotations(cached("annotations-en.json", CLDR_EN))
    ru = parse_annotations(cached("annotations-ru.json", CLDR_RU))
    try:
        en_d = parse_annotations(cached("annotationsDerived-en.json", CLDR_EN_DER))
        for k, v in en_d.items():
            en.setdefault(k, []).extend(v)
    except Exception:
        pass
    try:
        ru_d = parse_annotations(cached("annotationsDerived-ru.json", CLDR_RU_DER))
        for k, v in ru_d.items():
            ru.setdefault(k, []).extend(v)
    except Exception:
        pass

    existing: dict[str, str] = {}
    if EXISTING_KEYWORDS.exists():
        existing = json.loads(EXISTING_KEYWORDS.read_text(encoding="utf-8"))

    group = ""
    entries: list[dict] = []
    by_base_skins: dict[str, list[str]] = defaultdict(list)
    bases_order: list[str] = []
    meta: dict[str, dict] = {}

    for line in test_txt.splitlines():
        if line.startswith("# group:"):
            group = line.split(":", 1)[1].strip()
            continue
        if "; fully-qualified" not in line:
            continue
        m = LINE_RE.match(line.strip())
        if not m:
            continue
        emoji = m.group(2)
        ver = m.group(3)
        name = m.group(4).strip()
        cat = GROUP_MAP.get(group)
        if cat is None:
            continue
        if has_skin_tone(emoji):
            base = strip_skin_tones(emoji)
            by_base_skins[base].append(emoji)
            continue
        if emoji not in meta:
            bases_order.append(emoji)
            meta[emoji] = {
                "e": emoji,
                "n": name,
                "c": cat,
                "v": version_to_int(ver),
            }

    items = []
    for emoji in bases_order:
        info = meta[emoji]
        skins = by_base_skins.get(emoji, [])
        skin_ok = 1 if skins else 0
        tokens: list[str] = []
        tokens.extend(tokenize_blob(info["n"]))
        tokens.extend(en.get(emoji, []))
        tokens.extend(ru.get(emoji, []))
        if emoji in existing:
            tokens.extend(tokenize_blob(existing[emoji]))
        # dedupe preserve order
        seen = set()
        uniq = []
        for t in tokens:
            if len(t) < 2:
                continue
            if t not in seen:
                seen.add(t)
                uniq.append(t)
        row = [
            info["e"],
            info["n"],
            CATEGORIES.index(info["c"]),
            info["v"],
            skin_ok,
            " ".join(uniq),
        ]
        if skin_ok:
            # stable Fitzpatrick order
            ordered = []
            for tone in SKIN_TONES:
                for s in skins:
                    if tone in s and s not in ordered:
                        ordered.append(s)
            for s in skins:
                if s not in ordered:
                    ordered.append(s)
            row.append(ordered)
        items.append(row)

    payload = {
        "unicodeEmojiVersion": UNICODE_EMOJI_VERSION,
        "categories": CATEGORIES,
        "items": items,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    size = OUT.stat().st_size
    print(f"wrote {OUT} ({size} bytes, {len(items)} base emoji)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
