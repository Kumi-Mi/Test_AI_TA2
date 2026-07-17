class PronunciationScorer {
  const PronunciationScorer();

  int score(String expected, String recognised) {
    final target = _tokens(expected);
    final actual = _tokens(recognised);
    if (actual.isEmpty || target.isEmpty) return 0;

    final distance = _levenshtein(target, actual);
    final denominator = target.length > actual.length
        ? target.length
        : actual.length;
    return ((1 - distance / denominator) * 100).round().clamp(0, 100);
  }

  List<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  int _levenshtein(List<String> a, List<String> b) {
    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
        final insertion = current[j - 1] + 1;
        final deletion = previous[j] + 1;
        current[j] = [
          substitution,
          insertion,
          deletion,
        ].reduce((left, right) => left < right ? left : right);
      }
      previous = current;
    }
    return previous.last;
  }
}
