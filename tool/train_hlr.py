#!/usr/bin/env python3
"""Train mobile HLR weights from the public Duolingo trace CSV(.gz).

No third-party Python packages are required. The output JSON is loaded directly
by the Flutter app on its next build.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import json
import math
import pathlib
import zlib
from collections.abc import Iterator

LN2 = math.log(2.0)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=pathlib.Path, help="Duolingo CSV or CSV.gz")
    parser.add_argument(
        "--output",
        type=pathlib.Path,
        default=pathlib.Path("assets/models/memory_model.json"),
    )
    parser.add_argument("--max-rows", type=int)
    parser.add_argument("--learning-rate", type=float, default=0.003)
    parser.add_argument("--l2", type=float, default=0.0001)
    return parser.parse_args()


def rows(path: pathlib.Path, max_rows: int | None) -> Iterator[dict[str, str]]:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8", newline="") as handle:
        for index, row in enumerate(csv.DictReader(handle)):
            if max_rows is not None and index >= max_rows:
                break
            yield row


def is_validation(row: dict[str, str]) -> bool:
    # User-level split prevents the same learner leaking into train and test.
    return zlib.crc32(row["user_id"].encode("utf-8")) % 10 == 0


def feature_vector(row: dict[str, str]) -> list[float]:
    seen = int(row["history_seen"])
    correct = int(row["history_correct"])
    accuracy = correct / seen if seen else 0.5
    return [1.0, math.log1p(seen), accuracy - 0.5]


def predict(weights: list[float], features: list[float], delta_hours: float) -> float:
    log2_half_life = sum(w * x for w, x in zip(weights, features, strict=True))
    half_life = min(max(2.0**log2_half_life, 0.25), 8760.0)
    return min(max(2.0 ** (-delta_hours / half_life), 0.0001), 0.9999)


def main() -> None:
    args = parse_args()
    weights = [5.0, 0.55, 2.2]  # safe cold-start values
    trained = 0

    for row in rows(args.input, args.max_rows):
        if is_validation(row):
            continue
        target = min(max(float(row["p_recall"]), 0.0001), 0.9999)
        delta_hours = max(float(row["delta"]) / 3600.0, 0.0)
        features = feature_vector(row)
        log2_half_life = sum(
            w * x for w, x in zip(weights, features, strict=True)
        )
        half_life = min(max(2.0**log2_half_life, 0.25), 8760.0)
        prediction = min(
            max(2.0 ** (-delta_hours / half_life), 0.0001), 0.9999
        )
        # Gradient of squared recall error through h = 2^(w.x), matching
        # the probability term in Settles & Meeder's public implementation.
        error_gradient = (
            2.0
            * (prediction - target)
            * (LN2**2)
            * prediction
            * (delta_hours / half_life)
        )
        rate = args.learning_rate / math.sqrt(1.0 + trained / 1_000_000)
        for index, value in enumerate(features):
            weights[index] -= rate * (
                error_gradient * value + args.l2 * weights[index]
            )
        trained += 1

    absolute_error = 0.0
    validated = 0
    for row in rows(args.input, args.max_rows):
        if not is_validation(row):
            continue
        target = min(max(float(row["p_recall"]), 0.0001), 0.9999)
        delta_hours = max(float(row["delta"]) / 3600.0, 0.0)
        absolute_error += abs(
            target - predict(weights, feature_vector(row), delta_hours)
        )
        validated += 1

    payload = {
        "schemaVersion": 1,
        "model": "half_life_regression",
        "source": "duolingo_halflife_regression_dataset",
        "featureOrder": ["bias", "seen", "accuracy", "responseTime", "errors"],
        "weights": {
            "bias": weights[0],
            "seen": weights[1],
            "accuracy": weights[2],
            # These features do not exist in the Duolingo release. Keep the
            # conservative baseline until app-specific events are available.
            "responseTime": -0.65,
            "errors": -0.8,
        },
        "training": {
            "rows": trained,
            "validationRows": validated,
            "validationMaeRecall": (
                absolute_error / validated if validated else None
            ),
            "split": "user_id crc32; 90% train / 10% validation",
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Wrote {args.output} ({trained:,} train / {validated:,} validation)")


if __name__ == "__main__":
    main()
