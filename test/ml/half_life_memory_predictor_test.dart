import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:learnflow/ml/half_life_memory_predictor.dart';

void main() {
  const predictor = HalfLifeMemoryPredictor();

  test('elapsed time advances from the persisted last-seen timestamp', () {
    final item = VocabularyMemory(
      id: 'steady',
      word: 'steady',
      meaning: 'ổn định',
      features: const WordMemoryFeatures(
        responseTimeSeconds: 2,
        errorCount: 0,
        hoursSinceLastSeen: 1.5,
        historySeen: 4,
        historyCorrect: 3,
      ),
      lastSeenAt: DateTime.utc(2026, 1, 1, 8),
    );

    final advanced = item.atTime(DateTime.utc(2026, 1, 1, 14, 30));

    expect(advanced.features.hoursSinceLastSeen, 8);
  });

  test('recall probability falls as time since the last encounter grows', () {
    const recent = WordMemoryFeatures(
      responseTimeSeconds: 2,
      errorCount: 0,
      hoursSinceLastSeen: 12,
      historySeen: 8,
      historyCorrect: 7,
    );

    final later = recent.copyWith(hoursSinceLastSeen: 24 * 14);

    expect(
      predictor.predict(later).recallProbability,
      lessThan(predictor.predict(recent).recallProbability),
    );
  });

  test('slow answers with repeated errors are scheduled earlier', () {
    const fluent = WordMemoryFeatures(
      responseTimeSeconds: 1.2,
      errorCount: 0,
      hoursSinceLastSeen: 72,
      historySeen: 6,
      historyCorrect: 5,
    );
    const struggling = WordMemoryFeatures(
      responseTimeSeconds: 5.5,
      errorCount: 2,
      hoursSinceLastSeen: 72,
      historySeen: 6,
      historyCorrect: 5,
    );

    final fluentResult = predictor.predict(fluent);
    final strugglingResult = predictor.predict(struggling);

    expect(
      strugglingResult.recallProbability,
      lessThan(fluentResult.recallProbability),
    );
    expect(
      strugglingResult.nextReviewInHours,
      lessThan(fluentResult.nextReviewInHours),
    );
  });

  test('corpus prior seeds a new word without becoming personal history', () {
    const item = VocabularyMemory(
      id: 'want',
      word: 'want',
      meaning: 'muốn',
      corpusPrior: VocabularyCorpusPrior(
        meanRecall: 0.86,
        meanDeltaHours: 196,
        meanHistorySeen: 38,
        meanHistoryCorrect: 32,
        sessionAccuracy: 0.88,
      ),
      features: WordMemoryFeatures(
        responseTimeSeconds: 2.5,
        errorCount: 0,
        hoursSinceLastSeen: 0,
        historySeen: 0,
        historyCorrect: 0,
      ),
    );

    final coldStart = predictor.predictVocabulary(item);
    final struggling = predictor.predictVocabulary(
      item.copyWith(
        features: const WordMemoryFeatures(
          responseTimeSeconds: 7,
          errorCount: 4,
          hoursSinceLastSeen: 72,
          historySeen: 12,
          historyCorrect: 4,
        ),
      ),
    );

    expect(coldStart.recallProbability, closeTo(0.86, 0.001));
    expect(item.features.historySeen, 0);
    expect(struggling.recallProbability, lessThan(coldStart.recallProbability));
  });
}
