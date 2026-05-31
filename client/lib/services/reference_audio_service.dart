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
import 'r2_storage_service.dart';

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

  /// Downloads the audio for a YouTube URL into a temp file.
  ///
  /// Strategy: try audio-only first (typically 5–10× smaller than muxed mp4)
  /// to save user bandwidth and R2 upload time. If YouTube rejects the
  /// audio-only stream with 403 (its anti-bot path throttles audioOnly URLs
  /// more aggressively than muxed), fall back to the lowest-bitrate muxed
  /// mp4. The 200 MB sanity guard in [uploadToServer] then surfaces a clear
  /// error if a fallback muxed file is unexpectedly huge.
  Future<({File file, int durationMs, String extension})?> fetchYouTubeAudio(
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

      // Build the candidate list: audio-only mp4 first (small + best codec),
      // audio-only webm second (small but opus), muxed mp4 last (large but
      // most reliable against YouTube throttling).
      final audioOnly = manifest.audioOnly.toList()
        ..sort((a, b) =>
            a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
      final muxed = manifest.muxed.toList()
        ..sort((a, b) =>
            a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
      final candidates = <({dynamic info, String ext})>[];
      for (final s in audioOnly) {
        final isMp4 = s.container.name.toLowerCase() == 'mp4';
        candidates.add((info: s, ext: isMp4 ? 'm4a' : 'webm'));
      }
      // Sort so mp4-audio comes first, then webm-audio, then muxed mp4 below.
      candidates.sort((a, b) {
        final am = a.ext == 'm4a' ? 0 : 1;
        final bm = b.ext == 'm4a' ? 0 : 1;
        return am.compareTo(bm);
      });
      for (final s in muxed) {
        candidates.add((info: s, ext: 'mp4'));
      }
      if (candidates.isEmpty) {
        throw Exception('No streams available');
      }

      final dir = await getTemporaryDirectory();
      Object? lastError;
      for (var i = 0; i < candidates.length; i++) {
        final c = candidates[i];
        final streamInfo = c.info;
        final extension = c.ext;
        final totalBytes = streamInfo.size.totalBytes as int;
        final file = File('${dir.path}/yt_audio_temp.$extension');
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {/* best-effort */}
        }
        final sink = file.openWrite();
        int received = 0;
        onStatus?.call(i == 0 ? 'Opening stream…' : 'Retrying with fallback…');
        try {
          final request = http.Request('GET', streamInfo.url as Uri)
            ..headers['User-Agent'] =
                'com.google.android.youtube/17.36.4 (Linux; U; Android 12; GB) gzip'
            ..headers['Referer'] = 'https://www.youtube.com/';
          final response = await httpClient
              .send(request)
              .timeout(const Duration(seconds: 15));
          if (response.statusCode != 200) {
            await sink.close();
            throw Exception('HTTP ${response.statusCode}');
          }
          onStatus?.call('Downloading…');
          await response.stream.map((chunk) {
            received += chunk.length;
            final p = totalBytes > 0 ? received / totalBytes : -1.0;
            onProgress?.call(p);
            return chunk;
          }).pipe(sink);
          final bps = streamInfo.bitrate.bitsPerSecond as int;
          final durationMs = totalBytes > 0 && bps > 0
              ? (totalBytes * 8000 / bps).round()
              : 0;
          return (file: file, durationMs: durationMs, extension: extension);
        } catch (e) {
          lastError = e;
          debugPrint('[reference] yt stream attempt ${i + 1}/${candidates.length} '
              '($extension) failed: $e');
          try {
            await sink.close();
          } catch (_) {/* already closed */}
          // Try the next candidate (audio-only webm → muxed mp4 → …).
        }
      }
      throw lastError ?? Exception('All YouTube streams failed');
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

  /// Last error string from [uploadToServer]. Set when the R2 upload or
  /// `setReferenceAudio` call throws; cleared on the next successful run.
  /// Callers can read this to surface a user-visible toast — the upload
  /// itself is fire-and-forget so the original call site can't await the
  /// exception directly.
  String? lastUploadError;

  /// Uploads the locally-cached reference for [kalaamId] to the server so
  /// other devices opening this kalaam can follow-voice off it too. Returns
  /// the server's updated [KalaamModel] (with `referenceAudio` populated) so
  /// the caller can patch the in-memory list. Returns null when there's
  /// nothing to upload or the network call fails.
  Future<KalaamModel?> uploadToServer(String kalaamId) async {
    final ref = await getReference(kalaamId);
    if (ref == null) {
      lastUploadError = 'no local reference record for $kalaamId';
      debugPrint('[reference] uploadToServer skipped: ${lastUploadError!}');
      return null;
    }
    final file = File(ref.localWavPath);
    if (!await file.exists()) {
      lastUploadError = 'local file missing: ${ref.localWavPath}';
      debugPrint('[reference] uploadToServer skipped: ${lastUploadError!}');
      return null;
    }
    // R2 single-PUT supports up to 5 GB, but uploading a multi-GB blob over
    // mobile data is a footgun for the user. A 200 MB sanity cap stops
    // accidental video-with-no-audio-only-fallback cases without restricting
    // realistic kalaam references (audio-only is usually 5–15 MB).
    const maxUploadBytes = 200 * 1024 * 1024;
    final fileBytes = await file.length();
    if (fileBytes > maxUploadBytes) {
      final mb = (fileBytes / (1024 * 1024)).toStringAsFixed(1);
      lastUploadError =
          'reference is $mb MB; max upload is 200 MB. Pick a shorter clip or compress before saving.';
      debugPrint('[reference] uploadToServer skipped: ${lastUploadError!}');
      return null;
    }
    final extension = p.extension(ref.localWavPath).replaceFirst('.', '');
    try {
      // 1. Push the file bytes to R2 via a server-issued presigned PUT URL
      //    so the Bayaaz API server doesn't need a writable filesystem and
      //    R2 credentials never leave the server.
      final uploaded = await R2StorageService.instance.uploadReference(
        kalaamId: kalaamId,
        file: file,
        extension: extension,
      );
      // 2. Tell our API where the file lives so other devices opening
      //    this kalaam can fetch it from R2 too.
      final updated = await ApiService.setReferenceAudio(
        kalaamId: kalaamId,
        url: uploaded.url,
        sourceType: ref.sourceType,
        sourceUrl: ref.sourceUrl,
        durationMs: ref.durationMs,
        extension: extension,
      );
      lastUploadError = null;
      return updated;
    } catch (e, st) {
      lastUploadError = '${e.runtimeType}: $e';
      debugPrint('[reference] uploadToServer failed: ${lastUploadError!}');
      debugPrint('[reference] stack: $st');
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
