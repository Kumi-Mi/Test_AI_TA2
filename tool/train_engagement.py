#!/usr/bin/env python3
"""Train the three-class session-state model from labelled app sessions."""

from __future__ import annotations

import argparse
import csv
import json
import math
import pathlib
import zlib

LABELS = ["overloaded", "focused", "bored"]
FEATURES = [
    "bias",
    "winRate",
    "wins",
    "losses",
    "session",
    "extended",
    "fast",
    "slow",
    "fatigue",
    "winBalance",
    "speedBalance",
    "notExtended",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=pathlib.Path, help="Labelled app-session CSV")
    parser.add_argument(
        "--output",
        type=pathlib.Path,
        default=pathlib.Path("assets/models/engagement_model.json"),
    )
    parser.add_argument("--epochs", type=int, default=20)
    parser.add_argument("--learning-rate", type=float, default=0.03)
    parser.add_argument("--l2", type=float, default=0.0005)
    return parser.parse_args()


def vector(row: dict[str, str]) -> list[float]:
    win = min(max(float(row["win_rate"]), 0.0), 1.0)
    wins = min(max(int(row["consecutive_wins"]) / 8, 0.0), 1.0)
    losses = min(max(int(row["consecutive_losses"]) / 6, 0.0), 1.0)
    speed_ratio = float(row["completion_speed_ratio"])
    session_minutes = float(row["session_minutes"])
    session = min(max(session_minutes / 60, 0.0), 1.5)
    extended = min(max((session_minutes - 35) / 25, 0.0), 1.0)
    fast = min(max(1 - speed_ratio, 0.0), 1.0)
    slow = min(max(speed_ratio - 1, 0.0), 1.0)
    fatigue = session * (0.35 + 0.65 * max(wins, losses))
    return [
        1.0,
        win,
        wins,
        losses,
        session,
        extended,
        fast,
        slow,
        fatigue,
        min(max(1 - abs(win - 0.68) * 2, 0.0), 1.0),
        min(max(1 - abs(speed_ratio - 1), 0.0), 1.0),
        1 - extended,
    ]


def probabilities(weights: list[list[float]], features: list[float]) -> list[float]:
    logits = [sum(w * x for w, x in zip(row, features, strict=True)) for row in weights]
    ceiling = max(logits)
    exps = [math.exp(value - ceiling) for value in logits]
    total = sum(exps)
    return [value / total for value in exps]


def validation_key(row: dict[str, str], index: int) -> str:
    return row.get("user_id") or row.get("session_id") or str(index)


def main() -> None:
    args = parse_args()
    with args.input.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    weights = [[0.0 for _ in FEATURES] for _ in LABELS]
    for epoch in range(args.epochs):
        rate = args.learning_rate / math.sqrt(epoch + 1)
        for index, row in enumerate(rows):
            key = validation_key(row, index)
            if zlib.crc32(key.encode("utf-8")) % 10 == 0:
                continue
            features = vector(row)
            predicted = probabilities(weights, features)
            target = LABELS.index(row["label"])
            for class_index in range(len(LABELS)):
                error = predicted[class_index] - (1 if class_index == target else 0)
                for feature_index, value in enumerate(features):
                    weights[class_index][feature_index] -= rate * (
                        error * value + args.l2 * weights[class_index][feature_index]
                    )

    correct = 0
    validated = 0
    for index, row in enumerate(rows):
        key = validation_key(row, index)
        if zlib.crc32(key.encode("utf-8")) % 10 != 0:
            continue
        predicted = probabilities(weights, vector(row))
        correct += LABELS[predicted.index(max(predicted))] == row["label"]
        validated += 1

    payload = {
        "schemaVersion": 1,
        "model": "multiclass_softmax",
        "source": "labelled_learnflow_sessions",
        "featureOrder": FEATURES,
        "coefficients": dict(zip(LABELS, weights, strict=True)),
        "training": {
            "rows": len(rows) - validated,
            "validationRows": validated,
            "validationAccuracy": correct / validated if validated else None,
            "split": "user_id/session_id crc32; 90% train / 10% validation",
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Wrote {args.output} ({validated:,} validation sessions)")


if __name__ == "__main__":
    main()
