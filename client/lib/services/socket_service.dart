import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    _socket = IO.io(
      'https://hue-conventicular-rosalyn.ngrok-free.dev',
      IO.OptionBuilder()
          .setTransports(['polling', 'websocket'])
          .setAuth({'token': token ?? ''})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
  }

  void joinSession(String sessionId) =>
      _socket?.emit('session:join', {'sessionId': sessionId});

  void leaveSession(String sessionId) =>
      _socket?.emit('session:leave', {'sessionId': sessionId});

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

  // Listener registration
  void on(String event, void Function(dynamic) handler) =>
      _socket?.on(event, handler);

  void off(String event) => _socket?.off(event);

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
