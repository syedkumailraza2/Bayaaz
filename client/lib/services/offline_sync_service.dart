import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/cached_kalaam.dart';
import '../db/cached_queue_item.dart';
import '../db/cached_session.dart';
import '../db/isar_service.dart';
import '../db/kalaam_mappers.dart';
import '../db/my_kalaam_cache.dart';
import '../db/pending_save_op.dart';
import '../db/pending_session_op.dart';
import '../db/saved_kalaam_cache.dart';
import '../db/sync_meta.dart';
import '../models/kalaam_model.dart';
import '../models/queue_item_model.dart';
import '../models/session_model.dart';
import 'analytics_service.dart';
import 'api_service.dart';
import 'reference_audio_service.dart';

const Duration kFeedTtl = Duration(days: 1);
const Duration kSavedTtl = Duration(days: 10);
const Duration kMyTtl = Duration(days: 10);
const int kFeedCacheSize = 40;
const int kFeedPageLimit = 20;

const String _kFeedMetaKey = 'feed';
const String _kSavedMetaKey = 'saved';
const String _kMyMetaKey = 'my';

class OfflineSyncService {
  OfflineSyncService._();
  static final OfflineSyncService instance = OfflineSyncService._();

  Isar get _db => IsarService.instance.db;

  // ─── Reads ──────────────────────────────────────────────────────────────────

  Future<List<KalaamModel>> readCachedFeed() async {
    final rows = await _db.cachedKalaams
        .where()
        .sortByFeedPosition()
        .findAll();
    return rows.map(fromCachedKalaam).toList();
  }

  Future<List<KalaamModel>> readCachedSaved() async {
    final rows = await _db.savedKalaamCaches
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return rows.map(fromSavedKalaamCache).toList();
  }

  Future<List<KalaamModel>> readCachedMy() async {
    final rows = await _db.myKalaamCaches
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return rows.map(fromMyKalaamCache).toList();
  }

  Future<bool> isFeedCacheStale() async {
    final meta = await _readMeta(_kFeedMetaKey);
    if (meta == null) return true;
    return DateTime.now().difference(meta.lastSyncedAt) > kFeedTtl;
  }

  Future<bool> isSavedCacheStale() async {
    final meta = await _readMeta(_kSavedMetaKey);
    if (meta == null) return true;
    return DateTime.now().difference(meta.lastSyncedAt) > kSavedTtl;
  }

  Future<bool> isMyCacheStale() async {
    final meta = await _readMeta(_kMyMetaKey);
    if (meta == null) return true;
    return DateTime.now().difference(meta.lastSyncedAt) > kMyTtl;
  }

  // ─── Writes ─────────────────────────────────────────────────────────────────

  /// Replace slots [page*limit .. page*limit+items.length) in the feed cache.
  /// Page is 1-indexed (matches server). Only pages 1 and 2 are persisted.
  Future<void> writeFeedPage(int page, List<KalaamModel> items) async {
    if (page < 1 || page > 2) return; // cap cache at 40 (pages 1 & 2)
    final start = (page - 1) * kFeedPageLimit;
    final rows = <CachedKalaam>[];
    for (var i = 0; i < items.length && start + i < kFeedCacheSize; i++) {
      rows.add(toCachedKalaam(items[i], feedPosition: start + i));
    }
    await _db.writeTxn(() async {
      // Clear any rows currently occupying this page's slots (handles shorter pages).
      final stale = await _db.cachedKalaams
          .filter()
          .feedPositionBetween(start, start + kFeedPageLimit - 1)
          .findAll();
      if (stale.isNotEmpty) {
        await _db.cachedKalaams.deleteAll(stale.map((r) => r.id).toList());
      }
      if (rows.isNotEmpty) {
        await _db.cachedKalaams.putAll(rows);
      }
      if (page == 1) {
        await _writeMeta(_kFeedMetaKey, DateTime.now());
      }
    });
  }

  /// Replace the entire saved-cache with [items]. Rows currently flagged
  /// `pendingSync=true` are preserved (in-flight offline saves take priority).
  Future<void> replaceSavedCache(List<KalaamModel> items) async {
    await _db.writeTxn(() async {
      final pending = await _db.savedKalaamCaches
          .filter()
          .pendingSyncEqualTo(true)
          .findAll();
      final pendingIds = pending.map((r) => r.serverId).toSet();

      final all = await _db.savedKalaamCaches.where().findAll();
      final toDelete = all
          .where((r) => !pendingIds.contains(r.serverId))
          .map((r) => r.id)
          .toList();
      if (toDelete.isNotEmpty) {
        await _db.savedKalaamCaches.deleteAll(toDelete);
      }

      final rows = items
          .where((m) => !pendingIds.contains(m.id))
          .map((m) => toSavedKalaamCache(m, pendingSync: false))
          .toList();
      if (rows.isNotEmpty) {
        await _db.savedKalaamCaches.putAll(rows);
      }

      await _writeMeta(_kSavedMetaKey, DateTime.now());
    });
  }

  /// Replace the entire my-kalaams cache with [items].
  Future<void> replaceMyCache(List<KalaamModel> items) async {
    await _db.writeTxn(() async {
      await _db.myKalaamCaches.clear();
      if (items.isNotEmpty) {
        await _db.myKalaamCaches.putAll(items.map(toMyKalaamCache).toList());
      }
      await _writeMeta(_kMyMetaKey, DateTime.now());
    });
  }

  /// Insert (save) a kalaam into the saved cache as a pending offline op.
  Future<void> stashOfflineSave(KalaamModel m) async {
    final row = toSavedKalaamCache(m, pendingSync: true);
    await _db.writeTxn(() async {
      await _db.savedKalaamCaches.put(row);
      await _db.pendingSaveOps.put(
        PendingSaveOp()
          ..kalaamId = m.id
          ..action = 'save'
          ..createdAt = DateTime.now(),
      );
    });
  }

  /// Remove (unsave) a kalaam from the saved cache and queue an unsave op.
  Future<void> stashOfflineUnsave(String kalaamId) async {
    await _db.writeTxn(() async {
      final existing = await _db.savedKalaamCaches
          .filter()
          .serverIdEqualTo(kalaamId)
          .findFirst();
      if (existing != null) {
        await _db.savedKalaamCaches.delete(existing.id);
      }
      await _db.pendingSaveOps.put(
        PendingSaveOp()
          ..kalaamId = kalaamId
          ..action = 'unsave'
          ..createdAt = DateTime.now(),
      );
    });
  }

  /// Mirror an online save into the saved cache (no pending op queued —
  /// the server already accepted the toggle).
  Future<void> mirrorOnlineSave(KalaamModel m) async {
    final row = toSavedKalaamCache(m, pendingSync: false);
    await _db.writeTxn(() => _db.savedKalaamCaches.put(row));
  }

  /// Mirror an online unsave into the saved cache.
  Future<void> mirrorOnlineUnsave(String kalaamId) async {
    await _db.writeTxn(() async {
      final existing = await _db.savedKalaamCaches
          .filter()
          .serverIdEqualTo(kalaamId)
          .findFirst();
      if (existing != null) {
        await _db.savedKalaamCaches.delete(existing.id);
      }
    });
  }

  /// Drain pending save/unsave ops in FIFO order. On any error, bump the
  /// attempt counter and stop the drain. Drop after 5 attempts.
  Future<void> drainPendingOps() async {
    final ops =
        await _db.pendingSaveOps.where().sortByCreatedAt().findAll();
    for (final op in ops) {
      try {
        final result = await ApiService.toggleSave(op.kalaamId);
        final serverSaved = result['saved'] as bool? ?? false;
        final wantSaved = op.action == 'save';
        if (serverSaved != wantSaved) {
          // Toggle landed on the wrong side — fire once more to align intent.
          await ApiService.toggleSave(op.kalaamId);
        }
        await _db.writeTxn(() async {
          await _db.pendingSaveOps.delete(op.id);
          if (wantSaved) {
            final row = await _db.savedKalaamCaches
                .filter()
                .serverIdEqualTo(op.kalaamId)
                .findFirst();
            if (row != null && row.pendingSync) {
              row.pendingSync = false;
              await _db.savedKalaamCaches.put(row);
            }
          }
        });
      } catch (_) {
        await _db.writeTxn(() async {
          op.attemptCount += 1;
          if (op.attemptCount >= 5) {
            await _db.pendingSaveOps.delete(op.id);
          } else {
            await _db.pendingSaveOps.put(op);
          }
        });
        // Stop the drain; next sync window will retry remaining ops.
        break;
      }
    }
  }

  // ─── Orchestration ──────────────────────────────────────────────────────────

  /// Full sync: drain queue → refetch feed if stale → refetch saved if stale →
  /// refetch user-authored kalaams if stale. Designed to be fire-and-forget.
  Future<void> syncAll() async {
    if (!IsarService.instance.isOpen) return;
    await drainPendingOps();
    await drainPendingEngagement();
    await drainPendingReferenceUploads();
    await AnalyticsService.instance.drainPendingPracticeSessions();
    await _maybeSyncFeed();
    await _maybeSyncSaved();
    await _maybeSyncMy();
  }

  Future<void> _maybeSyncFeed() async {
    final stale = await isFeedCacheStale();
    final empty = await _db.cachedKalaams.count() == 0;
    if (!stale && !empty) return;
    try {
      final results = await Future.wait([
        ApiService.getPublicKalaams(page: 1, limit: kFeedPageLimit),
        ApiService.getPublicKalaams(page: 2, limit: kFeedPageLimit),
      ]);
      await writeFeedPage(1, results[0].items);
      if (results[1].items.isNotEmpty) {
        await writeFeedPage(2, results[1].items);
      }
    } catch (_) {
      // best-effort; serve cached on next read
    }
  }

  Future<void> _maybeSyncSaved() async {
    final stale = await isSavedCacheStale();
    final empty = await _db.savedKalaamCaches.count() == 0;
    if (!stale && !empty) return;
    try {
      final saved = await ApiService.getSavedKalaams();
      await replaceSavedCache(saved);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _maybeSyncMy() async {
    final stale = await isMyCacheStale();
    final empty = await _db.myKalaamCaches.count() == 0;
    if (!stale && !empty) return;
    try {
      final mine = await ApiService.getMyKalaams();
      await replaceMyCache(mine);
    } catch (_) {
      // best-effort
    }
  }

  // ─── Session cache (reads + mirrors) ────────────────────────────────────────

  Future<SessionModel?> readCachedSession(String sessionId) async {
    if (!IsarService.instance.isOpen) return null;
    final session = await _db.cachedSessions
        .filter()
        .serverIdEqualTo(sessionId)
        .findFirst();
    if (session == null) return null;
    final items = await _db.cachedQueueItems
        .filter()
        .sessionIdEqualTo(sessionId)
        .findAll();
    return SessionModel(
      id: session.serverId,
      groupId: session.groupId,
      hostId: session.hostId,
      currentKalamId: session.currentKalamId,
      currentStanza: session.currentStanza,
      currentLine: session.currentLine,
      isActive: session.isActive,
      isPlaying: session.isPlaying,
      queue: items.map((i) => i.kalaamId).toList(),
      queueKalaams: const [],
      currentQueueIndex: 0,
      queueItems: items.map(_itemFromCache).toList(),
    );
  }

  /// Mirror a server-confirmed session into the cache. Preserves any
  /// pendingSync queue items that haven't drained yet.
  Future<void> mirrorSession(SessionModel s) async {
    if (!IsarService.instance.isOpen) return;
    await _db.writeTxn(() async {
      final existingSession = await _db.cachedSessions
          .filter()
          .serverIdEqualTo(s.id)
          .findFirst();
      final row = existingSession ?? CachedSession();
      row
        ..serverId = s.id
        ..groupId = s.groupId
        ..hostId = s.hostId
        ..currentKalamId = s.currentKalamId
        ..currentStanza = s.currentStanza
        ..currentLine = s.currentLine
        ..isActive = s.isActive
        ..isPlaying = s.isPlaying
        ..cachedAt = DateTime.now();
      await _db.cachedSessions.put(row);

      // Replace queue rows for this session, preserving pendingSync rows.
      final existingItems = await _db.cachedQueueItems
          .filter()
          .sessionIdEqualTo(s.id)
          .findAll();
      final pending = existingItems.where((r) => r.pendingSync).toList();
      final pendingKalaamIds = pending.map((r) => r.kalaamId).toSet();
      final toDelete = existingItems
          .where((r) => !r.pendingSync)
          .map((r) => r.id)
          .toList();
      if (toDelete.isNotEmpty) {
        await _db.cachedQueueItems.deleteAll(toDelete);
      }
      final fresh = s.queueItems
          .where((i) => !pendingKalaamIds.contains(i.kalaamId))
          .map((i) => _itemToCache(s.id, i))
          .toList();
      if (fresh.isNotEmpty) await _db.cachedQueueItems.putAll(fresh);
    });
  }

  SessionQueueItem _itemFromCache(CachedQueueItem r) => SessionQueueItem(
        kalaamId: r.kalaamId,
        kalaamTitle: r.kalaamTitle,
        kalaamCategory: r.kalaamCategory,
        kalaamAuthorName: r.kalaamAuthorName,
        addedById: r.addedById,
        addedAt: r.addedAt,
        votes: r.voters.toSet(),
        pinned: r.pinned,
        pinPosition: r.pinPosition,
        pendingSync: r.pendingSync,
      );

  CachedQueueItem _itemToCache(String sessionId, SessionQueueItem i) {
    return CachedQueueItem()
      ..sessionId = sessionId
      ..kalaamId = i.kalaamId
      ..kalaamTitle = i.kalaamTitle
      ..kalaamCategory = i.kalaamCategory
      ..kalaamAuthorName = i.kalaamAuthorName
      ..addedById = i.addedById
      ..addedAt = i.addedAt
      ..voters = i.votes.toList()
      ..pinned = i.pinned
      ..pinPosition = i.pinPosition
      ..pendingSync = i.pendingSync
      ..cachedAt = DateTime.now();
  }

  // ─── Pending session ops (offline writes) ───────────────────────────────────

  Future<void> _enqueueSessionOp(String sessionId, String action,
      Map<String, dynamic> payload) async {
    if (!IsarService.instance.isOpen) return;
    await _db.writeTxn(() async {
      await _db.pendingSessionOps.put(
        PendingSessionOp()
          ..sessionId = sessionId
          ..action = action
          ..payloadJson = jsonEncode(payload)
          ..createdAt = DateTime.now(),
      );
    });
  }

  Future<void> stashOfflineQueueAdd(
      String sessionId, KalaamModel kalaam, String addedById) async {
    if (!IsarService.instance.isOpen) return;
    await _db.writeTxn(() async {
      await _db.cachedQueueItems.put(_itemToCache(
        sessionId,
        SessionQueueItem.optimistic(kalaam: kalaam, addedById: addedById),
      ));
    });
    await _enqueueSessionOp(sessionId, 'addQueue', {'kalaamId': kalaam.id});
  }

  Future<void> stashOfflineVote(
      String sessionId, String kalaamId, String userId) async {
    if (!IsarService.instance.isOpen) return;
    await _db.writeTxn(() async {
      final existing = await _db.cachedQueueItems
          .filter()
          .sessionIdEqualTo(sessionId)
          .and()
          .kalaamIdEqualTo(kalaamId)
          .findFirst();
      if (existing != null) {
        final voters = List<String>.from(existing.voters);
        if (!voters.remove(userId)) voters.add(userId);
        existing.voters = voters;
        await _db.cachedQueueItems.put(existing);
      }
    });
    await _enqueueSessionOp(sessionId, 'vote', {'kalaamId': kalaamId});
  }

  Future<void> stashOfflineRemove(String sessionId, String kalaamId) async {
    if (!IsarService.instance.isOpen) return;
    await _db.writeTxn(() async {
      final existing = await _db.cachedQueueItems
          .filter()
          .sessionIdEqualTo(sessionId)
          .and()
          .kalaamIdEqualTo(kalaamId)
          .findFirst();
      if (existing != null) await _db.cachedQueueItems.delete(existing.id);
    });
    await _enqueueSessionOp(sessionId, 'removeQueue', {'kalaamId': kalaamId});
  }

  Future<void> stashOfflinePin(
      String sessionId, String kalaamId,
      {required bool pinned, int? pinPosition}) async {
    await _enqueueSessionOp(sessionId, 'pin', {
      'kalaamId': kalaamId,
      'pinned': pinned,
      if (pinPosition != null) 'pinPosition': pinPosition,
    });
  }

  Future<void> stashOfflineLineAdvance(
      String sessionId, int stanza, int line) async {
    await _enqueueSessionOp(sessionId, 'lineAdvance', {
      'stanza': stanza,
      'line': line,
    });
  }

  Future<void> stashOfflineAdvanceToNext(String sessionId) async {
    await _enqueueSessionOp(sessionId, 'advanceToNext', {});
  }

  /// Drain pending session ops FIFO. On error, bump attemptCount and halt
  /// (the next reconnect retries). Drop ops after 5 attempts.
  Future<void> drainPendingSessionOps() async {
    if (!IsarService.instance.isOpen) return;
    final ops = await _db.pendingSessionOps
        .where()
        .sortByCreatedAt()
        .findAll();
    for (final op in ops) {
      try {
        final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
        SessionModel? refreshed;
        switch (op.action) {
          case 'addQueue':
            refreshed = await ApiService.addToQueue(
                op.sessionId, payload['kalaamId'] as String);
            break;
          case 'vote':
            refreshed = await ApiService.voteOnQueueItem(
                op.sessionId, payload['kalaamId'] as String);
            break;
          case 'removeQueue':
            refreshed = await ApiService.removeFromQueue(
                op.sessionId, payload['kalaamId'] as String);
            break;
          case 'pin':
            refreshed = await ApiService.pinQueueItem(
              op.sessionId,
              payload['kalaamId'] as String,
              pinned: payload['pinned'] as bool? ?? false,
              pinPosition: payload['pinPosition'] as int?,
            );
            break;
          case 'lineAdvance':
            refreshed = await ApiService.setStanza(
              op.sessionId,
              payload['stanza'] as int? ?? 0,
              payload['line'] as int? ?? 0,
            );
            break;
          case 'advanceToNext':
            refreshed = await ApiService.advanceToNext(op.sessionId);
            break;
          default:
            // Unknown action — drop silently so it doesn't block the queue.
            break;
        }
        await _db.writeTxn(() async {
          await _db.pendingSessionOps.delete(op.id);
          // Clear pendingSync on the cached row that just made it through.
          if (op.action == 'addQueue') {
            final row = await _db.cachedQueueItems
                .filter()
                .sessionIdEqualTo(op.sessionId)
                .and()
                .kalaamIdEqualTo(payload['kalaamId'] as String)
                .findFirst();
            if (row != null && row.pendingSync) {
              row.pendingSync = false;
              await _db.cachedQueueItems.put(row);
            }
          }
        });
        // Mirror the canonical state if the server returned it.
        if (refreshed != null) await mirrorSession(refreshed);
      } catch (_) {
        await _db.writeTxn(() async {
          op.attemptCount += 1;
          if (op.attemptCount >= 5) {
            await _db.pendingSessionOps.delete(op.id);
          } else {
            await _db.pendingSessionOps.put(op);
          }
        });
        // Halt the drain — next sync window will retry.
        break;
      }
    }
  }

  // ─── Pending like / view intents ───────────────────────────────────────────
  // Like and view are tiny intent records, not full mutations, so a list of
  // kalaam-ids in SharedPreferences is plenty — no Isar codegen needed.
  // Like queue toggles by parity: two stashes for the same id cancel out
  // (matches the server's toggle semantics). View queue is a Set since the
  // server is already idempotent per user.
  static const _kPendingLikeToggles = 'pending_like_toggles';
  static const _kPendingViews = 'pending_views';

  Future<void> stashPendingLikeToggle(String kalaamId) async {
    if (kalaamId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingLikeToggles) ?? const <String>[];
    // Even number of entries for a given id = net-zero, so we cancel pairs
    // instead of queueing them both.
    final lastIdx = list.lastIndexOf(kalaamId);
    if (lastIdx >= 0) {
      final next = List<String>.from(list)..removeAt(lastIdx);
      if (next.isEmpty) {
        await prefs.remove(_kPendingLikeToggles);
      } else {
        await prefs.setStringList(_kPendingLikeToggles, next);
      }
      return;
    }
    await prefs.setStringList(_kPendingLikeToggles, [...list, kalaamId]);
  }

  Future<void> stashPendingView(String kalaamId) async {
    if (kalaamId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_kPendingViews) ?? []).toSet();
    set.add(kalaamId);
    await prefs.setStringList(_kPendingViews, set.toList());
  }

  Future<void> drainPendingEngagement() async {
    final prefs = await SharedPreferences.getInstance();

    final likes = prefs.getStringList(_kPendingLikeToggles) ?? const <String>[];
    final unsentLikes = <String>[];
    for (final id in likes) {
      try {
        await ApiService.toggleLike(id);
      } catch (e) {
        debugPrint('[sync] like drain failed for $id: $e');
        unsentLikes.add(id);
      }
    }
    if (unsentLikes.isEmpty) {
      await prefs.remove(_kPendingLikeToggles);
    } else {
      await prefs.setStringList(_kPendingLikeToggles, unsentLikes);
    }

    final views = prefs.getStringList(_kPendingViews) ?? const <String>[];
    final unsentViews = <String>[];
    for (final id in views) {
      try {
        await ApiService.recordView(id);
      } catch (e) {
        debugPrint('[sync] view drain failed for $id: $e');
        unsentViews.add(id);
      }
    }
    if (unsentViews.isEmpty) {
      await prefs.remove(_kPendingViews);
    } else {
      await prefs.setStringList(_kPendingViews, unsentViews);
    }
  }

  // ─── Pending reference-audio uploads ───────────────────────────────────────
  // Kalaam reference recitations are heavy (audio/video bytes) and don't
  // naturally fit a small Isar op row, so we track the pending kalaam-ids
  // in SharedPreferences and replay through ReferenceAudioService on drain.
  // Files themselves live in app-docs `reference_audio/<id>.<ext>` keyed by
  // kalaam id — no copy is needed beyond what `extractAndNormalize` did.
  static const _kPendingRefUploads = 'pending_reference_uploads';

  Future<void> stashPendingReferenceUpload(String kalaamId) async {
    if (kalaamId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_kPendingRefUploads) ?? []).toSet();
    set.add(kalaamId);
    await prefs.setStringList(_kPendingRefUploads, set.toList());
  }

  Future<void> clearPendingReferenceUpload(String kalaamId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingRefUploads) ?? const <String>[];
    if (!list.contains(kalaamId)) return;
    final remaining = list.where((id) => id != kalaamId).toList();
    if (remaining.isEmpty) {
      await prefs.remove(_kPendingRefUploads);
    } else {
      await prefs.setStringList(_kPendingRefUploads, remaining);
    }
  }

  Future<List<String>> readPendingReferenceUploads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kPendingRefUploads) ?? const <String>[];
  }

  /// Replays every pending reference upload, invoking [onUploaded] with the
  /// server-fresh kalaam so the calling provider can patch its in-memory
  /// lists. Best-effort: a failure leaves the id in the queue for a later
  /// drain (typically the next online→offline transition).
  Future<void> drainPendingReferenceUploads({
    void Function(KalaamModel updated)? onUploaded,
  }) async {
    final ids = await readPendingReferenceUploads();
    for (final id in ids) {
      try {
        final updated =
            await ReferenceAudioService.instance.uploadToServer(id);
        if (updated != null) {
          await clearPendingReferenceUpload(id);
          onUploaded?.call(updated);
        }
      } catch (e) {
        debugPrint('[sync] reference upload retry failed for $id: $e');
      }
    }
  }

  // ─── Meta ───────────────────────────────────────────────────────────────────

  Future<SyncMeta?> _readMeta(String key) {
    return _db.syncMetas.filter().keyEqualTo(key).findFirst();
  }

  Future<void> _writeMeta(String key, DateTime at) async {
    final existing = await _readMeta(key);
    final row = existing ?? SyncMeta();
    row.key = key;
    row.lastSyncedAt = at;
    await _db.syncMetas.put(row);
  }
}
