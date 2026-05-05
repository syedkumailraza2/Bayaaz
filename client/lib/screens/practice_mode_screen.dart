import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/kalaam_model.dart';
import '../providers/practice_provider.dart';

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _LineItem {
  final int stanzaIndex;
  final int lineIndex;
  final String text;
  _LineItem({required this.stanzaIndex, required this.lineIndex, required this.text});
}

enum _PracticeMode { solo, follow, listen }

_PracticeMode _parseModeStr(String s) {
  switch (s) {
    case 'follow':
      return _PracticeMode.follow;
    case 'listen':
      return _PracticeMode.listen;
    default:
      return _PracticeMode.solo;
  }
}

String _modeLabel(_PracticeMode m) {
  switch (m) {
    case _PracticeMode.follow:
      return 'Follow';
    case _PracticeMode.listen:
      return 'Listen';
    case _PracticeMode.solo:
      return 'Solo';
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PracticeModeScreen extends StatefulWidget {
  const PracticeModeScreen({super.key});

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  late final KalaamModel _kalaam;
  late final List<_LineItem> _lines;
  late final List<GlobalKey> _lineKeys;
  final ScrollController _scrollController = ScrollController();

  late _PracticeMode _mode;
  int _currentLineIndex = 0;
  bool _isPlaying = false;
  Timer? _timer;
  double _speed = 1.0;

  // Memorization
  bool _memorizationMode = false;
  int _hideLevel = 0; // 0=none 1=last word 2=every other 3=all but first

  // Loop stanza (-1 = no loop)
  int _loopStanzaIndex = -1;

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _kalaam = args['kalaam'] as KalaamModel;
    final modeStr = args['mode'] as String;

    _lines = _buildLines(_kalaam);
    _lineKeys = List.generate(_lines.length, (_) => GlobalKey());
    _mode = _parseModeStr(modeStr);

    // Restore saved progress
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final provider = context.read<PracticeProvider>();
    await provider.loadProgress(_kalaam.id);
    if (!mounted) return;
    final progress = provider.getProgress(_kalaam.id);
    if (progress != null && !progress.completed) {
      setState(() {
        _currentLineIndex = progress.lastLine.clamp(0, _lines.length - 1);
        _loopStanzaIndex = progress.loopStanza;
        // Only restore mode if launched without an explicit mode preference
        // (we keep the mode the user tapped in the launcher)
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _saveFinalProgress();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lines builder
  // ---------------------------------------------------------------------------

  List<_LineItem> _buildLines(KalaamModel kalaam) {
    final result = <_LineItem>[];
    for (int si = 0; si < kalaam.content.length; si++) {
      final stanza = kalaam.content[si];
      for (int li = 0; li < stanza.lines.length; li++) {
        result.add(_LineItem(stanzaIndex: si, lineIndex: li, text: stanza.lines[li]));
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _nextLine() {
    if (_lines.isEmpty) return;

    // If looping a stanza, check if we're at the last line of that stanza
    if (_loopStanzaIndex >= 0) {
      final currentStanza = _lines[_currentLineIndex].stanzaIndex;
      if (currentStanza == _loopStanzaIndex) {
        // Are we at the last line of this stanza?
        final isLastInStanza = _currentLineIndex == _lines.length - 1 ||
            _lines[_currentLineIndex + 1].stanzaIndex != _loopStanzaIndex;
        if (isLastInStanza) {
          // Wrap to first line of loop stanza
          final firstLineOfStanza =
              _lines.indexWhere((l) => l.stanzaIndex == _loopStanzaIndex);
          if (firstLineOfStanza >= 0) {
            setState(() => _currentLineIndex = firstLineOfStanza);
            _persistProgress(completed: false);
            return;
          }
        }
      }
    }

    if (_currentLineIndex < _lines.length - 1) {
      setState(() => _currentLineIndex++);
      _persistProgress(completed: false);
    } else {
      // Reached the very last line
      _persistProgress(completed: true);
    }
  }

  void _prevLine() {
    if (_currentLineIndex > 0) {
      setState(() => _currentLineIndex--);
      _persistProgress(completed: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Follow mode
  // ---------------------------------------------------------------------------

  void _startFollow() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: (2500 / _speed).round()),
      (_) {
        if (!_isPlaying) {
          _timer?.cancel();
          return;
        }
        _nextLine();
        _scrollToCurrentLine();
      },
    );
  }

  void _stopFollow() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _stopFollow();
    } else {
      setState(() => _isPlaying = true);
      _startFollow();
    }
  }

  // ---------------------------------------------------------------------------
  // Scroll
  // ---------------------------------------------------------------------------

  void _scrollToCurrentLine() {
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

  // ---------------------------------------------------------------------------
  // Progress persistence
  // ---------------------------------------------------------------------------

  void _persistProgress({required bool completed}) {
    final provider = context.read<PracticeProvider>();
    final currentStanza = _lines.isEmpty ? 0 : _lines[_currentLineIndex].stanzaIndex;
    provider.saveProgress(
      _kalaam.id,
      PracticeProgress(
        lastLine: _currentLineIndex,
        lastStanza: currentStanza,
        completed: completed,
        mode: _mode.name,
        loopStanza: _loopStanzaIndex,
      ),
    );
  }

  void _saveFinalProgress() {
    final provider = context.read<PracticeProvider>();
    final currentStanza = _lines.isEmpty ? 0 : _lines[_currentLineIndex].stanzaIndex;
    provider.saveProgress(
      _kalaam.id,
      PracticeProgress(
        lastLine: _currentLineIndex,
        lastStanza: currentStanza,
        completed: _currentLineIndex == _lines.length - 1,
        mode: _mode.name,
        loopStanza: _loopStanzaIndex,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stanza jumper
  // ---------------------------------------------------------------------------

  void _jumpToStanza(int stanzaIndex) {
    final lineIndex = _lines.indexWhere((l) => l.stanzaIndex == stanzaIndex);
    if (lineIndex < 0) return;
    setState(() => _currentLineIndex = lineIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine());
    if (_isPlaying) {
      _timer?.cancel();
      _startFollow();
    }
  }

  void _openStanzaJumper() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _kalaam.content.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (_, i) {
                final stanza = _kalaam.content[i];
                final isLooping = _loopStanzaIndex == i;
                return ListTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    _jumpToStanza(i);
                  },
                  title: Text(
                    'Stanza ${stanza.stanzaNumber}',
                    style: const TextStyle(
                      color: Color(0xFFe2b96f),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    stanza.preview,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: isLooping ? 'Clear loop' : 'Loop this stanza',
                    icon: Icon(
                      Icons.loop,
                      color: isLooping
                          ? const Color(0xFFe2b96f)
                          : Colors.white38,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _loopStanzaIndex = isLooping ? -1 : i;
                      });
                      setSheetState(() {});
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Line rendering
  // ---------------------------------------------------------------------------

  Widget _buildLine(int i) {
    final item = _lines[i];
    final isCurrent = i == _currentLineIndex;

    if (isCurrent && _memorizationMode && _hideLevel > 0) {
      final words = item.text.trim().split(RegExp(r'\s+'));
      return Container(
        key: _lineKeys[i],
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: words.asMap().entries.map((e) {
                final wi = e.key;
                final word = e.value;

                bool hidden;
                switch (_hideLevel) {
                  case 1:
                    hidden = wi == words.length - 1;
                    break;
                  case 2:
                    hidden = wi % 2 == 1; // odd indices
                    break;
                  case 3:
                    hidden = wi != 0; // all but first
                    break;
                  default:
                    hidden = false;
                }

                final display = hidden ? '█' * word.length : word;
                return TextSpan(
                  text: wi < words.length - 1 ? '$display ' : display,
                  style: TextStyle(
                    color: hidden ? Colors.white24 : const Color(0xFFe2b96f),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return Container(
      key: _lineKeys[i],
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        item.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isCurrent ? const Color(0xFFe2b96f) : Colors.white54,
          fontSize: isCurrent ? 20 : 17,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          height: 1.6,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom controls
  // ---------------------------------------------------------------------------

  Widget _buildSoloControls() {
    final total = _lines.length;
    final current = _currentLineIndex + 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xEE0f0f1a), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentLineIndex > 0 ? _prevLine : null,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: _currentLineIndex > 0
                  ? const Color(0xFFe2b96f)
                  : const Color(0xFFe2b96f).withValues(alpha: 0.3),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFe2b96f).withValues(alpha: 0.3)),
            ),
            child: Text(
              '$current / $total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentLineIndex < _lines.length - 1 ? _nextLine : null,
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _currentLineIndex < _lines.length - 1
                  ? const Color(0xFFe2b96f)
                  : const Color(0xFFe2b96f).withValues(alpha: 0.3),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xEE0f0f1a), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause FAB
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFe2b96f),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFe2b96f).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Speed slider
          Row(
            children: [
              const Text(
                'Speed',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFe2b96f),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: const Color(0xFFe2b96f),
                    overlayColor: const Color(0x29e2b96f),
                  ),
                  child: Slider(
                    value: _speed,
                    min: 0.5,
                    max: 3.0,
                    onChanged: (val) {
                      setState(() => _speed = val);
                      if (_isPlaying) {
                        _timer?.cancel();
                        _startFollow();
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '${_speed.toStringAsFixed(1)}x',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFe2b96f),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListenControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xEE0f0f1a), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.graphic_eq,
            color: const Color(0xFFe2b96f).withValues(alpha: 0.4),
            size: 48,
          ),
          const SizedBox(height: 10),
          const Text(
            'Audio coming soon',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        _timer?.cancel();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        _saveFinalProgress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0f0f1a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1a2e),
          foregroundColor: Colors.white,
          title: Text(
            _kalaam.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          actions: [
            // Mode chip
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFe2b96f).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFe2b96f).withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _modeLabel(_mode),
                style: const TextStyle(
                  color: Color(0xFFe2b96f),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Memorization toggle
            IconButton(
              tooltip: 'Memorization mode',
              icon: Icon(
                _memorizationMode ? Icons.visibility_off : Icons.psychology_outlined,
                color: _memorizationMode
                    ? const Color(0xFFe2b96f)
                    : Colors.white54,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  if (_memorizationMode) {
                    _memorizationMode = false;
                    _hideLevel = 0;
                  } else {
                    _memorizationMode = true;
                    _hideLevel = 1;
                  }
                });
              },
            ),
            // Hide level cycle (only when memorization is on)
            if (_memorizationMode)
              IconButton(
                tooltip: 'Hide level (${_hideLevel})',
                icon: Text(
                  'L$_hideLevel',
                  style: const TextStyle(
                    color: Color(0xFFe2b96f),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _hideLevel = (_hideLevel % 3) + 1;
                  });
                },
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            // --------------- Main scrollable content ---------------
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              itemCount: _lines.length,
              itemBuilder: (_, i) => _buildLine(i),
            ),

            // --------------- Top title gradient overlay ---------------
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 12, bottom: 20, left: 24, right: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC0f0f1a), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _kalaam.title,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFe2b96f),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --------------- Bottom controls overlay ---------------
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _mode == _PracticeMode.solo
                  ? _buildSoloControls()
                  : _mode == _PracticeMode.follow
                      ? _buildFollowControls()
                      : _buildListenControls(),
            ),

            // --------------- Loop chip (top-right) ---------------
            if (_loopStanzaIndex >= 0)
              Positioned(
                top: 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => setState(() => _loopStanzaIndex = -1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFe2b96f).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFe2b96f).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.loop,
                            color: Color(0xFFe2b96f), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Loop: Stanza ${_loopStanzaIndex + 1}',
                          style: const TextStyle(
                            color: Color(0xFFe2b96f),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close,
                            color: Color(0xFFe2b96f), size: 12),
                      ],
                    ),
                  ),
                ),
              ),

            // --------------- Stanza jumper mini FAB ---------------
            Positioned(
              bottom: _mode == _PracticeMode.solo ? 100 : 160,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: _openStanzaJumper,
                backgroundColor: const Color(0xFF1a1a2e),
                foregroundColor: const Color(0xFFe2b96f),
                child: const Icon(Icons.format_list_bulleted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
