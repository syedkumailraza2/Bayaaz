import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../models/lyric.dart';
import '../models/category.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  late Box<User> _userBox;
  late Box<Lyric> _lyricBox;
  late Box<Category> _categoryBox;
  late Box _settingsBox;
  late Box _syncBox;
  late SharedPreferences _prefs;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(UserStatsAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(UserSubscriptionAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(LyricAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(LyricAttachmentAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(LyricMetadataAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(LyricVersionAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(CategoryAdapter());
      }

      // Open boxes
      _userBox = await Hive.openBox<User>(AppConstants.userBox);
      _lyricBox = await Hive.openBox<Lyric>(AppConstants.lyricBox);
      _categoryBox = await Hive.openBox<Category>(AppConstants.categoryBox);
      _settingsBox = await Hive.openBox(AppConstants.settingsBox);
      _syncBox = await Hive.openBox(AppConstants.syncBox);

      // Initialize shared preferences
      _prefs = await SharedPreferences.getInstance();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize storage: $e');
    }
  }

  Future<void> close() async {
    if (!_isInitialized) return;

    await _userBox.close();
    await _lyricBox.close();
    await _categoryBox.close();
    await _settingsBox.close();
    await _syncBox.close();

    _isInitialized = false;
  }

  Future<void> clearAll() async {
    if (!_isInitialized) return;

    await _userBox.clear();
    await _lyricBox.clear();
    await _categoryBox.clear();
    await _settingsBox.clear();
    await _syncBox.clear();
    await _prefs.clear();
  }

  // User operations
  Future<User?> getCurrentUser() async {
    if (!_isInitialized) return null;

    try {
      final userJson = _prefs.getString(AppConstants.userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        return User.fromJson(userMap);
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
      await removeCurrentUser();
    }
    return null;
  }

  Future<void> saveCurrentUser(User user) async {
    if (!_isInitialized) return;

    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs.setString(AppConstants.userKey, userJson);
    } catch (e) {
      debugPrint('Error saving current user: $e');
    }
  }

  Future<void> removeCurrentUser() async {
    if (!_isInitialized) return;
    await _prefs.remove(AppConstants.userKey);
  }

  // Lyric operations
  Future<List<Lyric>> getAllLyrics() async {
    if (!_isInitialized) return [];
    return _lyricBox.values.toList();
  }

  Future<List<Lyric>> getLyricsByCategory(String categoryId) async {
    if (!_isInitialized) return [];
    return _lyricBox.values
        .where((lyric) => lyric.categoryId == categoryId)
        .toList();
  }

  Future<List<Lyric>> getFavoriteLyrics() async {
    if (!_isInitialized) return [];
    return _lyricBox.values.where((lyric) => lyric.isFavorite).toList();
  }

  Future<List<Lyric>> getPinnedLyrics() async {
    if (!_isInitialized) return [];
    return _lyricBox.values.where((lyric) => lyric.isPinned).toList();
  }

  Future<Lyric?> getLyricById(String id) async {
    if (!_isInitialized) return null;
    return _lyricBox.get(id);
  }

  Future<void> saveLyric(Lyric lyric) async {
    if (!_isInitialized) return;
    await _lyricBox.put(lyric.id ?? lyric.hashCode.toString(), lyric);
  }

  Future<void> saveLyrics(List<Lyric> lyrics) async {
    if (!_isInitialized) return;

    for (final lyric in lyrics) {
      await saveLyric(lyric);
    }
  }

  Future<void> deleteLyric(String id) async {
    if (!_isInitialized) return;
    await _lyricBox.delete(id);
  }

  Future<List<Lyric>> searchLyrics(String query) async {
    if (!_isInitialized) return [];

    final lowerQuery = query.toLowerCase();
    return _lyricBox.values.where((lyric) {
      return lyric.title.toLowerCase().contains(lowerQuery) ||
          lyric.poet.toLowerCase().contains(lowerQuery) ||
          lyric.plainText.toLowerCase().contains(lowerQuery) ||
          lyric.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Category operations
  Future<List<Category>> getAllCategories() async {
    if (!_isInitialized) return [];
    return _categoryBox.values.toList();
  }

  Future<Category?> getCategoryById(String id) async {
    if (!_isInitialized) return null;
    try {
      return _categoryBox.values.firstWhere(
        (category) => category.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveCategory(Category category) async {
    if (!_isInitialized) return;
    await _categoryBox.put(category.id ?? category.hashCode.toString(), category);
  }

  Future<void> saveCategories(List<Category> categories) async {
    if (!_isInitialized) return;

    for (final category in categories) {
      await saveCategory(category);
    }
  }

  Future<void> deleteCategory(String id) async {
    if (!_isInitialized) return;
    await _categoryBox.delete(id);
  }

  // Settings operations
  Future<String?> getToken() async {
    if (!_isInitialized) return null;
    return _prefs.getString(AppConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    if (!_isInitialized) return;
    await _prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> removeToken() async {
    if (!_isInitialized) return;
    await _prefs.remove(AppConstants.tokenKey);
  }

  Future<String> getTheme() async {
    if (!_isInitialized) return 'light';
    return _prefs.getString(AppConstants.themeKey) ?? 'light';
  }

  Future<void> setTheme(String theme) async {
    if (!_isInitialized) return;
    await _prefs.setString(AppConstants.themeKey, theme);
  }

  Future<double> getFontSize() async {
    if (!_isInitialized) return 16.0;
    return _prefs.getDouble(AppConstants.fontSizeKey) ?? 16.0;
  }

  Future<void> setFontSize(double fontSize) async {
    if (!_isInitialized) return;
    await _prefs.setDouble(AppConstants.fontSizeKey, fontSize);
  }

  // Sync operations
  Future<DateTime?> getLastSyncTime() async {
    if (!_isInitialized) return null;
    final timestamp = _prefs.getInt(AppConstants.lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    if (!_isInitialized) return;
    await _prefs.setInt(AppConstants.lastSyncKey, time.millisecondsSinceEpoch);
  }

  Future<void> markAllAsSynced() async {
    if (!_isInitialized) return;

    for (final lyric in _lyricBox.values) {
      lyric.isSynced = true;
      lyric.needsSync = false;
      lyric.lastSyncAt = DateTime.now();
      await lyric.save();
    }

    for (final category in _categoryBox.values) {
      category.isSynced = true;
      category.needsSync = false;
      category.lastSyncAt = DateTime.now();
      await category.save();
    }
  }

  Future<List<Lyric>> getUnsyncedLyrics() async {
    if (!_isInitialized) return [];
    return _lyricBox.values.where((lyric) => lyric.needsSync).toList();
  }

  Future<List<Category>> getUnsyncedCategories() async {
    if (!_isInitialized) return [];
    return _categoryBox.values.where((category) => category.needsSync).toList();
  }

  // Statistics
  Future<int> getTotalLyricsCount() async {
    if (!_isInitialized) return 0;
    return _lyricBox.length;
  }

  Future<int> getTotalCategoriesCount() async {
    if (!_isInitialized) return 0;
    return _categoryBox.length;
  }

  Future<int> getFavoritesCount() async {
    if (!_isInitialized) return 0;
    return _lyricBox.values.where((lyric) => lyric.isFavorite).length;
  }

  Future<Map<String, int>> getCategoryLyricsCount() async {
    if (!_isInitialized) return {};

    final Map<String, int> counts = {};
    for (final lyric in _lyricBox.values) {
      final categoryId = lyric.categoryId ?? 'uncategorized';
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }
    return counts;
  }

  // Backup and restore
  Future<Map<String, dynamic>> exportData() async {
    if (!_isInitialized) return {};

    return {
      'lyrics': _lyricBox.values.map((lyric) => lyric.toJson()).toList(),
      'categories': _categoryBox.values.map((category) => category.toJson()).toList(),
      'user': await getCurrentUser(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (!_isInitialized) return;

    // Clear existing data
    await _lyricBox.clear();
    await _categoryBox.clear();

    // Import categories
    if (data['categories'] != null) {
      final categoriesData = data['categories'] as List;
      for (final categoryData in categoriesData) {
        final category = Category.fromJson(categoryData);
        await saveCategory(category);
      }
    }

    // Import lyrics
    if (data['lyrics'] != null) {
      final lyricsData = data['lyrics'] as List;
      for (final lyricData in lyricsData) {
        final lyric = Lyric.fromJson(lyricData);
        await saveLyric(lyric);
      }
    }

    // Import user if available
    if (data['user'] != null) {
      final userData = data['user'];
      final user = User.fromJson(userData);
      await saveCurrentUser(user);
    }
  }
}