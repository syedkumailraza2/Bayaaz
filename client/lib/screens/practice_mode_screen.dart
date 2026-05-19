import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/kalaam_model.dart';
import '../providers/practice_provider.dart';

// ───────────────────────────────────────────────────────────────────────────
// Design tokens (mirrors home_screen.dart)
// ───────────────────────────────────────────────────────────────────────────

const _kTeal = Color(0xFF234547);
const _kTealDeep = Color(0xFF1B3739);
const _kOrange = Color(0xFFFDA944);
const _kSurfaceMuted = Color(0xFFF4F4F4);
const _kInkPrimary = Color(0xFF1F1F1F);
const _kInkMuted = Color(0xFF9CA3AF);
const _kWaveInactive = Color(0xFFD9D9D9);

// ───────────────────────────────────────────────────────────────────────────
// Internal helpers
// ───────────────────────────────────────────────────────────────────────────

class _LineItem {
  final int stanzaIndex;
  final int lineIndex;
  final String text;
  _LineItem({
    required this.stanzaIndex,
    required this.lineIndex,
    required this.text,
  });
}

/// Decide a sensible text direction for a stanza by sniffing the first
/// non-whitespace character. Arabic Unicode glyphs → RTL; otherwise LTR
/// (the Figma reference shows Roman-Urdu transliteration).
TextDirection _scriptDirectionFor(String text) {
  for (final rune in text.runes) {
    if (rune == 0x20 || rune == 0x09 || rune == 0x0A) continue;
    final isArabic = (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }
  return TextDirection.ltr;
}

class _CategoryGlyph {
  final String glyph;
  const _CategoryGlyph(this.glyph);

  static _CategoryGlyph from(String category) {
    switch (category) {
      case 'nauha':
        return const _CategoryGlyph('نوحہ');
      case 'marsiya':
        return const _CategoryGlyph('مرثیہ');
      case 'qasida':
        return const _CategoryGlyph('قصیدہ');
      case 'qata':
        return const _CategoryGlyph('قطع');
      default:
        return const _CategoryGlyph('بیاض');
    }
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Widget
// ───────────────────────────────────────────────────────────────────────────

class PracticeModeScreen extends StatefulWidget {
  const PracticeModeScreen({super.key});

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen>
    with TickerProviderStateMixin {
  // ── State preserved from the original behaviour ─────────────────────────
  late final KalaamModel _kalaam;
  late final List<_LineItem> _lines;
  late final List<GlobalKey> _lineKeys;
  late final ScrollController _sheetScrollController;

  int _currentLineIndex = 0;
  int _loopStanzaIndex = -1;
  bool _isPlaying = false;
  bool _initialized = false;

  // Mode flag kept around so saved progress stays well-formed. Defaults to
  // 'solo' when no mode is supplied via route arguments.
  String _mode = 'solo';

  // ── New visual-only animation state ─────────────────────────────────────
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final AnimationController _heroEntryController;
  late final AnimationController _glyphEntryController;
  late final AnimationController _diamondSpinController;
  late final AnimationController _playheadController;

  double _sheetSize = 0.62;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _heroEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glyphEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _diamondSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _playheadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    );

    _sheetScrollController = ScrollController();
    _sheetController.addListener(_onSheetSizeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroEntryController.forward();
      _glyphEntryController.forward();
    });
  }

  void _onSheetSizeChanged() {
    final size = _sheetController.size;
    if ((size - _sheetSize).abs() > 0.005) {
      setState(() => _sheetSize = size);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _kalaam = args['kalaam'] as KalaamModel;
    _mode = (args['mode'] as String?) ?? 'solo';

    _lines = _buildLines(_kalaam);
    _lineKeys = List.generate(_lines.length, (_) => GlobalKey());

    final startStanza = args['startStanza'];
    if (startStanza is int) {
      final firstLine =
          _lines.indexWhere((l) => l.stanzaIndex == startStanza);
      if (firstLine >= 0) {
        _currentLineIndex = firstLine;
      }
    }

    _restoreProgress();

    // Animate the sheet in from a slightly smaller resting size to its
    // initial `0.62` height. The DraggableScrollableSheet itself starts at
    // 0.62 — we briefly drive it from 0.50 → 0.62 to get a softer entry.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _sheetController.animateTo(
          0.62,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
        // Controller may not be attached yet on cold frames; ignore.
      }
    });
  }

  Future<void> _restoreProgress() async {
    final provider = context.read<PracticeProvider>();
    await provider.loadProgress(_kalaam.id);
    if (!mounted) return;
    final progress = provider.getProgress(_kalaam.id);
    if (progress != null && !progress.completed) {
      setState(() {
        _currentLineIndex =
            progress.lastLine.clamp(0, math.max(0, _lines.length - 1));
        _loopStanzaIndex = progress.loopStanza;
      });
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    _heroEntryController.dispose();
    _glyphEntryController.dispose();
    _diamondSpinController.dispose();
    _playheadController.dispose();
    _sheetScrollController.dispose();
    _saveFinalProgress();
    super.dispose();
  }

  // ── Lines ──────────────────────────────────────────────────────────────

  List<_LineItem> _buildLines(KalaamModel kalaam) {
    final result = <_LineItem>[];
    for (int si = 0; si < kalaam.content.length; si++) {
      final stanza = kalaam.content[si];
      for (int li = 0; li < stanza.lines.length; li++) {
        result.add(_LineItem(
          stanzaIndex: si,
          lineIndex: li,
          text: stanza.lines[li],
        ));
      }
    }
    return result;
  }

  // ── Navigation (preserved) ──────────────────────────────────────────────

  void _nextLine() {
    if (_lines.isEmpty) return;

    if (_loopStanzaIndex >= 0) {
      final currentStanza = _lines[_currentLineIndex].stanzaIndex;
      if (currentStanza == _loopStanzaIndex) {
        final isLastInStanza = _currentLineIndex == _lines.length - 1 ||
            _lines[_currentLineIndex + 1].stanzaIndex != _loopStanzaIndex;
        if (isLastInStanza) {
          final firstLineOfStanza =
              _lines.indexWhere((l) => l.stanzaIndex == _loopStanzaIndex);
          if (firstLineOfStanza >= 0) {
            setState(() => _currentLineIndex = firstLineOfStanza);
            _persistProgress(completed: false);
            _scrollToCurrentLine();
            return;
          }
        }
      }
    }

    if (_currentLineIndex < _lines.length - 1) {
      setState(() => _currentLineIndex++);
      _persistProgress(completed: false);
      _scrollToCurrentLine();
    } else {
      _persistProgress(completed: true);
    }
  }

  void _prevLine() {
    if (_currentLineIndex > 0) {
      setState(() => _currentLineIndex--);
      _persistProgress(completed: false);
      _scrollToCurrentLine();
    }
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _playheadController.repeat();
    } else {
      _playheadController.stop();
    }
  }

  void _toggleLoopForStanza(int stanzaIndex) {
    setState(() {
      _loopStanzaIndex =
          _loopStanzaIndex == stanzaIndex ? -1 : stanzaIndex;
    });
    _persistProgress(completed: false);
  }

  // ── Scroll ──────────────────────────────────────────────────────────────

  void _scrollToCurrentLine() {
    if (_currentLineIndex < 0 || _currentLineIndex >= _lineKeys.length) return;
    final key = _lineKeys[_currentLineIndex];
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        alignment: 0.4,
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Progress persistence (preserved) ────────────────────────────────────

  void _persistProgress({required bool completed}) {
    final provider = context.read<PracticeProvider>();
    final currentStanza =
        _lines.isEmpty ? 0 : _lines[_currentLineIndex].stanzaIndex;
    provider.saveProgress(
      _kalaam.id,
      PracticeProgress(
        lastLine: _currentLineIndex,
        lastStanza: currentStanza,
        completed: completed,
        mode: _mode,
        loopStanza: _loopStanzaIndex,
      ),
    );
  }

  void _saveFinalProgress() {
    final provider = context.read<PracticeProvider>();
    final currentStanza =
        _lines.isEmpty ? 0 : _lines[_currentLineIndex].stanzaIndex;
    provider.saveProgress(
      _kalaam.id,
      PracticeProgress(
        lastLine: _currentLineIndex,
        lastStanza: currentStanza,
        completed: _currentLineIndex == _lines.length - 1,
        mode: _mode,
        loopStanza: _loopStanzaIndex,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final heroHeight = math.max(220.0, math.min(320.0, screenHeight * 0.34));

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        _saveFinalProgress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Teal hero ─────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _HeroTombstone(
                height: heroHeight,
                heroController: _heroEntryController,
                glyphController: _glyphEntryController,
                glyph: _CategoryGlyph.from(_kalaam.category).glyph,
              ),
            ),

            // ── Draggable sheet ───────────────────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.62,
              minChildSize: 0.62,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: const [0.62, 0.92],
              builder: (context, scrollController) {
                return _SheetSurface(
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SheetHeader(
                          tag: _kalaam.tags.isNotEmpty
                              ? _kalaam.tags.first
                              : 'Hussian AS',
                          title: _kalaam.title,
                          hideCaption: _sheetSize >= 0.90,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        sliver: SliverList.builder(
                          itemCount: _kalaam.content.length,
                          itemBuilder: (ctx, si) {
                            final stanza = _kalaam.content[si];
                            final showDivider =
                                si < _kalaam.content.length - 1;
                            return Column(
                              children: [
                                _StanzaBlock(
                                  stanza: stanza,
                                  stanzaIndex: si,
                                  currentLineIndex: _currentLineIndex,
                                  lines: _lines,
                                  lineKeys: _lineKeys,
                                  isLooping: _loopStanzaIndex == si,
                                ),
                                if (showDivider)
                                  _StanzaDivider(
                                    spinController:
                                        _diamondSpinController,
                                    onLongPress: () =>
                                        _toggleLoopForStanza(si),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _WaveformBlock(
                          seed: _kalaam.id.hashCode,
                          playhead: _playheadController,
                          isPlaying: _isPlaying,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 120),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Bottom action bar ─────────────────────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: media.padding.bottom + 12,
              child: _BottomActionBar(
                isPlaying: _isPlaying,
                onBack: () => Navigator.of(context).maybePop(),
                onPrev: _prevLine,
                onNext: _nextLine,
                onPlayPause: _togglePlayPause,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Hero tombstone
// ───────────────────────────────────────────────────────────────────────────

class _HeroTombstone extends StatelessWidget {
  final double height;
  final AnimationController heroController;
  final AnimationController glyphController;
  final String glyph;

  const _HeroTombstone({
    required this.height,
    required this.heroController,
    required this.glyphController,
    required this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    final heroFade = CurvedAnimation(
      parent: heroController,
      curve: Curves.easeOut,
    );
    final glyphFade = CurvedAnimation(
      parent: glyphController,
      curve: Curves.easeOut,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([heroController, glyphController]),
      builder: (context, _) {
        final dy = (1 - heroFade.value) * -8;
        final glyphScale = 0.92 + (glyphFade.value * 0.08);
        return Opacity(
          opacity: heroFade.value,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(80),
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_kTealDeep, _kTeal],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Opacity(
                        opacity: glyphFade.value,
                        child: Transform.scale(
                          scale: glyphScale,
                          child: Text(
                            glyph,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 80,
                              height: 1.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Sheet surface
// ───────────────────────────────────────────────────────────────────────────

class _SheetSurface extends StatelessWidget {
  final Widget child;
  const _SheetSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: child,
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Sheet header (handle + caption + tag chip + title)
// ───────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final String tag;
  final String title;
  final bool hideCaption;

  const _SheetHeader({
    required this.tag,
    required this.title,
    required this.hideCaption,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedOpacity(
            opacity: hideCaption ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            child: const Text(
              'Swipe up to open in full screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _kInkMuted,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.black,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Stanza block (active-line wash)
// ───────────────────────────────────────────────────────────────────────────

class _StanzaBlock extends StatelessWidget {
  final Stanza stanza;
  final int stanzaIndex;
  final int currentLineIndex;
  final List<_LineItem> lines;
  final List<GlobalKey> lineKeys;
  final bool isLooping;

  const _StanzaBlock({
    required this.stanza,
    required this.stanzaIndex,
    required this.currentLineIndex,
    required this.lines,
    required this.lineKeys,
    required this.isLooping,
  });

  @override
  Widget build(BuildContext context) {
    final activeStanzaIndex = lines.isEmpty
        ? -1
        : lines[currentLineIndex.clamp(0, lines.length - 1)].stanzaIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int li = 0; li < stanza.lines.length; li++)
          _LineRow(
            text: stanza.lines[li],
            lineKey: _lineKeyFor(stanzaIndex, li),
            isActive: _isActive(stanzaIndex, li),
            isInActiveStanza: activeStanzaIndex == stanzaIndex,
            isLooping: isLooping,
          ),
      ],
    );
  }

  GlobalKey? _lineKeyFor(int si, int li) {
    final flatIndex = lines.indexWhere(
      (l) => l.stanzaIndex == si && l.lineIndex == li,
    );
    if (flatIndex < 0) return null;
    return lineKeys[flatIndex];
  }

  bool _isActive(int si, int li) {
    if (currentLineIndex < 0 || currentLineIndex >= lines.length) return false;
    final cur = lines[currentLineIndex];
    return cur.stanzaIndex == si && cur.lineIndex == li;
  }
}

class _LineRow extends StatelessWidget {
  final String text;
  final GlobalKey? lineKey;
  final bool isActive;
  final bool isInActiveStanza;
  final bool isLooping;

  const _LineRow({
    required this.text,
    required this.lineKey,
    required this.isActive,
    required this.isInActiveStanza,
    required this.isLooping,
  });

  @override
  Widget build(BuildContext context) {
    final direction = _scriptDirectionFor(text);
    final textColor = isInActiveStanza
        ? _kInkPrimary
        : const Color(0xFF9AA0A6);

    return Container(
      key: lineKey,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? _kOrange.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isLooping && isActive
              ? Border.all(
                  color: _kOrange.withValues(alpha: 0.45),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          textDirection: direction,
          style: TextStyle(
            fontSize: 16,
            height: 1.55,
            color: textColor,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Stanza divider with rotating diamond
// ───────────────────────────────────────────────────────────────────────────

class _StanzaDivider extends StatelessWidget {
  final AnimationController spinController;
  final VoidCallback onLongPress;

  const _StanzaDivider({
    required this.spinController,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            const Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0x14000000),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(height: 1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: RotationTransition(
                turns: spinController,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    color: _kOrange,
                  ),
                ),
              ),
            ),
            const Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0x14000000),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Waveform
// ───────────────────────────────────────────────────────────────────────────

class _WaveformBlock extends StatelessWidget {
  final int seed;
  final AnimationController playhead;
  final bool isPlaying;
  const _WaveformBlock({
    required this.seed,
    required this.playhead,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '00:03',
                  style: TextStyle(
                    fontSize: 11,
                    color: _kInkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '01:30',
                  style: TextStyle(
                    fontSize: 11,
                    color: _kInkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: AnimatedBuilder(
              animation: playhead,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _WaveformPainter(
                    seed: seed,
                    progress: playhead.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final int seed;
  final double progress;
  static const int barCount = 44;

  _WaveformPainter({required this.seed, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final heights = List<double>.generate(
      barCount,
      (_) => 0.18 + rng.nextDouble() * 0.82,
    );

    final slot = size.width / barCount;
    final barWidth = math.max(1.5, slot * 0.45);
    final activePaint = Paint()..color = _kTeal;
    final inactivePaint = Paint()..color = _kWaveInactive;

    final playheadX = size.width * progress;

    for (int i = 0; i < barCount; i++) {
      final h = heights[i] * size.height;
      final centerX = slot * i + slot / 2;
      final left = centerX - barWidth / 2;
      final top = (size.height - h) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, h),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        rect,
        centerX <= playheadX ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress || old.seed != seed;
}

// ───────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ───────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onBack;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;

  const _BottomActionBar({
    required this.isPlaying,
    required this.onBack,
    required this.onPrev,
    required this.onNext,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            height: 44,
            width: 88,
            decoration: BoxDecoration(
              color: _kSurfaceMuted,
              borderRadius: BorderRadius.circular(40),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: 16, color: _kInkPrimary),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kInkPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: _kTeal,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: _kTeal.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CapsuleIconButton(
                  icon: Icons.skip_previous_rounded,
                  onTap: onPrev,
                ),
                GestureDetector(
                  onTap: onPlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(isPlaying),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                _CapsuleIconButton(
                  icon: Icons.skip_next_rounded,
                  onTap: onNext,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CapsuleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CapsuleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
