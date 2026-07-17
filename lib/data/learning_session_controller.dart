import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/learning_models.dart';
import '../ml/adaptive_difficulty_adapter.dart';
import '../ml/adaptive_learning_planner.dart';
import '../ml/half_life_memory_predictor.dart';

class LearningSessionController extends ChangeNotifier {
  LearningSessionController._({
    required this._vocabulary,
    this._preferences,
    this._planner = const AdaptiveLearningPlanner(),
  });

  static const _storageKey = 'learnflow_vocabulary_v1';
  final SharedPreferences? _preferences;
  final AdaptiveLearningPlanner _planner;
  final DateTime _startedAt = DateTime.now();
  List<VocabularyMemory> _vocabulary;
  int _wins = 0;
  int _losses = 0;
  int _consecutiveWins = 0;
  int _consecutiveLosses = 0;
  double _totalResponseSeconds = 0;

  static Future<LearningSessionController> create() async {
    final preferences = await SharedPreferences.getInstance();
    final planner = await _loadPlanner();
    final stored = preferences.getString(_storageKey);
    if (stored != null) {
      try {
        final list = jsonDecode(stored) as List<dynamic>;
        return LearningSessionController._(
          vocabulary: list
              .map((item) => _fromJson(item as Map<String, dynamic>))
              .toList(),
          preferences: preferences,
          planner: planner,
        );
      } on Object {
        // Invalid local demo data falls back to the safe built-in seed.
      }
    }
    return LearningSessionController._(
      vocabulary: List.of(_seedVocabulary),
      preferences: preferences,
      planner: planner,
    );
  }

  factory LearningSessionController.demo() {
    return LearningSessionController._(vocabulary: List.of(_seedVocabulary));
  }

  List<VocabularyMemory> get vocabulary {
    final now = DateTime.now();
    return List.unmodifiable(_vocabulary.map((item) => item.atTime(now)));
  }

  SessionFeatures get sessionFeatures {
    final total = _wins + _losses;
    if (total == 0) {
      return const SessionFeatures(
        winRate: 0.68,
        consecutiveWins: 2,
        consecutiveLosses: 0,
        completionSpeedRatio: 1,
        sessionMinutes: 18,
      );
    }
    final elapsedMinutes = DateTime.now().difference(_startedAt).inSeconds / 60;
    final averageResponse = _totalResponseSeconds / total;
    return SessionFeatures(
      winRate: _wins / total,
      consecutiveWins: _consecutiveWins,
      consecutiveLosses: _consecutiveLosses,
      completionSpeedRatio: (averageResponse / 2.5).clamp(0.35, 2),
      sessionMinutes: elapsedMinutes.clamp(1, 120),
    );
  }

  AdaptiveLearningPlan get plan =>
      _planner.compose(session: sessionFeatures, vocabulary: vocabulary);

  int get answered => _wins + _losses;
  int get wins => _wins;

  void recordAnswer({
    required String vocabularyId,
    required bool correct,
    required double responseSeconds,
  }) {
    final index = _vocabulary.indexWhere((item) => item.id == vocabularyId);
    if (index == -1) return;

    final old = _vocabulary[index];
    final oldFeatures = old.features;
    final newFeatures = WordMemoryFeatures(
      responseTimeSeconds: responseSeconds.clamp(0.2, 30),
      errorCount: correct ? 0 : oldFeatures.errorCount + 1,
      hoursSinceLastSeen: 0,
      historySeen: oldFeatures.historySeen + 1,
      historyCorrect: oldFeatures.historyCorrect + (correct ? 1 : 0),
    );
    _vocabulary[index] = VocabularyMemory(
      id: old.id,
      word: old.word,
      meaning: old.meaning,
      features: newFeatures,
      lastSeenAt: DateTime.now(),
    );

    _totalResponseSeconds += responseSeconds;
    if (correct) {
      _wins++;
      _consecutiveWins++;
      _consecutiveLosses = 0;
    } else {
      _losses++;
      _consecutiveLosses++;
      _consecutiveWins = 0;
    }
    notifyListeners();
    _persist();
  }

  Future<void> resetDemoData() async {
    _vocabulary = List.of(_seedVocabulary);
    _wins = 0;
    _losses = 0;
    _consecutiveWins = 0;
    _consecutiveLosses = 0;
    _totalResponseSeconds = 0;
    await _preferences?.remove(_storageKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final value = jsonEncode(_vocabulary.map(_toJson).toList());
    await _preferences?.setString(_storageKey, value);
  }

  static Map<String, dynamic> _toJson(VocabularyMemory item) => {
    'id': item.id,
    'word': item.word,
    'meaning': item.meaning,
    'responseTimeSeconds': item.features.responseTimeSeconds,
    'errorCount': item.features.errorCount,
    'hoursSinceLastSeen': item.features.hoursSinceLastSeen,
    'historySeen': item.features.historySeen,
    'historyCorrect': item.features.historyCorrect,
    'lastSeenAt': item.lastSeenAt?.toIso8601String(),
  };

  static VocabularyMemory _fromJson(Map<String, dynamic> json) {
    return VocabularyMemory(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      lastSeenAt: switch (json['lastSeenAt']) {
        final String value => DateTime.tryParse(value),
        _ => null,
      },
      features: WordMemoryFeatures(
        responseTimeSeconds: (json['responseTimeSeconds'] as num).toDouble(),
        errorCount: json['errorCount'] as int,
        hoursSinceLastSeen: (json['hoursSinceLastSeen'] as num).toDouble(),
        historySeen: json['historySeen'] as int,
        historyCorrect: json['historyCorrect'] as int,
      ),
    );
  }

  static Future<AdaptiveLearningPlanner> _loadPlanner() async {
    try {
      final files = await Future.wait([
        rootBundle.loadString('assets/models/memory_model.json'),
        rootBundle.loadString('assets/models/engagement_model.json'),
      ]);
      final memoryJson = jsonDecode(files[0]) as Map<String, dynamic>;
      final engagementJson = jsonDecode(files[1]) as Map<String, dynamic>;
      return AdaptiveLearningPlanner(
        memoryPredictor: HalfLifeMemoryPredictor(
          weights: HalfLifeWeights.fromJson(
            memoryJson['weights'] as Map<String, dynamic>,
          ),
        ),
        difficultyAdapter: AdaptiveDifficultyAdapter(
          weights: EngagementModelWeights.fromJson(engagementJson),
        ),
      );
    } on Object {
      return const AdaptiveLearningPlanner();
    }
  }

  static const _seedVocabulary = <VocabularyMemory>[
    VocabularyMemory(
      id: 'fragile',
      word: 'fragile',
      meaning: 'dễ vỡ, mong manh',
      features: WordMemoryFeatures(
        responseTimeSeconds: 4.8,
        errorCount: 2,
        hoursSinceLastSeen: 240,
        historySeen: 4,
        historyCorrect: 2,
      ),
    ),
    VocabularyMemory(
      id: 'evidence',
      word: 'evidence',
      meaning: 'bằng chứng',
      features: WordMemoryFeatures(
        responseTimeSeconds: 3.4,
        errorCount: 1,
        hoursSinceLastSeen: 168,
        historySeen: 6,
        historyCorrect: 4,
      ),
    ),
    VocabularyMemory(
      id: 'whisper',
      word: 'whisper',
      meaning: 'thì thầm',
      features: WordMemoryFeatures(
        responseTimeSeconds: 2.8,
        errorCount: 1,
        hoursSinceLastSeen: 96,
        historySeen: 5,
        historyCorrect: 4,
      ),
    ),
    VocabularyMemory(
      id: 'approach',
      word: 'approach',
      meaning: 'cách tiếp cận',
      features: WordMemoryFeatures(
        responseTimeSeconds: 2.1,
        errorCount: 0,
        hoursSinceLastSeen: 120,
        historySeen: 9,
        historyCorrect: 8,
      ),
    ),
    VocabularyMemory(
      id: 'curious',
      word: 'curious',
      meaning: 'tò mò',
      features: WordMemoryFeatures(
        responseTimeSeconds: 1.7,
        errorCount: 0,
        hoursSinceLastSeen: 48,
        historySeen: 8,
        historyCorrect: 7,
      ),
    ),
    VocabularyMemory(
      id: 'schedule',
      word: 'schedule',
      meaning: 'lịch trình',
      features: WordMemoryFeatures(
        responseTimeSeconds: 2.4,
        errorCount: 1,
        hoursSinceLastSeen: 72,
        historySeen: 7,
        historyCorrect: 5,
      ),
    ),
    VocabularyMemory(
      id: 'improve',
      word: 'improve',
      meaning: 'cải thiện',
      features: WordMemoryFeatures(
        responseTimeSeconds: 1.5,
        errorCount: 0,
        hoursSinceLastSeen: 36,
        historySeen: 12,
        historyCorrect: 11,
      ),
    ),
    VocabularyMemory(
      id: 'steady',
      word: 'steady',
      meaning: 'ổn định',
      features: WordMemoryFeatures(
        responseTimeSeconds: 1.3,
        errorCount: 0,
        hoursSinceLastSeen: 24,
        historySeen: 10,
        historyCorrect: 9,
      ),
    ),
  ];
}
