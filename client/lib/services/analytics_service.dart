import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../db/isar_service.dart';
import '../db/kalaam_practice_meta.dart';
import '../db/practice_session_record.dart';
import '../models/kalaam_model.dart';
import '../services/api_service.dart';
import '../services/scoring_service.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  Isar get _db => IsarService.instance.db;

  Future<void> recordSession({
    required KalaamModel kalaam,
    required SessionScore score,
    required String mode,
  }) async {
    if (!IsarService.instance.isOpen) return;

    final record = PracticeSessionRecord()
      ..kalaamId = kalaam.id
      ..kalaamTitle = kalaam.title
      ..mode = mode
      ..sessionAt = DateTime.now()
      ..overallScore = score.overall
      ..accuracyScore = score.accuracy
      ..completionScore = score.completion
      ..flowScore = score.flowScore
      ..pauseScore = score.pauseScore
      ..perLineScoresJson =
          jsonEncode(score.perLine.map((l) => l.accuracy).toList())
      ..clientToken = const Uuid().v4()
      ..syncedToServer = false;

    await _db.writeTxn(() async {
      await _db.practiceSessionRecords.put(record);
      await _updateMeta(kalaam.id, score);
    });

    // Push to the server in the background. On failure the row stays
    // `syncedToServer = false` and OfflineSyncService.drainPendingPracticeSessions
    // retries on the next reconnect.
    unawaited(_syncToServer(record, score));
  }

  Future<void> _syncToServer(
    PracticeSessionRecord record,
    SessionScore score,
  ) async {
    try {
      await ApiService.postPracticeSession(
        kalaamId: record.kalaamId,
        kalaamTitle: record.kalaamTitle,
        mode: record.mode,
        sessionAt: record.sessionAt,
        overallScore: record.overallScore,
        accuracyScore: record.accuracyScore,
        completionScore: record.completionScore,
        flowScore: record.flowScore,
        pauseScore: record.pauseScore,
        perLineScores: score.perLine.map((l) => l.accuracy).toList(),
        clientToken: record.clientToken,
      );
      record.syncedToServer = true;
      await _db.writeTxn(() => _db.practiceSessionRecords.put(record));
    } catch (e) {
      debugPrint('[analytics] live sync failed (queued for retry): $e');
    }
  }

  /// Iterate every still-unsynced session and POST them to the server in
  /// order. Idempotent: the server dedupes on `clientToken`. Called from
  /// OfflineSyncService on reconnect.
  Future<int> drainPendingPracticeSessions() async {
    if (!IsarService.instance.isOpen) return 0;
    final pending = await _db.practiceSessionRecords
        .filter()
        .syncedToServerEqualTo(false)
        .sortBySessionAt()
        .findAll();
    int drained = 0;
    for (final record in pending) {
      try {
        final perLine = (jsonDecode(record.perLineScoresJson) as List)
            .map((v) => (v as num).toDouble())
            .toList();
        await ApiService.postPracticeSession(
          kalaamId: record.kalaamId,
          kalaamTitle: record.kalaamTitle,
          mode: record.mode,
          sessionAt: record.sessionAt,
          overallScore: record.overallScore,
          accuracyScore: record.accuracyScore,
          completionScore: record.completionScore,
          flowScore: record.flowScore,
          pauseScore: record.pauseScore,
          perLineScores: perLine,
          clientToken: record.clientToken,
        );
        record.syncedToServer = true;
        await _db.writeTxn(() => _db.practiceSessionRecords.put(record));
        drained += 1;
      } catch (e) {
        debugPrint('[analytics] drain failed for ${record.clientToken}: $e');
        // Stop the drain on the first failure — the network is probably
        // still flaky; the next reconnect tick will retry the queue.
        break;
      }
    }
    return drained;
  }

  Future<void> _updateMeta(String kalaamId, SessionScore score) async {
    final existing =
        await _db.kalaamPracticeMetas.getByKalaamId(kalaamId);
    final now = DateTime.now();

    if (existing == null) {
      final meta = KalaamPracticeMeta()
        ..kalaamId = kalaamId
        ..totalSessions = 1
        ..bestOverallScore = score.overall
        ..lastPracticedAt = now
        ..currentStreak = 1
        ..longestStreak = 1
        ..weakLineIndices = _weakLines(score);
      await _db.kalaamPracticeMetas.put(meta);
      return;
    }

    final daysSinceLast =
        now.difference(existing.lastPracticedAt).inDays;
    final streak = daysSinceLast <= 1 ? existing.currentStreak + 1 : 1;

    existing
      ..totalSessions = existing.totalSessions + 1
      ..bestOverallScore = score.overall > existing.bestOverallScore
          ? score.overall
          : existing.bestOverallScore
      ..lastPracticedAt = now
      ..currentStreak = streak
      ..longestStreak =
          streak > existing.longestStreak ? streak : existing.longestStreak
      ..weakLineIndices = _weakLines(score);

    await _db.kalaamPracticeMetas.put(existing);
  }

  String _weakLines(SessionScore score) {
    final weak = <int>[];
    for (int i = 0; i < score.perLine.length; i++) {
      if (score.perLine[i].accuracy < 0.5) weak.add(i);
    }
    return weak.join(',');
  }

  Future<KalaamPracticeMeta?> getMeta(String kalaamId) async {
    if (!IsarService.instance.isOpen) return null;
    return _db.kalaamPracticeMetas.getByKalaamId(kalaamId);
  }

  Future<List<PracticeSessionRecord>> getHistory(
    String kalaamId, {
    int limit = 20,
  }) async {
    if (!IsarService.instance.isOpen) return [];
    return _db.practiceSessionRecords
        .filter()
        .kalaamIdEqualTo(kalaamId)
        .sortBySessionAtDesc()
        .limit(limit)
        .findAll();
  }

  Future<List<int>> getWeakLines(String kalaamId) async {
    final meta = await getMeta(kalaamId);
    if (meta == null || meta.weakLineIndices.isEmpty) return [];
    return meta.weakLineIndices
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }
}
