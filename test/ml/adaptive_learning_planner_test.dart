import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:learnflow/ml/adaptive_learning_planner.dart';

void main() {
  const planner = AdaptiveLearningPlanner();

  test(
    'an overloaded learner receives a gentle review of the riskiest word',
    () {
      const session = SessionFeatures(
        winRate: 0.88,
        consecutiveWins: 5,
        consecutiveLosses: 0,
        completionSpeedRatio: 0.9,
        sessionMinutes: 52,
      );
      const words = [
        VocabularyMemory(
          id: 'steady',
          word: 'steady',
          meaning: 'ổn định',
          features: WordMemoryFeatures(
            responseTimeSeconds: 1.4,
            errorCount: 0,
            hoursSinceLastSeen: 24,
            historySeen: 9,
            historyCorrect: 8,
          ),
        ),
        VocabularyMemory(
          id: 'fragile',
          word: 'fragile',
          meaning: 'dễ vỡ',
          features: WordMemoryFeatures(
            responseTimeSeconds: 4.8,
            errorCount: 2,
            hoursSinceLastSeen: 24 * 10,
            historySeen: 4,
            historyCorrect: 2,
          ),
        ),
      ];

      final plan = planner.compose(session: session, vocabulary: words);

      expect(plan.recommendation.difficulty, LearningDifficulty.gentleReview);
      expect(plan.orderedVocabulary.first.word, 'fragile');
      expect(plan.game, MiniGameType.wordCatch);
    },
  );

  test('a focused learner keeps the gentle word-catch game', () {
    const session = SessionFeatures(
      winRate: 0.68,
      consecutiveWins: 2,
      consecutiveLosses: 0,
      completionSpeedRatio: 1,
      sessionMinutes: 18,
    );

    final plan = planner.compose(session: session, vocabulary: const []);

    expect(plan.recommendation.difficulty, LearningDifficulty.balanced);
    expect(plan.game, MiniGameType.wordCatch);
  });

  test('a bored learner is routed to the text-cipher challenge', () {
    const session = SessionFeatures(
      winRate: 0.96,
      consecutiveWins: 7,
      consecutiveLosses: 0,
      completionSpeedRatio: 0.55,
      sessionMinutes: 12,
    );

    final plan = planner.compose(session: session, vocabulary: const []);

    expect(plan.recommendation.difficulty, LearningDifficulty.challenge);
    expect(plan.game, MiniGameType.textCipher);
  });
}
