import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/services/pronunciation_scorer.dart';

void main() {
  const scorer = PronunciationScorer();

  test('ignores punctuation and letter case', () {
    expect(
      scorer.score('Practice makes progress.', 'practice makes progress'),
      100,
    );
  });

  test('penalises missing and substituted words', () {
    final score = scorer.score(
      'The library closes at nine',
      'The library opens nine',
    );

    expect(score, inInclusiveRange(50, 75));
  });

  test('returns zero when no speech was recognised', () {
    expect(scorer.score('Keep going', ''), 0);
  });
}
