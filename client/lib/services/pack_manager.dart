import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../db/isar_service.dart';
import '../db/pack_record.dart';
import 'device_capability_service.dart';

enum PackId {
  speech,        // Vosk model — Urdu STT
  coach,         // On-device LLM (Phi-3 Mini Q4_K_M GGUF)
  pronunciation, // Phoneme reference data
}

extension PackIdExt on PackId {
  String get name => switch (this) {
        PackId.speech => 'speech',
        PackId.coach => 'coach',
        PackId.pronunciation => 'pronunciation',
      };

  String get displayName => switch (this) {
        PackId.speech => 'Speech Recognition',
        PackId.coach => 'AI Coach',
        PackId.pronunciation => 'Pronunciation Guide',
      };

  String get version => '1.0.0';
}

class PackManager {
  static final PackManager instance = PackManager._();
  PackManager._();

  // Coach pack is auto-installed on high-end devices and auto-deleted after 24h.
  static const _packTtl = Duration(hours: 24);

  // Set at build time: flutter run --dart-define=COACH_PACK_URL=https://...
  static const _coachPackUrl = String.fromEnvironment(
    'COACH_PACK_URL',
    defaultValue: '',
  );

  Future<Directory> _packsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/packs');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> packDirectory(PackId id) async {
    if (!await isPackInstalled(id)) return null;
    final base = await _packsDir();
    return '${base.path}/${id.name}';
  }

  Future<bool> isPackInstalled(PackId id) async {
    if (!IsarService.instance.isOpen) return false;
    final record =
        await IsarService.instance.db.packRecords.getByPackId(id.name);
    if (record == null || !record.isValid) return false;
    final dir = Directory('${(await _packsDir()).path}/${id.name}');
    return dir.existsSync();
  }

  // Returns true if the pack was installed more than [_packTtl] ago.
  Future<bool> isPackExpired(PackId id) async {
    if (!IsarService.instance.isOpen) return false;
    final record =
        await IsarService.instance.db.packRecords.getByPackId(id.name);
    if (record == null || !record.isValid) return false;
    return DateTime.now().difference(record.installedAt) >= _packTtl;
  }

  // Deletes the pack if its TTL has elapsed.
  Future<void> expireIfNeeded(PackId id) async {
    if (await isPackExpired(id)) {
      debugPrint('[PackManager] ${id.name} pack expired (>24h) — deleting.');
      await deletePack(id);
    }
  }

  /// Silently downloads and installs the coach pack on high-end devices.
  /// No-op if:
  ///   • device is not high-tier
  ///   • COACH_PACK_URL dart-define is not set
  ///   • pack is already installed
  Future<void> autoInstallCoach() async {
    if (DeviceCapabilityService.instance.tier != DeviceTier.high) return;
    if (_coachPackUrl.isEmpty) {
      debugPrint('[PackManager] COACH_PACK_URL not configured; skipping auto-install.');
      return;
    }
    if (await isPackInstalled(PackId.coach)) return;

    debugPrint('[PackManager] Auto-installing coach pack in background...');
    try {
      await downloadPack(PackId.coach, downloadUrl: _coachPackUrl);
      debugPrint('[PackManager] Coach pack installed.');
    } catch (e) {
      debugPrint('[PackManager] Auto-install failed: $e');
    }
  }

  Future<void> downloadPack(
    PackId id, {
    String? downloadUrl,
    void Function(double progress)? onProgress,
  }) async {
    if (downloadUrl == null) {
      debugPrint('[PackManager] No download URL for ${id.name}');
      return;
    }

    try {
      final base = await _packsDir();
      final packDir = Directory('${base.path}/${id.name}');
      if (!await packDir.exists()) await packDir.create(recursive: true);

      final tmpFile = File('${base.path}/${id.name}.tmp');

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);
      final total = response.contentLength ?? 0;
      int received = 0;

      final sink = tmpFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();

      final isValid = await _verifySha256(tmpFile);
      if (!isValid) {
        await tmpFile.delete();
        throw Exception('SHA-256 verification failed for ${id.name}');
      }

      await tmpFile.rename('${packDir.path}/pack.bin');
      await _saveRecord(id, isValid: true);
    } catch (e) {
      debugPrint('[PackManager] Download failed: $e');
      rethrow;
    }
  }

  // Stub: real implementation would fetch a .sha256 sidecar and compare.
  Future<bool> _verifySha256(File file) async {
    try {
      final bytes = await file.readAsBytes();
      sha256.convert(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveRecord(PackId id, {required bool isValid}) async {
    if (!IsarService.instance.isOpen) return;
    final db = IsarService.instance.db;
    final existing = await db.packRecords.getByPackId(id.name);
    final record = existing ?? PackRecord();
    record
      ..packId = id.name
      ..version = id.version
      ..installedAt = DateTime.now()
      ..isValid = isValid;
    await db.writeTxn(() => db.packRecords.put(record));
  }

  Future<void> deletePack(PackId id) async {
    if (!IsarService.instance.isOpen) return;
    final base = await _packsDir();
    final packDir = Directory('${base.path}/${id.name}');
    if (await packDir.exists()) await packDir.delete(recursive: true);
    final db = IsarService.instance.db;
    await db.writeTxn(() async {
      final record = await db.packRecords.getByPackId(id.name);
      if (record != null) await db.packRecords.delete(record.id);
    });
  }
}
