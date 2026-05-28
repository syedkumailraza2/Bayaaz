import 'package:flutter/foundation.dart';
import 'llm_service.dart';
import 'feedback_engine.dart';
import 'scoring_service.dart';
import '../models/kalaam_model.dart';

class AiCoachService {
  static final AiCoachService instance = AiCoachService._();
  AiCoachService._();

  String _buildPrompt(SessionScore score, KalaamModel kalaam) {
    final overallPct = (score.overall * 100).round();
    final accPct = (score.accuracy * 100).round();
    final compPct = (score.completion * 100).round();
    final weakLines = <String>[];
    for (int i = 0; i < score.perLine.length; i++) {
      if (score.perLine[i].accuracy < 0.5) weakLines.add('Line ${i + 1}');
    }
    final weakStr = weakLines.isEmpty ? 'none' : weakLines.join(', ');

    return 'You are a compassionate coach for Urdu/Arabic devotional poetry recitation.\n\n'
        'A student practised "${kalaam.title}" and received:\n'
        '  Overall $overallPct%  Accuracy $accPct%  Completion $compPct%\n'
        '  Weak lines: $weakStr\n\n'
        'Give a short coaching response (one headline line, then 2-3 sentences of advice, '
        'then 1-2 bullet tips starting with "•"). Be warm and specific.';
  }

  /// Returns null if the LLM stream is empty (FFI not yet wired).
  /// Caller (FeedbackEngine) falls back to template in that case.
  Future<PracticeFeedback?> generateFeedback(
      SessionScore score, KalaamModel kalaam) async {
    final prompt = _buildPrompt(score, kalaam);
    final buffer = StringBuffer();
    try {
      await for (final token
          in LlmService.instance.generate(prompt, maxTokens: 200)) {
        buffer.write(token);
      }
    } catch (e) {
      debugPrint('[AiCoach] Generation error: $e');
      return null;
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) return null;

    return _parse(text);
  }

  // Parses free-form model output into structured PracticeFeedback.
  // Expects: first non-empty line = headline, subsequent lines = body,
  // lines starting with "•" = tips.
  PracticeFeedback _parse(String text) {
    final lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String headline = 'Great effort!';
    final bodyLines = <String>[];
    final tips = <String>[];

    for (int i = 0; i < lines.length; i++) {
      if (i == 0) {
        headline = lines[0];
      } else if (lines[i].startsWith('•') || lines[i].startsWith('-')) {
        tips.add(lines[i].replaceFirst(RegExp(r'^[•\-]\s*'), ''));
      } else {
        bodyLines.add(lines[i]);
      }
    }

    return PracticeFeedback(
      headline: headline,
      body: bodyLines.join(' '),
      tips: tips,
    );
  }
}
