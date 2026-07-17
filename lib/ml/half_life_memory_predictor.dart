import 'dart:math' as math;

import '../domain/learning_models.dart';

class HalfLifeWeights {
  const HalfLifeWeights({
    this.bias = 5,
    this.seen = 0.55,
    this.accuracy = 2.2,
    this.responseTime = -0.65,
    this.errors = -0.8,
  });

  final double bias;
  final double seen;
  final double accuracy;
  final double responseTime;
  final double errors;

  factory HalfLifeWeights.fromJson(Map<String, dynamic> json) {
    return HalfLifeWeights(
      bias: (json['bias'] as num).toDouble(),
      seen: (json['seen'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      responseTime: (json['responseTime'] as num).toDouble(),
      errors: (json['errors'] as num).toDouble(),
    );
  }
}

/// A mobile-friendly inference layer based on Duolingo's Half-Life Regression.
///
/// The model estimates log2(memory half-life), then applies the HLR forgetting
/// curve p(recall) = 2 ^ (-elapsed / halfLife). App-specific response time and
/// error features extend the public Duolingo feature set.
class HalfLifeMemoryPredictor {
  const HalfLifeMemoryPredictor({
    this.weights = const HalfLifeWeights(),
    this.targetRecall = 0.75,
  });

  final HalfLifeWeights weights;
  final double targetRecall;

  MemoryPrediction predict(WordMemoryFeatures input) {
    final logHalfLife =
        weights.bias +
        weights.seen * math.log(1 + input.historySeen) +
        weights.accuracy * (input.historicalAccuracy - 0.5) +
        weights.responseTime * math.log(1 + input.responseTimeSeconds) +
        weights.errors * input.errorCount;

    final halfLife = math
        .pow(2, logHalfLife)
        .toDouble()
        .clamp(1, 8760)
        .toDouble();
    final elapsed = input.hoursSinceLastSeen.clamp(0, double.infinity);
    final probability = math
        .pow(2, -elapsed / halfLife)
        .toDouble()
        .clamp(0, 1)
        .toDouble();
    final reviewDelay = (-halfLife * math.log(targetRecall) / math.ln2)
        .clamp(0.25, 8760)
        .toDouble();

    return MemoryPrediction(
      recallProbability: probability,
      halfLifeHours: halfLife,
      nextReviewInHours: reviewDelay,
    );
  }
}
