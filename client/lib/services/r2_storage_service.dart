import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Uploads reference media to Cloudflare R2 via a server-issued presigned
/// PUT URL. The flow is:
///   1. POST `/kalaams/:id/reference/presign` to get `(uploadUrl, publicUrl,
///      contentType)`.
///   2. PUT the file bytes to `uploadUrl` with exactly that `Content-Type`
///      header (S3 binds it into the signature — mismatched MIME = 403).
///   3. Hand the `publicUrl` back to the caller, which will persist it via
///      `ApiService.setReferenceAudio`.
///
/// R2 access keys live only on the server. This class is safe to use without
/// any client-side credentials — the presign endpoint is the auth gate.
class R2StorageService {
  static final R2StorageService instance = R2StorageService._();
  R2StorageService._();

  /// Uploads [file] and returns its public URL. Throws on failure — callers
  /// decide whether to retry or surface the error to the user.
  Future<({String url, String storagePath})> uploadReference({
    required String kalaamId,
    required File file,
    required String extension,
    String? contentType, // unused — server picks Content-Type from extension
  }) async {
    final cleanExt = extension.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
    final ext = cleanExt.isEmpty ? 'm4a' : cleanExt;

    final presign = await ApiService.presignReferenceUpload(
      kalaamId: kalaamId,
      extension: ext,
    );

    final bytes = await file.readAsBytes();
    final res = await http.put(
      Uri.parse(presign.uploadUrl),
      headers: {'Content-Type': presign.contentType},
      body: bytes,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      // R2 returns the upstream S3 XML error body — surface it so failures
      // (bad CORS, signature mismatch, expired URL) are debuggable instead
      // of "upload failed".
      throw Exception(
        'R2 upload failed: HTTP ${res.statusCode} — ${_truncate(res.body, 240)}',
      );
    }
    // R2's public URL doesn't expose the bucket key as a separate path
    // segment — we treat the URL itself as the storage identifier. Deletion
    // is server-side via `ApiService.deleteReferenceAudio` so the client
    // doesn't need to parse the key out.
    return (url: presign.publicUrl, storagePath: presign.publicUrl);
  }

  /// Best-effort deletion. Server-side delete is the canonical path (it runs
  /// when the user clears the reference or the kalaam itself is deleted) so
  /// this is a no-op today — kept on the class to keep the call sites in
  /// `reference_audio_service.dart` stable across the Supabase→R2 swap.
  Future<void> deleteByDownloadUrl(String url) async {
    debugPrint('[r2] deleteByDownloadUrl no-op (server handles deletion): $url');
  }

  String _truncate(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n)}…';
}
