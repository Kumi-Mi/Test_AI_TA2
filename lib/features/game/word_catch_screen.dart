import 'package:flutter/material.dart';

import '../../data/learning_session_controller.dart';
import '../../domain/learning_models.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/learnflow_components.dart';

class WordCatchScreen extends StatefulWidget {
  const WordCatchScreen({required this.controller, super.key});

  final LearningSessionController controller;

  @override
  State<WordCatchScreen> createState() => _WordCatchScreenState();
}

class _WordCatchScreenState extends State<WordCatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fallController;
  List<PlannedVocabulary> _roundItems = const [];
  int _round = 0;
  int _score = 0;
  bool _playing = false;
  bool _locked = false;
  bool _finished = false;
  bool? _lastCorrect;
  LearningDifficulty _difficulty = LearningDifficulty.balanced;
  DateTime _roundStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fallController =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _playing && !_locked) {
              _choose(null);
            }
          });
  }

  @override
  void dispose() {
    _fallController.dispose();
    super.dispose();
  }

  void _start() {
    final plan = widget.controller.plan;
    final difficulty = plan.recommendation.difficulty;
    setState(() {
      _roundItems = plan.orderedVocabulary.take(6).toList();
      _difficulty = difficulty;
      _round = 0;
      _score = 0;
      _playing = true;
      _finished = false;
      _locked = false;
      _lastCorrect = null;
      _roundStartedAt = DateTime.now();
    });
    _fallController.duration = Duration(
      seconds: difficulty == LearningDifficulty.gentleReview ? 11 : 7,
    );
    _fallController.forward(from: 0);
  }

  PlannedVocabulary get _current => _roundItems[_round % _roundItems.length];

  List<PlannedVocabulary> get _choices {
    if (_roundItems.isEmpty) return const [];
    final count = _difficulty == LearningDifficulty.gentleReview ? 2 : 3;
    return List.generate(
      count,
      (index) => _roundItems[(_round + index) % _roundItems.length],
    );
  }

  void _choose(PlannedVocabulary? selected) {
    if (_locked || !_playing) return;
    _locked = true;
    _fallController.stop();
    final correct = selected?.id == _current.id;
    final response =
        DateTime.now()
            .difference(_roundStartedAt)
            .inMilliseconds
            .clamp(200, 30000) /
        1000;
    widget.controller.recordAnswer(
      vocabularyId: _current.id,
      correct: correct,
      responseSeconds: response,
    );

    setState(() {
      _lastCorrect = correct;
      if (correct) _score++;
    });

    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      if (_round >= 4) {
        setState(() {
          _playing = false;
          _finished = true;
        });
        return;
      }
      setState(() {
        _round++;
        _locked = false;
        _lastCorrect = null;
        _roundStartedAt = DateTime.now();
      });
      _fallController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
      return _GameIntro(
        finished: _finished,
        score: _score,
        plan: widget.controller.plan,
        onStart: _start,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MonoLabel('Lượt ${_round + 1} / 5'),
              const Spacer(),
              Text(
                '$_score điểm',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Chạm vào từ có nghĩa:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            _current.meaning,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpace.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _lastCorrect == null
                ? const SizedBox(height: 28)
                : Row(
                    key: ValueKey(_lastCorrect),
                    children: [
                      Icon(
                        _lastCorrect!
                            ? Icons.check_circle_outline
                            : Icons.refresh_rounded,
                        color: _lastCorrect!
                            ? AppColors.pearDeep
                            : AppColors.danger,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          _lastCorrect!
                              ? 'Đúng. HLR đã cập nhật lần gặp này.'
                              : 'Chưa đúng. Từ này sẽ được ôn sớm hơn.',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpace.xs),
          Expanded(
            child: LearnflowCard(
              color: AppColors.cyan,
              padding: EdgeInsets.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const chipWidth = 112.0;
                  final available = (constraints.maxWidth - chipWidth).clamp(
                    0,
                    double.infinity,
                  );
                  final fractions = _choices.length == 2
                      ? const [0.06, 0.94]
                      : const [0.04, 0.5, 0.96];
                  return AnimatedBuilder(
                    animation: _fallController,
                    builder: (context, _) {
                      final y =
                          (_fallController.value * (constraints.maxHeight - 62))
                              .clamp(0, double.infinity)
                              .toDouble();
                      return Stack(
                        children: [
                          Positioned(
                            left: AppSpace.md,
                            top: AppSpace.md,
                            child: Opacity(
                              opacity: .55,
                              child: Text(
                                'BẮT TRƯỚC KHI CHẠM ĐÁY',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      color: AppColors.ink,
                                    ),
                              ),
                            ),
                          ),
                          ...List.generate(_choices.length, (index) {
                            final item = _choices[index];
                            return Positioned(
                              left: available * fractions[index],
                              top: y,
                              width: chipWidth,
                              child: _FallingWord(
                                word: item.word,
                                color: const [
                                  AppColors.pear,
                                  AppColors.coral,
                                  AppColors.lavender,
                                ][index],
                                onTap: _locked ? null : () => _choose(item),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          LinearProgressIndicator(
            value: (_round + 1) / 5,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            color: AppColors.ink,
            backgroundColor: AppColors.rule,
          ),
        ],
      ),
    );
  }
}

class _GameIntro extends StatelessWidget {
  const _GameIntro({
    required this.finished,
    required this.score,
    required this.plan,
    required this.onStart,
  });

  final bool finished;
  final int score;
  final AdaptiveLearningPlan plan;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final riskCount = plan.orderedVocabulary
        .where((item) => item.prediction.isAtRisk)
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(finished ? 'Phiên vừa hoàn thành' : 'Mini-game thích nghi'),
          const SizedBox(height: AppSpace.sm),
          Text(
            finished
                ? '$score / 5 từ đã bắt đúng'
                : 'Bắt từ sắp rơi khỏi trí nhớ.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpace.lg),
          LearnflowCard(
            color: AppColors.coral,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MemoryMascot(size: 82),
                const SizedBox(height: AppSpace.lg),
                Text(
                  '$riskCount từ đang dưới ngưỡng nhớ 65%',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpace.xs),
                const Text(
                  'Mỗi lần chạm ghi lại thời gian phản xạ và đúng/sai. Lịch ôn được tính lại ngay sau lượt.',
                ),
                const SizedBox(height: AppSpace.lg),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(finished ? 'Chơi lại' : 'Bắt đầu 5 lượt'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          const LearnflowCard(
            color: AppColors.paperDeep,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.touch_app_outlined),
                SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'Từ yếu xuất hiện trước. Trả lời chậm hoặc sai làm half-life ngắn lại; hệ thống sẽ đưa từ đó quay lại sớm hơn.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallingWord extends StatelessWidget {
  const _FallingWord({
    required this.word,
    required this.color,
    required this.onTap,
  });

  final String word;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.card),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          child: Text(
            word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
