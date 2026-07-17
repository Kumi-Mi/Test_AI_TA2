enum PracticeMode { listening, speaking, reading, writing }

class CustomExercise {
  const CustomExercise({
    required this.mode,
    required this.sourceText,
    required this.targetSentence,
    required this.prompt,
    this.missingWord,
  });

  final PracticeMode mode;
  final String sourceText;
  final String targetSentence;
  final String prompt;
  final String? missingWord;
}

class CustomExerciseGenerator {
  const CustomExerciseGenerator();

  CustomExercise generate(String input, PracticeMode mode) {
    final source = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (source.split(' ').length < 5) {
      throw const FormatException(
        'Đoạn văn quá ngắn. Hãy nhập ít nhất 5 từ để tạo bài tập.',
      );
    }

    final firstSentence = source
        .split(RegExp(r'[.!?]+'))
        .map((part) => part.trim())
        .firstWhere((part) => part.isNotEmpty);
    final words = RegExp(
      r"[A-Za-z']+",
    ).allMatches(firstSentence).map((match) => match.group(0)!).toList();
    final missing = words.reduce(
      (left, right) => left.length >= right.length ? left : right,
    );

    final prompt = switch (mode) {
      PracticeMode.listening =>
        'Nghe câu đầu tiên rồi gõ lại những gì bạn nghe được.',
      PracticeMode.speaking =>
        'Đọc câu sau thành tiếng. Hệ thống sẽ so khớp các từ nhận diện được.',
      PracticeMode.reading => firstSentence.replaceFirst(
        RegExp('\\b${RegExp.escape(missing)}\\b', caseSensitive: false),
        '______',
      ),
      PracticeMode.writing =>
        'Viết lại câu đầu tiên bằng tiếng Anh mà không nhìn bản gốc.',
    };

    return CustomExercise(
      mode: mode,
      sourceText: source,
      targetSentence: firstSentence,
      prompt: prompt,
      missingWord: mode == PracticeMode.reading ? missing : null,
    );
  }
}
