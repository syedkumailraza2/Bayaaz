import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/kalaam_model.dart';
import '../models/queue_item_model.dart';
import '../models/session_model.dart';
import '../models/suggestion_model.dart';
import '../services/api_service.dart';
import '../services/offline_sync_service.dart';
import '../services/socket_service.dart';
import 'connectivity_provider.dart';

class SessionProvider extends ChangeNotifier {
  SessionModel? _session;
  List<SuggestionModel> _suggestions = [];
  bool _loading = false;
  String? _error;
  String? _activeSessionId;
  String? _currentUserId;

  ConnectivityProvider? _connectivity;
  StreamSubscription<bool>? _connectivitySub;

  SessionModel? get session => _session;
  List<SuggestionModel> get suggestions => List.unmodifiable(_suggestions);
  bool get loading => _loading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  bool get isHost =>
      _session != null && _currentUserId != null && _session!.hostId == _currentUserId;

  // Socket.IO JSON ints can land as num — coerce defensively.
  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Wired from main.dart via ChangeNotifierProxyProvider. We use the same
  /// onChange stream the splash already subscribes to so we can refresh the
  /// session room when connectivity returns.
  void attachConnectivity(ConnectivityProvider c) {
    if (identical(_connectivity, c)) return;
    _connectivitySub?.cancel();
    _connectivity = c;
    _connectivitySub = c.onChange.listen((online) {
      if (online) _onReconnect();
    });
  }

  bool get _isOnline => _connectivity?.isOnline ?? true;

  Future<void> _onReconnect() async {
    final sid = _activeSessionId;
    if (sid == null) return;
    final socket = SocketService();
    try {
      await socket.connect();
      socket.joinSession(sid);
    } catch (_) {}
    // Drain any session ops the user queued while offline. The server
    // broadcasts after each drain step so other devices catch up too.
    unawaited(OfflineSyncService.instance.drainPendingSessionOps());
  }

  /// Hydrate the session view from Isar so an offline open paints
  /// immediately, before any network call.
  Future<void> hydrateSessionFromCache(String sessionId) async {
    final cached = await OfflineSyncService.instance.readCachedSession(sessionId);
    if (cached == null) return;
    _session = cached;
    _activeSessionId = sessionId;
    notifyListeners();
  }

  Future<void> _ensureUserId() async {
    if (_currentUserId != null) return;
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null || userJson.isEmpty) return;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      _currentUserId = (map['_id'] ?? map['id'])?.toString();
    } catch (_) {}
  }

  // ── Load & Socket ──────────────────────────────────────────────────────────

  Future<void> loadSession(String sessionId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    await _ensureUserId();
    // Paint from cache instantly while we hit the network.
    await hydrateSessionFromCache(sessionId);

    if (!_isOnline) {
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      _session = await ApiService.getSession(sessionId);
      _activeSessionId = sessionId;
      unawaited(OfflineSyncService.instance.mirrorSession(_session!));
      final socket = SocketService();
      await socket.connect();
      // Register listeners BEFORE emitting session:join so the server's
      // `session:joined` echo and any racing `session:stanzaChanged` aren't
      // dropped on the floor.
      _listenToSocket(sessionId);
      socket.joinSession(sessionId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _listenToSocket(String sessionId) {
    final socket = SocketService();

    socket.on('session:joined', (data) {
      try {
        if (data is Map && data['session'] != null) {
          _session = SessionModel.fromJson(
              Map<String, dynamic>.from(data['session'] as Map));
          unawaited(OfflineSyncService.instance.mirrorSession(_session!));
          notifyListeners();
        }
      } catch (_) {}
    });

    socket.on('session:kalamChanged', (data) {
      if (_session == null || data is! Map) return;
      final newKalamId = data['kalamId']?.toString();
      final stanza = _asInt(data['stanza']) ?? 0;
      final line = _asInt(data['line']) ?? 0;
      // Rebuild session directly so currentKalam (the populated full object)
      // is dropped — otherwise the teleprompter renders the previous kalaam.
      _session = SessionModel(
        id: _session!.id,
        groupId: _session!.groupId,
        hostId: _session!.hostId,
        currentKalamId: newKalamId ?? _session!.currentKalamId,
        currentKalam: null,
        currentStanza: stanza,
        currentLine: line,
        isActive: _session!.isActive,
        isPlaying: _session!.isPlaying,
        queue: _session!.queue,
        queueKalaams: _session!.queueKalaams,
        currentQueueIndex: _session!.currentQueueIndex,
        queueItems: _session!.queueItems,
      );
      notifyListeners();
    });

    socket.on('session:stanzaChanged', (data) {
      if (_session == null || data is! Map) return;
      final stanza = _asInt(data['stanza']) ?? _session!.currentStanza;
      final line = _asInt(data['line']) ?? _session!.currentLine;
      debugPrint('[socket] session:stanzaChanged → ($stanza,$line)');
      _session = _session!.copyWith(
        currentStanza: stanza,
        currentLine: line,
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
      // New server: payload contains enriched queueItems. Old server: only
      // a flat `queue` list. Prefer queueItems when present.
      final rawItems = data['queueItems'];
      if (rawItems is List) {
        final items = rawItems
            .whereType<Map>()
            .map((m) => SessionQueueItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        _session = _session!.copyWith(
          queueItems: items,
          queue: data['queue'] is List
              ? (data['queue'] as List).map((e) => e.toString()).toList()
              : _session!.queue,
        );
        unawaited(OfflineSyncService.instance.mirrorSession(_session!));
        notifyListeners();
        return;
      }
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

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ── REST methods ───────────────────────────────────────────────────────────

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
    if (!_isOnline) {
      await OfflineSyncService.instance.stashOfflineLineAdvance(sessionId, stanza, line);
      _session = _session?.copyWith(currentStanza: stanza, currentLine: line);
      notifyListeners();
      return true;
    }
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

  /// Add a kalaam (full model) to the queue. Pre-inserts an optimistic
  /// pendingSync row so the UI updates instantly; the server response (or
  /// the broadcasted `session:queueUpdated`) replaces it with the canonical
  /// item.
  Future<bool> addToQueue(String sessionId, KalaamModel kalaam) async {
    await _ensureUserId();
    final optimistic = SessionQueueItem.optimistic(
      kalaam: kalaam,
      addedById: _currentUserId ?? '',
    );
    final alreadyQueued =
        _session?.queueItems.any((i) => i.kalaamId == kalaam.id) ?? false;
    if (_session != null && !alreadyQueued) {
      _session = _session!.copyWith(
        queueItems: [..._session!.queueItems, optimistic],
      );
      notifyListeners();
    }

    if (!_isOnline) {
      await OfflineSyncService.instance.stashOfflineQueueAdd(
        sessionId,
        kalaam,
        _currentUserId ?? '',
      );
      return true;
    }

    try {
      _session = await ApiService.addToQueue(sessionId, kalaam.id);
      unawaited(OfflineSyncService.instance.mirrorSession(_session!));
      notifyListeners();
      return true;
    } catch (e) {
      // Online attempt failed mid-flight — stash so reconnect drains it,
      // and keep the optimistic row visible.
      await OfflineSyncService.instance.stashOfflineQueueAdd(
        sessionId,
        kalaam,
        _currentUserId ?? '',
      );
      return true;
    }
  }

  Future<bool> removeFromQueue(String sessionId, String kalamId) async {
    // Optimistic removal so UI updates instantly online or off.
    if (_session != null) {
      _session = _session!.copyWith(
        queueItems: _session!.queueItems
            .where((i) => i.kalaamId != kalamId)
            .toList(),
      );
      notifyListeners();
    }
    if (!_isOnline) {
      await OfflineSyncService.instance.stashOfflineRemove(sessionId, kalamId);
      return true;
    }
    try {
      _session = await ApiService.removeFromQueue(sessionId, kalamId);
      unawaited(OfflineSyncService.instance.mirrorSession(_session!));
      notifyListeners();
      return true;
    } catch (e) {
      await OfflineSyncService.instance.stashOfflineRemove(sessionId, kalamId);
      return true;
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

  // ── Voting / pinning / advance (new flow) ──────────────────────────────────

  /// Toggle the current user's upvote on a queue item. Optimistic — the
  /// broadcast `session:queueUpdated` will overwrite with the canonical state.
  Future<bool> toggleVote(String sessionId, String kalaamId) async {
    await _ensureUserId();
    final uid = _currentUserId;
    if (uid == null || _session == null) return false;

    _session = _session!.copyWith(
      queueItems: _session!.queueItems.map((i) {
        if (i.kalaamId != kalaamId) return i;
        final newVotes = Set<String>.from(i.votes);
        if (!newVotes.add(uid)) newVotes.remove(uid);
        return i.copyWith(votes: newVotes);
      }).toList(),
    );
    notifyListeners();

    if (!_isOnline) {
      await OfflineSyncService.instance.stashOfflineVote(sessionId, kalaamId, uid);
      return true;
    }

    try {
      final socket = SocketService();
      if (socket.isConnected) {
        socket.emitVote(sessionId, kalaamId);
        return true;
      }
      _session = await ApiService.voteOnQueueItem(sessionId, kalaamId);
      unawaited(OfflineSyncService.instance.mirrorSession(_session!));
      notifyListeners();
      return true;
    } catch (_) {
      // Network blip — queue it for the next reconnect.
      await OfflineSyncService.instance.stashOfflineVote(sessionId, kalaamId, uid);
      return true;
    }
  }

  Future<bool> pinItem(
    String sessionId,
    String kalaamId, {
    required bool pinned,
    int? pinPosition,
  }) async {
    if (!_isOnline) {
      await OfflineSyncService.instance.stashOfflinePin(
        sessionId,
        kalaamId,
        pinned: pinned,
        pinPosition: pinPosition,
      );
      return true;
    }
    try {
      final socket = SocketService();
      if (socket.isConnected) {
        socket.emitPinQueueItem(sessionId, kalaamId,
            pinned: pinned, pinPosition: pinPosition);
        return true;
      }
      _session = await ApiService.pinQueueItem(
        sessionId,
        kalaamId,
        pinned: pinned,
        pinPosition: pinPosition,
      );
      unawaited(OfflineSyncService.instance.mirrorSession(_session!));
      notifyListeners();
      return true;
    } catch (_) {
      await OfflineSyncService.instance.stashOfflinePin(
        sessionId,
        kalaamId,
        pinned: pinned,
        pinPosition: pinPosition,
      );
      return true;
    }
  }

  Future<bool> advanceToNext(String sessionId) async {
    if (!_isOnline) {
      await OfflineSyncService.instance.stashOfflineAdvanceToNext(sessionId);
      return true;
    }
    try {
      final socket = SocketService();
      if (socket.isConnected) {
        socket.emitAdvanceToNext(sessionId);
        return true;
      }
      _session = await ApiService.advanceToNext(sessionId);
      unawaited(OfflineSyncService.instance.mirrorSession(_session!));
      notifyListeners();
      return true;
    } catch (_) {
      await OfflineSyncService.instance.stashOfflineAdvanceToNext(sessionId);
      return true;
    }
  }

  // ── Suggestions (legacy) ───────────────────────────────────────────────────

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
