import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/learning_models.dart';

class VocabularyCatalogMetadata {
  const VocabularyCatalogMetadata({
    required this.source,
    required this.rowsScanned,
    required this.englishRows,
    required this.catalogRows,
    required this.droppedEnglishRows,
    required this.uniqueLearners,
    required this.catalogEntries,
    required this.columnsUsed,
    required this.languageCounts,
    required this.uiLanguageCounts,
    this.firstTraceAt,
    this.lastTraceAt,
  });

  final String source;
  final int rowsScanned;
  final int englishRows;
  final int catalogRows;
  final int droppedEnglishRows;
  final int uniqueLearners;
  final int catalogEntries;
  final List<String> columnsUsed;
  final Map<String, int> languageCounts;
  final Map<String, int> uiLanguageCounts;
  final DateTime? firstTraceAt;
  final DateTime? lastTraceAt;

  String get tracePeriodLabel {
    if (firstTraceAt == null || lastTraceAt == null) return 'không xác định';
    return '${_yearMonth(firstTraceAt!)} – ${_yearMonth(lastTraceAt!)}';
  }

  factory VocabularyCatalogMetadata.fallback(int catalogEntries) {
    return VocabularyCatalogMetadata(
      source: 'built_in_fallback',
      rowsScanned: 0,
      englishRows: 0,
      catalogRows: 0,
      droppedEnglishRows: 0,
      uniqueLearners: 0,
      catalogEntries: catalogEntries,
      columnsUsed: const [],
      languageCounts: const {},
      uiLanguageCounts: const {},
    );
  }

  factory VocabularyCatalogMetadata.fromJson(Map<String, dynamic> json) {
    return VocabularyCatalogMetadata(
      source: json['source'] as String,
      rowsScanned: (json['rowsScanned'] as num).toInt(),
      englishRows: (json['englishRows'] as num).toInt(),
      catalogRows: (json['catalogRows'] as num?)?.toInt() ?? 0,
      droppedEnglishRows: (json['droppedEnglishRows'] as num?)?.toInt() ?? 0,
      uniqueLearners: (json['uniqueLearners'] as num).toInt(),
      catalogEntries: (json['catalogEntries'] as num).toInt(),
      columnsUsed: (json['columnsUsed'] as List<dynamic>)
          .map((value) => value as String)
          .toList(growable: false),
      languageCounts: _intMap(json['languageCounts']),
      uiLanguageCounts: _intMap(json['uiLanguageCounts']),
      firstTraceAt: _timestamp(json['firstTimestamp']),
      lastTraceAt: _timestamp(json['lastTimestamp']),
    );
  }
}

class VocabularyCatalog {
  const VocabularyCatalog({required this.metadata, required this.vocabulary});

  final VocabularyCatalogMetadata metadata;
  final List<VocabularyMemory> vocabulary;

  List<VocabularyMemory> mergeProgress(List<VocabularyMemory> stored) {
    final progressByWord = {
      for (final item in stored) item.word.toLowerCase(): item,
    };
    return vocabulary
        .map((catalogItem) {
          final progress = progressByWord[catalogItem.word.toLowerCase()];
          if (progress == null) return catalogItem;
          return catalogItem.copyWith(
            features: progress.features,
            lastSeenAt: progress.lastSeenAt,
          );
        })
        .toList(growable: false);
  }

  factory VocabularyCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 2) {
      throw const FormatException('Unsupported vocabulary catalog schema.');
    }
    final metadata = VocabularyCatalogMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>,
    );
    final entries = (json['entries'] as List<dynamic>)
        .map((raw) {
          final entry = raw as Map<String, dynamic>;
          final corpusPrior = VocabularyCorpusPrior(
            meanRecall: (entry['meanRecall'] as num)
                .toDouble()
                .clamp(0.0001, 0.9999)
                .toDouble(),
            meanDeltaHours: (entry['meanDeltaHours'] as num)
                .toDouble()
                .clamp(0.25, 8760)
                .toDouble(),
            meanHistorySeen: (entry['meanHistorySeen'] as num).toDouble(),
            meanHistoryCorrect: (entry['meanHistoryCorrect'] as num).toDouble(),
            sessionAccuracy: (entry['sessionAccuracy'] as num)
                .toDouble()
                .clamp(0, 1)
                .toDouble(),
          );
          return VocabularyMemory(
            id: entry['id'] as String,
            word: entry['word'] as String,
            lemma: entry['lemma'] as String,
            partOfSpeech: entry['partOfSpeech'] as String,
            meaning: entry['meaning'] as String,
            traceCount: (entry['traceCount'] as num).toInt(),
            lexemeCount:
                (entry['lexemeIds'] as List<dynamic>?)?.length ??
                (entry['lexemeCount'] as num?)?.toInt() ??
                0,
            corpusPrior: corpusPrior,
            features: const WordMemoryFeatures(
              responseTimeSeconds: 2.5,
              errorCount: 0,
              hoursSinceLastSeen: 0,
              historySeen: 0,
              historyCorrect: 0,
            ),
          );
        })
        .toList(growable: false);
    return VocabularyCatalog(metadata: metadata, vocabulary: entries);
  }

  static Future<VocabularyCatalog> load({AssetBundle? bundle}) async {
    final contents = await (bundle ?? rootBundle).loadString(
      'assets/data/duolingo_english_vocabulary.json',
    );
    return VocabularyCatalog.fromJson(
      jsonDecode(contents) as Map<String, dynamic>,
    );
  }
}

Map<String, int> _intMap(Object? raw) {
  if (raw is! Map<String, dynamic>) return const {};
  return raw.map((key, value) => MapEntry(key, (value as num).toInt()));
}

DateTime? _timestamp(Object? raw) {
  if (raw is! num) return null;
  return DateTime.fromMillisecondsSinceEpoch(raw.toInt() * 1000, isUtc: true);
}

String _yearMonth(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}';
