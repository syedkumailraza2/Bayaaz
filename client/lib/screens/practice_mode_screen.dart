import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../models/kalaam_model.dart';
import '../providers/listen_session_provider.dart';
import '../providers/practice_provider.dart';
import '../services/reference_audio_service.dart';
import '../services/socket_service.dart';

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

  // ── Visual animation state ────────────────────────────────────────────────
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final AnimationController _heroEntryController;
  late final AnimationController _glyphEntryController;
  late final AnimationController _diamondSpinController;

  // ── Audio playback state ─────────────────────────────────────────────────
  AudioPlayer? _audioPlayer;
  bool _hasAudio = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  double _sheetSize = 0.62;

  // ── Follow-my-voice STT state (mode == 'follow') ─────────────────────────
  // Same protocol as the group teleprompter: AudioRecorder pushes 16 kHz
  // mono PCM frames to the server over socket.io. The server runs Vosk and
  // emits `voice:soloStanzaChanged` back to this socket as the matcher
  // confidently advances the cursor.
  AudioRecorder? _voiceRecorder;
  bool _voiceAvailable = false;
  bool _voiceMode = false;
  bool _isStreaming = false;
  bool _voiceInitAttempted = false;
  StreamSubscription<Uint8List>? _pcmSub;
  StreamSubscription<Amplitude>? _ampSub;
  final ValueNotifier<double> _soundLevel = ValueNotifier<double>(0.0);
  static const int _voiceSampleRate = 16000;

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
    _loadReferenceAudio();
    if (_mode == 'follow') _initVoice();

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

  Future<void> _loadReferenceAudio() async {
    // 1. Prefer the locally-cached file (zero latency).
    var ref = await ReferenceAudioService.instance.getReference(_kalaam.id);
    var file = ref != null ? File(ref.localWavPath) : null;

    // 2. If the device hasn't seen this kalaam before but the server has a
    //    reference attached, pull it down into the cache and try again. This
    //    is what makes follow-voice work on a second device — without this
    //    step the timeline would never appear because the reference only
    //    existed on the uploader's device.
    final serverMedia = _kalaam.referenceAudio;
    if ((file == null || !await file.exists()) && serverMedia != null) {
      final ok = await ReferenceAudioService.instance.ensureLocalCopy(
        kalaamId: _kalaam.id,
        media: serverMedia,
      );
      if (!ok || !mounted) return;
      ref = await ReferenceAudioService.instance.getReference(_kalaam.id);
      file = ref != null ? File(ref.localWavPath) : null;
    }

    if (ref == null || file == null || !await file.exists()) {
      debugPrint('[ref-audio] no playable file for kalaam ${_kalaam.id}');
      return;
    }

    final player = AudioPlayer();
    try {
      await player.setSource(DeviceFileSource(file.path));
    } catch (e) {
      // Silent failures here were the symptom behind the audio-upload bug —
      // a wrongly-named file path made the native decoder reject the source
      // and the timeline never appeared. Log so future regressions surface.
      debugPrint('[ref-audio] setSource failed for ${file.path}: $e');
      await player.dispose();
      return;
    }
    if (!mounted) {
      await player.dispose();
      return;
    }

    player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _audioPosition = pos);
    });
    player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _audioDuration = dur);
    });
    player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    setState(() {
      _audioPlayer = player;
      _hasAudio = true;
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
    _sheetScrollController.dispose();
    _audioPlayer?.dispose();
    if (_voiceMode || _isStreaming) {
      _voiceMode = false;
      SocketService().emitVoiceEnd();
      _voiceRecorder?.stop().catchError((_) => null);
    }
    _pcmSub?.cancel();
    _ampSub?.cancel();
    _voiceRecorder?.dispose();
    SocketService().off('voice:soloStanzaChanged');
    SocketService().off('voice:ready');
    SocketService().off('voice:error');
    _soundLevel.dispose();
    _saveFinalProgress();
    super.dispose();
  }

  // ── Follow-my-voice control ─────────────────────────────────────────────

  Future<void> _initVoice() async {
    if (_voiceInitAttempted) return;
    _voiceInitAttempted = true;
    try {
      _voiceRecorder = AudioRecorder();
      _voiceAvailable = await _voiceRecorder!.hasPermission();
    } catch (e) {
      debugPrint('[follow-voice] recorder init failed: $e');
      _voiceAvailable = false;
    }
    // Make sure the socket is connected before we register listeners — the
    // group teleprompter relies on existing session traffic to keep it open,
    // but solo practice has no such guarantee.
    try {
      await SocketService().connect();
    } catch (e) {
      debugPrint('[follow-voice] socket connect failed: $e');
    }
    SocketService().on('voice:ready', (_) {
      debugPrint('[follow-voice] bridge ready');
    });
    SocketService().on('voice:error', (data) {
      debugPrint('[follow-voice] bridge error: $data');
    });
    SocketService().on('voice:soloStanzaChanged', _onSoloStanzaChanged);
    if (mounted) setState(() {});
  }

  void _onSoloStanzaChanged(dynamic data) {
    if (data is! Map) return;
    final stanza = _asInt(data['stanza']);
    final line = _asInt(data['line']);
    if (stanza == null || line == null) return;
    final flat = _lines.indexWhere(
      (l) => l.stanzaIndex == stanza && l.lineIndex == line,
    );
    if (flat < 0) return;
    if (_currentLineIndex == flat) return;
    if (!mounted) return;
    setState(() => _currentLineIndex = flat);
    _persistProgress(completed: false);
    _scrollToCurrentLine();
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> _toggleVoiceFollow() async {
    if (!_voiceAvailable) {
      // Permission was previously denied — re-request so the user can
      // approve from a settings detour without restarting the screen.
      try {
        _voiceAvailable = await (_voiceRecorder?.hasPermission() ??
            Future.value(false));
      } catch (_) {
        _voiceAvailable = false;
      }
      if (!_voiceAvailable) return;
    }
    if (_voiceMode) {
      await _stopVoiceFollow();
    } else {
      setState(() => _voiceMode = true);
      await _startVoiceFollow();
    }
  }

  Future<void> _startVoiceFollow() async {
    final recorder = _voiceRecorder;
    if (recorder == null) return;
    final socket = SocketService();
    socket.emitVoiceSoloStart(_kalaam.id);
    try {
      _ampSub?.cancel();
      _ampSub = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 150))
          .listen((amp) {
        final v = ((amp.current + 50) / 50).clamp(0.0, 1.0);
        _soundLevel.value = v;
      });

      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _voiceSampleRate,
          numChannels: 1,
        ),
      );
      _isStreaming = true;
      if (mounted) setState(() {});

      _pcmSub = stream.listen(
        (frame) => socket.emitVoiceFrame(frame),
        onError: (e) => debugPrint('[follow-voice] pcm stream error: $e'),
        onDone: () => debugPrint('[follow-voice] pcm stream done'),
      );
    } catch (e) {
      debugPrint('[follow-voice] start failed: $e');
      _voiceMode = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _stopVoiceFollow() async {
    _voiceMode = false;
    try {
      if (await (_voiceRecorder?.isRecording() ?? Future.value(false))) {
        await _voiceRecorder!.stop();
      }
    } catch (_) {}
    await _pcmSub?.cancel();
    _pcmSub = null;
    _ampSub?.cancel();
    _ampSub = null;
    SocketService().emitVoiceEnd();
    _soundLevel.value = 0.0;
    if (mounted) setState(() => _isStreaming = false);
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
    if (_audioPlayer == null) return;
    if (_isPlaying) {
      _audioPlayer!.pause();
    } else {
      _audioPlayer!.resume();
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
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 200),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Bottom action bar + timeline ──────────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: media.padding.bottom + 12,
              child: _mode == 'listen'
                  ? _ListenBottomBar(kalaam: _kalaam)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasAudio) ...[
                          _TimelineBar(
                            position: _audioPosition,
                            duration: _audioDuration,
                            onSeek: (pos) => _audioPlayer?.seek(pos),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _BottomActionBar(
                          isPlaying: _isPlaying,
                          hasAudio: _hasAudio,
                          onBack: () => Navigator.of(context).maybePop(),
                          onPrev: _prevLine,
                          onNext: _nextLine,
                          onPlayPause: _togglePlayPause,
                        ),
                      ],
                    ),
            ),

            // ── Top "AppBar" overlay (Follow mode) ────────────────────────
            // Floats over the teal hero so the existing layout doesn't
            // collapse. Hosts the back button + voice-follow mic toggle.
            if (_mode == 'follow')
              Positioned(
                top: media.padding.top + 4,
                left: 4,
                right: 4,
                child: _FollowVoiceAppBar(
                  voiceAvailable: _voiceAvailable,
                  voiceMode: _voiceMode,
                  isStreaming: _isStreaming,
                  soundLevel: _soundLevel,
                  onBack: () => Navigator.of(context).maybePop(),
                  onToggleVoice: _toggleVoiceFollow,
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
// Timeline bar (attached to bottom nav)
// ───────────────────────────────────────────────────────────────────────────

class _TimelineBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _TimelineBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: _kTeal,
              inactiveTrackColor: _kWaveInactive,
              thumbColor: _kOrange,
            ),
            child: Slider(
              value: progress.toDouble(),
              onChanged: (v) => onSeek(
                Duration(
                    milliseconds:
                        (v * duration.inMilliseconds).round()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(position),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kInkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _fmt(duration),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kInkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ───────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final bool isPlaying;
  final bool hasAudio;
  final VoidCallback onBack;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;

  const _BottomActionBar({
    required this.isPlaying,
    required this.hasAudio,
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
                  onTap: hasAudio ? onPlayPause : null,
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
                          !hasAudio
                              ? Icons.music_note_rounded
                              : isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          key: ValueKey(!hasAudio
                              ? 'no_audio'
                              : isPlaying
                                  ? 'pause'
                                  : 'play'),
                          color: hasAudio
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
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

// ───────────────────────────────────────────────────────────────────────────
// Listen mode bottom bar
// ───────────────────────────────────────────────────────────────────────────

class _ListenBottomBar extends StatefulWidget {
  final KalaamModel kalaam;
  const _ListenBottomBar({required this.kalaam});

  @override
  State<_ListenBottomBar> createState() => _ListenBottomBarState();
}

class _ListenBottomBarState extends State<_ListenBottomBar> {
  bool _navigating = false;

  Future<void> _onMicTap(ListenSessionProvider provider) async {
    if (provider.state == ListenSessionState.idle ||
        provider.state == ListenSessionState.error) {
      await provider.startListening(widget.kalaam);
    } else if (provider.state == ListenSessionState.recording) {
      await provider.stopAndScore();
    }
  }

  Future<void> _onDoneTap(ListenSessionProvider provider) async {
    if (provider.state == ListenSessionState.recording) {
      await provider.stopAndScore();
    } else if (provider.state == ListenSessionState.scored) {
      _navigateToResults(provider);
    }
  }

  void _navigateToResults(ListenSessionProvider provider) {
    if (_navigating) return;
    _navigating = true;
    Navigator.pushNamed(
      context,
      '/practice-results',
      arguments: {
        'score': provider.latestScore,
        'kalaam': widget.kalaam,
        'feedback': provider.latestFeedback,
      },
    ).then((_) {
      if (mounted) {
        setState(() => _navigating = false);
        provider.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListenSessionProvider>();
    final state = provider.state;

    // Auto-navigate when scoring completes.
    if (state == ListenSessionState.scored && !_navigating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigateToResults(provider);
      });
    }

    final isRecording = state == ListenSessionState.recording;
    final isProcessing = state == ListenSessionState.processing;
    final doneEnabled = isRecording || state == ListenSessionState.scored;

    return Row(
      children: [
        // Back
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            height: 44,
            width: 72,
            decoration: BoxDecoration(
              color: _kSurfaceMuted,
              borderRadius: BorderRadius.circular(40),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 16, color: _kInkPrimary),
                SizedBox(width: 4),
                Text('Back',
                    style: TextStyle(
                        fontSize: 13,
                        color: _kInkPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Mic / Stop / Spinner
        Expanded(
          child: GestureDetector(
            onTap: isProcessing ? null : () => _onMicTap(provider),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isRecording ? const Color(0xFFDC2626) : _kTeal,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? const Color(0xFFDC2626) : _kTeal)
                        .withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: isProcessing
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        key: ValueKey(isRecording ? 'stop' : 'mic'),
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Done
        GestureDetector(
          onTap: doneEnabled && !isProcessing ? () => _onDoneTap(provider) : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: doneEnabled ? 1.0 : 0.35,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Follow-my-voice AppBar overlay (mode == 'follow')
// ───────────────────────────────────────────────────────────────────────────

/// Floating "AppBar" rendered over the teal hero. The hero already provides
/// the background colour, so we draw transparent icon buttons on top instead
/// of stacking a real Material AppBar (which would push the hero down).
class _FollowVoiceAppBar extends StatelessWidget {
  final bool voiceAvailable;
  final bool voiceMode;
  final bool isStreaming;
  final ValueNotifier<double> soundLevel;
  final VoidCallback onBack;
  final VoidCallback onToggleVoice;

  const _FollowVoiceAppBar({
    required this.voiceAvailable,
    required this.voiceMode,
    required this.isStreaming,
    required this.soundLevel,
    required this.onBack,
    required this.onToggleVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const Spacer(),
          if (voiceMode && isStreaming)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 60,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: ValueListenableBuilder<double>(
                    valueListenable: soundLevel,
                    builder: (_, level, _) => LinearProgressIndicator(
                      value: level,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          _kOrange),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: voiceMode
                ? 'Stop voice follow'
                : voiceAvailable
                    ? 'Start voice follow'
                    : 'Microphone unavailable',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                voiceMode ? Icons.mic_rounded : Icons.mic_none_outlined,
                key: ValueKey(voiceMode),
                color: voiceMode
                    ? _kOrange
                    : Colors.white.withValues(alpha: voiceAvailable ? 0.9 : 0.4),
                size: 24,
              ),
            ),
            onPressed: voiceAvailable ? onToggleVoice : null,
          ),
        ],
      ),
    );
  }
}
