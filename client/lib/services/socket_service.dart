import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  Future<void>? _connecting;

  bool get isConnected => _socket?.connected ?? false;

  /// Idempotent and actually waits for the handshake to complete.
  ///
  /// The previous implementation returned the moment `_socket!.connect()`
  /// was called — so callers ran `joinGroup()` / `joinSession()` against a
  /// disconnected socket. socket.io-client buffers those emits, but only
  /// flushes them once the underlying transport is up. If the transport
  /// never came up (stale Cloudflare tunnel, blocked websocket upgrade) the
  /// emits sat in the buffer forever and the room was never joined —
  /// silently breaking every realtime feature.
  Future<void> connect() async {
    if (isConnected) return;
    if (_connecting != null) return _connecting!;

    final completer = Completer<void>();
    _connecting = completer.future;

    try {
      if (_socket == null) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if ((token ?? '').isEmpty) {
          debugPrint('[socket] WARNING: connecting without a token');
        }
        debugPrint('[socket] dialing ${AppConfig.socketUrl}');
        _socket = IO.io(
          AppConfig.socketUrl,
          IO.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .setAuth({'token': token ?? ''})
              .enableReconnection()
              .setReconnectionDelay(1000)
              .setReconnectionAttempts(1 << 30)
              .disableAutoConnect()
              .build(),
        );
        _attachLifecycleLogs(_socket!);
      }

      final socket = _socket!;

      void cleanup() {
        socket.off('connect', _onConnectComplete);
        socket.off('connect_error', _onConnectFail);
      }

      _onConnectComplete = (_) {
        cleanup();
        if (!completer.isCompleted) completer.complete();
      };
      _onConnectFail = (err) {
        debugPrint('[socket] connect_error: $err');
        cleanup();
        if (!completer.isCompleted) completer.complete(); // don't deadlock callers
      };

      socket.on('connect', _onConnectComplete!);
      socket.on('connect_error', _onConnectFail!);

      if (!socket.connected) socket.connect();

      // Hard ceiling so a dead tunnel can't hang every screen forever.
      Timer(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          debugPrint('[socket] connect timeout — proceeding optimistically');
          cleanup();
          completer.complete();
        }
      });

      await completer.future;
    } finally {
      _connecting = null;
    }
  }

  dynamic Function(dynamic)? _onConnectComplete;
  dynamic Function(dynamic)? _onConnectFail;

  void _attachLifecycleLogs(IO.Socket s) {
    s.on('connect', (_) => debugPrint('[socket] connected id=${s.id}'));
    s.on('disconnect', (reason) => debugPrint('[socket] disconnected: $reason'));
    s.on('reconnect', (n) => debugPrint('[socket] reconnect attempt $n succeeded'));
    s.on('reconnect_attempt', (n) => debugPrint('[socket] reconnect attempt $n'));
    s.on('connect_error', (e) => debugPrint('[socket] connect_error: $e'));
    s.on('error', (e) => debugPrint('[socket] error: $e'));
    s.on('session:error', (e) => debugPrint('[socket] session:error: $e'));
  }

  void joinSession(String sessionId) =>
      _socket?.emit('session:join', {'sessionId': sessionId});

  void leaveSession(String sessionId) =>
      _socket?.emit('session:leave', {'sessionId': sessionId});

  // Group room — used by the group detail screen to receive
  // `group:sessionStarted` / `group:sessionEnded` events in realtime.
  void joinGroup(String groupId) =>
      _socket?.emit('group:join', {'groupId': groupId});

  void leaveGroup(String groupId) =>
      _socket?.emit('group:leave', {'groupId': groupId});

  // Host emitters
  void emitSetKalam(String sessionId, String kalamId) =>
      _socket?.emit('host:setKalam', {'sessionId': sessionId, 'kalamId': kalamId});

  void emitSetStanza(String sessionId, int stanza, int line) =>
      _socket?.emit('host:setStanza', {'sessionId': sessionId, 'stanza': stanza, 'line': line});

  void emitSetPlayState(String sessionId, bool isPlaying) =>
      _socket?.emit('host:setPlayState', {'sessionId': sessionId, 'isPlaying': isPlaying});

  void emitQueueUpdated(String sessionId, List<String> queue) =>
      _socket?.emit('host:queueUpdated', {'sessionId': sessionId, 'queue': queue});

  // Member emitters
  void emitSuggest(String sessionId, String kalamId) =>
      _socket?.emit('member:suggest', {'sessionId': sessionId, 'kalamId': kalamId});

  void emitHandleSuggestion(String sessionId, String suggestionId, String status) =>
      _socket?.emit('host:suggestionHandled', {
        'sessionId': sessionId,
        'suggestionId': suggestionId,
        'status': status,
      });

  // Voting + queue control (new flow)
  void emitVote(String sessionId, String kalaamId) => _socket?.emit(
        'member:vote',
        {'sessionId': sessionId, 'kalaamId': kalaamId},
      );

  void emitPinQueueItem(
    String sessionId,
    String kalaamId, {
    required bool pinned,
    int? pinPosition,
  }) {
    _socket?.emit('host:pinQueueItem', {
      'sessionId': sessionId,
      'kalaamId': kalaamId,
      'pinned': pinned,
      if (pinPosition != null) 'pinPosition': pinPosition,
    });
  }

  void emitAdvanceToNext(String sessionId) =>
      _socket?.emit('host:advanceToNext', {'sessionId': sessionId});

  // Voice streaming (Vosk path).
  // The host opens a streaming PCM channel with `voice:start`, then pushes
  // raw 16-bit mono PCM frames via `voice:frame`. The server bridges to
  // Vosk and broadcasts `session:stanzaChanged` as the cursor moves.
  void emitVoiceStart(String sessionId) =>
      _socket?.emit('voice:start', {'sessionId': sessionId});

  void emitVoiceFrame(List<int> pcm) =>
      _socket?.emit('voice:frame', pcm);

  void emitVoiceEnd() => _socket?.emit('voice:end', {});

  // Listener registration
  void on(String event, void Function(dynamic) handler) =>
      _socket?.on(event, handler);

  void off(String event) => _socket?.off(event);

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
