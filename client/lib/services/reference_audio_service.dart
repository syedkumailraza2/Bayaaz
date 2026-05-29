import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../db/isar_service.dart';
import '../db/kalaam_reference_audio.dart';
import '../models/kalaam_model.dart';
import 'api_service.dart';
import 'supabase_storage_service.dart';

/// Container for a picked media file plus the extension we'll persist it
/// under. Returned by [ReferenceAudioService.pickAudioFile] /
/// [ReferenceAudioService.pickVideoFile] so callers don't have to re-derive
/// the extension from a possibly-messy native file path.
class PickedMedia {
  final File file;
  final String extension; // no leading dot, lowercase

  const PickedMedia({required this.file, required this.extension});
}

class ReferenceAudioService {
  static final ReferenceAudioService instance = ReferenceAudioService._();
  ReferenceAudioService._();

  Future<PickedMedia?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    return _resolvePicked(result, fallbackExt: 'm4a');
  }

  Future<PickedMedia?> pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    return _resolvePicked(result, fallbackExt: 'mp4');
  }

  /// Pulls the extension from `file_picker`'s metadata first (most reliable
  /// across providers), then from the path via the `path` package (which
  /// correctly handles directory names with dots), then falls back to the
  /// supplied default. We always keep an extension because Android's native
  /// audio decoders infer the codec from the filename when no explicit
  /// MIME type is supplied.
  PickedMedia? _resolvePicked(FilePickerResult? result, {required String fallbackExt}) {
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final path = picked.path;
    if (path == null) return null;
    final pickerExt = (picked.extension ?? '').toLowerCase();
    final pathExt = p.extension(path).replaceFirst('.', '').toLowerCase();
    final ext = pickerExt.isNotEmpty
        ? pickerExt
        : (pathExt.isNotEmpty ? pathExt : fallbackExt);
    return PickedMedia(file: File(path), extension: ext);
  }

  /// Downloads the audio stream from a YouTube URL to a temp file.
  /// Returns the file and duration from video metadata (no extra probe needed).
  Future<({File file, int durationMs})?> fetchYouTubeAudio(
    String url, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    final yt = YoutubeExplode();
    final httpClient = http.Client();
    try {
      final videoId = VideoId.parseVideoId(url);
      if (videoId == null) return null;
      onStatus?.call('Resolving stream…');
      final manifest = await yt.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 30));
      // Use the lowest-bitrate muxed (mp4) stream — muxed streams are served
      // via standard CDN and not subject to the throttling that hits audioOnly.
      // audioplayers' native decoder plays the audio track from mp4 directly,
      // so no FFmpeg extraction step is needed.
      final muxed = manifest.muxed.toList()
        ..sort((a, b) =>
            a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
      if (muxed.isEmpty) throw Exception('No streams available');
      final streamInfo = muxed.first; // lowest bitrate = smallest file
      final totalBytes = streamInfo.size.totalBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/yt_audio_temp.mp4');
      final sink = file.openWrite();
      int received = 0;
      onStatus?.call('Opening stream…');
      final request = http.Request('GET', streamInfo.url)
        ..headers['User-Agent'] =
            'com.google.android.youtube/17.36.4 (Linux; U; Android 12; GB) gzip'
        ..headers['Referer'] = 'https://www.youtube.com/';
      final response = await httpClient
          .send(request)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      onStatus?.call('Downloading…');
      await response.stream.map((chunk) {
        received += chunk.length;
        final p = totalBytes > 0 ? received / totalBytes : -1.0;
        onProgress?.call(p);
        return chunk;
      }).pipe(sink);
      final durationMs =
          totalBytes > 0 && streamInfo.bitrate.bitsPerSecond > 0
              ? (totalBytes * 8000 / streamInfo.bitrate.bitsPerSecond).round()
              : 0;
      return (file: file, durationMs: durationMs);
    } finally {
      yt.close();
      httpClient.close();
    }
  }

  /// Copies source audio/video to the reference_audio directory.
  /// FFmpeg normalization to 16kHz WAV is deferred to Phase 1 (Vosk integration).
  ///
  /// Pass [extension] (no leading dot) when known — e.g. from [PickedMedia].
  /// When omitted we read it via the `path` package, which (unlike
  /// `split('.').last`) doesn't mistake dots in directory names for the
  /// real file extension. We fall back to `m4a` as a last resort because
  /// audioplayers' native backends infer the codec from the extension; a
  /// missing/garbage extension breaks playback even when the bytes are fine.
  Future<String> extractAndNormalize(
    File source,
    String kalaamId, {
    String? extension,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/reference_audio');
    await outDir.create(recursive: true);
    final resolvedExt = _normaliseExt(
      extension ?? p.extension(source.path).replaceFirst('.', ''),
      fallback: 'm4a',
    );
    final outPath = '${outDir.path}/$kalaamId.$resolvedExt';
    await source.copy(outPath);
    return outPath;
  }

  String _normaliseExt(String raw, {required String fallback}) {
    final t = raw.trim().toLowerCase();
    // Reject anything that looks like part of a path leaked in from the
    // legacy `split('.').last` extraction.
    if (t.isEmpty || t.contains('/') || t.contains('\\') || t.length > 6) {
      return fallback;
    }
    return t;
  }

  /// Reads the duration of any audio file via the device's native decoder.
  /// Returns 0 if the format is unsupported or the file can't be read.
  Future<int> getFileDurationMs(String filePath) async {
    final player = AudioPlayer();
    try {
      final completer = Completer<int>();
      late StreamSubscription<Duration> sub;
      sub = player.onDurationChanged.listen((d) {
        if (!completer.isCompleted) {
          completer.complete(d.inMilliseconds);
          sub.cancel();
        }
      });
      await player.setSource(DeviceFileSource(filePath));
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          sub.cancel();
          return 0;
        },
      );
    } catch (_) {
      return 0;
    } finally {
      await player.dispose();
    }
  }

  Future<void> saveReference({
    required String kalaamId,
    required String wavPath,
    required String sourceType,
    String? sourceUrl,
    required int durationMs,
  }) async {
    final db = IsarService.instance.db;
    final record = KalaamReferenceAudio()
      ..kalaamId = kalaamId
      ..localWavPath = wavPath
      ..sourceType = sourceType
      ..sourceUrl = sourceUrl
      ..durationMs = durationMs
      ..createdAt = DateTime.now()
      ..metadataGenerated = false;
    await db.writeTxn(() => db.kalaamReferenceAudios.put(record));
  }

  /// After kalaam creation the server assigns a real ID. This method
  /// renames the WAV file and updates the Isar record to use it.
  Future<void> linkToKalaam({
    required String tempId,
    required String realId,
  }) async {
    final db = IsarService.instance.db;
    final existing = await db.kalaamReferenceAudios.getByKalaamId(tempId);
    if (existing == null) return;

    final dir = await getApplicationDocumentsDirectory();
    // Use the `path` package's extension() so dotted directory names along
    // the way (e.g., `/data/.../com.bayaaz/...`) don't poison the result.
    final existingExt = _normaliseExt(
      p.extension(existing.localWavPath).replaceFirst('.', ''),
      fallback: 'm4a',
    );
    final newWavPath = '${dir.path}/reference_audio/$realId.$existingExt';

    final oldFile = File(existing.localWavPath);
    if (await oldFile.exists()) {
      await oldFile.rename(newWavPath);
    }

    await db.writeTxn(() async {
      await db.kalaamReferenceAudios.deleteByKalaamId(tempId);
      final updated = KalaamReferenceAudio()
        ..kalaamId = realId
        ..localWavPath = newWavPath
        ..sourceType = existing.sourceType
        ..sourceUrl = existing.sourceUrl
        ..durationMs = existing.durationMs
        ..createdAt = existing.createdAt
        ..metadataGenerated = false;
      await db.kalaamReferenceAudios.put(updated);
    });
  }

  Future<KalaamReferenceAudio?> getReference(String kalaamId) {
    return IsarService.instance.db.kalaamReferenceAudios
        .getByKalaamId(kalaamId);
  }

  Future<void> deleteReference(String kalaamId) async {
    final db = IsarService.instance.db;
    final existing = await db.kalaamReferenceAudios.getByKalaamId(kalaamId);
    if (existing != null) {
      final f = File(existing.localWavPath);
      if (await f.exists()) await f.delete();
    }
    await db.writeTxn(
        () => db.kalaamReferenceAudios.deleteByKalaamId(kalaamId));
  }

  /// Uploads the locally-cached reference for [kalaamId] to the server so
  /// other devices opening this kalaam can follow-voice off it too. Returns
  /// the server's updated [KalaamModel] (with `referenceAudio` populated) so
  /// the caller can patch the in-memory list. Returns null when there's
  /// nothing to upload or the network call fails.
  Future<KalaamModel?> uploadToServer(String kalaamId) async {
    final ref = await getReference(kalaamId);
    if (ref == null) return null;
    final file = File(ref.localWavPath);
    if (!await file.exists()) return null;
    final extension = p.extension(ref.localWavPath).replaceFirst('.', '');
    try {
      // 1. Push the file bytes directly to Supabase Storage so the
      //    Bayaaz API server doesn't need a writable filesystem (Vercel
      //    serverless can't host uploads).
      final uploaded = await SupabaseStorageService.instance.uploadReference(
        kalaamId: kalaamId,
        file: file,
        extension: extension,
      );
      // 2. Tell our API where the file lives so other devices opening
      //    this kalaam can fetch it from Supabase too.
      final updated = await ApiService.setReferenceAudio(
        kalaamId: kalaamId,
        url: uploaded.url,
        sourceType: ref.sourceType,
        sourceUrl: ref.sourceUrl,
        durationMs: ref.durationMs,
        extension: extension,
      );
      return updated;
    } catch (e) {
      debugPrint('[reference] uploadToServer failed: $e');
      return null;
    }
  }

  /// Ensures a local cached copy of [media] exists for [kalaamId]. If the
  /// Isar record already points to a valid file, we keep it. Otherwise we
  /// download the bytes from `media.url` into `reference_audio/`.
  /// Returns true when the local file is ready to play.
  Future<bool> ensureLocalCopy({
    required String kalaamId,
    required KalaamReferenceMedia media,
  }) async {
    final db = IsarService.instance.db;
    final existing = await db.kalaamReferenceAudios.getByKalaamId(kalaamId);
    if (existing != null && await File(existing.localWavPath).exists()) {
      return true;
    }
    if (media.url.isEmpty) return false;

    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/reference_audio');
    await outDir.create(recursive: true);
    final ext = _normaliseExt(
      media.extension.isNotEmpty
          ? media.extension
          : p.extension(media.url).replaceFirst('.', ''),
      fallback: 'm4a',
    );
    final outPath = '${outDir.path}/$kalaamId.$ext';

    try {
      final res = await http
          .get(Uri.parse(media.url))
          .timeout(const Duration(minutes: 5));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return false;
      await File(outPath).writeAsBytes(res.bodyBytes, flush: true);
    } catch (_) {
      return false;
    }

    await saveReference(
      kalaamId: kalaamId,
      wavPath: outPath,
      sourceType: media.sourceType,
      sourceUrl: media.sourceUrl,
      durationMs: media.durationMs,
    );
    return true;
  }
}
