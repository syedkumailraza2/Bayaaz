import 'package:flutter/material.dart';
import '../models/kalaam_model.dart';
import '../services/analytics_service.dart';
import '../services/feedback_engine.dart';
import '../services/scoring_service.dart';
import '../db/practice_session_record.dart';

const _kTeal = Color(0xFF234547);
const _kTealDeep = Color(0xFF1B3739);
const _kOrange = Color(0xFFFDA944);
const _kSurfaceMuted = Color(0xFFF4F4F4);
const _kInkPrimary = Color(0xFF1F1F1F);
const _kInkMuted = Color(0xFF9CA3AF);

class PracticeResultsScreen extends StatefulWidget {
  const PracticeResultsScreen({super.key});

  @override
  State<PracticeResultsScreen> createState() => _PracticeResultsScreenState();
}

class _PracticeResultsScreenState extends State<PracticeResultsScreen> {
  List<PracticeSessionRecord>? _history;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final kalaam = args['kalaam'] as KalaamModel;
    _loadHistory(kalaam.id);
  }

  Future<void> _loadHistory(String kalaamId) async {
    final records =
        await AnalyticsService.instance.getHistory(kalaamId, limit: 5);
    if (mounted) setState(() => _history = records);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final score = args['score'] as SessionScore;
    final kalaam = args['kalaam'] as KalaamModel;
    final feedback = args['feedback'] as PracticeFeedback?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(score: score, kalaam: kalaam),
          ),

          // Feedback section
          if (feedback != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _FeedbackCard(feedback: feedback),
              ),
            ),

          // Per-line accuracy with word-level diff
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.builder(
              itemCount: score.perLine.length,
              itemBuilder: (_, i) => _LineAccuracyRow(
                lineScore: score.perLine[i],
                lineNumber: i + 1,
              ),
            ),
          ),

          // Session history
          if (_history != null && _history!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _HistorySection(records: _history!),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
              child: _ActionButtons(
                onPracticeAgain: () => Navigator.pop(context),
                onHome: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
                onPacks: () => Navigator.pushNamed(context, '/packs'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header with overall score ─────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final SessionScore score;
  final KalaamModel kalaam;
  const _HeroHeader({required this.score, required this.kalaam});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, top + 20, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kTealDeep, _kTeal],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            kalaam.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Listen Mode Results',
            style:
                TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 28),
          // Row 1: Overall (large) + Accuracy + Completion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScorePill(label: 'Overall', value: score.overall, large: true),
              _ScorePill(label: 'Accuracy', value: score.accuracy),
              _ScorePill(label: 'Completion', value: score.completion),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Flow + Pause
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScorePill(label: 'Flow', value: score.flowScore),
              _ScorePill(label: 'Pause', value: score.pauseScore),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final double value;
  final bool large;
  const _ScorePill(
      {required this.label, required this.value, this.large = false});

  Color get _color {
    if (value >= 0.8) return const Color(0xFF4ADE80);
    if (value >= 0.5) return _kOrange;
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Column(
      children: [
        Container(
          width: large ? 80 : 62,
          height: large ? 80 : 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _color, width: large ? 3 : 2),
            color: _color.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Text(
              '$pct%',
              style: TextStyle(
                fontSize: large ? 22 : 16,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Feedback card ─────────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  final PracticeFeedback feedback;
  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTeal.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 18, color: _kTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feedback.headline,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback.body,
            style: const TextStyle(
                fontSize: 13, color: _kInkPrimary, height: 1.45),
          ),
          if (feedback.tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final tip in feedback.tips)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            color: _kOrange, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                            fontSize: 12, color: _kInkMuted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Per-line accuracy row with word-level diff ────────────────────────────────

class _LineAccuracyRow extends StatelessWidget {
  final LineScore lineScore;
  final int lineNumber;

  const _LineAccuracyRow({
    required this.lineScore,
    required this.lineNumber,
  });

  Color get _barColor {
    final v = lineScore.accuracy;
    if (v >= 0.8) return const Color(0xFF22C55E);
    if (v >= 0.5) return _kOrange;
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (lineScore.accuracy * 100).round();
    final skipped = lineScore.hypothesis.isEmpty;

    // Compute word-level alignment for the reference line
    final alignment = skipped
        ? ScoringService.alignWords('', lineScore.reference)
        : ScoringService.alignWords(lineScore.hypothesis, lineScore.reference);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: line number + score percent
          Row(
            children: [
              Text(
                'Line $lineNumber',
                style: const TextStyle(
                  fontSize: 11,
                  color: _kInkMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                skipped ? 'Not recited' : '$pct%',
                style: TextStyle(
                  fontSize: 13,
                  color: skipped ? _kInkMuted : _barColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Reference line with word-level coloring
          Text.rich(
            TextSpan(
              children: [
                for (final w in alignment)
                  TextSpan(
                    text: '${w.word} ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: w.matched
                          ? const Color(0xFF16A34A)   // green — said correctly
                          : const Color(0xFFDC2626),  // red — missed / wrong
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lineScore.accuracy,
              minHeight: 4,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(_barColor),
            ),
          ),

          // "You said:" row — shown when there are actual mistakes to surface
          if (!skipped && lineScore.accuracy < 0.90 && lineScore.hypothesis.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You said: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: _kInkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    lineScore.hypothesis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kInkMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Skipped label
          if (skipped) ...[
            const SizedBox(height: 6),
            const Text(
              'Practice this line — it wasn\'t detected in your recitation.',
              style: TextStyle(fontSize: 11, color: _kInkMuted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Session history ───────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<PracticeSessionRecord> records;
  const _HistorySection({required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kInkPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        for (final rec in records) _HistoryRow(record: rec),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final PracticeSessionRecord record;
  const _HistoryRow({required this.record});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (record.overallScore * 100).round();
    final color = record.overallScore >= 0.8
        ? const Color(0xFF22C55E)
        : record.overallScore >= 0.5
            ? _kOrange
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              color: color.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                '$pct%',
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.sessionAt),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kInkPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Accuracy ${(record.accuracyScore * 100).round()}%  •  '
                  'Completion ${(record.completionScore * 100).round()}%',
                  style: const TextStyle(fontSize: 11, color: _kInkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onPracticeAgain;
  final VoidCallback onHome;
  final VoidCallback onPacks;
  const _ActionButtons({
    required this.onPracticeAgain,
    required this.onHome,
    required this.onPacks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPracticeAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
              elevation: 0,
            ),
            child: const Text(
              'Practice Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kInkPrimary,
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onPacks,
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Manage AI Packs'),
          style: TextButton.styleFrom(foregroundColor: _kInkMuted),
        ),
      ],
    );
  }
}
