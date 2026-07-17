import 'dart:math' as math;

import '../domain/learning_models.dart';

/// Three-class linear softmax inference for session engagement.
///
/// The default coefficients are a conservative cold-start baseline. The
/// training script replaces them with learned weights after labelled session
/// feedback has been collected.
class AdaptiveDifficultyAdapter {
  const AdaptiveDifficultyAdapter({
    this.weights = const EngagementModelWeights.coldStart(),
  });

  final EngagementModelWeights weights;

  List<double> featureVector(SessionFeatures input) {
    final winRate = input.winRate.clamp(0, 1).toDouble();
    final wins = (input.consecutiveWins / 8).clamp(0, 1).toDouble();
    final losses = (input.consecutiveLosses / 6).clamp(0, 1).toDouble();
    final session = (input.sessionMinutes / 60).clamp(0, 1.5).toDouble();
    final extended = ((input.sessionMinutes - 35) / 25).clamp(0, 1).toDouble();
    final fast = (1 - input.completionSpeedRatio).clamp(0, 1).toDouble();
    final slow = (input.completionSpeedRatio - 1).clamp(0, 1).toDouble();
    final streakLoad = math.max(wins, losses);
    final fatigue = session * (0.35 + 0.65 * streakLoad);

    return <double>[
      1,
      winRate,
      wins,
      losses,
      session,
      extended,
      fast,
      slow,
      fatigue,
      (1 - (winRate - 0.68).abs() * 2).clamp(0, 1).toDouble(),
      (1 - (input.completionSpeedRatio - 1).abs()).clamp(0, 1).toDouble(),
      1 - extended,
    ];
  }

  DifficultyRecommendation recommend(SessionFeatures input) {
    final features = featureVector(input);
    final logits = {
      for (final state in EngagementState.values)
        state: _dot(weights.forState(state), features),
    };

    final probabilities = _softmax(logits);
    final state = probabilities.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return switch (state) {
      EngagementState.overloaded => DifficultyRecommendation(
        state: state,
        difficulty: LearningDifficulty.gentleReview,
        confidence: probabilities[state]!,
        reason:
            'Phiên học đã dài và tải nhận thức đang tăng. Chuyển sang ôn từ có nguy cơ quên.',
      ),
      EngagementState.focused => DifficultyRecommendation(
        state: state,
        difficulty: LearningDifficulty.balanced,
        confidence: probabilities[state]!,
        reason: 'Nhịp độ và độ chính xác đang ổn định. Giữ độ khó hiện tại.',
      ),
      EngagementState.bored => DifficultyRecommendation(
        state: state,
        difficulty: LearningDifficulty.challenge,
        confidence: probabilities[state]!,
        reason:
            'Bạn đang thắng nhanh ở đầu phiên. Thêm thử thách để giữ tập trung.',
      ),
    };
  }

  Map<EngagementState, double> _softmax(Map<EngagementState, double> logits) {
    final maxLogit = logits.values.reduce(math.max);
    final exponentials = logits.map(
      (key, value) => MapEntry(key, math.exp(value - maxLogit)),
    );
    final total = exponentials.values.reduce((a, b) => a + b);
    return exponentials.map((key, value) => MapEntry(key, value / total));
  }

  double _dot(List<double> coefficients, List<double> features) {
    var total = 0.0;
    for (var i = 0; i < coefficients.length && i < features.length; i++) {
      total += coefficients[i] * features[i];
    }
    return total;
  }
}

class EngagementModelWeights {
  const EngagementModelWeights({required this.coefficients});

  const EngagementModelWeights.coldStart()
    : coefficients = const [
        // bias, win, wins, losses, session, extended, fast, slow, fatigue,
        // winBalance, speedBalance, notExtended
        [-1.1, 0, 0, 1.4, 0, 2.6, 0, 0.8, 2.8, 0, 0, 0],
        [0.8, 0, 0, 0, 0, 0, 0, 0, 0, 1.1, 0.8, 0.5],
        [-1, 2.2, 1.8, 0, -2.3, 0, 2, 0, 0, 0, 0, 0],
      ];

  final List<List<double>> coefficients;

  static const featureOrder = <String>[
    'bias',
    'winRate',
    'wins',
    'losses',
    'session',
    'extended',
    'fast',
    'slow',
    'fatigue',
    'winBalance',
    'speedBalance',
    'notExtended',
  ];

  List<double> forState(EngagementState state) => coefficients[state.index];

  factory EngagementModelWeights.fromJson(Map<String, dynamic> json) {
    final rawOrder = (json['featureOrder'] as List<dynamic>?)
        ?.map((value) => value as String)
        .toList();
    if (rawOrder == null || !_sameOrder(rawOrder, featureOrder)) {
      throw const FormatException('Unsupported engagement feature order.');
    }
    final raw = json['coefficients'] as Map<String, dynamic>;
    return EngagementModelWeights(
      coefficients: EngagementState.values.map((state) {
        final values = raw[state.name] as List<dynamic>;
        if (values.length != featureOrder.length) {
          throw FormatException(
            'Expected ${featureOrder.length} coefficients for ${state.name}.',
          );
        }
        return values.map((value) => (value as num).toDouble()).toList();
      }).toList(),
    );
  }

  static bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
