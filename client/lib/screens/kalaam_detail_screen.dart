import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/kalaam_model.dart';
import 'practice_launcher_sheet.dart';

class KalaamDetailScreen extends StatefulWidget {
  const KalaamDetailScreen({super.key});

  @override
  State<KalaamDetailScreen> createState() => _KalaamDetailScreenState();
}

class _KalaamDetailScreenState extends State<KalaamDetailScreen> {
  KalaamModel? _kalaam;
  bool _initialized = false;

  // Flat line representation for highlight + scroll
  late final List<_DetailLine> _lines;
  late final List<GlobalKey> _lineKeys;
  late final List<int> _lineWordStarts;
  late final List<int> _lineWordCounts;
  late final List<String> _normalizedWords;
  int _totalWords = 0;

  // Voice mode
  final SpeechToText _speech = SpeechToText();
  bool _voiceAvailable = false;
  bool _voiceMode = false;
  bool _isListening = false;
  int _sessionWordOffset = 0;
  // Notifiers drive per-line/word updates without rebuilding the whole screen.
  // -1 line = no active highlight.
  final ValueNotifier<int> _currentLine = ValueNotifier<int>(-1);
  final ValueNotifier<int> _currentWord = ValueNotifier<int>(0);
  final ValueNotifier<double> _soundLevel = ValueNotifier<double>(0.0);

  static final _listenOptions = SpeechListenOptions(
    partialResults: true,
    cancelOnError: false,
    listenMode: ListenMode.dictation,
    autoPunctuation: false,
  );
  static const _listenFor = Duration(minutes: 5);
  static const _pauseFor = Duration(seconds: 10);

  static final _diacritics = RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭ]');
  static final _nonAlphaNum = RegExp(r"[^\p{L}\p{N}]+", unicode: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _kalaam = ModalRoute.of(context)!.settings.arguments as KalaamModel;
    _buildLineMaps();
    _initVoice();
  }

  void _buildLineMaps() {
    _lines = <_DetailLine>[];
    _lineWordStarts = <int>[];
    _lineWordCounts = <int>[];
    final normalized = <String>[];
    int total = 0;
    final stanzas = _kalaam!.content;
    for (int si = 0; si < stanzas.length; si++) {
      final stanza = stanzas[si];
      for (int li = 0; li < stanza.lines.length; li++) {
        final text = stanza.lines[li];
        _lines.add(_DetailLine(
          stanzaIndex: si,
          lineIndex: li,
          text: text,
          isLastInStanza: li == stanza.lines.length - 1,
        ));
        _lineWordStarts.add(total);
        final raw = text.trim();
        final words = raw.isEmpty ? const <String>[] : raw.split(RegExp(r'\s+'));
        _lineWordCounts.add(words.length);
        total += words.length;
        for (final w in words) {
          normalized.add(_normalizeWord(w));
        }
      }
    }
    _normalizedWords = normalized;
    _totalWords = total;
    _lineKeys = List.generate(_lines.length, (_) => GlobalKey());
  }

  String _normalizeWord(String s) {
    var out = s.toLowerCase();
    out = out.replaceAll(_diacritics, '');
    out = out.replaceAll(_nonAlphaNum, '');
    return out;
  }

  int _levDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = a.length, n = b.length;
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);
    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      for (int j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        var best = del < ins ? del : ins;
        if (sub < best) best = sub;
        curr[j] = best;
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }

  bool _wordsMatch(String spoken, String kalaam) {
    if (spoken.isEmpty || kalaam.isEmpty) return false;
    if (spoken == kalaam) return true;
    final maxLen = spoken.length > kalaam.length ? spoken.length : kalaam.length;
    if (maxLen <= 3) return false;
    if (spoken.startsWith(kalaam) || kalaam.startsWith(spoken)) {
      final shortLen =
          spoken.length < kalaam.length ? spoken.length : kalaam.length;
      if (shortLen >= 3) return true;
    }
    final tolerance = (maxLen / 4).floor().clamp(1, 3);
    return _levDistance(spoken, kalaam) <= tolerance;
  }

  Future<void> _initVoice() async {
    _voiceAvailable = await _speech.initialize(
      onError: (e) => debugPrint('STT error: $e'),
      onStatus: (s) {
        if (s == 'done' && _isListening && _voiceMode) _restartListening();
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() {
    if (!_voiceAvailable) return;
    setState(() => _isListening = true);
    _speech.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) => _soundLevel.value = level,
      listenFor: _listenFor,
      pauseFor: _pauseFor,
      listenOptions: _listenOptions,
    );
  }

  void _restartListening() {
    if (!_voiceMode || !mounted) return;
    _speech.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) => _soundLevel.value = level,
      listenFor: _listenFor,
      pauseFor: _pauseFor,
      listenOptions: _listenOptions,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted || !_voiceMode) return;

    final spoken = result.recognizedWords
        .split(RegExp(r'\s+'))
        .map(_normalizeWord)
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (spoken.isEmpty) return;

    const lookahead = 5;
    int kPtr = _sessionWordOffset;
    int lastMatched = -1;

    for (final sw in spoken) {
      if (kPtr >= _totalWords) break;
      int found = -1;
      final maxStep =
          kPtr + lookahead < _totalWords ? lookahead : _totalWords - kPtr;
      for (int step = 0; step < maxStep; step++) {
        final kw = _normalizedWords[kPtr + step];
        if (kw.isEmpty) continue;
        if (_wordsMatch(sw, kw)) {
          found = kPtr + step;
          break;
        }
      }
      if (found >= 0) {
        lastMatched = found;
        kPtr = found + 1;
      }
    }

    if (result.finalResult) {
      _sessionWordOffset = lastMatched >= 0
          ? (lastMatched + 1).clamp(0, _totalWords)
          : _sessionWordOffset;
    }

    if (lastMatched >= 0) {
      _updatePositionFromWordCount(lastMatched);
    }
  }

  void _updatePositionFromWordCount(int globalWord) {
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (_lineWordStarts[i] <= globalWord) {
        final wordInLine = (globalWord - _lineWordStarts[i])
            .clamp(0, (_lineWordCounts[i] - 1).clamp(0, 999));
        final lineChanged = _currentLine.value != i;
        // Notifier writes are O(1) and only rebuild the lines that depend on
        // the changed value — no full-screen rebuild on each STT partial.
        _currentLine.value = i;
        _currentWord.value = wordInLine;
        if (lineChanged) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToCurrentLine());
        }
        break;
      }
    }
  }

  void _scrollToCurrentLine() {
    final idx = _currentLine.value;
    if (idx < 0 || idx >= _lineKeys.length) return;
    final ctx = _lineKeys[idx].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 150),
      alignment: 0.4,
      curve: Curves.easeOutCubic,
    );
  }

  void _stopListening() {
    _speech.stop();
    _soundLevel.value = 0.0;
    setState(() => _isListening = false);
  }

  Future<void> _jumpToLine(int i) async {
    if (i < 0 || i >= _lines.length) return;
    if (!_voiceAvailable) return;
    HapticFeedback.selectionClick();

    _sessionWordOffset = _lineWordStarts[i];
    if (!_voiceMode) {
      setState(() => _voiceMode = true);
    }
    _currentLine.value = i;
    _currentWord.value = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToCurrentLine();
    });

    // Reset the STT session so words spoken before the jump don't leak into
    // the new position's match window. Guard against the onStatus('done')
    // auto-restart by clearing _isListening before cancel.
    if (_isListening) {
      _isListening = false;
      try {
        await _speech.cancel();
      } catch (_) {}
    }
    if (_voiceMode && mounted) {
      _startListening();
    }
  }

  void _toggleVoiceMode() {
    setState(() => _voiceMode = !_voiceMode);
    if (_voiceMode) {
      _sessionWordOffset = 0;
      _currentLine.value = 0;
      _currentWord.value = 0;
      _startListening();
    } else {
      _stopListening();
      _currentLine.value = -1;
      _currentWord.value = 0;
    }
  }

  @override
  void dispose() {
    if (_isListening) _speech.stop();
    _soundLevel.dispose();
    _currentLine.dispose();
    _currentWord.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kalaam = _kalaam;
    if (kalaam == null) return const Scaffold(backgroundColor: Color(0xFF0f0f1a));

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        title: Text(
          kalaam.category[0].toUpperCase() + kalaam.category.substring(1),
          style: const TextStyle(color: Color(0xFFe2b96f)),
        ),
        actions: [
          // if (isOwner)
          //   IconButton(
          //     tooltip: 'Edit',
          //     icon: const Icon(Icons.edit_outlined, color: Color(0xFFe2b96f), size: 20),
          //     onPressed: () => Navigator.pushReplacementNamed(
          //       context,
          //       '/edit',
          //       arguments: kalaam,
          //     ),
          //   ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: _FollowVoiceButton(
              voiceMode: _voiceMode,
              voiceAvailable: _voiceAvailable,
              onTap: _voiceAvailable ? _toggleVoiceMode : null,
            ),
          ),
          TextButton.icon(
            onPressed: () => showPracticeLauncher(context, kalaam),
            icon: const Icon(Icons.school_outlined, color: Color(0xFFe2b96f), size: 18),
            label: const Text('Practice', style: TextStyle(color: Color(0xFFe2b96f), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kalaam.isPublic
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  kalaam.isPublic ? Icons.public : Icons.lock_outline,
                  size: 14,
                  color: kalaam.isPublic ? Colors.greenAccent : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  kalaam.isPublic ? 'Public' : 'Private',
                  style: TextStyle(
                    fontSize: 12,
                    color: kalaam.isPublic ? Colors.greenAccent : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, _voiceMode ? 100 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Decorative top bar
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2b96f),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  kalaam.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold, height: 1.3),
                ),
                if (kalaam.poet != null && kalaam.poet!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '— ${kalaam.poet}',
                    style: const TextStyle(color: Color(0xFFe2b96f), fontSize: 15, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFFe2b96f),
                      backgroundImage: kalaam.author.avatar != null ? NetworkImage(kalaam.author.avatar!) : null,
                      child: kalaam.author.avatar == null
                          ? Text(
                              kalaam.author.name.isNotEmpty ? kalaam.author.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(kalaam.author.name, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(width: 16),
                    Text(_formatDate(kalaam.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                if (kalaam.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: kalaam.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe2b96f).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFe2b96f).withValues(alpha: 0.3)),
                      ),
                      child: Text(tag, style: const TextStyle(color: Color(0xFFe2b96f), fontSize: 11)),
                    )).toList(),
                  ),
                ],
                const Divider(color: Colors.white10, height: 48),
                ..._buildLineWidgets(),
              ],
            ),
          ),

          // Voice indicator (when voice mode is on)
          if (_voiceMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEE0a0a14), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color: _isListening ? const Color(0xFFe2b96f) : Colors.white38,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: ValueListenableBuilder<double>(
                          valueListenable: _soundLevel,
                          builder: (_, level, _) => LinearProgressIndicator(
                            value: ((level + 50) / 50).clamp(0.0, 1.0),
                            backgroundColor: Colors.white12,
                            color: const Color(0xFFe2b96f),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Voice active',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildLineWidgets() {
    final widgets = <Widget>[];
    for (int i = 0; i < _lines.length; i++) {
      widgets.add(_KalaamLineView(
        lineKey: _lineKeys[i],
        index: i,
        line: _lines[i],
        wordCount: _lineWordCounts[i],
        voiceMode: _voiceMode,
        currentLine: _currentLine,
        currentWord: _currentWord,
        onDoubleTap: _voiceAvailable ? () => _jumpToLine(i) : null,
      ));
      if (_lines[i].isLastInStanza && i < _lines.length - 1) {
        widgets.add(_StanzaDivider());
      }
    }
    widgets.add(const SizedBox(height: 16));
    return widgets;
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _KalaamLineView extends StatelessWidget {
  final GlobalKey lineKey;
  final int index;
  final _DetailLine line;
  final int wordCount;
  final bool voiceMode;
  final ValueListenable<int> currentLine;
  final ValueListenable<int> currentWord;
  final VoidCallback? onDoubleTap;

  const _KalaamLineView({
    required this.lineKey,
    required this.index,
    required this.line,
    required this.wordCount,
    required this.voiceMode,
    required this.currentLine,
    required this.currentWord,
    required this.onDoubleTap,
  });

  // Shared paint instance — used by every active-word background, avoiding
  // a new Paint allocation on each word-highlight rebuild.
  static final Paint _highlightPaint = Paint()
    ..color = const Color(0xFFe2b96f);
  static final RegExp _wsSplit = RegExp(r'\s+');

  static const _activeWordStyle = TextStyle(
    color: Color(0xFFe2b96f),
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.8,
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: onDoubleTap,
        child: Container(
          key: lineKey,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ValueListenableBuilder<int>(
            valueListenable: currentLine,
            builder: (_, curLine, _) {
              final isCurrent = voiceMode && curLine == index;
              if (isCurrent && wordCount > 0) {
                return ValueListenableBuilder<int>(
                  valueListenable: currentWord,
                  builder: (_, curWord, _) => _buildActive(curWord),
                );
              }
              final dimmed = voiceMode && curLine >= 0 && !isCurrent;
              return _buildInactive(dimmed);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActive(int curWord) {
    final words = line.text.trim().split(_wsSplit);
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: List<TextSpan>.generate(words.length, (wi) {
            final word = words[wi];
            final isCurrentWord = wi == curWord;
            final text = wi < words.length - 1 ? '$word ' : word;
            if (!isCurrentWord) {
              return TextSpan(text: text, style: _activeWordStyle);
            }
            return TextSpan(
              text: text,
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.8,
                background: _highlightPaint,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInactive(bool dimmed) {
    return Text(
      line.text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: dimmed ? Colors.white38 : const Color(0xDEFFFFFF),
        fontSize: 17,
        height: 1.8,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

class _DetailLine {
  final int stanzaIndex;
  final int lineIndex;
  final String text;
  final bool isLastInStanza;
  _DetailLine({
    required this.stanzaIndex,
    required this.lineIndex,
    required this.text,
    required this.isLastInStanza,
  });
}

class _StanzaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 1, color: Colors.white12),
          const SizedBox(width: 10),
          const Text('✦', style: TextStyle(color: Color(0xFFe2b96f), fontSize: 12)),
          const SizedBox(width: 10),
          Container(width: 40, height: 1, color: Colors.white12),
        ],
      ),
    );
  }
}

class _FollowVoiceButton extends StatelessWidget {
  final bool voiceMode;
  final bool voiceAvailable;
  final VoidCallback? onTap;

  const _FollowVoiceButton({
    required this.voiceMode,
    required this.voiceAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFe2b96f);
    final fg = voiceMode
        ? activeColor
        : (voiceAvailable ? Colors.white70 : Colors.white24);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: voiceMode ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: voiceMode
                ? activeColor.withValues(alpha: 0.5)
                : (voiceAvailable ? Colors.white24 : Colors.white12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              voiceMode ? Icons.mic : Icons.mic_none,
              size: 14,
              color: fg,
            ),
            const SizedBox(width: 6),
            Text(
              voiceMode
                  ? 'Voice on'
                  : (voiceAvailable ? 'Follow my voice' : 'Mic unavailable'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
