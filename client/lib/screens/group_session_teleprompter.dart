import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../models/kalaam_model.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

// ─── Brand tokens ─────────────────────────────────────────────────────────────
const _kTeal = Color(0xFF234547);
const _kOrange = Color(0xFFFDA43F);
const _kOrangeGrad2 = Color(0xFFFDBA55);

class _Palette {
  final bool isDark;
  const _Palette._(this.isDark);
  factory _Palette.of(BuildContext c) =>
      _Palette._(Theme.of(c).brightness == Brightness.dark);

  Color get pageBg => isDark ? const Color(0xFF0A0A0A) : Colors.white;
  Color get cardBg => isDark ? const Color(0xFF161616) : Colors.white;
  Color get surfaceMuted =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
  Color get textPrimary => isDark ? Colors.white : Colors.black;
  Color get textSecondary =>
      isDark ? const Color(0xFFCFCFCF) : const Color(0xFF545454);
  Color get textMuted => const Color(0xFFA0A0A0);

  // Teleprompter-specific
  Color get lineDim => isDark
      ? Colors.white.withValues(alpha: 0.28)
      : Colors.black.withValues(alpha: 0.38);
  Color get separatorDot => isDark
      ? Colors.white.withValues(alpha: 0.18)
      : Colors.black.withValues(alpha: 0.12);
  Color get bottomBarBg =>
      isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
  Color get bottomBarBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.07);
  Color get overlayGradientOpaque => isDark
      ? const Color(0xDD0A0A0A)
      : Colors.white.withValues(alpha: 0.87);
}

/// Line-by-line teleprompter for an in-progress group session.
///
/// Host: single-tap any line to highlight + broadcast it (`host:setStanza`).
/// Host can also enable Voice Follow (mic button in AppBar) — the recorder
/// streams raw 16-bit PCM over the socket to the Vosk bridge, which runs
/// the fuzzy matcher on each partial/final transcript and broadcasts
/// `session:stanzaChanged` to the whole room.
/// "Done — Next" in the bottom bar pops the next kalaam off the sorted queue.
/// Members: read-only. The current line follows whatever the host emits.
class GroupSessionTeleprompter extends StatefulWidget {
  const GroupSessionTeleprompter({super.key});

  @override
  State<GroupSessionTeleprompter> createState() =>
      _GroupSessionTeleprompterState();
}

class _GroupSessionTeleprompterState extends State<GroupSessionTeleprompter> {
  late final ScrollController _scroll = ScrollController();
  final ValueNotifier<int> _currentLine = ValueNotifier<int>(0);

  String? _sessionId;
  String? _lastKalamId;
  KalaamModel? _kalaam;
  List<_FlatLine> _lines = const [];
  List<GlobalKey> _lineKeys = const [];
  bool _fetchingKalam = false;
  bool _initialized = false;
  bool _adoptScheduled = false;

  // ── Voice follow (host only) ─────────────────────────────────────────────
  AudioRecorder? _recorder;
  bool _voiceAvailable = false;
  bool _voiceMode = false;
  bool _isStreaming = false;
  bool _voiceInitAttempted = false;
  StreamSubscription<Uint8List>? _pcmSub;
  StreamSubscription<Amplitude>? _ampSub;
  final ValueNotifier<double> _soundLevel = ValueNotifier<double>(0.0);

  static const _sampleRate = 16000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is SessionModel) {
        _sessionId = arg.id;
      } else if (arg is Map && arg['sessionId'] is String) {
        _sessionId = arg['sessionId'] as String;
      }
      final sid = _sessionId;
      if (sid != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<SessionProvider>().loadSession(sid);
          context.read<SessionProvider>().loadSuggestions(sid);
          _initVoiceIfHost();
        });
      }
    }
    _syncFromSession();
  }

  Future<void> _initVoiceIfHost() async {
    if (_voiceInitAttempted) return;
    final auth = context.read<AuthProvider>();
    final session = context.read<SessionProvider>().session;
    final isHost = session?.hostId == auth.user?.id;
    if (!isHost) return;
    _voiceInitAttempted = true;
    try {
      _recorder = AudioRecorder();
      _voiceAvailable = await _recorder!.hasPermission();
    } catch (e) {
      debugPrint('Recorder init failed: $e');
      _voiceAvailable = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_voiceMode || _isStreaming) {
      _voiceMode = false;
      SocketService().emitVoiceEnd();
      _recorder?.stop().catchError((_) => null);
    }
    _pcmSub?.cancel();
    _ampSub?.cancel();
    _recorder?.dispose();
    if (_sessionId != null) {
      SocketService().leaveSession(_sessionId!);
      for (final event in [
        'session:joined',
        'session:kalamChanged',
        'session:stanzaChanged',
        'session:playStateChanged',
        'session:queueUpdated',
        'session:newSuggestion',
        'session:suggestionHandled',
        'session:ended',
        'voice:ready',
        'voice:error',
      ]) {
        SocketService().off(event);
      }
    }
    _scroll.dispose();
    _currentLine.dispose();
    _soundLevel.dispose();
    super.dispose();
  }

  void _syncFromSession() {
    final session = context.read<SessionProvider>().session;
    if (session == null) return;

    if (!_voiceInitAttempted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initVoiceIfHost();
      });
    }

    if (session.currentKalamId == null) {
      if (_kalaam != null || _lines.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _kalaam = null;
            _lines = const [];
            _lineKeys = const [];
            _lastKalamId = null;
          });
        });
      }
      _maybeSeedFromQueue(session);
      return;
    }

    if (session.currentKalamId != _lastKalamId ||
        _kalaam == null ||
        _kalaam!.content.isEmpty) {
      if (!_adoptScheduled) {
        _lastKalamId = session.currentKalamId;
        if (session.currentKalam != null &&
            session.currentKalam!.content.isNotEmpty) {
          final k = session.currentKalam!;
          _adoptScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _adoptScheduled = false;
            if (!mounted) return;
            _adoptKalam(k);
          });
        } else {
          _fetchKalamIfNeeded(session.id);
        }
      }
    }

    final flat = _flatLineIndex(session.currentStanza, session.currentLine);
    if (_currentLine.value != flat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _currentLine.value = flat;
        setState(() {});
        _scrollToCurrentLine();
      });
    }
  }

  bool _seedingFromQueue = false;
  Future<void> _maybeSeedFromQueue(dynamic session) async {
    if (_seedingFromQueue) return;
    final auth = context.read<AuthProvider>();
    if (session.hostId != auth.user?.id) return;
    final firstId = session.queueItems != null && session.queueItems.isNotEmpty
        ? session.queueItems.first.kalaamId
        : null;
    if (firstId == null) return;
    _seedingFromQueue = true;
    try {
      final socket = SocketService();
      if (socket.isConnected) {
        socket.emitSetKalam(session.id, firstId);
      } else if (mounted) {
        await context.read<SessionProvider>().setKalam(session.id, firstId);
      }
    } catch (_) {
    } finally {
      _seedingFromQueue = false;
    }
  }

  Future<void> _fetchKalamIfNeeded(String sessionId) async {
    if (_fetchingKalam) return;
    _fetchingKalam = true;
    try {
      final refreshed = await ApiService.getSession(sessionId);
      if (!mounted) return;
      if (refreshed.currentKalam != null) _adoptKalam(refreshed.currentKalam!);
    } catch (_) {
    } finally {
      _fetchingKalam = false;
    }
  }

  void _adoptKalam(KalaamModel kalaam) {
    _kalaam = kalaam;
    final flat = <_FlatLine>[];
    for (int si = 0; si < kalaam.content.length; si++) {
      final s = kalaam.content[si];
      for (int li = 0; li < s.lines.length; li++) {
        flat.add(_FlatLine(stanzaIndex: si, lineIndex: li, text: s.lines[li]));
      }
    }
    _lines = flat;
    _lineKeys = List.generate(flat.length, (_) => GlobalKey());
    setState(() {});
  }

  // ── Voice follow ──────────────────────────────────────────────────────────

  void _toggleVoiceMode() {
    if (!_voiceAvailable) return;
    setState(() => _voiceMode = !_voiceMode);
    if (_voiceMode) {
      _startStreaming();
    } else {
      _stopStreaming();
    }
  }

  Future<void> _startStreaming() async {
    final sid = _sessionId;
    if (sid == null || _recorder == null) return;

    final socket = SocketService();
    socket.on('voice:ready', (_) => debugPrint('[voice] bridge ready'));
    socket.on('voice:error', (data) => debugPrint('[voice] bridge error: $data'));

    socket.emitVoiceStart(sid);

    try {
      _ampSub?.cancel();
      _ampSub = _recorder!
          .onAmplitudeChanged(const Duration(milliseconds: 150))
          .listen((amp) {
        final v = ((amp.current + 50) / 50).clamp(0.0, 1.0);
        _soundLevel.value = v;
      });

      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      _isStreaming = true;
      if (mounted) setState(() {});

      _pcmSub = stream.listen(
        (frame) => socket.emitVoiceFrame(frame),
        onError: (e) => debugPrint('[voice] pcm stream error: $e'),
        onDone: () => debugPrint('[voice] pcm stream done'),
      );
    } catch (e) {
      debugPrint('[voice] start failed: $e');
      _voiceMode = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _stopStreaming() async {
    _voiceMode = false;
    try {
      if (await (_recorder?.isRecording() ?? Future.value(false))) {
        await _recorder!.stop();
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

  int _flatLineIndex(int stanza, int line) {
    if (_lines.isEmpty) return 0;
    for (int i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      if (l.stanzaIndex == stanza && l.lineIndex == line) return i;
    }
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].stanzaIndex == stanza) return i;
    }
    return 0;
  }

  void _scrollToCurrentLine() {
    final idx = _currentLine.value;
    if (idx < 0 || idx >= _lineKeys.length) return;
    final ctx = _lineKeys[idx].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 180),
      alignment: 0.4,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirmAndEndSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = _Palette.of(ctx);
        return AlertDialog(
          backgroundColor: palette.cardBg,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'End session?',
            style: TextStyle(
                color: palette.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Members will be returned to the group screen. The current queue will be saved.',
            style: TextStyle(
                color: palette.textSecondary, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text('Cancel', style: TextStyle(color: palette.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'End',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<SessionProvider>().endSession(sessionId);
    if (!mounted) return;
    if (ok) {
      nav.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not end session')),
      );
    }
  }

  void _hostJumpToLine(int flatIndex) {
    final sid = _sessionId;
    if (sid == null) return;
    if (flatIndex < 0 || flatIndex >= _lines.length) return;
    HapticFeedback.selectionClick();
    _currentLine.value = flatIndex;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToCurrentLine());
    final line = _lines[flatIndex];
    final socket = SocketService();
    if (socket.isConnected) {
      socket.emitSetStanza(sid, line.stanzaIndex, line.lineIndex);
    } else {
      context
          .read<SessionProvider>()
          .setStanza(sid, line.stanzaIndex, line.lineIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final session = sessionProvider.session;
    final auth = context.read<AuthProvider>();
    final isHost = session?.hostId == auth.user?.id;
    final palette = _Palette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBg,
      appBar: AppBar(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _kalaam?.title ?? 'Session',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isHost && _voiceAvailable)
            _VoiceMicButton(
              voiceMode: _voiceMode,
              linesEmpty: _lines.isEmpty,
              onTap: _toggleVoiceMode,
            ),
          if (isHost && (session != null || _sessionId != null))
            TextButton.icon(
              icon: const Icon(Icons.stop_circle_outlined,
                  color: Colors.redAccent, size: 18),
              label: const Text(
                'End',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              onPressed: () =>
                  _confirmAndEndSession(session?.id ?? _sessionId!),
            ),
        ],
      ),
      body: Stack(
        children: [
          _lines.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _kTeal,
                    strokeWidth: 2,
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                      vertical: 80, horizontal: 20),
                  cacheExtent: 2400,
                  itemCount: _lines.length,
                  itemBuilder: (_, i) {
                    final line = _lines[i];
                    final showSep = i > 0 &&
                        _lines[i - 1].stanzaIndex != line.stanzaIndex;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showSep)
                          _StanzaSeparator(dotColor: palette.separatorDot),
                        _GroupLineView(
                          lineKey: _lineKeys[i],
                          index: i,
                          text: line.text,
                          isCurrent: _currentLine.value == i,
                          dimColor: palette.lineDim,
                          onTap: isHost ? () => _hostJumpToLine(i) : null,
                        ),
                      ],
                    );
                  },
                ),
          // Top fade softens the list edge under the AppBar.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.pageBg, palette.pageBg.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          if (isHost && _voiceMode)
            _VoiceOverlay(
              isStreaming: _isStreaming,
              soundLevel: _soundLevel,
              overlayColor: palette.overlayGradientOpaque,
              isDark: palette.isDark,
            ),
        ],
      ),
      bottomNavigationBar: isHost && session != null
          ? _BottomBar(
              palette: palette,
              onAdvance: () => context
                  .read<SessionProvider>()
                  .advanceToNext(session.id),
            )
          : null,
    );
  }
}

// ─── Voice mic AppBar button ──────────────────────────────────────────────────

class _VoiceMicButton extends StatelessWidget {
  final bool voiceMode;
  final bool linesEmpty;
  final VoidCallback onTap;

  const _VoiceMicButton({
    required this.voiceMode,
    required this.linesEmpty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: voiceMode ? 'Stop voice follow' : 'Start voice follow',
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            voiceMode ? Icons.mic_rounded : Icons.mic_none_outlined,
            key: ValueKey(voiceMode),
            color: voiceMode
                ? _kOrange
                : Colors.white.withValues(alpha: 0.7),
            size: 22,
          ),
        ),
        onPressed: linesEmpty ? null : onTap,
      ),
    );
  }
}

// ─── Voice status overlay ─────────────────────────────────────────────────────

class _VoiceOverlay extends StatelessWidget {
  final bool isStreaming;
  final ValueNotifier<double> soundLevel;
  final Color overlayColor;
  final bool isDark;

  const _VoiceOverlay({
    required this.isStreaming,
    required this.soundLevel,
    required this.overlayColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.45);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [overlayColor, overlayColor.withValues(alpha: 0)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isStreaming ? Icons.mic_rounded : Icons.mic_off_rounded,
                color: isStreaming ? _kOrange : mutedColor,
                size: 15,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: ValueListenableBuilder<double>(
                    valueListenable: soundLevel,
                    builder: (_, level, _) => LinearProgressIndicator(
                      value: level,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.10),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_kOrange),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isStreaming ? 'Voice follow · listening' : 'Voice follow',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatefulWidget {
  final _Palette palette;
  final VoidCallback onAdvance;
  const _BottomBar({required this.palette, required this.onAdvance});

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: widget.palette.bottomBarBg,
          border: Border(
            top: BorderSide(color: widget.palette.bottomBarBorder),
          ),
        ),
        child: GestureDetector(
          onTap: widget.onAdvance,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_kOrange, _kOrangeGrad2],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Done — Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data + line widget ───────────────────────────────────────────────────────

class _StanzaSeparator extends StatelessWidget {
  final Color dotColor;
  const _StanzaSeparator({required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlatLine {
  final int stanzaIndex;
  final int lineIndex;
  final String text;
  const _FlatLine({
    required this.stanzaIndex,
    required this.lineIndex,
    required this.text,
  });
}

class _GroupLineView extends StatelessWidget {
  final GlobalKey lineKey;
  final int index;
  final String text;
  final bool isCurrent;
  final Color dimColor;
  final VoidCallback? onTap;

  const _GroupLineView({
    required this.lineKey,
    required this.index,
    required this.text,
    required this.isCurrent,
    required this.dimColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        key: lineKey,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.symmetric(
          vertical: isCurrent ? 14 : 10,
          horizontal: 12,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCurrent ? _kOrange : dimColor,
            fontSize: isCurrent ? 23 : 17,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
            height: 1.75,
            letterSpacing: isCurrent ? 0.2 : 0,
          ),
        ),
      ),
    );
  }
}
