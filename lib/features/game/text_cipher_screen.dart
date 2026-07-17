import 'package:flutter/material.dart';

import '../../data/learning_session_controller.dart';
import '../../domain/learning_models.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/learnflow_components.dart';

class TextCipherScreen extends StatefulWidget {
  const TextCipherScreen({required this.controller, super.key});

  final LearningSessionController controller;

  @override
  State<TextCipherScreen> createState() => _TextCipherScreenState();
}

class _TextCipherScreenState extends State<TextCipherScreen> {
  final _answerController = TextEditingController();
  List<PlannedVocabulary> _roundItems = const [];
  int _round = 0;
  int _score = 0;
  bool _playing = false;
  bool _locked = false;
  bool _finished = false;
  bool? _lastCorrect;
  DateTime _roundStartedAt = DateTime.now();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  PlannedVocabulary get _current => _roundItems[_round];

  void _start() {
    setState(() {
      _roundItems = widget.controller.plan.orderedVocabulary.take(5).toList();
      _round = 0;
      _score = 0;
      _playing = _roundItems.isNotEmpty;
      _finished = false;
      _locked = false;
      _lastCorrect = null;
      _roundStartedAt = DateTime.now();
      _answerController.clear();
    });
  }

  void _submit() {
    if (_locked || !_playing || _answerController.text.trim().isEmpty) return;
    final correct =
        _answerController.text.trim().toLowerCase() ==
        _current.word.toLowerCase();
    final responseSeconds =
        DateTime.now()
            .difference(_roundStartedAt)
            .inMilliseconds
            .clamp(200, 30000) /
        1000;
    widget.controller.recordAnswer(
      vocabularyId: _current.id,
      correct: correct,
      responseSeconds: responseSeconds,
    );
    setState(() {
      _locked = true;
      _lastCorrect = correct;
      if (correct) _score++;
    });

    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_round == _roundItems.length - 1) {
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
        _answerController.clear();
      });
    });
  }

  String _cipher(String word) {
    if (word.length < 2) return word.toUpperCase();
    final pivot = (word.length / 2).ceil();
    return '${word.substring(pivot)}${word.substring(0, pivot)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
      return _CipherIntro(finished: _finished, score: _score, onStart: _start);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        Row(
          children: [
            MonoLabel('Lượt ${_round + 1} / ${_roundItems.length}'),
            const Spacer(),
            Text(
              '$_score điểm',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        LearnflowCard(
          color: AppColors.lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MonoLabel('Bản mã', color: AppColors.ink),
              const SizedBox(height: AppSpace.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _cipher(_current.word),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontFamily: 'JetBrains Mono',
                    letterSpacing: 5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'Gợi ý: ${_current.meaning}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          controller: _answerController,
          enabled: !_locked,
          autofocus: true,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Từ gốc tiếng Anh',
            hintText: 'Gõ từ đã giải mã',
          ),
        ),
        const SizedBox(height: AppSpace.md),
        FilledButton.icon(
          onPressed: _locked ? null : _submit,
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('Mở khóa'),
        ),
        const SizedBox(height: AppSpace.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _lastCorrect == null
              ? const SizedBox(height: 32)
              : Text(
                  _lastCorrect!
                      ? 'Đúng. Mật mã đã mở.'
                      : 'Đáp án là “${_current.word}”. Từ này sẽ quay lại sớm hơn.',
                  key: ValueKey((_round, _lastCorrect)),
                  style: TextStyle(
                    color: _lastCorrect!
                        ? AppColors.pearDeep
                        : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        LinearProgressIndicator(
          value: (_round + 1) / _roundItems.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          color: AppColors.ink,
          backgroundColor: AppColors.rule,
        ),
      ],
    );
  }
}

class _CipherIntro extends StatelessWidget {
  const _CipherIntro({
    required this.finished,
    required this.score,
    required this.onStart,
  });

  final bool finished;
  final int score;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        MonoLabel(finished ? 'Thử thách hoàn thành' : 'Độ khó · thử thách'),
        const SizedBox(height: AppSpace.sm),
        Text(
          finished ? '$score / 5 mật mã đã mở' : 'Xoay chữ. Mở khóa từ.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpace.lg),
        LearnflowCard(
          color: AppColors.lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.password_rounded, size: 42),
              const SizedBox(height: AppSpace.xl),
              Text(
                'Model nhận thấy phiên hiện tại còn quá dễ.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.xs),
              const Text(
                'Các chữ trong từ bị xoay vị trí. Dùng nghĩa tiếng Việt để giải mã trước khi đồng hồ phản xạ tăng.',
              ),
              const SizedBox(height: AppSpace.lg),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(finished ? 'Chơi lại' : 'Bắt đầu giải mã'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
