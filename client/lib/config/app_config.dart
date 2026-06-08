import 'package:shared_preferences/shared_preferences.dart';

/// Build-time flag flipping the app into "beta" mode. Surfaces a small
/// BETA pill on the splash + home header so testers know they are on a
/// pre-release build. Flip to `false` for the stable launch.
const bool kIsBeta = true;

/// Human-readable version shown alongside the BETA pill. Keep in sync
/// with `version:` in pubspec.yaml — that's the source of truth at
/// build time; this constant is only for display.
const String kAppVersionLabel = '1.0.0-beta.1';

/// Holds the server base URL.
///
/// Resolution order (first match wins):
///   1. Runtime override saved in SharedPreferences (set from the in-app dialog)
///   2. Compile-time `--dart-define=BASE_URL=https://...` flag
///   3. Hardcoded fallback (the current Cloudflare tunnel URL)
///
/// Use `AppConfig.apiUrl` everywhere we used to use `kBaseUrl`, and
/// `AppConfig.socketUrl` for the Socket.IO connection.
class AppConfig {
  static const String _prefsKey = 'base_url_override';

  static const String _envBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue:
        // Production default for pushed builds → Render.
        // For local dev, use the in-app Server-URL dialog to override with a
        // tunnel/LAN URL (e.g. the current cloudflared https://...trycloudflare.com).
        'https://bayaaz-r9oe.onrender.com',
        
  );

  static String? _override;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _override = (saved != null && saved.isNotEmpty) ? saved : null;
    _initialized = true;
  }

  static String _strip(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    // If the user pasted an /api suffix, drop it so apiUrl/socketUrl stay consistent.
    if (u.endsWith('/api')) u = u.substring(0, u.length - 4);
    return u;
  }

  static String get baseUrl {
    final raw = (_override != null && _override!.isNotEmpty)
        ? _override!
        : _envBaseUrl;
    return _strip(raw);
  }

  static String get apiUrl => '$baseUrl/api';
  static String get socketUrl => baseUrl;

  static String get envBaseUrl => _strip(_envBaseUrl);
  static String? get override =>
      (_override != null && _override!.isNotEmpty) ? _strip(_override!) : null;
  static bool get isOverridden => override != null;

  /// Saves a new base URL. Pass `null` or empty to clear the override
  /// and fall back to the compile-time default.
  static Future<void> setBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = url?.trim() ?? '';
    if (clean.isEmpty) {
      await prefs.remove(_prefsKey);
      _override = null;
    } else {
      await prefs.setString(_prefsKey, clean);
      _override = clean;
    }
  }
}
