import 'package:flutter/material.dart';

import '../../domain/learning_models.dart';
import '../../ml/adaptive_difficulty_adapter.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/learnflow_components.dart';

class MlLabScreen extends StatefulWidget {
  const MlLabScreen({super.key});

  @override
  State<MlLabScreen> createState() => _MlLabScreenState();
}

class _MlLabScreenState extends State<MlLabScreen> {
  static const _adapter = AdaptiveDifficultyAdapter();

  double _winRate = .68;
  double _sessionMinutes = 18;
  double _speedRatio = 1;
  double _streak = 2;

  SessionFeatures get _features => SessionFeatures(
    winRate: _winRate,
    consecutiveWins: _winRate >= .5 ? _streak.round() : 0,
    consecutiveLosses: _winRate < .5 ? _streak.round() : 0,
    completionSpeedRatio: _speedRatio,
    sessionMinutes: _sessionMinutes,
  );

  @override
  Widget build(BuildContext context) {
    final result = _adapter.recommend(_features);
    return ListView(
      key: const PageStorageKey('ml-lab-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        const MonoLabel('Phòng thí nghiệm mô hình'),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Thử xem độ khó đổi thế nào.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Thay đổi tín hiệu phiên chơi. Bộ phân loại softmax sẽ suy luận lại ngay, không cần gửi dữ liệu lên server.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            OutlinedButton(
              onPressed: () => _applyPreset(.68, 18, 1, 2),
              child: const Text('Tập trung'),
            ),
            OutlinedButton(
              onPressed: () => _applyPreset(.9, 55, .82, 6),
              child: const Text('Quá tải'),
            ),
            OutlinedButton(
              onPressed: () => _applyPreset(.96, 12, .55, 7),
              child: const Text('Nhàm chán'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        LearnflowCard(
          color: AppColors.paperDeep,
          child: Column(
            children: [
              _FeatureSlider(
                label: 'Tỷ lệ thắng',
                valueLabel: '${(_winRate * 100).round()}%',
                value: _winRate,
                min: 0,
                max: 1,
                divisions: 20,
                onChanged: (value) => setState(() => _winRate = value),
              ),
              _FeatureSlider(
                label: 'Chuỗi thắng / thua',
                valueLabel: _streak.round().toString(),
                value: _streak,
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => setState(() => _streak = value),
              ),
              _FeatureSlider(
                label: 'Tốc độ hoàn thành',
                valueLabel: '${_speedRatio.toStringAsFixed(2)}× chuẩn',
                value: _speedRatio,
                min: .4,
                max: 1.8,
                divisions: 28,
                onChanged: (value) => setState(() => _speedRatio = value),
              ),
              _FeatureSlider(
                label: 'Thời lượng phiên',
                valueLabel: '${_sessionMinutes.round()} phút',
                value: _sessionMinutes,
                min: 1,
                max: 75,
                divisions: 74,
                onChanged: (value) => setState(() => _sessionMinutes = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _PredictionCard(result: result),
        const SizedBox(height: AppSpace.xl),
        Text(
          'Model nào học từ đâu?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpace.md),
        const LearnflowCard(
          color: AppColors.cyan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel('1 · Trí nhớ từ vựng', color: AppColors.ink),
              SizedBox(height: AppSpace.sm),
              Text(
                'Half-Life Regression',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppSpace.xs),
              Text(
                'Duolingo cung cấp p_recall, delta, history_seen và history_correct. Artifact đang chạy là baseline chưa huấn luyện; script HLR sẽ thay trọng số sau khi tải bộ dữ liệu 13 triệu trace.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        const LearnflowCard(
          color: AppColors.lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel('2 · Trạng thái phiên', color: AppColors.ink),
              SizedBox(height: AppSpace.sm),
              Text(
                'Softmax 3 lớp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppSpace.xs),
              Text(
                'Cần dữ liệu app kèm nhãn tự báo cáo “quá tải / tập trung / nhàm chán”. Bản MVP dùng bộ trọng số cold-start có thể thay thế sau huấn luyện.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyPreset(
    double winRate,
    double minutes,
    double speed,
    double streak,
  ) {
    setState(() {
      _winRate = winRate;
      _sessionMinutes = minutes;
      _speedRatio = speed;
      _streak = streak;
    });
  }
}

class _FeatureSlider extends StatelessWidget {
  const _FeatureSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(valueLabel),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.result});

  final DifficultyRecommendation result;

  @override
  Widget build(BuildContext context) {
    final state = switch (result.state) {
      EngagementState.overloaded => 'Quá tải',
      EngagementState.focused => 'Tập trung',
      EngagementState.bored => 'Nhàm chán',
    };
    final difficulty = switch (result.difficulty) {
      LearningDifficulty.gentleReview => 'Ôn nhẹ từ sắp quên',
      LearningDifficulty.balanced => 'Giữ độ khó cân bằng',
      LearningDifficulty.challenge => 'Tăng thử thách',
    };
    final color = switch (result.state) {
      EngagementState.overloaded => AppColors.coral,
      EngagementState.focused => AppColors.pear,
      EngagementState.bored => AppColors.lavender,
    };
    return LearnflowCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel('Dự đoán · $state', color: AppColors.ink),
          const SizedBox(height: AppSpace.sm),
          Text(difficulty, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpace.xs),
          Text(result.reason),
          const SizedBox(height: AppSpace.lg),
          ProbabilityBar(value: result.confidence, color: AppColors.ink),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Độ tin cậy ${(result.confidence * 100).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
