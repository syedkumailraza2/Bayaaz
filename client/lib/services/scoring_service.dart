import 'dart:math' as math;

class LineScore {
  final double accuracy;
  final String reference;   // original reference line text
  final String hypothesis;  // what the user said (empty if line was skipped)

  const LineScore({
    required this.accuracy,
    required this.reference,
    required this.hypothesis,
  });
}

class SessionScore {
  final double overall;
  final double accuracy;
  final double completion;
  final double flowScore;
  final double pauseScore;
  final List<LineScore> perLine;

  const SessionScore({
    required this.overall,
    required this.accuracy,
    required this.completion,
    this.flowScore = 0.0,
    this.pauseScore = 0.0,
    required this.perLine,
  });
}

/// One reference word annotated with whether the user said it correctly.
typedef WordMatch = ({String word, bool matched});

class ScoringService {
  // Strip Arabic diacritics (harakat) and normalise whitespace.
  static String normaliseText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[ً-ٰٟۖ-ۜ۟-۪ۤۧۨ-ۭ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Word-level edit distance (WER numerator).
  static int _wordEditDistance(List<String> a, List<String> b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) { dp[i][0] = i; }
    for (var j = 0; j <= n; j++) { dp[0][j] = j; }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(math.min);
        }
      }
    }
    return dp[m][n];
  }

  // Word-level similarity: 1 - WER, clamped to [0, 1].
  static double lineSimilarity(String hypothesis, String reference) {
    final h = normaliseText(hypothesis).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final r = normaliseText(reference).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (h.isEmpty && r.isEmpty) return 1.0;
    if (r.isEmpty) return 0.0;
    final dist = _wordEditDistance(h, r);
    return (1.0 - dist / r.length).clamp(0.0, 1.0);
  }

  /// Aligns each word in [referenceOriginal] against [hypothesis] using
  /// Levenshtein backtracking. Returns each reference word with a flag
  /// indicating whether the user said it correctly.
  ///
  /// Preserves original casing of [referenceOriginal] words so the UI can
  /// display them directly; comparison is done on normalised forms.
  static List<WordMatch> alignWords(String hypothesis, String referenceOriginal) {
    final rWords = referenceOriginal
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final rNorm = rWords.map(normaliseText).toList();
    final hNorm = normaliseText(hypothesis)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final m = rNorm.length;
    if (m == 0) return [];
    if (hNorm.isEmpty) {
      return [for (final w in rWords) (word: w, matched: false)];
    }

    final n = hNorm.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) { dp[i][0] = i; }
    for (var j = 0; j <= n; j++) { dp[0][j] = j; }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (rNorm[i - 1] == hNorm[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(math.min);
        }
      }
    }

    // Backtrack to mark which reference words were matched.
    final matched = List.filled(m, false);
    var i = m, j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && rNorm[i - 1] == hNorm[j - 1]) {
        matched[i - 1] = true;
        i--; j--;
      } else {
        final fromDiag = (i > 0 && j > 0) ? dp[i - 1][j - 1] : 999999;
        final fromUp   = i > 0 ? dp[i - 1][j]  : 999999;
        final fromLeft = j > 0 ? dp[i][j - 1]  : 999999;

        if (fromDiag <= fromUp && fromDiag <= fromLeft) {
          i--; j--; // substitution — ref word said wrong
        } else if (fromUp <= fromLeft) {
          i--;       // deletion — ref word skipped
        } else {
          j--;       // insertion — extra word said
        }
      }
    }

    return [
      for (int k = 0; k < rWords.length; k++)
        (word: rWords[k], matched: matched[k]),
    ];
  }

  // Global DP alignment: maps each hypothesis word to the reference line it
  // best matches. This correctly handles partial recitation (when the user
  // recites only some lines) — unlike proportional splitting, which spreads
  // the hypothesis thinly across ALL lines regardless of coverage.
  static List<String> alignToLines(String hypothesis, List<String> refLines) {
    final hypWords = normaliseText(hypothesis)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (hypWords.isEmpty) return List.filled(refLines.length, '');

    // Flatten all reference lines into one word sequence, recording which
    // line each word belongs to.
    final refFlat = <String>[];
    final wordLine = <int>[];
    for (int li = 0; li < refLines.length; li++) {
      final words = normaliseText(refLines[li])
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty);
      for (final w in words) {
        refFlat.add(w);
        wordLine.add(li);
      }
    }

    if (refFlat.isEmpty) return List.filled(refLines.length, '');

    final m = refFlat.length;
    final n = hypWords.length;

    // Standard word edit-distance DP (ref × hyp).
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) { dp[i][0] = i; }
    for (var j = 0; j <= n; j++) { dp[0][j] = j; }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        dp[i][j] = refFlat[i - 1] == hypWords[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(math.min);
      }
    }

    // Backtrack: assign each hyp word to the ref line of its aligned ref word.
    // Matches and substitutions → assigned to the ref word's line.
    // Deletions (ref word skipped) → no hyp word assigned.
    // Insertions (extra hyp word) → dropped (no ref word to bind to).
    final lineHypIndices = List.generate(refLines.length, (_) => <int>[]);
    var i = m, j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && refFlat[i - 1] == hypWords[j - 1]) {
        lineHypIndices[wordLine[i - 1]].add(j - 1); // match
        i--; j--;
      } else {
        final fromDiag = (i > 0 && j > 0) ? dp[i - 1][j - 1] : 999999;
        final fromUp   = i > 0 ? dp[i - 1][j]   : 999999;
        final fromLeft = j > 0 ? dp[i][j - 1]   : 999999;
        if (fromDiag <= fromUp && fromDiag <= fromLeft) {
          lineHypIndices[wordLine[i - 1]].add(j - 1); // substitution
          i--; j--;
        } else if (fromUp <= fromLeft) {
          i--; // deletion — ref word has no hyp counterpart
        } else {
          j--; // insertion — extra hyp word, not assigned to any line
        }
      }
    }

    return [
      for (int li = 0; li < refLines.length; li++)
        lineHypIndices[li].isEmpty
            ? ''
            : (lineHypIndices[li].toList()..sort())
                .map((hi) => hypWords[hi])
                .join(' '),
    ];
  }

  // Flow score: naturalness of pace relative to a target WPM.
  static double computeFlowScore({
    required int totalWords,
    required Duration sessionDuration,
    double expectedWpm = 80.0,
  }) {
    if (sessionDuration.inSeconds == 0 || totalWords == 0) return 0.0;
    final actualWpm = (totalWords * 60.0) / sessionDuration.inSeconds;
    final ratio = actualWpm / expectedWpm;
    return (1.0 - (ratio - 1.0).abs()).clamp(0.0, 1.0);
  }

  // Pause score: proxy until Silero VAD provides per-line silence data.
  static double computePauseScore(double accuracy, double completion) {
    return (accuracy * 0.6 + completion * 0.4).clamp(0.0, 1.0);
  }

  static SessionScore scoreSession({
    required List<String> referenceLines,
    required List<String?> hypothesisLines,
    Duration? sessionDuration,
  }) {
    final perLine = <LineScore>[];
    int recited = 0;

    for (int i = 0; i < referenceLines.length; i++) {
      final ref = referenceLines[i];
      final hyp = i < hypothesisLines.length ? hypothesisLines[i] : null;
      if (hyp == null || hyp.trim().isEmpty) {
        perLine.add(LineScore(accuracy: 0.0, reference: ref, hypothesis: ''));
      } else {
        final acc = lineSimilarity(hyp, ref);
        perLine.add(LineScore(accuracy: acc, reference: ref, hypothesis: hyp));
        recited++;
      }
    }

    final accuracy = perLine.isEmpty
        ? 0.0
        : perLine.map((l) => l.accuracy).reduce((a, b) => a + b) / perLine.length;
    final completion = referenceLines.isEmpty ? 0.0 : recited / referenceLines.length;

    final totalWords = hypothesisLines
        .whereType<String>()
        .expand((s) => s.split(RegExp(r'\s+')))
        .where((w) => w.isNotEmpty)
        .length;
    final flow = sessionDuration != null
        ? computeFlowScore(
            totalWords: totalWords,
            sessionDuration: sessionDuration,
          )
        : 0.0;
    final pause = computePauseScore(accuracy, completion);

    final overall =
        (accuracy * 0.5 + completion * 0.25 + flow * 0.15 + pause * 0.10)
            .clamp(0.0, 1.0);

    return SessionScore(
      overall: overall,
      accuracy: accuracy,
      completion: completion,
      flowScore: flow,
      pauseScore: pause,
      perLine: perLine,
    );
  }
}
