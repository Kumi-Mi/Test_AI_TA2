import csv
import gzip
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from build_vocabulary_catalog import (
    CSV_COLUMNS,
    DictionaryLookup,
    build_catalog,
    resolve_gloss,
)


class VocabularyCatalogPipelineTest(unittest.TestCase):
    def test_uses_every_trace_column_and_joins_vietnamese_meanings(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            dictionary = root / "dictionary"
            dictionary.mkdir()
            (dictionary / "directoryEng1.csv").write_text(
                "apple\t- quả táo\\n- cây táo\n"
                "woman [01/'wumən/]\t- phụ nữ\n"
                "are\t- đơn vị diện tích\n"
                "be\t- thì, là\n"
                "eat [01/i:t/]\tnhư [03ate]\n"
                "ate [01/i:t/]\t[01* động từ]\\n- ăn\n"
                "drink\t[01* dtừ]\\n- đồ uống\\n[01* ngđtừ]\\n- uống\n"
                "bread\t[01* ngđtừ]\\n- làm thủng\\n[01* dtừ]\\n- bánh mì\n"
                "my\t[01* ttừ sở hữu]\\n- của tôi\\n[01* thán từ]\\n- ôi chao\n"
                "we\t[01* dtừ]\\n- chúng tôi, chúng ta\n",
                encoding="utf-8",
            )
            traces = root / "traces.csv.gz"
            rows = [
                {
                    "p_recall": "0.50",
                    "timestamp": "100",
                    "delta": "3600",
                    "user_id": "u1",
                    "learning_language": "en",
                    "ui_language": "es",
                    "lexeme_id": "apple-id",
                    "lexeme_string": "apple/apple<n><sg>",
                    "history_seen": "2",
                    "history_correct": "1",
                    "session_seen": "2",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.70",
                    "timestamp": "390",
                    "delta": "3600",
                    "user_id": "u9",
                    "learning_language": "en",
                    "ui_language": "it",
                    "lexeme_id": "my-id",
                    "lexeme_string": "my/my<det><pos><p1><sg>",
                    "history_seen": "5",
                    "history_correct": "4",
                    "session_seen": "1",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.70",
                    "timestamp": "395",
                    "delta": "3600",
                    "user_id": "u10",
                    "learning_language": "en",
                    "ui_language": "it",
                    "lexeme_id": "we-id",
                    "lexeme_string": "we/prpers<prn><subj><p1><pl>",
                    "history_seen": "5",
                    "history_correct": "4",
                    "session_seen": "1",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.70",
                    "timestamp": "370",
                    "delta": "3600",
                    "user_id": "u7",
                    "learning_language": "en",
                    "ui_language": "it",
                    "lexeme_id": "drink-id",
                    "lexeme_string": "drink/drink<vblex><pres>",
                    "history_seen": "5",
                    "history_correct": "4",
                    "session_seen": "1",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.70",
                    "timestamp": "380",
                    "delta": "3600",
                    "user_id": "u8",
                    "learning_language": "en",
                    "ui_language": "it",
                    "lexeme_id": "bread-id",
                    "lexeme_string": "bread/bread<n><sg>",
                    "history_seen": "5",
                    "history_correct": "4",
                    "session_seen": "1",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.80",
                    "timestamp": "350",
                    "delta": "3600",
                    "user_id": "u5",
                    "learning_language": "en",
                    "ui_language": "it",
                    "lexeme_id": "be-id",
                    "lexeme_string": "are/be<vbser><pres>",
                    "history_seen": "5",
                    "history_correct": "4",
                    "session_seen": "1",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.70",
                    "timestamp": "360",
                    "delta": "3600",
                    "user_id": "u6",
                    "learning_language": "en",
                    "ui_language": "it",
                    "lexeme_id": "eat-id",
                    "lexeme_string": "eat/eat<vblex><pres>",
                    "history_seen": "5",
                    "history_correct": "4",
                    "session_seen": "1",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.75",
                    "timestamp": "200",
                    "delta": "7200",
                    "user_id": "u2",
                    "learning_language": "en",
                    "ui_language": "vi",
                    "lexeme_id": "apple-id",
                    "lexeme_string": "apple/apple<n><sg>",
                    "history_seen": "4",
                    "history_correct": "3",
                    "session_seen": "1",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.40",
                    "timestamp": "300",
                    "delta": "10800",
                    "user_id": "u3",
                    "learning_language": "en",
                    "ui_language": "it",
                    "lexeme_id": "woman-id",
                    "lexeme_string": "women/woman<n><pl>",
                    "history_seen": "3",
                    "history_correct": "1",
                    "session_seen": "2",
                    "session_correct": "1",
                },
                {
                    "p_recall": "0.90",
                    "timestamp": "400",
                    "delta": "1800",
                    "user_id": "u4",
                    "learning_language": "es",
                    "ui_language": "en",
                    "lexeme_id": "hola-id",
                    "lexeme_string": "hola/hola<ij>",
                    "history_seen": "8",
                    "history_correct": "7",
                    "session_seen": "1",
                    "session_correct": "1",
                },
            ]
            with gzip.open(traces, "wt", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=CSV_COLUMNS)
                writer.writeheader()
                writer.writerows(rows)

            payload = build_catalog(traces, dictionary)

            metadata = payload["metadata"]
            self.assertEqual(metadata["rowsScanned"], 10)
            self.assertEqual(metadata["englishRows"], 9)
            self.assertEqual(metadata["catalogRows"], 9)
            self.assertEqual(metadata["droppedEnglishRows"], 0)
            self.assertEqual(metadata["firstTimestamp"], 100)
            self.assertEqual(metadata["lastTimestamp"], 400)
            self.assertEqual(metadata["columnsUsed"], CSV_COLUMNS)
            self.assertEqual(metadata["languageCounts"], {"en": 9, "es": 1})
            self.assertEqual(
                metadata["uiLanguageCounts"], {"es": 1, "vi": 1, "it": 7}
            )

            entries = {entry["word"]: entry for entry in payload["entries"]}
            apple = entries["apple"]
            self.assertEqual(apple["meaning"], "quả táo")
            self.assertEqual(apple["traceCount"], 2)
            self.assertAlmostEqual(apple["meanRecall"], 0.625)
            self.assertAlmostEqual(apple["meanDeltaHours"], 1.5)
            self.assertEqual(apple["totalSessionSeen"], 3)
            self.assertEqual(apple["totalSessionCorrect"], 2)
            self.assertEqual(apple["firstTimestamp"], 100)
            self.assertEqual(apple["lastTimestamp"], 200)
            self.assertEqual(apple["lexemeCount"], 1)
            self.assertAlmostEqual(apple["meanHistorySeen"], 3)
            self.assertAlmostEqual(apple["meanHistoryCorrect"], 2)
            self.assertAlmostEqual(apple["sessionAccuracy"], 2 / 3)

            self.assertEqual(entries["women"]["meaning"], "phụ nữ")
            self.assertEqual(entries["are"]["meaning"], "thì, là")
            self.assertEqual(entries["eat"]["meaning"], "ăn")
            self.assertEqual(entries["drink"]["meaning"], "uống")
            self.assertEqual(entries["bread"]["meaning"], "bánh mì")
            self.assertEqual(entries["my"]["meaning"], "của tôi")
            self.assertEqual(entries["we"]["meaning"], "chúng tôi, chúng ta")
            self.assertNotIn("hola", entries)

    def test_rejects_dictionary_cross_references_and_applies_modern_glosses(self) -> None:
        dictionary = DictionaryLookup(
            {
                "see": "[01* đtừ]\\n- /seen/\\n- thấy, nhìn thấy",
                "turtle": "[01* dtừ]\\n- (như) [03turtle-dove]\\n- con rùa",
                "let": "[01* ngđtừ]\\n- (cổ) ngăn cản\\n[01* ngđtừ let]\\n- để cho, cho phép",
                "want": "[01* ngđtừ]\\n- thiếu\\n- muốn",
            }
        )

        self.assertEqual(resolve_gloss(dictionary, "see", "see", "vblex"), "thấy, nhìn thấy")
        self.assertEqual(resolve_gloss(dictionary, "turtle", "turtles", "n"), "con rùa")
        self.assertEqual(resolve_gloss(dictionary, "let", "lets", "vblex"), "cho phép, để cho")
        self.assertEqual(resolve_gloss(dictionary, "want", "wanted", "vblex"), "muốn")


if __name__ == "__main__":
    unittest.main()
