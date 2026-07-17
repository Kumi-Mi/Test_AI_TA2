import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:learnflow/ml/adaptive_difficulty_adapter.dart';

void main() {
  test('Dart inference matches the shared engagement feature contract', () {
    final contract =
        jsonDecode(
              File('tool/engagement_feature_contract.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final input = contract['input'] as Map<String, dynamic>;
    final expected = (contract['expected'] as List<dynamic>)
        .map((value) => (value as num).toDouble())
        .toList();

    final actual = const AdaptiveDifficultyAdapter().featureVector(
      SessionFeatures(
        winRate: (input['win_rate'] as num).toDouble(),
        consecutiveWins: input['consecutive_wins'] as int,
        consecutiveLosses: input['consecutive_losses'] as int,
        completionSpeedRatio: (input['completion_speed_ratio'] as num)
            .toDouble(),
        sessionMinutes: (input['session_minutes'] as num).toDouble(),
      ),
    );

    expect(actual, hasLength(expected.length));
    for (var index = 0; index < expected.length; index++) {
      expect(actual[index], closeTo(expected[index], 1e-12));
    }
  });
}
