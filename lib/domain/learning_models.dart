enum EngagementState { overloaded, focused, bored }

enum LearningDifficulty { gentleReview, balanced, challenge }

enum MiniGameType { wordCatch, textCipher }

class WordMemoryFeatures {
  const WordMemoryFeatures({
    required this.responseTimeSeconds,
    required this.errorCount,
    required this.hoursSinceLastSeen,
    required this.historySeen,
    required this.historyCorrect,
  });

  final double responseTimeSeconds;
  final int errorCount;
  final double hoursSinceLastSeen;
  final int historySeen;
  final int historyCorrect;

  double get historicalAccuracy =>
      historySeen == 0 ? 0.5 : (historyCorrect / historySeen).clamp(0, 1);

  WordMemoryFeatures copyWith({
    double? responseTimeSeconds,
    int? errorCount,
    double? hoursSinceLastSeen,
    int? historySeen,
    int? historyCorrect,
  }) {
    return WordMemoryFeatures(
      responseTimeSeconds: responseTimeSeconds ?? this.responseTimeSeconds,
      errorCount: errorCount ?? this.errorCount,
      hoursSinceLastSeen: hoursSinceLastSeen ?? this.hoursSinceLastSeen,
      historySeen: historySeen ?? this.historySeen,
      historyCorrect: historyCorrect ?? this.historyCorrect,
    );
  }
}

class MemoryPrediction {
  const MemoryPrediction({
    required this.recallProbability,
    required this.halfLifeHours,
    required this.nextReviewInHours,
  });

  final double recallProbability;
  final double halfLifeHours;
  final double nextReviewInHours;

  bool get isAtRisk => recallProbability < 0.65;
}

class SessionFeatures {
  const SessionFeatures({
    required this.winRate,
    required this.consecutiveWins,
    required this.consecutiveLosses,
    required this.completionSpeedRatio,
    required this.sessionMinutes,
  });

  final double winRate;
  final int consecutiveWins;
  final int consecutiveLosses;

  /// Actual completion time divided by the learner's personal baseline.
  /// Values below 1 mean the learner is moving faster than usual.
  final double completionSpeedRatio;
  final double sessionMinutes;
}

class DifficultyRecommendation {
  const DifficultyRecommendation({
    required this.state,
    required this.difficulty,
    required this.confidence,
    required this.reason,
  });

  final EngagementState state;
  final LearningDifficulty difficulty;
  final double confidence;
  final String reason;
}

class VocabularyCorpusPrior {
  const VocabularyCorpusPrior({
    required this.meanRecall,
    required this.meanDeltaHours,
    required this.meanHistorySeen,
    required this.meanHistoryCorrect,
    required this.sessionAccuracy,
  });

  final double meanRecall;
  final double meanDeltaHours;
  final double meanHistorySeen;
  final double meanHistoryCorrect;
  final double sessionAccuracy;

  double get historicalAccuracy => meanHistorySeen <= 0
      ? 0.5
      : (meanHistoryCorrect / meanHistorySeen).clamp(0, 1);
}

class VocabularyMemory {
  const VocabularyMemory({
    required this.id,
    required this.word,
    required this.meaning,
    required this.features,
    this.lastSeenAt,
    this.lemma,
    this.partOfSpeech,
    this.traceCount = 0,
    this.lexemeCount = 0,
    this.corpusPrior,
  });

  final String id;
  final String word;
  final String meaning;
  final WordMemoryFeatures features;
  final DateTime? lastSeenAt;
  final String? lemma;
  final String? partOfSpeech;
  final int traceCount;
  final int lexemeCount;
  final VocabularyCorpusPrior? corpusPrior;

  double? get datasetRecall => corpusPrior?.meanRecall;

  VocabularyMemory copyWith({
    WordMemoryFeatures? features,
    DateTime? lastSeenAt,
  }) {
    return VocabularyMemory(
      id: id,
      word: word,
      meaning: meaning,
      features: features ?? this.features,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lemma: lemma,
      partOfSpeech: partOfSpeech,
      traceCount: traceCount,
      lexemeCount: lexemeCount,
      corpusPrior: corpusPrior,
    );
  }

  VocabularyMemory atTime(DateTime now) {
    if (lastSeenAt == null) return this;
    final elapsedMilliseconds = now.difference(lastSeenAt!).inMilliseconds;
    final elapsedHours = elapsedMilliseconds <= 0
        ? 0.0
        : elapsedMilliseconds / Duration.millisecondsPerHour;
    return copyWith(
      features: features.copyWith(
        hoursSinceLastSeen: features.hoursSinceLastSeen + elapsedHours,
      ),
    );
  }
}

class PlannedVocabulary {
  const PlannedVocabulary({required this.item, required this.prediction});

  final VocabularyMemory item;
  final MemoryPrediction prediction;

  String get id => item.id;
  String get word => item.word;
  String get meaning => item.meaning;
  String? get lemma => item.lemma;
  String? get partOfSpeech => item.partOfSpeech;
  int get traceCount => item.traceCount;
  int get lexemeCount => item.lexemeCount;
  double? get datasetRecall => item.datasetRecall;
}

class AdaptiveLearningPlan {
  const AdaptiveLearningPlan({
    required this.recommendation,
    required this.orderedVocabulary,
    required this.game,
  });

  final DifficultyRecommendation recommendation;
  final List<PlannedVocabulary> orderedVocabulary;
  final MiniGameType game;
}
