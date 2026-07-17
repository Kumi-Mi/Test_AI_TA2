# Flutter Foundation & Truthful States Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish production/development boundaries, remove invented learner state from the production experience, and separate Flutter session logic from asset and persistence infrastructure without changing the existing lesson catalog or game mechanics.

**Architecture:** Keep the existing ChangeNotifier UI approach for this slice, but move resource loading and local progress behind repository interfaces. Make “no engagement evidence” an explicit domain state, bootstrap failures visible, and developer-only surfaces conditional on an immutable `AppConfig`. This creates stable seams for the later NestJS/MySQL and Drift synchronization plans.

**Tech Stack:** Flutter/Dart 3.12+, Material 3, SharedPreferences (temporary local adapter), existing HLR/engagement JSON assets, Android Gradle product flavors, Flutter test.

## Global Constraints

- Primary learner platform is Android; Admin web is a separate subsystem and is not part of this plan.
- Production must not invent users, scores, ranks, streaks, session duration, model confidence, or learning history.
- `ML Lab`, demo fixtures, and developer controls must not be reachable in production navigation.
- Production resource failure must be visible; it must never silently replace learner progress with fictional seed data.
- The 1,718-item CSV-derived catalog and trained HLR model remain unchanged.
- No backend, MySQL, authentication, Figma redesign, new exercise type, or leaderboard is implemented in this plan.
- Every behavior change follows red → green → refactor and ends in a focused commit.
- Existing unrelated user changes must be preserved.

## Subproject Boundary

This is plan 1 of the approved delivery sequence. Later independent plans, in dependency order, are: Backend/Auth/MySQL; Admin Curriculum/TTS; Figma Quiet Editorial; Curriculum/Offline Sync; Practice Depth/Custom Library; Progress/Motivation/Leaderboard; Hardening/Android Release. Their interfaces must consume the repositories and explicit evidence states produced here rather than reaching back into `LearningSessionController` internals.

## Target File Structure

```text
lib/
  bootstrap.dart                              # composition root and startup failure boundary
  main_development.dart                      # development entry point
  main_staging.dart                          # staging entry point
  main_production.dart                       # production entry point
  core/config/app_config.dart                # immutable environment flags
  core/presentation/startup_failure_screen.dart
  features/learning/
    application/learning_session_controller.dart
    data/asset_learning_resources_repository.dart
    data/learning_progress_repository.dart
    data/learning_resources_repository.dart
    data/shared_preferences_learning_progress_repository.dart
    domain/vocabulary_progress.dart
test/
  core/config/app_config_test.dart
  features/learning/application/learning_session_controller_test.dart
  features/learning/data/shared_preferences_learning_progress_repository_test.dart
  features/shell/app_shell_test.dart
```

The existing `lib/data/learning_session_controller.dart` is deleted only after all imports move to the feature path. `lib/data/vocabulary_catalog.dart` remains in place for this slice because it represents the bundled catalog pipeline, not learner persistence.

---

### Task 1: Add explicit application environments and Android flavors

**Files:**
- Create: `lib/core/config/app_config.dart`
- Create: `lib/bootstrap.dart`
- Create: `lib/main_development.dart`
- Create: `lib/main_staging.dart`
- Create: `lib/main_production.dart`
- Modify: `lib/main.dart`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/core/config/app_config_test.dart`

**Interfaces:**
- Produces: `enum AppEnvironment { development, staging, production }`
- Produces: `AppConfig.environment`, `AppConfig.developerToolsEnabled`, `AppConfig.displayName`
- Consumed by: Task 6 bootstrap and shell visibility.

- [ ] **Step 1: Write the failing configuration test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/core/config/app_config.dart';

void main() {
  test('developer tools are enabled only in development', () {
    expect(AppConfig.development.developerToolsEnabled, isTrue);
    expect(AppConfig.staging.developerToolsEnabled, isFalse);
    expect(AppConfig.production.developerToolsEnabled, isFalse);
  });

  test('each environment has an honest application label', () {
    expect(AppConfig.development.displayName, 'LearnFlow Dev');
    expect(AppConfig.staging.displayName, 'LearnFlow Staging');
    expect(AppConfig.production.displayName, 'LearnFlow');
  });
}
```

- [ ] **Step 2: Run the test and verify the public seam is missing**

Run:

```powershell
flutter test test\core\config\app_config_test.dart
```

Expected: compilation fails because `core/config/app_config.dart` does not exist.

- [ ] **Step 3: Implement the immutable configuration**

```dart
enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig._({required this.environment, required this.displayName});

  static const development = AppConfig._(
    environment: AppEnvironment.development,
    displayName: 'LearnFlow Dev',
  );
  static const staging = AppConfig._(
    environment: AppEnvironment.staging,
    displayName: 'LearnFlow Staging',
  );
  static const production = AppConfig._(
    environment: AppEnvironment.production,
    displayName: 'LearnFlow',
  );

  final AppEnvironment environment;
  final String displayName;

  bool get developerToolsEnabled =>
      environment == AppEnvironment.development;
}
```

- [ ] **Step 4: Add a compatibility composition root and environment entry points**

Create `lib/bootstrap.dart` first so this task remains independently buildable before Task 6 replaces startup wiring with repositories and a visible failure boundary:

```dart
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/learning_session_controller.dart';

Future<void> bootstrap(AppConfig _config) async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await LearningSessionController.create();
  runApp(LearnFlowApp(controller: controller));
}
```

Use this exact shape in each file; only the constant differs:

```dart
import 'bootstrap.dart';
import 'core/config/app_config.dart';

Future<void> main() => bootstrap(AppConfig.development);
```

`main_staging.dart` passes `AppConfig.staging`; `main_production.dart` and the compatibility `main.dart` pass `AppConfig.production`.

- [ ] **Step 5: Configure Android product flavors**

Inside `android {}` in `android/app/build.gradle.kts`, add:

```kotlin
flavorDimensions += "environment"
productFlavors {
    create("development") {
        dimension = "environment"
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
        resValue("string", "app_name", "LearnFlow Dev")
    }
    create("staging") {
        dimension = "environment"
        applicationIdSuffix = ".staging"
        versionNameSuffix = "-staging"
        resValue("string", "app_name", "LearnFlow Staging")
    }
    create("production") {
        dimension = "environment"
        resValue("string", "app_name", "LearnFlow")
    }
}
```

Change the manifest application label to:

```xml
android:label="@string/app_name"
```

- [ ] **Step 6: Run configuration tests and list Gradle tasks**

Run:

```powershell
flutter test test\core\config\app_config_test.dart
Set-Location android
.\gradlew.bat tasks --all | Select-String 'assemble(Development|Staging|Production)Debug'
Set-Location ..
```

Expected: two Flutter tests pass and all three debug assemble task families appear.

- [ ] **Step 7: Commit the environment boundary**

```powershell
git add lib/bootstrap.dart lib/core/config/app_config.dart lib/main.dart lib/main_development.dart lib/main_staging.dart lib/main_production.dart android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml test/core/config/app_config_test.dart
git commit -m "feat: add explicit app environments"
```

---

### Task 2: Represent missing engagement evidence explicitly

**Files:**
- Modify: `lib/domain/learning_models.dart`
- Modify: `lib/ml/adaptive_learning_planner.dart`
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Modify: `lib/features/lab/ml_lab_screen.dart`
- Test: `test/ml/adaptive_learning_planner_test.dart`
- Test: `test/ml/adaptive_difficulty_adapter_test.dart`

**Interfaces:**
- Changes: `DifficultyRecommendation.state` from `EngagementState` to `EngagementState?`
- Changes: `DifficultyRecommendation.confidence` from `double` to `double?`
- Changes: `AdaptiveLearningPlanner.compose({required SessionFeatures? session, ...})`
- Produces: a balanced, explicitly evidence-free recommendation when `session == null`.

- [ ] **Step 1: Add a failing planner test for a new learner**

Append to `test/ml/adaptive_learning_planner_test.dart`:

```dart
test('a learner without session evidence is not assigned a fake state', () {
  final plan = const AdaptiveLearningPlanner().compose(
    session: null,
    vocabulary: const [
      VocabularyMemory(
        id: 'hello',
        word: 'hello',
        meaning: 'xin chào',
        features: WordMemoryFeatures(
          responseTimeSeconds: 0,
          errorCount: 0,
          hoursSinceLastSeen: 0,
          historySeen: 0,
          historyCorrect: 0,
        ),
      ),
    ],
  );

  expect(plan.recommendation.state, isNull);
  expect(plan.recommendation.confidence, isNull);
  expect(plan.recommendation.difficulty, LearningDifficulty.balanced);
  expect(plan.recommendation.reason, contains('Chưa đủ dữ liệu'));
});
```

- [ ] **Step 2: Verify the test fails at the signature**

Run:

```powershell
flutter test test\ml\adaptive_learning_planner_test.dart
```

Expected: compilation fails because `SessionFeatures` is currently non-nullable.

- [ ] **Step 3: Make evidence absence part of the domain contract**

Change `DifficultyRecommendation` to:

```dart
class DifficultyRecommendation {
  const DifficultyRecommendation({
    required this.state,
    required this.difficulty,
    required this.confidence,
    required this.reason,
  });

  final EngagementState? state;
  final LearningDifficulty difficulty;
  final double? confidence;
  final String reason;

  bool get isEvidenceBased => state != null && confidence != null;
}
```

At the start of `AdaptiveLearningPlanner.compose`, use:

```dart
final recommendation = session == null
    ? const DifficultyRecommendation(
        state: null,
        difficulty: LearningDifficulty.balanced,
        confidence: null,
        reason: 'Chưa đủ dữ liệu phiên để dự đoán trạng thái. '
            'LearnFlow giữ nhịp cân bằng trong lúc học cách bạn luyện tập.',
      )
    : difficultyAdapter.recommend(session);
```

Leave `AdaptiveDifficultyAdapter` returning non-null predictions. Update ML Lab display switches by first unwrapping its known non-null result:

```dart
final predictedState = result.state!;
final confidence = result.confidence!;
```

Keep the existing Dashboard buildable before its full evidence-aware rewrite in Task 7. Handle nullable values at the existing display sites:

```dart
final stateLabel = switch (plan.recommendation.state) {
  null => 'Đang thu thập dữ liệu',
  EngagementState.overloaded => 'Có dấu hiệu quá tải',
  EngagementState.focused => 'Đang tập trung',
  EngagementState.bored => 'Cần thêm thử thách',
};
final confidence = plan.recommendation.confidence;
```

Render the confidence chip conditionally inside its existing `Wrap`:

```dart
if (confidence != null)
  _MetricChip(
    value: '${(confidence * 100).round()}%',
    label: 'độ tin cậy',
  ),
```

- [ ] **Step 4: Run planner and adapter tests**

```powershell
flutter test test\ml\adaptive_learning_planner_test.dart test\ml\adaptive_difficulty_adapter_test.dart
```

Expected: all planner and adapter tests pass, including the evidence-free case.

- [ ] **Step 5: Commit the explicit evidence state**

```powershell
git add lib/domain/learning_models.dart lib/ml/adaptive_learning_planner.dart lib/features/dashboard/dashboard_screen.dart lib/features/lab/ml_lab_screen.dart test/ml/adaptive_learning_planner_test.dart test/ml/adaptive_difficulty_adapter_test.dart
git commit -m "fix: represent missing engagement evidence"
```

---

### Task 3: Define focused learning repositories and progress records

**Files:**
- Create: `lib/features/learning/domain/vocabulary_progress.dart`
- Create: `lib/features/learning/data/learning_progress_repository.dart`
- Create: `lib/features/learning/data/learning_resources_repository.dart`
- Modify: `lib/data/vocabulary_catalog.dart`
- Test: `test/features/learning/domain/vocabulary_progress_test.dart`
- Modify: `test/data/vocabulary_catalog_test.dart`

**Interfaces:**
- Produces: `VocabularyProgress.fromMemory(VocabularyMemory)`
- Produces: `VocabularyProgress.hasEvidence`
- Produces: `abstract interface class LearningProgressRepository`
- Produces: `LearningResources(catalog, planner)` and `LearningResourcesRepository.load()`
- Changes: `VocabularyCatalog.mergeProgress(List<VocabularyProgress>)`.

- [ ] **Step 1: Write the failing progress-record test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:learnflow/features/learning/domain/vocabulary_progress.dart';

void main() {
  test('only personal evidence is represented as progress', () {
    const unseen = VocabularyMemory(
      id: 'hello',
      word: 'hello',
      meaning: 'xin chào',
      traceCount: 100,
      features: WordMemoryFeatures(
        responseTimeSeconds: 0,
        errorCount: 0,
        hoursSinceLastSeen: 0,
        historySeen: 0,
        historyCorrect: 0,
      ),
    );
    final seen = unseen.copyWith(
      features: unseen.features.copyWith(historySeen: 1, historyCorrect: 1),
      lastSeenAt: DateTime.utc(2026, 7, 18),
    );

    expect(VocabularyProgress.fromMemory(unseen).hasEvidence, isFalse);
    expect(VocabularyProgress.fromMemory(seen).hasEvidence, isTrue);
    expect(VocabularyProgress.fromMemory(seen).word, 'hello');
  });
}
```

- [ ] **Step 2: Run the test and verify the domain type is missing**

```powershell
flutter test test\features\learning\domain\vocabulary_progress_test.dart
```

Expected: compilation fails on the missing import/type.

- [ ] **Step 3: Implement the progress record**

```dart
import '../../../domain/learning_models.dart';

class VocabularyProgress {
  const VocabularyProgress({
    required this.vocabularyId,
    required this.word,
    required this.features,
    this.lastSeenAt,
  });

  factory VocabularyProgress.fromMemory(VocabularyMemory memory) {
    return VocabularyProgress(
      vocabularyId: memory.id,
      word: memory.word,
      features: memory.features,
      lastSeenAt: memory.lastSeenAt,
    );
  }

  final String vocabularyId;
  final String word;
  final WordMemoryFeatures features;
  final DateTime? lastSeenAt;

  bool get hasEvidence => features.historySeen > 0 || lastSeenAt != null;
}
```

- [ ] **Step 4: Add repository contracts**

```dart
abstract interface class LearningProgressRepository {
  Future<List<VocabularyProgress>> load();
  Future<void> save(Iterable<VocabularyProgress> progress);
  Future<void> clear();
}
```

```dart
class LearningResources {
  const LearningResources({required this.catalog, required this.planner});

  final VocabularyCatalog catalog;
  final AdaptiveLearningPlanner planner;
}

abstract interface class LearningResourcesRepository {
  Future<LearningResources> load();
}
```

Use the imports from `lib/data/vocabulary_catalog.dart` and `lib/ml/adaptive_learning_planner.dart` in the resources contract.

- [ ] **Step 5: Change catalog progress merging**

Replace the `VocabularyMemory` progress map with:

```dart
List<VocabularyMemory> mergeProgress(List<VocabularyProgress> stored) {
  final progressByWord = {
    for (final item in stored) item.word.toLowerCase(): item,
  };
  return vocabulary.map((catalogItem) {
    final progress = progressByWord[catalogItem.word.toLowerCase()];
    if (progress == null) return catalogItem;
    return catalogItem.copyWith(
      features: progress.features,
      lastSeenAt: progress.lastSeenAt,
    );
  }).toList(growable: false);
}
```

Update `test/data/vocabulary_catalog_test.dart` to construct `VocabularyProgress` instead of a full legacy `VocabularyMemory` for stored progress.

- [ ] **Step 6: Run domain and catalog tests**

```powershell
flutter test test\features\learning\domain\vocabulary_progress_test.dart test\data\vocabulary_catalog_test.dart
```

Expected: progress tests pass and catalog metadata remains sourced from the bundled catalog while personal features are merged.

- [ ] **Step 7: Commit repository interfaces**

```powershell
git add lib/features/learning/domain/vocabulary_progress.dart lib/features/learning/data/learning_progress_repository.dart lib/features/learning/data/learning_resources_repository.dart lib/data/vocabulary_catalog.dart test/features/learning/domain/vocabulary_progress_test.dart test/data/vocabulary_catalog_test.dart
git commit -m "refactor: define learning repository boundaries"
```

---

### Task 4: Move SharedPreferences JSON behind the progress repository

**Files:**
- Create: `lib/features/learning/data/shared_preferences_learning_progress_repository.dart`
- Test: `test/features/learning/data/shared_preferences_learning_progress_repository_test.dart`

**Interfaces:**
- Implements: `LearningProgressRepository`.
- Storage key: `learnflow_vocabulary_progress_v2`.
- Saves only records where `VocabularyProgress.hasEvidence == true`.

- [ ] **Step 1: Write failing repository round-trip tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:learnflow/features/learning/data/shared_preferences_learning_progress_repository.dart';
import 'package:learnflow/features/learning/domain/vocabulary_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists only real learner evidence', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesLearningProgressRepository(preferences);
    final progress = [
      const VocabularyProgress(
        vocabularyId: 'new',
        word: 'new',
        features: WordMemoryFeatures(
          responseTimeSeconds: 0,
          errorCount: 0,
          hoursSinceLastSeen: 0,
          historySeen: 0,
          historyCorrect: 0,
        ),
      ),
      VocabularyProgress(
        vocabularyId: 'seen',
        word: 'seen',
        lastSeenAt: DateTime.utc(2026, 7, 18),
        features: const WordMemoryFeatures(
          responseTimeSeconds: 2,
          errorCount: 1,
          hoursSinceLastSeen: 0,
          historySeen: 2,
          historyCorrect: 1,
        ),
      ),
    ];

    await repository.save(progress);
    final restored = await repository.load();

    expect(restored, hasLength(1));
    expect(restored.single.word, 'seen');
    expect(restored.single.features.errorCount, 1);
  });

  test('clear removes all local progress', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesLearningProgressRepository(preferences);
    await repository.save([
      VocabularyProgress(
        vocabularyId: 'seen',
        word: 'seen',
        lastSeenAt: DateTime.utc(2026, 7, 18),
        features: const WordMemoryFeatures(
          responseTimeSeconds: 2,
          errorCount: 0,
          hoursSinceLastSeen: 0,
          historySeen: 1,
          historyCorrect: 1,
        ),
      ),
    ]);

    await repository.clear();

    expect(await repository.load(), isEmpty);
  });
}
```

- [ ] **Step 2: Verify the repository is missing**

```powershell
flutter test test\features\learning\data\shared_preferences_learning_progress_repository_test.dart
```

Expected: compilation fails on the missing repository class.

- [ ] **Step 3: Implement the adapter and codec**

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/learning_models.dart';
import '../domain/vocabulary_progress.dart';
import 'learning_progress_repository.dart';

class SharedPreferencesLearningProgressRepository
    implements LearningProgressRepository {
  SharedPreferencesLearningProgressRepository(this._preferences);

  static const _storageKey = 'learnflow_vocabulary_progress_v2';
  final SharedPreferences _preferences;

  @override
  Future<List<VocabularyProgress>> load() async {
    final stored = _preferences.getString(_storageKey);
    if (stored == null) return const [];
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .map((raw) => _fromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> save(Iterable<VocabularyProgress> progress) async {
    final evidenced = progress.where((item) => item.hasEvidence).map(_toJson);
    await _preferences.setString(_storageKey, jsonEncode(evidenced.toList()));
  }

  @override
  Future<void> clear() => _preferences.remove(_storageKey);

  Map<String, dynamic> _toJson(VocabularyProgress item) => {
        'vocabularyId': item.vocabularyId,
        'word': item.word,
        'responseTimeSeconds': item.features.responseTimeSeconds,
        'errorCount': item.features.errorCount,
        'hoursSinceLastSeen': item.features.hoursSinceLastSeen,
        'historySeen': item.features.historySeen,
        'historyCorrect': item.features.historyCorrect,
        'lastSeenAt': item.lastSeenAt?.toIso8601String(),
      };

  VocabularyProgress _fromJson(Map<String, dynamic> json) {
    return VocabularyProgress(
      vocabularyId: json['vocabularyId'] as String,
      word: json['word'] as String,
      lastSeenAt: switch (json['lastSeenAt']) {
        final String value => DateTime.tryParse(value),
        _ => null,
      },
      features: WordMemoryFeatures(
        responseTimeSeconds: (json['responseTimeSeconds'] as num).toDouble(),
        errorCount: (json['errorCount'] as num).toInt(),
        hoursSinceLastSeen: (json['hoursSinceLastSeen'] as num).toDouble(),
        historySeen: (json['historySeen'] as num).toInt(),
        historyCorrect: (json['historyCorrect'] as num).toInt(),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the adapter tests**

```powershell
flutter test test\features\learning\data\shared_preferences_learning_progress_repository_test.dart
```

Expected: both tests pass.

- [ ] **Step 5: Commit the local adapter**

```powershell
git add lib/features/learning/data/shared_preferences_learning_progress_repository.dart test/features/learning/data/shared_preferences_learning_progress_repository_test.dart
git commit -m "refactor: isolate local learning progress"
```

---

### Task 5: Extract bundled resource loading and refactor the session controller

**Files:**
- Create: `lib/features/learning/data/asset_learning_resources_repository.dart`
- Create: `lib/features/learning/application/learning_session_controller.dart`
- Delete: `lib/data/learning_session_controller.dart`
- Modify: `lib/bootstrap.dart`
- Modify imports: `lib/app.dart`
- Modify imports: `lib/features/dashboard/dashboard_screen.dart`
- Modify imports: `lib/features/game/adaptive_game_screen.dart`
- Modify imports: `lib/features/game/word_catch_screen.dart`
- Modify imports: `lib/features/game/text_cipher_screen.dart`
- Modify imports: `lib/features/shell/app_shell.dart`
- Modify imports: all affected tests
- Test: `test/features/learning/application/learning_session_controller_test.dart`

**Interfaces:**
- Implements: `AssetLearningResourcesRepository.load()` with no fictional fallback.
- Produces: `LearningSessionController.create(resourcesRepository, progressRepository)`.
- Produces: `LearningSessionController.test(vocabulary, planner)` for tests only; vocabulary is required.
- Produces: `SessionFeatures? get sessionFeatures` and `bool get hasLearningHistory`.

- [ ] **Step 1: Replace the controller test with dependency-driven cases**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/data/vocabulary_catalog.dart';
import 'package:learnflow/domain/learning_models.dart';
import 'package:learnflow/features/learning/application/learning_session_controller.dart';
import 'package:learnflow/features/learning/data/learning_progress_repository.dart';
import 'package:learnflow/features/learning/data/learning_resources_repository.dart';
import 'package:learnflow/features/learning/domain/vocabulary_progress.dart';
import 'package:learnflow/ml/adaptive_learning_planner.dart';

class _MemoryProgressRepository implements LearningProgressRepository {
  List<VocabularyProgress> values = [];
  @override Future<List<VocabularyProgress>> load() async => values;
  @override
  Future<void> save(Iterable<VocabularyProgress> progress) async {
    values = progress.toList();
  }
  @override Future<void> clear() async => values = [];
}

class _MemoryResourcesRepository implements LearningResourcesRepository {
  @override
  Future<LearningResources> load() async => LearningResources(
        catalog: VocabularyCatalog(
          metadata: VocabularyCatalogMetadata.fallback(1),
          vocabulary: const [
            VocabularyMemory(
              id: 'fragile',
              word: 'fragile',
              meaning: 'dễ vỡ',
              features: WordMemoryFeatures(
                responseTimeSeconds: 0,
                errorCount: 0,
                hoursSinceLastSeen: 0,
                historySeen: 0,
                historyCorrect: 0,
              ),
            ),
          ],
        ),
        planner: const AdaptiveLearningPlanner(),
      );
}

void main() {
  test('a new learner has no invented session evidence', () async {
    final controller = await LearningSessionController.create(
      resourcesRepository: _MemoryResourcesRepository(),
      progressRepository: _MemoryProgressRepository(),
    );

    expect(controller.sessionFeatures, isNull);
    expect(controller.hasLearningHistory, isFalse);
    expect(controller.plan.recommendation.state, isNull);
  });

  test('first answer creates and persists real evidence', () async {
    final progress = _MemoryProgressRepository();
    final controller = await LearningSessionController.create(
      resourcesRepository: _MemoryResourcesRepository(),
      progressRepository: progress,
    );

    controller.recordAnswer(
      vocabularyId: 'fragile',
      correct: true,
      responseSeconds: 2,
    );
    await controller.persistenceIdle;

    expect(controller.sessionFeatures!.winRate, 1);
    expect(controller.hasLearningHistory, isTrue);
    expect(progress.values, hasLength(1));
    expect(progress.values.single.features.historySeen, 1);
  });
}
```

- [ ] **Step 2: Run the new controller test and verify the feature path is missing**

```powershell
flutter test test\features\learning\application\learning_session_controller_test.dart
```

Expected: compilation fails because the new controller path and dependency-based constructor do not exist.

- [ ] **Step 3: Move asset/model loading into the resource repository**

Implement `AssetLearningResourcesRepository` by moving the existing JSON loading logic from `_loadPlanner` and `_loadCatalog`. Its `load()` must:

```dart
@override
Future<LearningResources> load() async {
  final files = await Future.wait([
    rootBundle.loadString('assets/models/memory_model.json'),
    rootBundle.loadString('assets/models/engagement_model.json'),
  ]);
  final catalog = await VocabularyCatalog.load();
  final memoryJson = jsonDecode(files[0]) as Map<String, dynamic>;
  final engagementJson = jsonDecode(files[1]) as Map<String, dynamic>;
  return LearningResources(
    catalog: catalog,
    planner: AdaptiveLearningPlanner(
      memoryPredictor: HalfLifeMemoryPredictor(
        weights: HalfLifeWeights.fromJson(
          memoryJson['weights'] as Map<String, dynamic>,
        ),
      ),
      difficultyAdapter: AdaptiveDifficultyAdapter(
        weights: EngagementModelWeights.fromJson(engagementJson),
      ),
    ),
  );
}
```

Do not catch `Object` and do not return seed resources.

- [ ] **Step 4: Implement the dependency-driven controller**

Move the controller to the feature path. Replace static infrastructure access with constructor dependencies. The essential shape is:

```dart
static Future<LearningSessionController> create({
  required LearningResourcesRepository resourcesRepository,
  required LearningProgressRepository progressRepository,
}) async {
  final resources = await resourcesRepository.load();
  final progress = await progressRepository.load();
  return LearningSessionController._(
    vocabulary: resources.catalog.mergeProgress(progress),
    initialVocabulary: resources.catalog.vocabulary,
    catalogMetadata: resources.catalog.metadata,
    progressRepository: progressRepository,
    planner: resources.planner,
  );
}
```

Make session evidence nullable:

```dart
SessionFeatures? get sessionFeatures {
  final total = _wins + _losses;
  if (total == 0) return null;
  final elapsedMinutes = DateTime.now().difference(_startedAt).inSeconds / 60;
  final averageResponse = _totalResponseSeconds / total;
  return SessionFeatures(
    winRate: _wins / total,
    consecutiveWins: _consecutiveWins,
    consecutiveLosses: _consecutiveLosses,
    completionSpeedRatio: (averageResponse / _baselineResponseSeconds)
        .clamp(0.35, 2),
    sessionMinutes: elapsedMinutes.clamp(0, 120),
  );
}

bool get hasLearningHistory =>
    _vocabulary.any((item) => item.features.historySeen > 0);

AdaptiveLearningPlan get plan =>
    _planner.compose(session: sessionFeatures, vocabulary: vocabulary);
```

Persist progress records only:

```dart
Future<void> _persist() {
  final progress = _vocabulary
      .map(VocabularyProgress.fromMemory)
      .where((item) => item.hasEvidence);
  return _progressRepository.save(progress);
}
```

Track the latest persistence future so tests and later sync can await it:

```dart
Future<void> _persistenceIdle = Future.value();
Future<void> get persistenceIdle => _persistenceIdle;

// inside recordAnswer
_persistenceIdle = _persistenceIdle.then((_) => _persist());
```

Serializing saves prevents an older SharedPreferences write from completing after a newer answer and overwriting it.

Add the explicit test factory used by widget and controller tests:

```dart
factory LearningSessionController.test({
  required List<VocabularyMemory> vocabulary,
  AdaptiveLearningPlanner planner = const AdaptiveLearningPlanner(),
  LearningProgressRepository progressRepository =
      const _NoopLearningProgressRepository(),
}) {
  final initial = List<VocabularyMemory>.of(vocabulary);
  return LearningSessionController._(
    vocabulary: List<VocabularyMemory>.of(initial),
    initialVocabulary: initial,
    catalogMetadata: VocabularyCatalogMetadata.fallback(initial.length),
    progressRepository: progressRepository,
    planner: planner,
  );
}

class _NoopLearningProgressRepository implements LearningProgressRepository {
  const _NoopLearningProgressRepository();

  @override
  Future<List<VocabularyProgress>> load() async => const [];

  @override
  Future<void> save(Iterable<VocabularyProgress> progress) async {}

  @override
  Future<void> clear() async {}
}
```

Replace `resetDemoData` with `clearLocalProgress`, call `LearningProgressRepository.clear()`, and reset to the immutable catalog baseline.

- [ ] **Step 5: Update imports and test fixtures**

All production UI imports use:

```dart
import '../features/learning/application/learning_session_controller.dart';
```

Tests construct `LearningSessionController.test(vocabulary: [...])`; the vocabulary argument is mandatory. Delete the built-in eight-word seed and delete the old controller file only after `rg "data/learning_session_controller" lib test` returns no matches.

Update `lib/bootstrap.dart` in the same task so deleting the old controller never breaks an entry point:

```dart
Future<void> bootstrap(AppConfig _config) async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final controller = await LearningSessionController.create(
    resourcesRepository: const AssetLearningResourcesRepository(),
    progressRepository:
        SharedPreferencesLearningProgressRepository(preferences),
  );
  runApp(LearnFlowApp(controller: controller));
}
```

Move the controller import in `lib/app.dart` to the new feature path as part of this step.

- [ ] **Step 6: Run controller, catalog, planner, and widget tests**

```powershell
flutter test test\features\learning\application\learning_session_controller_test.dart test\data\vocabulary_catalog_test.dart test\ml\adaptive_learning_planner_test.dart test\widget_test.dart
```

Expected: all selected tests pass; no test receives a default 68%/18-minute session.

- [ ] **Step 7: Commit the controller extraction**

```powershell
git add lib/bootstrap.dart lib/features/learning lib/data/vocabulary_catalog.dart lib/features lib/app.dart test
git add -u lib/data/learning_session_controller.dart
git commit -m "refactor: separate learning infrastructure"
```

---

### Task 6: Add a visible bootstrap failure boundary and development-only Lab

**Files:**
- Modify: `lib/bootstrap.dart`
- Create: `lib/core/presentation/startup_failure_screen.dart`
- Modify: `lib/app.dart`
- Modify: `lib/features/shell/app_shell.dart`
- Test: `test/features/shell/app_shell_test.dart`
- Test: `test/core/presentation/startup_failure_screen_test.dart`

**Interfaces:**
- Produces: `Future<void> bootstrap(AppConfig config)`.
- Changes: `LearnFlowApp` requires `AppConfig config`.
- Changes: `AppShell` requires `bool developerToolsEnabled`.
- Produces: `StartupFailureScreen(developerMessage, showTechnicalDetails)`.

- [ ] **Step 1: Write failing shell truthfulness tests**

```dart
testWidgets('production hides developer-only labels and ML Lab', (tester) async {
  await tester.pumpWidget(
    LearnFlowApp(
      config: AppConfig.production,
      controller: LearningSessionController.test(vocabulary: testVocabulary),
    ),
  );

  expect(find.text('ML Lab'), findsNothing);
  expect(find.text('MVP CỤC BỘ'), findsNothing);
});

testWidgets('development exposes ML Lab without pretending it is learner UI',
    (tester) async {
  await tester.pumpWidget(
    LearnFlowApp(
      config: AppConfig.development,
      controller: LearningSessionController.test(vocabulary: testVocabulary),
    ),
  );

  expect(find.text('ML Lab'), findsOneWidget);
  expect(find.text('MVP CỤC BỘ'), findsNothing);
});
```

Define `testVocabulary` locally in the test as one zero-history `VocabularyMemory`; do not import production seed data.

- [ ] **Step 2: Write the failing startup failure test**

```dart
testWidgets('production startup failure does not leak technical details',
    (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: StartupFailureScreen(
        developerMessage: 'FormatException: bad asset',
        showTechnicalDetails: false,
        onRetry: () {},
      ),
    ),
  );

  expect(find.text('Không thể khởi động LearnFlow'), findsOneWidget);
  expect(find.textContaining('FormatException'), findsNothing);
  expect(find.text('Thử lại'), findsOneWidget);
});
```

- [ ] **Step 3: Run both tests and verify the new seams are absent**

```powershell
flutter test test\features\shell\app_shell_test.dart test\core\presentation\startup_failure_screen_test.dart
```

Expected: compilation fails for the missing config parameters and failure screen.

- [ ] **Step 4: Make navigation environment-aware**

Pass `config.developerToolsEnabled` from `LearnFlowApp` to `AppShell`. Build destinations with:

```dart
final destinations = [
  _AppDestination.today,
  _AppDestination.game,
  _AppDestination.custom,
  if (widget.developerToolsEnabled) _AppDestination.lab,
];
```

Use `destinations.indexOf(_selected)` for `IndexedStack`; reset `_selected` to Today if a widget update removes Lab. Remove the entire `MVP CỤC BỘ` AppBar badge.

- [ ] **Step 5: Implement the startup failure screen**

The screen must render:

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Icon(Icons.cloud_off_outlined, size: 48),
    const SizedBox(height: 16),
    Text('Không thể khởi động LearnFlow',
        style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 8),
    const Text(
      'Dữ liệu học chưa tải được. Tiến trình trên thiết bị vẫn được giữ.',
      textAlign: TextAlign.center,
    ),
    if (showTechnicalDetails) ...[
      const SizedBox(height: 12),
      SelectableText(developerMessage),
    ],
    const SizedBox(height: 20),
    FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
  ],
)
```

Require `VoidCallback onRetry`; the test supplies an empty callback.

- [ ] **Step 6: Implement the composition root**

`bootstrap` creates SharedPreferences, repositories, and controller. On failure, it runs the failure screen and only exposes technical details in development:

```dart
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    final controller = await LearningSessionController.create(
      resourcesRepository: const AssetLearningResourcesRepository(),
      progressRepository:
          SharedPreferencesLearningProgressRepository(preferences),
    );
    runApp(LearnFlowApp(config: config, controller: controller));
  } on Object catch (error, stackTrace) {
    runApp(MaterialApp(
      theme: buildAppTheme(),
      home: StartupFailureScreen(
        developerMessage: '$error\n$stackTrace',
        showTechnicalDetails: config.developerToolsEnabled,
        onRetry: () => bootstrap(config),
      ),
    ));
  }
}
```

- [ ] **Step 7: Run shell and startup tests**

```powershell
flutter test test\features\shell\app_shell_test.dart test\core\presentation\startup_failure_screen_test.dart
```

Expected: production hides Lab and technical details; development exposes Lab; no MVP badge exists.

- [ ] **Step 8: Commit the honest bootstrap and navigation**

```powershell
git add lib/bootstrap.dart lib/core/presentation/startup_failure_screen.dart lib/app.dart lib/features/shell/app_shell.dart test/features/shell/app_shell_test.dart test/core/presentation/startup_failure_screen_test.dart
git commit -m "fix: isolate developer tools from production"
```

---

### Task 7: Replace dashboard pseudo-metrics with evidence-aware states

**Files:**
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Modify: `lib/features/shell/app_shell.dart`
- Test: `test/features/dashboard/dashboard_screen_test.dart`

**Interfaces:**
- Consumes: `LearningSessionController.hasLearningHistory`.
- Consumes: nullable `sessionFeatures`, recommendation `state`, and `confidence`.
- Produces: truthful first-session and evidence-backed returning-session UI.

- [ ] **Step 1: Write failing new-learner dashboard assertions**

```dart
testWidgets('new learner sees no invented personal metrics', (tester) async {
  final controller = LearningSessionController.test(
    vocabulary: testVocabulary,
  );
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(),
    home: DashboardScreen(
      controller: controller,
      openGame: () {},
      openCustomInput: () {},
    ),
  ));

  expect(find.text('Phiên đầu tiên của bạn'), findsOneWidget);
  expect(find.textContaining('khả năng nhớ'), findsNothing);
  expect(find.textContaining('độ tin cậy'), findsNothing);
  expect(find.text('Đang tìm hiểu nhịp học của bạn'), findsOneWidget);
  expect(find.text('Từ gợi ý để bắt đầu'), findsOneWidget);
});
```

Use a local `testVocabulary` containing at least four corpus-prior items with zero personal history so the list layout remains exercised.

- [ ] **Step 2: Add a returning-learner dashboard assertion**

```dart
testWidgets('real answers unlock evidence-backed metrics', (tester) async {
  final controller = LearningSessionController.test(vocabulary: testVocabulary);
  controller.recordAnswer(
    vocabularyId: testVocabulary.first.id,
    correct: true,
    responseSeconds: 2,
  );
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(),
    home: DashboardScreen(
      controller: controller,
      openGame: () {},
      openCustomInput: () {},
    ),
  ));

  expect(find.textContaining('khả năng nhớ'), findsOneWidget);
  expect(find.text('Từ cần gặp lại'), findsOneWidget);
});
```

- [ ] **Step 3: Run the test and verify current fake labels remain**

```powershell
flutter test test\features\dashboard\dashboard_screen_test.dart
```

Expected: new-learner assertions fail because the current dashboard always shows recall/confidence and “Từ cần gặp lại”.

- [ ] **Step 4: Gate plan metrics on personal evidence**

Pass `hasLearningHistory` into `_PlanWorkbench`. For no evidence, render:

```dart
const MonoLabel('Phiên đầu tiên của bạn', color: AppColors.ink),
const SizedBox(height: AppSpace.sm),
Text('Bắt đầu với một phiên cân bằng',
    style: Theme.of(context).textTheme.displaySmall),
const SizedBox(height: AppSpace.sm),
const Text(
  'Sau khi bạn trả lời, LearnFlow mới dùng tốc độ và kết quả thật '
  'để điều chỉnh những phiên tiếp theo.',
),
```

Do not render at-risk, recall, or confidence chips until `hasLearningHistory` is true. When confidence is present, format `plan.recommendation.confidence!` only inside the true branch.

- [ ] **Step 5: Make model explanation evidence-aware**

When `session == null`, replace all signal bars with one neutral explanation:

```dart
const Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Icon(Icons.hourglass_empty_rounded, size: 22),
    SizedBox(width: AppSpace.sm),
    Expanded(
      child: Text(
        'Đang tìm hiểu nhịp học của bạn. Chưa có tỷ lệ thắng, tốc độ '
        'hay thời lượng phiên để phân loại trạng thái.',
      ),
    ),
  ],
)
```

Keep the corpus provenance paragraph as dataset provenance, not a personal metric.

- [ ] **Step 6: Rename the vocabulary section according to evidence**

```dart
Text(
  controller.hasLearningHistory
      ? 'Từ cần gặp lại'
      : 'Từ gợi ý để bắt đầu',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

For a new learner, label recall values in row semantics as “prior cộng đồng”; do not describe them as the learner’s memory probability.

- [ ] **Step 7: Run dashboard and full widget tests**

```powershell
flutter test test\features\dashboard\dashboard_screen_test.dart test\widget_test.dart
```

Expected: both new and returning states pass; compact game coverage remains green.

- [ ] **Step 8: Commit truthful dashboard states**

```powershell
git add lib/features/dashboard/dashboard_screen.dart lib/features/shell/app_shell.dart test/features/dashboard/dashboard_screen_test.dart test/widget_test.dart
git commit -m "fix: show only evidenced learner metrics"
```

---

### Task 8: Migrate legacy local progress without inventing data

**Files:**
- Modify: `lib/features/learning/data/shared_preferences_learning_progress_repository.dart`
- Test: `test/features/learning/data/shared_preferences_learning_progress_repository_test.dart`
- Modify: `README.md`

**Interfaces:**
- Consumes legacy key: `learnflow_vocabulary_v1`.
- Produces only v2 personal progress records.
- Deletes the legacy key only after successful v2 persistence.

- [ ] **Step 1: Write the failing legacy migration test**

```dart
test('migrates only evidenced legacy progress and then removes v1', () async {
  SharedPreferences.setMockInitialValues({
    'learnflow_vocabulary_v1': jsonEncode([
      {
        'id': 'seen',
        'word': 'seen',
        'meaning': 'đã thấy',
        'responseTimeSeconds': 2.0,
        'errorCount': 1,
        'hoursSinceLastSeen': 0.0,
        'historySeen': 2,
        'historyCorrect': 1,
        'lastSeenAt': '2026-07-18T00:00:00.000Z',
      },
      {
        'id': 'unseen',
        'word': 'unseen',
        'meaning': 'chưa thấy',
        'responseTimeSeconds': 2.5,
        'errorCount': 0,
        'hoursSinceLastSeen': 0.0,
        'historySeen': 0,
        'historyCorrect': 0,
        'lastSeenAt': null,
      },
    ]),
  });
  final preferences = await SharedPreferences.getInstance();
  final repository = SharedPreferencesLearningProgressRepository(preferences);

  final migrated = await repository.load();

  expect(migrated.map((item) => item.word), ['seen']);
  expect(preferences.containsKey('learnflow_vocabulary_v1'), isFalse);
  expect(preferences.containsKey('learnflow_vocabulary_progress_v2'), isTrue);
});
```

Add `import 'dart:convert';` to the test.

- [ ] **Step 2: Verify migration is absent**

```powershell
flutter test test\features\learning\data\shared_preferences_learning_progress_repository_test.dart
```

Expected: migration test fails because `load()` returns empty when v2 is missing.

- [ ] **Step 3: Implement transactional-in-order migration**

At the start of `load()`:

```dart
final stored = _preferences.getString(_storageKey);
if (stored != null) return _decode(stored);

final legacy = _preferences.getString(_legacyStorageKey);
if (legacy == null) return const [];
final migrated = _decodeLegacy(legacy)
    .where((item) => item.hasEvidence)
    .toList(growable: false);
await save(migrated);
await _preferences.remove(_legacyStorageKey);
return migrated;
```

Define `_legacyStorageKey = 'learnflow_vocabulary_v1'`. `_decodeLegacy` reads only `id`, `word`, the five feature fields, and `lastSeenAt`; it must ignore catalog meaning/lemma/trace fields. If decode throws, leave the legacy key untouched and rethrow so bootstrap shows the visible failure boundary.

- [ ] **Step 4: Run progress repository tests**

```powershell
flutter test test\features\learning\data\shared_preferences_learning_progress_repository_test.dart
```

Expected: round-trip, clear, and migration tests pass.

- [ ] **Step 5: Document environment build commands and data behavior**

Add this exact section to `README.md`:

````markdown
## Environments

```powershell
flutter run --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
```

Only development exposes ML Lab. Production does not substitute demo learner
data when resources fail. Existing v1 personal progress is migrated once to the
v2 progress-only record; the bundled catalog remains the content source.
````

- [ ] **Step 6: Commit migration and documentation**

```powershell
git add lib/features/learning/data/shared_preferences_learning_progress_repository.dart test/features/learning/data/shared_preferences_learning_progress_repository_test.dart README.md
git commit -m "feat: migrate local learner progress safely"
```

---

### Task 9: Run the complete foundation release gate

**Files:**
- Modify only if verification exposes a defect in files already owned by Tasks 1–8.

**Interfaces:**
- Verifies every public seam produced by this plan.
- Produces clean development and production debug APKs.

- [ ] **Step 1: Format and check for stale/fake production code**

```powershell
dart format --output=none --set-exit-if-changed lib test
rg -n "MVP CỤC BỘ|winRate: 0\.68|sessionMinutes: 18|_seedVocabulary|resetDemoData" lib
rg -n "data/learning_session_controller" lib test
git diff --check
```

Expected: formatter exits 0; both `rg` commands return no matches; diff check is clean.

- [ ] **Step 2: Run static analysis and all tests**

```powershell
flutter analyze
flutter test
```

Expected: analyzer reports “No issues found” and every test passes.

- [ ] **Step 3: Build development and production Android variants**

```powershell
flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
```

Expected artifacts:

```text
build/app/outputs/flutter-apk/app-development-debug.apk
build/app/outputs/flutter-apk/app-production-debug.apk
```

- [ ] **Step 4: Verify production APK contains no developer copy**

```powershell
$apk = Get-Item -LiteralPath 'build\app\outputs\flutter-apk\app-production-debug.apk'
$apk | Select-Object FullName, Length
Test-Path -LiteralPath $apk.FullName
```

Expected: APK exists. Functional absence of ML Lab is already enforced by the production shell widget test; do not treat binary string scanning as the primary proof.

- [ ] **Step 5: Inspect the final diff and commit any verification-only fixes**

```powershell
git status --short
git log --oneline -10
git diff 37437ac...HEAD --check
```

Expected: worktree is clean. If verification exposes a defect, return to the owning task, add only that task's exact files, rerun its focused test, and use the task's commit message before repeating this release gate.

- [ ] **Step 6: Record the handoff evidence**

Copy the actual analyzer summary and test count from Step 2. Obtain both artifact paths and sizes with:

```powershell
Get-Item -LiteralPath `
  'build\app\outputs\flutter-apk\app-development-debug.apk', `
  'build\app\outputs\flutter-apk\app-production-debug.apk' |
  Select-Object FullName, Length
```

Record those outputs together with these evidence statements: production ML Lab navigation is absent by widget test; invented session defaults are absent by `rg` and tests; worktree is clean.

Do not claim the backend, authentication, MySQL, Figma redesign, or later learning features are complete; this gate completes only the first independent foundation slice.
