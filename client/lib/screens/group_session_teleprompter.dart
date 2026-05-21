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
  State<GroupSessionTeleprompter> createState() => _GroupSessionTeleprompterState();
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
  bool _adoptScheduled = false; // dedupes postFrame _adoptKalam calls

  // ── Voice follow (host only) ────────────────────────────────────────────
  // Streams raw 16-bit PCM over the socket to the Vosk bridge. Vosk emits
  // partial+final transcripts in realtime; the server fuzzy-matches each
  // against the current kalaam and broadcasts the matched line.
  AudioRecorder? _recorder;
  bool _voiceAvailable = false;
  bool _voiceMode = false;
  bool _isStreaming = false;     // mic is open + frames are flowing
  bool _voiceInitAttempted = false;
  StreamSubscription<Uint8List>? _pcmSub;
  StreamSubscription<Amplitude>? _ampSub;
  final ValueNotifier<double> _soundLevel = ValueNotifier<double>(0.0);

  // PCM stream config — must match what the Vosk bridge / model expects.
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
    // Pick up the latest session every time a provider notify lands so we
    // can react to kalaam changes mid-session.
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
    // Stop streaming and tear down the recorder.
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

  /// Pulls the latest currentKalam from SessionProvider and rebuilds the
  /// flat-line cache only when the kalaam itself changes.
  ///
  /// Safe to call from `build()`: any state mutation (setState / notifier value
  /// changes / scroll) is deferred to a post-frame callback.
  void _syncFromSession() {
    final session = context.read<SessionProvider>().session;
    if (session == null) return;

    // Now that we know who the host is, try to initialize voice once.
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
      // Self-heal: if the host opened a session that has a queued kalaam
      // but no current cursor, pick the first queue item so members see
      // content. This recovers from sessions created before the server
      // started auto-seeding currentKalamId on session creation.
      _maybeSeedFromQueue(session);
      return;
    }

    if (session.currentKalamId != _lastKalamId ||
        _kalaam == null ||
        _kalaam!.content.isEmpty) {
      // Dedupe: between scheduling and running the postFrame callback, build()
      // can fire many times. Without this guard each rebuild queues another
      // _adoptKalam call and we'd pay the rebuild cost on every frame.
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

    // Compute the flat-line index for the host-broadcast (stanza, line).
    final flat = _flatLineIndex(session.currentStanza, session.currentLine);
    if (_currentLine.value != flat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _currentLine.value = flat;
        // ValueListenableBuilder rebuilds the per-row text styling, but if
        // anything in the tree is shielding the rebuild (RepaintBoundary +
        // GlobalKey'd Container around the listenable) the highlight can
        // visually stick. Calling setState forces the ListView itself to
        // rebuild its visible rows so the gold/normal style applies reliably.
        setState(() {});
        _scrollToCurrentLine();
      });
    }
  }

  bool _seedingFromQueue = false;
  Future<void> _maybeSeedFromQueue(dynamic session) async {
    if (_seedingFromQueue) return;
    final auth = context.read<AuthProvider>();
    if (session.hostId != auth.user?.id) return; // host only
    final firstId = session.queueItems != null && session.queueItems.isNotEmpty
        ? session.queueItems.first.kalaamId
        : null;
    if (firstId == null) return;
    _seedingFromQueue = true;
    try {
      // Prefer the realtime path; fall back to REST if socket dropped.
      final socket = SocketService();
      if (socket.isConnected) {
        socket.emitSetKalam(session.id, firstId);
      } else if (mounted) {
        await context.read<SessionProvider>().setKalam(session.id, firstId);
      }
    } catch (_) {
      // best-effort; keeps the spinner visible if it fails
    } finally {
      _seedingFromQueue = false;
    }
  }

  Future<void> _fetchKalamIfNeeded(String sessionId) async {
    if (_fetchingKalam) return;
    _fetchingKalam = true;
    try {
      // Re-fetching the session is the cheapest way to get the populated kalaam
      // since the server populates currentKalamId.content on GET /sessions/:id.
      final refreshed = await ApiService.getSession(sessionId);
      if (!mounted) return;
      if (refreshed.currentKalam != null) _adoptKalam(refreshed.currentKalam!);
    } catch (_) {
      // best-effort
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

  // ── Voice follow: PCM streaming over socket.io ─────────────────────────

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
    // Hook up one-shot listeners for bridge readiness/errors.
    socket.on('voice:ready', (_) {
      debugPrint('[voice] bridge ready');
    });
    socket.on('voice:error', (data) {
      debugPrint('[voice] bridge error: $data');
    });

    socket.emitVoiceStart(sid);

    try {
      _ampSub?.cancel();
      _ampSub = _recorder!
          .onAmplitudeChanged(const Duration(milliseconds: 150))
          .listen((amp) {
        // amp.current is dBFS (~-160 … 0). Map to a 0..1 bar.
        final v = ((amp.current + 50) / 50).clamp(0.0, 1.0);
        _soundLevel.value = v;
      });

      // Raw 16-bit little-endian mono PCM at 16 kHz — Vosk's native input
      // format. The recorder emits frames as they're captured (typically
      // every 20–60ms) so the bridge sees audio with near-zero buffering.
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
        (frame) {
          socket.emitVoiceFrame(frame);
        },
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
    // Fall back to first line of the stanza if exact line out of range.
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('End session?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Members will be returned to the group screen. The current queue will be saved.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
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

  /// Host taps a line → set current cursor and broadcast `host:setStanza`.
  /// Voice mode (if on) keeps running; the next chunk's match will resync
  /// the cursor automatically against the new (stanza,line) starting point.
  void _hostJumpToLine(int flatIndex) {
    final sid = _sessionId;
    if (sid == null) return;
    if (flatIndex < 0 || flatIndex >= _lines.length) return;
    HapticFeedback.selectionClick();
    _currentLine.value = flatIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine());
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
    // Sync on every rebuild so external session changes (e.g. kalamChanged)
    // are reflected.
    _syncFromSession();

    final sessionProvider = context.watch<SessionProvider>();
    final session = sessionProvider.session;
    final auth = context.read<AuthProvider>();
    final isHost = session?.hostId == auth.user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          _kalaam?.title ?? 'Teleprompter',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isHost && _voiceAvailable)
            IconButton(
              tooltip: _voiceMode ? 'Stop voice follow' : 'Start voice follow',
              icon: Icon(
                _voiceMode ? Icons.mic : Icons.mic_none_outlined,
                color: _voiceMode ? const Color(0xFFe2b96f) : Colors.white70,
                size: 20,
              ),
              onPressed: _lines.isEmpty ? null : _toggleVoiceMode,
            ),
          if (isHost && (session != null || _sessionId != null))
            TextButton.icon(
              icon: const Icon(
                Icons.stop_circle_outlined,
                color: Colors.redAccent,
                size: 18,
              ),
              label: const Text(
                'End',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              onPressed: () => _confirmAndEndSession(session?.id ?? _sessionId!),
            ),
        ],
      ),
      body: Stack(
        children: [
          _lines.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFe2b96f)),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding:
                      const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  cacheExtent: 2400,
                  itemCount: _lines.length,
                  itemBuilder: (_, i) => _GroupLineView(
                    lineKey: _lineKeys[i],
                    index: i,
                    text: _lines[i].text,
                    isCurrent: _currentLine.value == i,
                    onTap: isHost ? () => _hostJumpToLine(i) : null,
                  ),
                ),
          if (isHost && _voiceMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                        _isStreaming ? Icons.mic : Icons.mic_off,
                        color: _isStreaming
                            ? const Color(0xFFe2b96f)
                            : Colors.white38,
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
                              value: level,
                              backgroundColor: Colors.white12,
                              color: const Color(0xFFe2b96f),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isStreaming
                            ? 'Voice follow · listening'
                            : 'Voice follow',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isHost && session != null
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1a1a2e),
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe2b96f),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Done — Next'),
                        onPressed: () => context
                            .read<SessionProvider>()
                            .advanceToNext(session.id),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
  final VoidCallback? onTap;

  const _GroupLineView({
    required this.lineKey,
    required this.index,
    required this.text,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        key: lineKey,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCurrent ? const Color(0xFFe2b96f) : Colors.white54,
            fontSize: isCurrent ? 20 : 17,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}
