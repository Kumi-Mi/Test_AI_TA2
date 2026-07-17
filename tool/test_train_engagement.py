import json
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from train_engagement import vector


class EngagementFeatureContractTest(unittest.TestCase):
    def test_python_training_matches_shared_contract(self) -> None:
        contract_path = pathlib.Path(__file__).with_name(
            "engagement_feature_contract.json"
        )
        contract = json.loads(contract_path.read_text(encoding="utf-8"))
        row = {key: str(value) for key, value in contract["input"].items()}

        actual = vector(row)

        self.assertEqual(len(actual), len(contract["expected"]))
        for value, expected in zip(actual, contract["expected"], strict=True):
            self.assertAlmostEqual(value, expected, places=12)


if __name__ == "__main__":
    unittest.main()
