import 'device_capability_service.dart';
import 'llm_service.dart';
import 'ai_coach_service.dart';
import '../services/scoring_service.dart';
import '../models/kalaam_model.dart';

class PracticeFeedback {
  final String headline;
  final String body;
  final List<String> tips;

  const PracticeFeedback({
    required this.headline,
    required this.body,
    required this.tips,
  });
}

abstract class FeedbackEngine {
  factory FeedbackEngine.forTier(DeviceTier tier) {
    if (tier == DeviceTier.high && LlmService.instance.isModelLoaded) {
      return const _AiBackedFeedbackEngine();
    }
    return const _TemplateFeedbackEngine();
  }

  Future<PracticeFeedback> generate(SessionScore score, KalaamModel kalaam);
}

class _TemplateFeedbackEngine implements FeedbackEngine {
  const _TemplateFeedbackEngine();

  @override
  Future<PracticeFeedback> generate(SessionScore score, KalaamModel kalaam) async {
    return PracticeFeedback(
      headline: _headline(score),
      body: _body(score),
      tips: _tips(score),
    );
  }

  // ── Headline ────────────────────────────────────────────────────────────────

  String _headline(SessionScore score) {
    final comp = score.completion;
    final acc = score.accuracy;

    if (comp >= 0.95 && acc >= 0.80) return 'Beautifully done — start to finish!';
    if (comp >= 0.95 && acc >= 0.50) return 'Full recitation — now sharpen the words';
    if (comp >= 0.95) return 'You went the distance — that matters!';
    if (comp >= 0.70 && acc >= 0.70) return 'Strong session — keep building!';
    if (comp >= 0.70) return 'Good momentum — accuracy needs attention';
    if (acc >= 0.75) return 'Accurate when you recited — push further next time';
    if (comp < 0.30) return 'Early days — every line you learn is progress';
    return 'Keep going — the words will settle with each attempt';
  }

  // ── Body — uses actual word-level mistake data ──────────────────────────────

  String _body(SessionScore score) {
    // Find the single hardest line the user actually attempted
    LineScore? hardest;
    int hardestIdx = -1;
    for (int i = 0; i < score.perLine.length; i++) {
      final ls = score.perLine[i];
      if (ls.hypothesis.isEmpty) continue; // skipped
      if (hardest == null || ls.accuracy < hardest.accuracy) {
        hardest = ls;
        hardestIdx = i;
      }
    }

    // Find the best line for positive reinforcement
    LineScore? best;
    int bestIdx = -1;
    for (int i = 0; i < score.perLine.length; i++) {
      final ls = score.perLine[i];
      if (ls.hypothesis.isEmpty) continue;
      if (best == null || ls.accuracy > best.accuracy) {
        best = ls;
        bestIdx = i;
      }
    }

    // Build a specific body from the actual mistakes
    if (hardest != null && hardest.accuracy < 0.50) {
      final alignment = ScoringService.alignWords(hardest.hypothesis, hardest.reference);
      final missed = alignment
          .where((w) => !w.matched)
          .map((w) => '"${w.word}"')
          .take(3)
          .toList();

      if (missed.isNotEmpty) {
        final missedStr = missed.join(', ');
        final lineLabel = 'line ${hardestIdx + 1}';

        if (missed.length == 1) {
          return 'Your trickiest moment was $lineLabel — you got most of it right '
              'but the word $missedStr slipped. Isolate that word, say it ten times '
              'slowly, then try the full line again.';
        }
        return 'The line that needs the most work is $lineLabel. You missed the words '
            '$missedStr there. Repeat just that line out loud until those words '
            'land naturally before moving on.';
      }
    }

    // Hardest line exists but accuracy isn't terrible — or no missed words resolved
    if (hardest != null && hardestIdx >= 0 && hardest.accuracy < 0.75) {
      return 'Line ${hardestIdx + 1} was your weakest — it\'s highlighted below in red. '
          'Read it out loud a few times, then try to say it from memory. '
          'Small focused repeats on one line beat running through the whole kalaam every time.';
    }

    // Best line positive reinforcement when overall is decent
    if (best != null && best.accuracy >= 0.80 && score.accuracy >= 0.60) {
      return 'Line ${bestIdx + 1} was your strongest — you really have that one. '
          'Carry that same confidence into the lines highlighted in red below, '
          'giving each one the same attention until it clicks.';
    }

    // Completion-focused message when user didn't finish
    if (score.completion < 0.50) {
      return 'You covered the first half — that\'s the hardest part to start. '
          'Each time you practice, try to add just one more line beyond where you stopped. '
          'The end of the kalaam will come faster than you think.';
    }

    // Generic fallback (shouldn't usually reach here)
    return 'The lines highlighted in red below are where the words didn\'t quite match. '
        'Focus your next session on those — reading each one slowly a few times '
        'before reciting from memory makes a big difference.';
  }

  // ── Tips — specific and actionable ─────────────────────────────────────────

  List<String> _tips(SessionScore score) {
    final tips = <String>[];

    // Word-level tip: name the specific worst line
    final recited = score.perLine.where((l) => l.hypothesis.isNotEmpty).toList();
    if (recited.isNotEmpty) {
      final sorted = [...recited]..sort((a, b) => a.accuracy.compareTo(b.accuracy));
      final worst = sorted.first;

      if (worst.accuracy < 0.40) {
        final alignment = ScoringService.alignWords(worst.hypothesis, worst.reference);
        final missedWords = alignment.where((w) => !w.matched).map((w) => w.word).toList();
        if (missedWords.length >= 3) {
          tips.add('Write down the line "${worst.reference}" and circle the words you keep missing — '
              'visual memory helps lock them in.');
        } else if (missedWords.isNotEmpty) {
          tips.add('The word${missedWords.length > 1 ? "s" : ""} '
              '"${missedWords.join('" and "')}" are your sticking point — '
              'say ${missedWords.length > 1 ? "them" : "it"} in context five times slowly.');
        }
      }
    }

    // Skipped lines tip
    final skipped = score.perLine.where((l) => l.hypothesis.isEmpty).length;
    if (skipped > 0) {
      tips.add('${skipped == 1 ? "One line" : "$skipped lines"} ${skipped == 1 ? "was" : "were"} '
          'not recited at all — those are shown at 0% below. Start there next session.');
    }

    // Flow tip
    if (score.flowScore < 0.45) {
      tips.add('Your pace was uneven — try reciting along with a recording to feel the natural rhythm before going solo.');
    }

    // Completion tip
    if (score.completion < 0.50) {
      tips.add('Set a goal of mastering one stanza at a time instead of the full kalaam — compound progress is faster.');
    } else if (score.completion < 0.80) {
      tips.add('You\'re over halfway — the second half often comes quicker once the opening is solid. Push through.');
    }

    // High accuracy encouragement
    if (score.accuracy >= 0.80 && score.completion >= 0.90) {
      tips.add('Try reciting with your eyes closed — that\'s the true test of how well it lives in your memory.');
    }

    return tips.take(3).toList();
  }
}

// Activated automatically on high-end devices once the coach pack is installed.
// Falls back to template if LLM inference is not yet available (FFI not built).
class _AiBackedFeedbackEngine implements FeedbackEngine {
  const _AiBackedFeedbackEngine();

  @override
  Future<PracticeFeedback> generate(SessionScore score, KalaamModel kalaam) async {
    try {
      final feedback = await AiCoachService.instance.generateFeedback(score, kalaam);
      if (feedback != null) return feedback;
    } catch (_) {}
    return await const _TemplateFeedbackEngine().generate(score, kalaam);
  }
}
