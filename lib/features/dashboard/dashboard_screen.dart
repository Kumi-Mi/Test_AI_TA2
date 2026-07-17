import 'package:flutter/material.dart';

import '../../data/learning_session_controller.dart';
import '../../domain/learning_models.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/learnflow_components.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.controller,
    required this.openGame,
    required this.openCustomInput,
    super.key,
  });

  final LearningSessionController controller;
  final VoidCallback openGame;
  final VoidCallback openCustomInput;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final plan = controller.plan;
        final atRisk = plan.orderedVocabulary
            .where((item) => item.prediction.isAtRisk)
            .length;
        final meanRecall = plan.orderedVocabulary.isEmpty
            ? 0.0
            : plan.orderedVocabulary
                      .map((item) => item.prediction.recallProbability)
                      .reduce((a, b) => a + b) /
                  plan.orderedVocabulary.length;

        return CustomScrollView(
          key: const PageStorageKey('dashboard-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.lg,
                AppSpace.md,
                AppSpace.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  const MonoLabel('Lộ trình thích nghi · dữ liệu mẫu'),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Hôm nay nên học gì?',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Mô hình ưu tiên từ sắp quên rồi chọn nhịp chơi theo trạng thái phiên hiện tại.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _PlanWorkbench(
                    plan: plan,
                    atRisk: atRisk,
                    meanRecall: meanRecall,
                    onStart: openGame,
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text(
                    'Vì sao hệ thống chọn vậy?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpace.md),
                  _ModelExplanation(
                    plan: plan,
                    session: controller.sessionFeatures,
                  ),
                  const SizedBox(height: AppSpace.xl),
                  _QuickActions(onCustomInput: openCustomInput),
                  const SizedBox(height: AppSpace.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Từ cần gặp lại',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const MonoLabel('HLR xếp hạng'),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  ...plan.orderedVocabulary
                      .take(4)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: _VocabularyRow(item: item),
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlanWorkbench extends StatelessWidget {
  const _PlanWorkbench({
    required this.plan,
    required this.atRisk,
    required this.meanRecall,
    required this.onStart,
  });

  final AdaptiveLearningPlan plan;
  final int atRisk;
  final double meanRecall;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final stateLabel = switch (plan.recommendation.state) {
      EngagementState.overloaded => 'Có dấu hiệu quá tải',
      EngagementState.focused => 'Đang tập trung',
      EngagementState.bored => 'Cần thêm thử thách',
    };
    final gameLabel = switch (plan.game) {
      MiniGameType.wordCatch => 'Bắt từ rơi',
      MiniGameType.textCipher => 'Giải mã văn bản',
      MiniGameType.shadowSpeaking => 'Nghe và nói đuổi',
    };

    return LearnflowCard(
      color: AppColors.pear,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoLabel(stateLabel, color: AppColors.ink),
                const SizedBox(height: AppSpace.sm),
                Text(
                  gameLabel,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  plan.recommendation.reason,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpace.lg),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    _MetricChip(value: '$atRisk', label: 'từ sắp quên'),
                    _MetricChip(
                      value: '${(meanRecall * 100).round()}%',
                      label: 'khả năng nhớ',
                    ),
                    _MetricChip(
                      value:
                          '${(plan.recommendation.confidence * 100).round()}%',
                      label: 'độ tin cậy',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Bắt đầu phiên'),
                ),
              ],
            ),
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: AppSpace.lg,
                      bottom: AppSpace.md,
                    ),
                    child: MemoryMascot(size: 92),
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 7, child: details),
              const Expanded(
                flex: 3,
                child: Center(child: MemoryMascot(size: 126)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value  ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: label),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

class _ModelExplanation extends StatelessWidget {
  const _ModelExplanation({required this.plan, required this.session});

  final AdaptiveLearningPlan plan;
  final SessionFeatures session;

  @override
  Widget build(BuildContext context) {
    final winRate = session.winRate.clamp(0, 1).toDouble();
    final speedScore = (2 - session.completionSpeedRatio)
        .clamp(0, 1)
        .toDouble();
    final durationScore = (session.sessionMinutes / 60).clamp(0, 1).toDouble();
    return LearnflowCard(
      color: AppColors.cyan,
      child: Column(
        children: [
          _SignalRow(label: 'Tỷ lệ thắng', value: winRate),
          const SizedBox(height: AppSpace.md),
          _SignalRow(label: 'Tốc độ so với chính bạn', value: speedScore),
          const SizedBox(height: AppSpace.md),
          _SignalRow(label: 'Thời lượng phiên', value: durationScore),
          const SizedBox(height: AppSpace.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_graph_rounded, size: 22),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Softmax phân loại trạng thái; HLR xếp từ theo xác suất nhớ. Kết quả này là suy luận trên thiết bị.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 126,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ProbabilityBar(value: value, color: AppColors.ink),
        ),
        const SizedBox(width: AppSpace.sm),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onCustomInput});

  final VoidCallback onCustomInput;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final custom = LearnflowCard(
          color: AppColors.coral,
          onTap: onCustomInput,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mic_none_rounded),
              const SizedBox(height: AppSpace.xl),
              Text(
                'Biến văn bản của bạn thành bài tập',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.xs),
              const Text('Nghe · Nói · Đọc · Viết'),
            ],
          ),
        );
        final privacy = const LearnflowCard(
          color: AppColors.lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.phonelink_lock_outlined),
              SizedBox(height: AppSpace.lg),
              Text(
                'Suy luận cục bộ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppSpace.xs),
              Text('Log học tập được lưu trên thiết bị trong bản MVP.'),
            ],
          ),
        );
        if (constraints.maxWidth < 540) {
          return Column(
            children: [
              custom,
              const SizedBox(height: AppSpace.sm),
              privacy,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: custom),
            const SizedBox(width: AppSpace.sm),
            Expanded(flex: 4, child: privacy),
          ],
        );
      },
    );
  }
}

class _VocabularyRow extends StatelessWidget {
  const _VocabularyRow({required this.item});

  final PlannedVocabulary item;

  @override
  Widget build(BuildContext context) {
    final probability = item.prediction.recallProbability;
    final color = probability < .65 ? AppColors.coral : AppColors.mint;
    return LearnflowCard(
      color: AppColors.paperDeep,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.input),
            ),
            child: Text(
              '${(probability * 100).round()}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.word, style: Theme.of(context).textTheme.titleLarge),
                Text(item.meaning),
              ],
            ),
          ),
          Text(
            '${item.prediction.nextReviewInHours.round()}h',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
