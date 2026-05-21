import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the app's light/dark mode preference and persists it across launches.
/// The home screen's sun/moon toggle flips [isDark]; widgets that need to
/// adapt should read `Theme.of(context).brightness` rather than this provider
/// directly, so they stay portable.
class ThemeProvider extends ChangeNotifier {
  static const _kPrefsKey = 'theme.isDark';

  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_kPrefsKey);
    if (stored != null && stored != _isDark) {
      _isDark = stored;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsKey, _isDark);
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsKey, _isDark);
  }
}
