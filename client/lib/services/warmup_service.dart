import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Pings `/health` until the server responds, then resolves.
///
/// The Bayaaz server runs on Render's free tier, which spins idle services
/// down after ~15 min. A cold request takes 30-50s while the dyno boots —
/// long enough that a 15s default HTTP timeout would fail before the server
/// is ready. This service issues short-timeout pings on a loop so the UI can
/// show a "waking up server…" state and the rest of the app can wait until
/// the server is actually reachable.
class WarmupService {
  WarmupService._();
  static final WarmupService instance = WarmupService._();

  bool _isWarm = false;
  bool get isWarm => _isWarm;

  Completer<void>? _inFlight;

  /// Fires `isWarm` once the server has responded. Listeners can hook this to
  /// hide a "connecting…" overlay or extend a splash screen until it resolves.
  final StreamController<bool> _warmController =
      StreamController<bool>.broadcast();
  Stream<bool> get onWarm => _warmController.stream;

  /// Pings `/health` repeatedly with backoff until it succeeds or
  /// [maxTotalDuration] elapses. Coalesces concurrent callers — only one ping
  /// loop runs at a time.
  ///
  /// Returns true if the server responded OK before the deadline.
  Future<bool> warmup({
    Duration maxTotalDuration = const Duration(seconds: 60),
    void Function(int attempt, Duration elapsed)? onAttempt,
  }) async {
    if (_isWarm) return true;
    if (_inFlight != null) {
      await _inFlight!.future;
      return _isWarm;
    }
    _inFlight = Completer<void>();

    final deadline = DateTime.now().add(maxTotalDuration);
    int attempt = 0;
    // Each individual ping uses a short timeout — Render either responds in
    // <1s (warm) or not at all (still booting). We don't want to sit on a
    // single 60s socket; we want to keep retrying so the user sees progress.
    const perAttemptTimeout = Duration(seconds: 5);
    const initialBackoff = Duration(milliseconds: 800);
    const maxBackoff = Duration(seconds: 3);
    var backoff = initialBackoff;
    final start = DateTime.now();

    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      onAttempt?.call(attempt, DateTime.now().difference(start));
      try {
        final res = await http
            .get(
              Uri.parse('${AppConfig.baseUrl}/health'),
              headers: const {'ngrok-skip-browser-warning': 'true'},
            )
            .timeout(perAttemptTimeout);
        if (res.statusCode == 200) {
          _isWarm = true;
          _warmController.add(true);
          _inFlight!.complete();
          _inFlight = null;
          return true;
        }
      } catch (_) {
        // Cold dyno; keep retrying.
      }
      await Future.delayed(backoff);
      backoff = Duration(
        milliseconds: (backoff.inMilliseconds * 1.5)
            .clamp(initialBackoff.inMilliseconds, maxBackoff.inMilliseconds)
            .round(),
      );
    }

    _inFlight!.complete();
    _inFlight = null;
    return false;
  }

  /// Resets the warm flag — call when the base URL changes (override dialog)
  /// so the next request triggers a fresh warmup against the new origin.
  void invalidate() {
    _isWarm = false;
  }
}
