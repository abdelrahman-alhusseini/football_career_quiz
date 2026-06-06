class AnswerChecker {
  static bool isCorrect({
    required String guess,
    required List<String> acceptedAnswers,
  }) {
    final cleanedGuess = _clean(guess);

    if (cleanedGuess.isEmpty) return false;

    for (final answer in acceptedAnswers) {
      final cleanedAnswer = _clean(answer);

      if (cleanedGuess == cleanedAnswer) {
        return true;
      }

      if (_isCloseEnough(cleanedGuess, cleanedAnswer)) {
        return true;
      }
    }

    return false;
  }

  static String _clean(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static bool _isCloseEnough(String guess, String answer) {
    if (guess.length < 4 || answer.length < 4) return false;

    final distance = _levenshteinDistance(guess, answer);
    final maxLength = guess.length > answer.length ? guess.length : answer.length;

    if (maxLength <= 6) return distance <= 1;
    if (maxLength <= 12) return distance <= 2;
    return distance <= 3;
  }

  static int _levenshteinDistance(String a, String b) {
    final rows = a.length + 1;
    final cols = b.length + 1;
    final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = _min3(
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[a.length][b.length];
  }

  static int _min3(int a, int b, int c) {
    var min = a < b ? a : b;
    return min < c ? min : c;
  }
}
