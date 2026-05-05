import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../models/suggestion_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class SessionProvider extends ChangeNotifier {
  SessionModel? _session;
  List<SuggestionModel> _suggestions = [];
  bool _loading = false;
  String? _error;
  String? _activeSessionId;

  SessionModel? get session => _session;
  List<SuggestionModel> get suggestions => List.unmodifiable(_suggestions);
  bool get loading => _loading;
  String? get error => _error;

  // ── Load & Socket ──────────────────────────────────────────────────────────

  Future<void> loadSession(String sessionId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _session = await ApiService.getSession(sessionId);
      _activeSessionId = sessionId;
      // Connect socket and join room
      final socket = SocketService();
      await socket.connect();
      socket.joinSession(sessionId);
      _listenToSocket(sessionId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _listenToSocket(String sessionId) {
    final socket = SocketService();

    // Full state on join (for late joiners / reconnects)
    socket.on('session:joined', (data) {
      try {
        if (data is Map && data['session'] != null) {
          _session = SessionModel.fromJson(
              Map<String, dynamic>.from(data['session'] as Map));
          notifyListeners();
        }
      } catch (_) {}
    });

    socket.on('session:kalamChanged', (data) {
      if (_session == null || data is! Map) return;
      _session = _session!.copyWith(
        currentKalamId: data['kalamId'] as String?,
        currentStanza: data['stanza'] as int? ?? 0,
        currentLine: data['line'] as int? ?? 0,
      );
      notifyListeners();
    });

    socket.on('session:stanzaChanged', (data) {
      if (_session == null || data is! Map) return;
      _session = _session!.copyWith(
        currentStanza: data['stanza'] as int? ?? _session!.currentStanza,
        currentLine: data['line'] as int? ?? _session!.currentLine,
      );
      notifyListeners();
    });

    socket.on('session:playStateChanged', (data) {
      if (_session == null || data is! Map) return;
      _session = _session!.copyWith(
        isPlaying: data['isPlaying'] as bool? ?? _session!.isPlaying,
      );
      notifyListeners();
    });

    socket.on('session:queueUpdated', (data) {
      if (_session == null || data is! Map) return;
      final rawQueue = data['queue'];
      if (rawQueue is List) {
        _session = _session!.copyWith(
          queue: rawQueue.map((e) => e.toString()).toList(),
        );
        notifyListeners();
      }
    });

    socket.on('session:newSuggestion', (data) {
      try {
        if (data is Map && data['suggestion'] != null) {
          final suggestion = SuggestionModel.fromJson(
              Map<String, dynamic>.from(data['suggestion'] as Map));
          _suggestions.insert(0, suggestion);
          notifyListeners();
        }
      } catch (_) {}
    });

    socket.on('session:suggestionHandled', (data) {
      if (data is! Map) return;
      final sid = data['suggestionId'] as String?;
      final status = data['status'] as String?;
      if (sid == null || status == null) return;
      final idx = _suggestions.indexWhere((s) => s.id == sid);
      if (idx != -1) {
        final old = _suggestions[idx];
        _suggestions[idx] = SuggestionModel(
          id: old.id,
          sessionId: old.sessionId,
          groupId: old.groupId,
          kalamId: old.kalamId,
          kalamTitle: old.kalamTitle,
          suggestedById: old.suggestedById,
          suggestedByName: old.suggestedByName,
          status: status,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    });

    socket.on('session:ended', (_) {
      _session = _session?.copyWith(isActive: false);
      notifyListeners();
    });
  }

  void leaveAndCleanup(String sessionId) {
    final socket = SocketService();
    socket.leaveSession(sessionId);
    for (final event in [
      'session:joined',
      'session:kalamChanged',
      'session:stanzaChanged',
      'session:playStateChanged',
      'session:queueUpdated',
      'session:newSuggestion',
      'session:suggestionHandled',
      'session:ended',
    ]) {
      socket.off(event);
    }
    _activeSessionId = null;
    _session = null;
    _suggestions = [];
  }

  // ── REST methods (unchanged) ───────────────────────────────────────────────

  Future<bool> setKalam(String sessionId, String kalamId) async {
    try {
      _session = await ApiService.setKalam(sessionId, kalamId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setStanza(String sessionId, int stanza, int line) async {
    try {
      _session = await ApiService.setStanza(sessionId, stanza, line);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setPlayState(String sessionId, bool isPlaying) async {
    try {
      _session = await ApiService.setPlayState(sessionId, isPlaying);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> endSession(String sessionId) async {
    try {
      await ApiService.endSession(sessionId);
      leaveAndCleanup(sessionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addToQueue(String sessionId, String kalamId) async {
    try {
      _session = await ApiService.addToQueue(sessionId, kalamId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromQueue(String sessionId, String kalamId) async {
    try {
      _session = await ApiService.removeFromQueue(sessionId, kalamId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reorderQueue(String sessionId, List<String> orderedIds) async {
    try {
      _session = await ApiService.reorderQueue(sessionId, orderedIds);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> skipToNext(String sessionId) async {
    try {
      _session = await ApiService.skipToNext(sessionId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadSuggestions(String sessionId) async {
    try {
      _suggestions = await ApiService.getSuggestions(sessionId);
      notifyListeners();
    } catch (e) {
      // silent — supplementary data
    }
  }

  Future<bool> suggestKalam(String sessionId, String kalamId) async {
    try {
      final suggestion = await ApiService.suggestKalam(sessionId, kalamId);
      _suggestions.insert(0, suggestion);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> handleSuggestion(String sessionId, String sid, String status) async {
    try {
      final updated = await ApiService.handleSuggestion(sessionId, sid, status);
      final idx = _suggestions.indexWhere((s) => s.id == sid);
      if (idx != -1) _suggestions[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
