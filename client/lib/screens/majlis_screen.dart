import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/kalaam_model.dart';

class _LineItem {
  final int stanzaIndex;
  final int lineIndex;
  final String text;
  _LineItem({required this.stanzaIndex, required this.lineIndex, required this.text});
}

class MajlisScreen extends StatefulWidget {
  const MajlisScreen({super.key});
  @override
  State<MajlisScreen> createState() => _MajlisScreenState();
}

class _MajlisScreenState extends State<MajlisScreen> {
  late final KalaamModel _kalaam;
  late final List<_LineItem> _lines;
  late final List<GlobalKey> _lineKeys;

  // Word position maps
  late final List<int> _lineWordStarts; // global word index at start of each line
  late final List<int> _lineWordCounts; // word count per line
  int _totalWords = 0;

  final ScrollController _scrollController = ScrollController();

  // Manual playback
  int _currentLineIndex = 0;
  bool _isPlaying = false;
  double _speed = 1.0;
  bool _controlsVisible = true;
  Timer? _scrollTimer;
  Timer? _hideControlsTimer;

  // Voice mode
  final SpeechToText _speech = SpeechToText();
  bool _voiceAvailable = false;
  bool _voiceMode = false;
  bool _isListening = false;
  int _sessionWordOffset = 0;
  int _currentWordGlobal = 0;
  int _currentWordInLine = 0;
  double _soundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kalaam = ModalRoute.of(context)!.settings.arguments as KalaamModel;
    _lines = _buildLines(_kalaam);
    _lineKeys = List.generate(_lines.length, (_) => GlobalKey());
    _buildWordMaps();
    _initVoice();
  }

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

  void _buildWordMaps() {
    _lineWordStarts = [];
    _lineWordCounts = [];
    int total = 0;
    for (final line in _lines) {
      _lineWordStarts.add(total);
      final count = line.text.trim().isEmpty
          ? 0
          : line.text.trim().split(RegExp(r'\s+')).length;
      _lineWordCounts.add(count);
      total += count;
    }
    _totalWords = total;
  }

  Future<void> _initVoice() async {
    _voiceAvailable = await _speech.initialize(
      onError: (e) => debugPrint('STT error: $e'),
      onStatus: (s) {
        if (s == 'done' && _isListening && _voiceMode) {
          _restartListening();
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() {
    if (!_voiceAvailable) return;
    setState(() => _isListening = true);
    _speech.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      partialResults: true,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
    );
  }

  void _restartListening() {
    if (!_voiceMode || !mounted) return;
    _speech.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      partialResults: true,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim().isEmpty
        ? 0
        : result.recognizedWords.trim().split(RegExp(r'\s+')).length;

    final globalWord = (_sessionWordOffset + words).clamp(0, _totalWords - 1) as int;

    if (result.finalResult) {
      _sessionWordOffset = (_sessionWordOffset + words).clamp(0, _totalWords) as int;
    }

    if (mounted) {
      setState(() => _currentWordGlobal = globalWord);
      _updatePositionFromWordCount(globalWord);
    }
  }

  void _updatePositionFromWordCount(int globalWord) {
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (_lineWordStarts[i] <= globalWord) {
        final wordInLine = (globalWord - _lineWordStarts[i])
            .clamp(0, (_lineWordCounts[i] - 1).clamp(0, 999));

        if (i != _currentLineIndex) {
          setState(() {
            _currentLineIndex = i;
            _currentWordInLine = wordInLine;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine());
        } else {
          setState(() => _currentWordInLine = wordInLine);
        }
        break;
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
  }

  void _toggleVoiceMode() {
    setState(() => _voiceMode = !_voiceMode);
    if (_voiceMode) {
      // Reset word tracking
      _sessionWordOffset = 0;
      _currentWordGlobal = 0;
      _currentWordInLine = 0;
      // Pause manual playback
      _pausePlaying();
      _startListening();
    } else {
      _stopListening();
    }
  }

  int get _msPerLine => (2500 / _speed).round();

  void _startPlaying() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(Duration(milliseconds: _msPerLine), (_) {
      if (_currentLineIndex < _lines.length - 1) {
        setState(() => _currentLineIndex++);
        _scrollToCurrentLine();
      } else {
        _pausePlaying();
      }
    });
  }

  void _pausePlaying() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    setState(() {
      _isPlaying = false;
      _controlsVisible = true;
    });
    _hideControlsTimer?.cancel();
  }

  void _togglePlayPause() {
    if (_voiceMode) return; // voice mode drives playback
    if (_isPlaying) {
      _pausePlaying();
    } else {
      setState(() {
        _isPlaying = true;
        _controlsVisible = true;
      });
      _startPlaying();
      _scheduleHideControls();
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (_isPlaying && mounted) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _onTapContent() {
    if (_voiceMode) return;
    if (_isPlaying) {
      _pausePlaying();
    } else {
      setState(() => _controlsVisible = true);
    }
  }

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

  void _jumpToStanza(int stanzaIndex) {
    final lineIndex = _lines.indexWhere((l) => l.stanzaIndex == stanzaIndex);
    if (lineIndex < 0) return;
    setState(() {
      _currentLineIndex = lineIndex;
      _currentWordInLine = 0;
      // Reset voice word offset to match new position
      if (_voiceMode) {
        _sessionWordOffset = _lineWordStarts[lineIndex];
        _currentWordGlobal = _lineWordStarts[lineIndex];
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine());
    if (_isPlaying) {
      _scrollTimer?.cancel();
      _startPlaying();
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
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _kalaam.content.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
          itemBuilder: (_, i) {
            final stanza = _kalaam.content[i];
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
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _hideControlsTimer?.cancel();
    _scrollController.dispose();
    if (_isListening) _speech.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Widget _buildLine(int i) {
    final item = _lines[i];
    final isCurrent = i == _currentLineIndex;

    if (isCurrent && _voiceMode) {
      // Word-level highlighting
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
                final isCurrentWord = wi == _currentWordInLine;
                return TextSpan(
                  text: wi < words.length - 1 ? '$word ' : word,
                  style: TextStyle(
                    color: isCurrentWord
                        ? Colors.black
                        : const Color(0xFFe2b96f),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                    background: isCurrentWord
                        ? (Paint()..color = const Color(0xFFe2b96f))
                        : null,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a14),
        body: Stack(
          children: [
            // Main scrollable content
            GestureDetector(
              onTap: _onTapContent,
              behavior: HitTestBehavior.opaque,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                itemCount: _lines.length,
                itemBuilder: (_, i) => _buildLine(i),
              ),
            ),

            // Title overlay (top)
            Positioned(
              top: 0, left: 0, right: 0,
              child: AnimatedOpacity(
                opacity: _isPlaying ? 0.3 : 0.85,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.only(top: 48, bottom: 16, left: 24, right: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC0a0a14), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    _kalaam.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFe2b96f),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // Control bar (bottom)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xEE0a0a14), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Voice mode indicator
                        if (_voiceMode) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListening ? Icons.mic : Icons.mic_off,
                                color: _isListening
                                    ? const Color(0xFFe2b96f)
                                    : Colors.white38,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              // Sound level bar
                              SizedBox(
                                width: 100,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: ((_soundLevel + 50) / 50).clamp(0.0, 1.0),
                                    backgroundColor: Colors.white12,
                                    color: const Color(0xFFe2b96f),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Voice active',
                                  style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Play/Pause or Voice indicator
                        if (!_voiceMode)
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

                        const SizedBox(height: 12),

                        // Speed slider (only in manual mode)
                        if (!_voiceMode)
                          Row(
                            children: [
                              const Text('Speed',
                                  style: TextStyle(color: Colors.white54, fontSize: 13)),
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
                                    min: 0.3,
                                    max: 3.0,
                                    onChanged: (val) {
                                      setState(() => _speed = val);
                                      if (_isPlaying) {
                                        _scrollTimer?.cancel();
                                        _startPlaying();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${_speed.toStringAsFixed(1)}x',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: Color(0xFFe2b96f),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                        // Voice toggle button
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _voiceAvailable ? _toggleVoiceMode : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _voiceMode
                                  ? const Color(0xFFe2b96f).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _voiceMode
                                    ? const Color(0xFFe2b96f).withValues(alpha: 0.5)
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _voiceMode ? Icons.mic : Icons.mic_none,
                                  size: 16,
                                  color: _voiceMode
                                      ? const Color(0xFFe2b96f)
                                      : (_voiceAvailable ? Colors.white54 : Colors.white24),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _voiceMode
                                      ? 'Voice On — tap to disable'
                                      : (_voiceAvailable
                                          ? 'Follow my voice'
                                          : 'Mic unavailable'),
                                  style: TextStyle(
                                    color: _voiceMode
                                        ? const Color(0xFFe2b96f)
                                        : (_voiceAvailable ? Colors.white54 : Colors.white24),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stanza jumper FAB
            Positioned(
              bottom: 140,
              right: 20,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _openStanzaJumper,
                    backgroundColor: const Color(0xFF1a1a2e),
                    foregroundColor: const Color(0xFFe2b96f),
                    child: const Icon(Icons.format_list_bulleted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
