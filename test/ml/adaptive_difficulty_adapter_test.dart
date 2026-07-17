import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:learnflow/ml/adaptive_difficulty_adapter.dart';

void main() {
  const adapter = AdaptiveDifficultyAdapter();

  test('keeps a steady learner in a balanced session', () {
    const features = SessionFeatures(
      winRate: 0.68,
      consecutiveWins: 2,
      consecutiveLosses: 0,
      completionSpeedRatio: 1,
      sessionMinutes: 18,
    );

    final result = adapter.recommend(features);

    expect(result.state, EngagementState.focused);
    expect(result.difficulty, LearningDifficulty.balanced);
  });

  test('reduces difficulty after a long high-streak session', () {
    const features = SessionFeatures(
      winRate: 0.9,
      consecutiveWins: 6,
      consecutiveLosses: 0,
      completionSpeedRatio: 0.82,
      sessionMinutes: 55,
    );

    final result = adapter.recommend(features);

    expect(result.state, EngagementState.overloaded);
    expect(result.difficulty, LearningDifficulty.gentleReview);
  });

  test('adds challenge when an early session is clearly too easy', () {
    const features = SessionFeatures(
      winRate: 0.96,
      consecutiveWins: 7,
      consecutiveLosses: 0,
      completionSpeedRatio: 0.55,
      sessionMinutes: 12,
    );

    final result = adapter.recommend(features);

    expect(result.state, EngagementState.bored);
    expect(result.difficulty, LearningDifficulty.challenge);
  });
}
