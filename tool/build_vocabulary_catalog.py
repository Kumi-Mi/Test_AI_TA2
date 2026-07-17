#!/usr/bin/env python3
"""Build the mobile English vocabulary catalog from Duolingo learning traces.

The Duolingo CSV supplies observed vocabulary, morphology, recall and practice
statistics. Vietnamese meanings are joined from the GPL-licensed Free
Vietnamese Dictionary Project export distributed by DictionaryForMIDs.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import json
import pathlib
import re
from collections import Counter
from datetime import UTC, datetime
from typing import Any

CSV_COLUMNS = [
    "p_recall",
    "timestamp",
    "delta",
    "user_id",
    "learning_language",
    "ui_language",
    "lexeme_id",
    "lexeme_string",
    "history_seen",
    "history_correct",
    "session_seen",
    "session_correct",
]

WORD_PATTERN = re.compile(r"^[a-z]+(?:['-][a-z]+)?$")
PRONUNCIATION_PATTERN = re.compile(r"\s*\[\d{2}/.*?/\]\s*")
MARKER_PATTERN = re.compile(r"\[\d{2}[^\]]*\]")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=pathlib.Path, help="Duolingo CSV or CSV.gz")
    parser.add_argument(
        "--dictionary-dir",
        required=True,
        type=pathlib.Path,
        help="Extracted DictionaryForMIDs directory containing directoryEng*.csv",
    )
    parser.add_argument(
        "--output",
        type=pathlib.Path,
        default=pathlib.Path("assets/data/duolingo_english_vocabulary.json"),
    )
    parser.add_argument("--max-rows", type=int)
    parser.add_argument("--max-entries", type=int)
    return parser.parse_args()


def _clean_headword(raw: str) -> str:
    return PRONUNCIATION_PATTERN.sub("", raw).strip().lower()


def _clean_meaning(raw: str) -> str | None:
    expanded = raw.replace("\\n", "\n")
    candidates = [line.strip() for line in expanded.splitlines()]
    preferred = [line for line in candidates if line.startswith("-")]
    for line in preferred or candidates:
        cleaned = line.lstrip("- ")
        cleaned = MARKER_PATTERN.sub("", cleaned)
        cleaned = re.sub(r"\s+", " ", cleaned).strip(" ;,")
        if (
            cleaned
            and cleaned.lower() not in {"xem", "như"}
            and not cleaned.lower().startswith(("xem ", "như "))
        ):
            return cleaned[:180]
    return None


def _dictionary_part_of_speech(marker: str) -> str | None:
    value = marker.lower()
    if any(token in value for token in ("ngđtừ", "nđtừ", "đtừ", "động từ", "trợ đtừ")):
        return "verb"
    if "dtừ" in value or "danh từ" in value:
        return "noun"
    if "ttừ" in value or "tính từ" in value:
        return "adjective"
    if "phtừ" in value or "phó từ" in value:
        return "adverb"
    if "đại từ" in value:
        return "pronoun"
    if "gtừ" in value or "giới từ" in value:
        return "preposition"
    if "ltừ" in value or "liên từ" in value:
        return "conjunction"
    return None


def _duolingo_part_of_speech(value: str) -> str | None:
    if value.startswith("vb"):
        return "verb"
    return {
        "n": "noun",
        "adj": "adjective",
        "adv": "adverb",
        "det": "adjective",
        "prn": "pronoun",
        "pr": "preposition",
        "cnjcoo": "conjunction",
        "cnjsub": "conjunction",
    }.get(value)


def _meaning_sections(raw: str) -> dict[str, str]:
    sections: dict[str, str] = {}
    current = "default"
    for line in raw.replace("\\n", "\n").splitlines():
        stripped = line.strip()
        marker = re.match(r"^\[01\*\s*([^\]]+)\]", stripped)
        if marker:
            current = _dictionary_part_of_speech(marker.group(1)) or "default"
            continue
        if not stripped.startswith("-"):
            continue
        meaning = _clean_meaning(stripped)
        if meaning is not None and current not in sections:
            sections[current] = meaning
    if not sections:
        meaning = _clean_meaning(raw)
        if meaning is not None:
            sections["default"] = meaning
    return sections


class DictionaryLookup:
    def __init__(self, raw_entries: dict[str, str]) -> None:
        self._raw_entries = raw_entries
        self._cache: dict[tuple[str, str | None], str | None] = {}

    def __len__(self) -> int:
        return len(self._raw_entries)

    def lookup(self, word: str, part_of_speech: str) -> str | None:
        canonical = _duolingo_part_of_speech(part_of_speech)
        return self._resolve(word, canonical, set())

    def _resolve(
        self,
        word: str,
        part_of_speech: str | None,
        visited: set[str],
    ) -> str | None:
        key = (word, part_of_speech)
        if key in self._cache:
            return self._cache[key]
        if word in visited or word not in self._raw_entries:
            return None
        raw = self._raw_entries[word]
        sections = _meaning_sections(raw)
        if part_of_speech in sections:
            self._cache[key] = sections[part_of_speech]
            return sections[part_of_speech]
        # FVDP's legacy "dtừ" marker is used for both nouns and pronouns.
        if part_of_speech == "pronoun" and "noun" in sections:
            self._cache[key] = sections["noun"]
            return sections["noun"]
        if "default" in sections:
            self._cache[key] = sections["default"]
            return sections["default"]
        next_visited = {*visited, word}
        for reference in re.findall(r"\[03([^\]]+)\]", raw):
            target = _clean_headword(reference.split(",", 1)[0])
            resolved = self._resolve(target, part_of_speech, next_visited)
            if resolved is not None:
                self._cache[key] = resolved
                return resolved
        if part_of_speech is None and sections:
            fallback = next(iter(sections.values()))
            self._cache[key] = fallback
            return fallback
        self._cache[key] = None
        return None


def load_dictionary(directory: pathlib.Path) -> DictionaryLookup:
    raw_entries: dict[str, str] = {}
    files = sorted(directory.glob("directoryEng*.csv"))
    if not files:
        raise FileNotFoundError(
            f"No directoryEng*.csv files found under {directory}"
        )
    for path in files:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            for line in handle:
                headword, separator, raw_meaning = line.rstrip("\n").partition("\t")
                if not separator:
                    continue
                word = _clean_headword(headword)
                if word and word not in raw_entries:
                    raw_entries[word] = raw_meaning

    return DictionaryLookup(raw_entries)


def _parse_lexeme(value: str) -> tuple[str, str, str]:
    surface, separator, tagged = value.partition("/")
    if not separator:
        return surface.lower(), surface.lower(), "unknown"
    lemma = tagged.split("<", 1)[0]
    match = re.search(r"<([^>]+)>", tagged)
    return surface.lower(), lemma.lower(), match.group(1) if match else "unknown"


def _new_stats(word: str) -> dict[str, Any]:
    return {
        "word": word,
        "lemmas": Counter(),
        "partsOfSpeech": Counter(),
        "meanings": Counter(),
        "lexemeIds": set(),
        "traceCount": 0,
        "recallSum": 0.0,
        "deltaHoursSum": 0.0,
        "historySeenSum": 0,
        "historyCorrectSum": 0,
        "totalSessionSeen": 0,
        "totalSessionCorrect": 0,
        "firstTimestamp": None,
        "lastTimestamp": None,
    }


def build_catalog(
    input_path: pathlib.Path,
    dictionary_dir: pathlib.Path,
    *,
    max_rows: int | None = None,
    max_entries: int | None = None,
) -> dict[str, Any]:
    dictionary = load_dictionary(dictionary_dir)
    opener = gzip.open if input_path.suffix == ".gz" else open
    language_counts: Counter[str] = Counter()
    ui_language_counts: Counter[str] = Counter()
    learners: set[str] = set()
    words: dict[str, dict[str, Any]] = {}
    rows_scanned = 0
    english_rows = 0
    first_timestamp: int | None = None
    last_timestamp: int | None = None

    with opener(input_path, "rt", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = [column for column in CSV_COLUMNS if column not in (reader.fieldnames or [])]
        if missing:
            raise ValueError(f"CSV is missing required columns: {', '.join(missing)}")
        for row in reader:
            if max_rows is not None and rows_scanned >= max_rows:
                break
            rows_scanned += 1
            timestamp = int(row["timestamp"])
            first_timestamp = (
                timestamp
                if first_timestamp is None
                else min(first_timestamp, timestamp)
            )
            last_timestamp = (
                timestamp if last_timestamp is None else max(last_timestamp, timestamp)
            )
            language = row["learning_language"]
            language_counts[language] += 1
            learners.add(row["user_id"])
            if language != "en":
                continue

            english_rows += 1
            ui_language_counts[row["ui_language"]] += 1
            word, lemma, part_of_speech = _parse_lexeme(row["lexeme_string"])
            if not WORD_PATTERN.fullmatch(word) or not 2 <= len(word) <= 24:
                continue
            meaning = dictionary.lookup(lemma, part_of_speech) or dictionary.lookup(
                word, part_of_speech
            )
            if meaning is None:
                continue

            stats = words.setdefault(word, _new_stats(word))
            stats["lemmas"][lemma] += 1
            stats["partsOfSpeech"][part_of_speech] += 1
            stats["meanings"][meaning] += 1
            stats["lexemeIds"].add(row["lexeme_id"])
            stats["traceCount"] += 1
            stats["recallSum"] += float(row["p_recall"])
            stats["deltaHoursSum"] += max(float(row["delta"]), 0.0) / 3600.0
            stats["historySeenSum"] += int(row["history_seen"])
            stats["historyCorrectSum"] += int(row["history_correct"])
            stats["totalSessionSeen"] += int(row["session_seen"])
            stats["totalSessionCorrect"] += int(row["session_correct"])
            current_first = stats["firstTimestamp"]
            current_last = stats["lastTimestamp"]
            stats["firstTimestamp"] = (
                timestamp if current_first is None else min(current_first, timestamp)
            )
            stats["lastTimestamp"] = (
                timestamp if current_last is None else max(current_last, timestamp)
            )

    entries = []
    for word, stats in words.items():
        trace_count = stats["traceCount"]
        mean_recall = stats["recallSum"] / trace_count
        mean_history_seen = stats["historySeenSum"] / trace_count
        mean_history_correct = stats["historyCorrectSum"] / trace_count
        prior_seen = min(max(round(mean_history_seen), 1), 20)
        prior_correct = min(max(round(mean_history_correct), 0), prior_seen)
        session_seen = stats["totalSessionSeen"]
        session_accuracy = (
            stats["totalSessionCorrect"] / session_seen if session_seen else 0.5
        )
        prior_errors = min(max(round((1.0 - session_accuracy) * 3), 0), 3)
        lemma = stats["lemmas"].most_common(1)[0][0]
        part_of_speech = stats["partsOfSpeech"].most_common(1)[0][0]
        meaning = stats["meanings"].most_common(1)[0][0]
        entries.append(
            {
                "id": f"duolingo:{word}",
                "word": word,
                "lemma": lemma,
                "partOfSpeech": part_of_speech,
                "meaning": meaning,
                "lexemeIds": sorted(stats["lexemeIds"]),
                "lexemeCount": len(stats["lexemeIds"]),
                "traceCount": trace_count,
                "meanRecall": mean_recall,
                "meanDeltaHours": stats["deltaHoursSum"] / trace_count,
                "meanHistorySeen": mean_history_seen,
                "meanHistoryCorrect": mean_history_correct,
                "totalSessionSeen": stats["totalSessionSeen"],
                "totalSessionCorrect": stats["totalSessionCorrect"],
                "firstTimestamp": stats["firstTimestamp"],
                "lastTimestamp": stats["lastTimestamp"],
                "initialHistorySeen": prior_seen,
                "initialHistoryCorrect": prior_correct,
                "initialErrorCount": prior_errors,
            }
        )

    entries.sort(key=lambda entry: (-entry["traceCount"], entry["word"]))
    if max_entries is not None:
        entries = entries[:max_entries]
    return {
        "schemaVersion": 1,
        "metadata": {
            "source": "duolingo_halflife_regression_dataset",
            "generatedAt": datetime.now(UTC).isoformat(),
            "rowsScanned": rows_scanned,
            "englishRows": english_rows,
            "uniqueLearners": len(learners),
            "firstTimestamp": first_timestamp,
            "lastTimestamp": last_timestamp,
            "columnsUsed": CSV_COLUMNS,
            "languageCounts": dict(language_counts),
            "uiLanguageCounts": dict(ui_language_counts),
            "dictionarySource": "Free Vietnamese Dictionary Project",
            "dictionaryLicense": "GPL-2.0-or-later",
            "dictionaryEntriesLoaded": len(dictionary),
            "catalogEntries": len(entries),
        },
        "entries": entries,
    }


def main() -> None:
    args = parse_args()
    payload = build_catalog(
        args.input,
        args.dictionary_dir,
        max_rows=args.max_rows,
        max_entries=args.max_entries,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    metadata = payload["metadata"]
    print(
        f"Wrote {args.output} ({metadata['catalogEntries']:,} words from "
        f"{metadata['englishRows']:,} English traces / "
        f"{metadata['rowsScanned']:,} total rows)"
    )


if __name__ == "__main__":
    main()
