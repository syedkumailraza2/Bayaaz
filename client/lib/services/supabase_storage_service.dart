import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';

/// Thin wrapper around Supabase Storage so the rest of the app deals in
/// download URLs instead of bucket paths. References live under
/// `<kalaamId>/<uuid>.<ext>` inside the [kSupabaseReferenceBucket]
/// bucket so each upload is a fresh object (replacing one is the
/// caller's job, currently fire-and-forget).
///
/// The bucket is expected to be public-read so other devices opening
/// the same kalaam can play the file off its `getPublicUrl` link with
/// no further auth. Writes are gated by the bucket's RLS policy
/// (authenticated users only — see README).
class SupabaseStorageService {
  static final SupabaseStorageService instance = SupabaseStorageService._();
  SupabaseStorageService._();

  SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  /// Uploads [file] under `<kalaamId>/<uuid>.<extension>` and returns
  /// its public URL. Throws on failure — callers decide whether to
  /// retry or surface the error.
  Future<({String url, String storagePath})> uploadReference({
    required String kalaamId,
    required File file,
    required String extension,
    String? contentType,
  }) async {
    final cleanExt = extension.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
    final ext = cleanExt.isEmpty ? 'm4a' : cleanExt;
    final storagePath = '$kalaamId/${_uuid.v4()}.$ext';

    await _client.storage.from(kSupabaseReferenceBucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: contentType ?? _guessContentType(ext),
            cacheControl: '604800', // 7 days
            upsert: false,
          ),
        );

    final url = _client.storage
        .from(kSupabaseReferenceBucket)
        .getPublicUrl(storagePath);
    return (url: url, storagePath: storagePath);
  }

  /// Deletes the object at [storagePath] in the references bucket.
  /// Swallows "not found" so callers can no-op safely on best-effort
  /// cleanup paths.
  Future<void> deleteByPath(String storagePath) async {
    try {
      await _client.storage
          .from(kSupabaseReferenceBucket)
          .remove([storagePath]);
    } on StorageException catch (e) {
      if (e.statusCode == '404') return;
      debugPrint('[storage] delete failed for $storagePath: ${e.message}');
    } catch (e) {
      debugPrint('[storage] delete unexpected error: $e');
    }
  }

  /// Best-effort deletion using a public download URL. Parses the
  /// storage path out of the URL and forwards to [deleteByPath].
  Future<void> deleteByDownloadUrl(String url) async {
    final path = _storagePathFromPublicUrl(url);
    if (path == null) return;
    await deleteByPath(path);
  }

  /// Public URLs look like:
  ///   `https://<ref>.supabase.co/storage/v1/object/public/<bucket>/<storagePath>`
  /// Return the `<storagePath>` portion when the bucket matches; else null.
  String? _storagePathFromPublicUrl(String url) {
    try {
      final u = Uri.parse(url);
      final segs = u.pathSegments;
      // Expect: ['storage', 'v1', 'object', 'public', <bucket>, ...path]
      if (segs.length < 6) return null;
      if (segs[0] != 'storage' ||
          segs[2] != 'object' ||
          segs[3] != 'public' ||
          segs[4] != kSupabaseReferenceBucket) {
        return null;
      }
      return segs.sublist(5).join('/');
    } catch (_) {
      return null;
    }
  }

  String _guessContentType(String ext) {
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }
}
