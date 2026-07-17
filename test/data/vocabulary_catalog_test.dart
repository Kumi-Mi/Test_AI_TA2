import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/data/learning_session_controller.dart';
import 'package:learnflow/data/vocabulary_catalog.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('catalog JSON becomes playable vocabulary with Duolingo priors', () {
    final catalog = VocabularyCatalog.fromJson({
      'schemaVersion': 2,
      'metadata': {
        'source': 'duolingo_halflife_regression_dataset',
        'rowsScanned': 13000000,
        'englishRows': 5000000,
        'catalogRows': 4700000,
        'droppedEnglishRows': 300000,
        'uniqueLearners': 100000,
        'catalogEntries': 2400,
        'firstTimestamp': 1362082504,
        'lastTimestamp': 1400000000,
        'languageCounts': const {'en': 5000000, 'es': 3000000},
        'uiLanguageCounts': const {'es': 4000000, 'it': 1000000},
        'columnsUsed': const [
          'p_recall',
          'timestamp',
          'delta',
          'user_id',
          'learning_language',
          'ui_language',
          'lexeme_id',
          'lexeme_string',
          'history_seen',
          'history_correct',
          'session_seen',
          'session_correct',
        ],
      },
      'entries': const [
        {
          'id': 'duolingo:women',
          'word': 'women',
          'lemma': 'woman',
          'partOfSpeech': 'n',
          'meaning': 'phụ nữ',
          'traceCount': 320,
          'lexemeIds': ['woman-n-pl'],
          'meanRecall': 0.62,
          'meanDeltaHours': 72.0,
          'meanHistorySeen': 6.0,
          'meanHistoryCorrect': 4.0,
          'sessionAccuracy': 0.75,
        },
      ],
    });

    expect(catalog.metadata.rowsScanned, 13000000);
    expect(catalog.metadata.columnsUsed, hasLength(12));
    expect(catalog.metadata.catalogRows, 4700000);
    expect(catalog.metadata.droppedEnglishRows, 300000);
    expect(catalog.metadata.languageCounts, contains('en'));
    expect(catalog.metadata.uiLanguageCounts, contains('es'));
    expect(catalog.metadata.firstTraceAt, isNotNull);
    expect(catalog.vocabulary, hasLength(1));
    expect(catalog.vocabulary.single.word, 'women');
    expect(catalog.vocabulary.single.lemma, 'woman');
    expect(catalog.vocabulary.single.partOfSpeech, 'n');
    expect(catalog.vocabulary.single.traceCount, 320);
    expect(catalog.vocabulary.single.lexemeCount, 1);
    expect(catalog.vocabulary.single.datasetRecall, 0.62);
    expect(catalog.vocabulary.single.corpusPrior!.meanDeltaHours, 72);
    expect(catalog.vocabulary.single.corpusPrior!.meanHistorySeen, 6);
    expect(catalog.vocabulary.single.corpusPrior!.sessionAccuracy, 0.75);
    expect(catalog.vocabulary.single.features.hoursSinceLastSeen, 0);
    expect(catalog.vocabulary.single.features.historySeen, 0);
    expect(catalog.vocabulary.single.features.historyCorrect, 0);
    expect(catalog.vocabulary.single.features.errorCount, 0);
  });

  test('catalog keeps personal progress while refreshing dataset metadata', () {
    final catalog = VocabularyCatalog.fromJson({
      'schemaVersion': 2,
      'metadata': {
        'source': 'duolingo_halflife_regression_dataset',
        'rowsScanned': 10,
        'englishRows': 10,
        'catalogRows': 9,
        'droppedEnglishRows': 1,
        'uniqueLearners': 2,
        'catalogEntries': 1,
        'firstTimestamp': 100,
        'lastTimestamp': 200,
        'languageCounts': const {'en': 10},
        'uiLanguageCounts': const {'vi': 10},
        'columnsUsed': const <String>[],
      },
      'entries': const [
        {
          'id': 'duolingo:women',
          'word': 'women',
          'lemma': 'woman',
          'partOfSpeech': 'n',
          'meaning': 'phụ nữ',
          'traceCount': 320,
          'lexemeIds': ['woman-n-pl'],
          'meanRecall': 0.62,
          'meanDeltaHours': 72.0,
          'meanHistorySeen': 6.0,
          'meanHistoryCorrect': 4.0,
          'sessionAccuracy': 0.75,
        },
      ],
    });
    final lastSeen = DateTime.utc(2026, 7, 18);
    final stored = VocabularyMemory(
      id: 'legacy-women',
      word: 'women',
      meaning: 'old value',
      lastSeenAt: lastSeen,
      features: const WordMemoryFeatures(
        responseTimeSeconds: 1.4,
        errorCount: 2,
        hoursSinceLastSeen: 0,
        historySeen: 10,
        historyCorrect: 8,
      ),
    );

    final merged = catalog.mergeProgress([stored]).single;

    expect(merged.id, 'duolingo:women');
    expect(merged.meaning, 'phụ nữ');
    expect(merged.lemma, 'woman');
    expect(merged.traceCount, 320);
    expect(merged.lexemeCount, 1);
    expect(merged.features.historySeen, 10);
    expect(merged.features.errorCount, 2);
    expect(merged.lastSeenAt, lastSeen);
  });

  testWidgets('app startup loads the generated Duolingo catalog asset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final controller = await tester.runAsync(LearningSessionController.create);

    expect(controller, isNotNull);
    expect(controller!.catalogMetadata.columnsUsed, hasLength(12));
    expect(controller.catalogMetadata.rowsScanned, greaterThan(12000000));
    expect(controller.vocabulary.length, greaterThan(1000));
    expect(controller.vocabulary.any((item) => item.word == 'apple'), isTrue);
    final byWord = {for (final item in controller.vocabulary) item.word: item};
    expect(byWord['see']!.meaning, contains('thấy'));
    expect(byWord['turtles']!.meaning, contains('rùa'));
    expect(byWord['want']!.meaning, 'muốn');
    expect(byWord['let']!.meaning, 'cho phép, để cho');
    expect(byWord['summer']!.meaning, 'mùa hè');
    expect(byWord['bridge']!.meaning, 'cây cầu');
    expect(byWord['phone']!.meaning, 'điện thoại');
  });
}
