import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/data/learning_session_controller.dart';
import 'package:learnflow/domain/learning_models.dart';

void main() {
  test('keeps cumulative errors and compares speed with learner history', () {
    final controller = LearningSessionController.demo(
      vocabulary: const [
        VocabularyMemory(
          id: 'fragile',
          word: 'fragile',
          meaning: 'dễ vỡ',
          features: WordMemoryFeatures(
            responseTimeSeconds: 4,
            errorCount: 2,
            hoursSinceLastSeen: 24,
            historySeen: 4,
            historyCorrect: 2,
          ),
        ),
      ],
    );

    controller.recordAnswer(
      vocabularyId: 'fragile',
      correct: true,
      responseSeconds: 2,
    );

    expect(controller.vocabulary.single.features.errorCount, 2);
    expect(controller.sessionFeatures.completionSpeedRatio, 0.5);
  });
}
