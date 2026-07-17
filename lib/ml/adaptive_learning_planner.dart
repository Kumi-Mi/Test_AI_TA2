import '../domain/learning_models.dart';
import 'adaptive_difficulty_adapter.dart';
import 'half_life_memory_predictor.dart';

class AdaptiveLearningPlanner {
  const AdaptiveLearningPlanner({
    this.memoryPredictor = const HalfLifeMemoryPredictor(),
    this.difficultyAdapter = const AdaptiveDifficultyAdapter(),
  });

  final HalfLifeMemoryPredictor memoryPredictor;
  final AdaptiveDifficultyAdapter difficultyAdapter;

  AdaptiveLearningPlan compose({
    required SessionFeatures session,
    required List<VocabularyMemory> vocabulary,
  }) {
    final recommendation = difficultyAdapter.recommend(session);
    final ordered =
        vocabulary
            .map(
              (item) => PlannedVocabulary(
                item: item,
                prediction: memoryPredictor.predict(item.features),
              ),
            )
            .toList()
          ..sort(
            (a, b) => a.prediction.recallProbability.compareTo(
              b.prediction.recallProbability,
            ),
          );

    final game = switch (recommendation.difficulty) {
      LearningDifficulty.gentleReview => MiniGameType.wordCatch,
      LearningDifficulty.balanced => MiniGameType.shadowSpeaking,
      LearningDifficulty.challenge => MiniGameType.textCipher,
    };

    return AdaptiveLearningPlan(
      recommendation: recommendation,
      orderedVocabulary: ordered,
      game: game,
    );
  }
}
