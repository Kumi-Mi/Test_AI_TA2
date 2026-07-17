import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../services/custom_exercise_generator.dart';
import '../../services/pronunciation_scorer.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/learnflow_components.dart';

extension on PracticeMode {
  String get displayLabel => switch (this) {
    PracticeMode.listening => 'Nghe',
    PracticeMode.speaking => 'Nói',
    PracticeMode.reading => 'Đọc',
    PracticeMode.writing => 'Viết',
  };

  String get exerciseLabel => displayLabel.toLowerCase();

  Color get displayColor => switch (this) {
    PracticeMode.listening => AppColors.cyan,
    PracticeMode.speaking => AppColors.coral,
    PracticeMode.reading => AppColors.pear,
    PracticeMode.writing => AppColors.lavender,
  };
}

class CustomInputScreen extends StatefulWidget {
  const CustomInputScreen({super.key});

  @override
  State<CustomInputScreen> createState() => _CustomInputScreenState();
}

class _CustomInputScreenState extends State<CustomInputScreen> {
  static const _generator = CustomExerciseGenerator();
  static const _scorer = PronunciationScorer();

  final _textController = TextEditingController(
    text:
        'Small steps become strong habits. Practice a little every day and notice what changes.',
  );
  final _answerController = TextEditingController();
  final _tts = FlutterTts();
  final _speech = SpeechToText();
  PracticeMode _mode = PracticeMode.listening;
  CustomExercise? _exercise;
  String? _inputError;
  String? _speechError;
  String _recognised = '';
  int? _score;
  bool _isListening = false;

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    _textController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _generate() {
    try {
      final exercise = _generator.generate(_textController.text, _mode);
      setState(() {
        _exercise = exercise;
        _inputError = null;
        _speechError = null;
        _recognised = '';
        _score = null;
        _answerController.clear();
      });
    } on FormatException catch (error) {
      setState(() {
        _inputError = error.message;
        _exercise = null;
      });
    }
  }

  Future<void> _speak() async {
    final exercise = _exercise;
    if (exercise == null) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1);
    await _tts.speak(exercise.targetSentence);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _speechError =
              'Không thể nhận dạng giọng nói: ${error.errorMsg}. Kiểm tra quyền micro rồi thử lại.';
          _isListening = false;
        });
      },
      onStatus: (status) {
        if (mounted && status == 'done') {
          setState(() => _isListening = false);
        }
      },
    );
    if (!available) {
      if (mounted) {
        setState(() {
          _speechError =
              'Thiết bị chưa cung cấp nhận dạng giọng nói. Bạn vẫn có thể dùng bài Nghe, Đọc hoặc Viết.';
        });
      }
      return;
    }

    setState(() {
      _isListening = true;
      _speechError = null;
      _recognised = '';
      _score = null;
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: 'en_US'),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _recognised = result.recognizedWords;
          if (result.finalResult && _exercise != null) {
            _score = _scorer.score(
              _exercise!.targetSentence,
              result.recognizedWords,
            );
          }
        });
      },
    );
  }

  void _checkTypedAnswer() {
    final exercise = _exercise;
    if (exercise == null) return;
    final expected = exercise.mode == PracticeMode.reading
        ? exercise.missingWord!
        : exercise.targetSentence;
    setState(() => _score = _scorer.score(expected, _answerController.text));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('custom-input-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        const MonoLabel('Custom Input'),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Một đoạn văn, bốn cách luyện.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Dán kịch bản của bạn. App tách câu đầu tiên và tạo bài tập ngay trên thiết bị.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpace.lg),
        const Text(
          'Đoạn văn tiếng Anh',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpace.xs),
        TextField(
          controller: _textController,
          minLines: 5,
          maxLines: 9,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Ví dụ: The train leaves at seven…',
            helperMaxLines: 2,
            helperText: _inputError == null
                ? 'Tối thiểu 5 từ. Nội dung không được tải lên máy chủ.'
                : null,
            errorText: _inputError,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        const Text(
          'Kỹ năng muốn luyện',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: PracticeMode.values.map((mode) {
            return ChoiceChip(
              selected: _mode == mode,
              onSelected: (_) => setState(() {
                _mode = mode;
                _exercise = null;
                _score = null;
              }),
              label: Text(mode.displayLabel),
              selectedColor: mode.displayColor,
              backgroundColor: AppColors.paperDeep,
              side: BorderSide.none,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpace.lg),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.auto_awesome_motion_outlined),
          label: const Text('Tạo bài tập'),
        ),
        if (_exercise case final exercise?) ...[
          const SizedBox(height: AppSpace.xl),
          _ExerciseWorkbench(
            exercise: exercise,
            answerController: _answerController,
            recognised: _recognised,
            speechError: _speechError,
            isListening: _isListening,
            score: _score,
            onSpeak: _speak,
            onListen: _toggleListening,
            onCheck: _checkTypedAnswer,
          ),
        ],
      ],
    );
  }
}

class _ExerciseWorkbench extends StatelessWidget {
  const _ExerciseWorkbench({
    required this.exercise,
    required this.answerController,
    required this.recognised,
    required this.speechError,
    required this.isListening,
    required this.score,
    required this.onSpeak,
    required this.onListen,
    required this.onCheck,
  });

  final CustomExercise exercise;
  final TextEditingController answerController;
  final String recognised;
  final String? speechError;
  final bool isListening;
  final int? score;
  final VoidCallback onSpeak;
  final VoidCallback onListen;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final isSpeaking = exercise.mode == PracticeMode.speaking;
    final showTarget = exercise.mode == PracticeMode.speaking;
    return LearnflowCard(
      color: exercise.mode.displayColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel('Bài ${exercise.mode.exerciseLabel}', color: AppColors.ink),
          const SizedBox(height: AppSpace.sm),
          Text(exercise.prompt, style: Theme.of(context).textTheme.titleLarge),
          if (showTarget) ...[
            const SizedBox(height: AppSpace.md),
            SelectableText(
              '“${exercise.targetSentence}”',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (exercise.mode == PracticeMode.listening) ...[
            const SizedBox(height: AppSpace.lg),
            OutlinedButton.icon(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Phát câu'),
            ),
          ],
          if (isSpeaking) ...[
            const SizedBox(height: AppSpace.lg),
            FilledButton.icon(
              onPressed: onListen,
              icon: Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded),
              label: Text(isListening ? 'Dừng thu' : 'Bắt đầu thu'),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              recognised.isEmpty
                  ? 'Lời nói nhận diện sẽ hiện ở đây.'
                  : 'Đã nhận diện: “$recognised”',
            ),
            if (speechError != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                speechError!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: AppSpace.lg),
            const Text(
              'Câu trả lời',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpace.xs),
            TextField(
              controller: answerController,
              minLines: exercise.mode == PracticeMode.writing ? 3 : 1,
              maxLines: exercise.mode == PracticeMode.writing ? 5 : 2,
              decoration: InputDecoration(
                hintText: exercise.mode == PracticeMode.reading
                    ? 'Điền từ còn thiếu'
                    : 'Nhập câu tiếng Anh',
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FilledButton(onPressed: onCheck, child: const Text('Chấm bài')),
          ],
          if (score case final value?) ...[
            const SizedBox(height: AppSpace.lg),
            _ScoreResult(value: value),
          ],
          const SizedBox(height: AppSpace.md),
          Text(
            isSpeaking
                ? 'Điểm phát âm là độ giống giữa bản chép giọng nói và câu gốc; đây không phải đánh giá âm vị chuyên sâu.'
                : 'Điểm dùng khoảng cách từ (word error rate) sau khi bỏ dấu câu và chữ hoa.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ScoreResult extends StatelessWidget {
  const _ScoreResult({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final message = switch (value) {
      >= 85 => 'Rất sát câu gốc',
      >= 65 => 'Khá tốt, thử thêm một lần để rõ hơn',
      _ => 'Cần luyện lại từng cụm ngắn',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Row(
        children: [
          Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'điểm tương đồng / 100',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
