import 'package:flutter/foundation.dart';
import '../models/lyric.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class LyricProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final StorageService _storageService = StorageService.instance;

  List<Lyric> _lyrics = [];
  List<Lyric> _filteredLyrics = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _sortBy;
  bool? _isFavorite;
  bool? _isPinned;

  // Getters
  List<Lyric> get lyrics => _filteredLyrics;
  List<Lyric> get allLyrics => _lyrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get sortBy => _sortBy;
  bool? get isFavoriteFilter => _isFavorite;
  bool? get isPinnedFilter => _isPinned;

  // Statistics
  int get totalLyrics => _lyrics.length;
  int get favoriteLyrics => _lyrics.where((lyric) => lyric.isFavorite).length;
  int get pinnedLyrics => _lyrics.where((lyric) => lyric.isPinned).length;

  // Initialize and load lyrics
  Future<void> initialize() async {
    await loadLyrics();
  }

  // Load lyrics from storage and/or API
  Future<void> loadLyrics({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      // First, load from local storage
      await _loadLyricsFromStorage();

      // If online and force refresh, sync with API
      if (forceRefresh && _apiService.isAuthenticated) {
        await _syncLyricsWithApi();
      }

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      notifyListeners();
    }
  }

  // Load lyrics from local storage
  Future<void> _loadLyricsFromStorage() async {
    _lyrics = await _storageService.getAllLyrics();
  }

  // Sync lyrics with API
  Future<void> _syncLyricsWithApi() async {
    if (!_apiService.isAuthenticated) return;

    try {
      // Get last sync time
      final lastSyncTime = await _storageService.getLastSyncTime();

      // Get server data
      final syncData = await _apiService.syncData(lastSyncTime: lastSyncTime);

      if (syncData['lyrics'] != null) {
        final serverLyrics = (syncData['lyrics'] as List)
            .map((json) => Lyric.fromJson(json))
            .toList();

        // Update local storage with server data
        await _mergeServerLyrics(serverLyrics);
      }

      // Update last sync time
      await _storageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('Sync failed: $e');
      // Don't throw error, continue with local data
    }
  }

  // Merge server lyrics with local data
  Future<void> _mergeServerLyrics(List<Lyric> serverLyrics) async {
    for (final serverLyric in serverLyrics) {
      final localIndex = _lyrics.indexWhere(
        (lyric) => lyric.id == serverLyric.id,
      );

      if (localIndex >= 0) {
        // Update existing lyric if server version is newer
        final localLyric = _lyrics[localIndex];
        if (serverLyric.updatedAt!.isAfter(localLyric.updatedAt ?? DateTime(0))) {
          _lyrics[localIndex] = serverLyric;
          await _storageService.saveLyric(serverLyric);
        }
      } else {
        // Add new lyric
        _lyrics.add(serverLyric);
        await _storageService.saveLyric(serverLyric);
      }
    }

    // Upload unsynced local lyrics
    await _uploadUnsyncedLyrics();
  }

  // Upload unsynced lyrics to server
  Future<void> _uploadUnsyncedLyrics() async {
    if (!_apiService.isAuthenticated) return;

    final unsyncedLyrics = await _storageService.getUnsyncedLyrics();

    for (final lyric in unsyncedLyrics) {
      try {
        if (lyric.id == null || lyric.id!.startsWith('local_')) {
          // Create new lyric
          final createdLyric = await _apiService.createLyric(
            title: lyric.title,
            content: lyric.content,
            categoryId: lyric.categoryId!,
            poet: lyric.poet.isNotEmpty ? lyric.poet : null,
            year: lyric.year,
            tags: lyric.tags.isNotEmpty ? lyric.tags : null,
            language: lyric.language,
          );

          // Update local lyric with server ID
          final index = _lyrics.indexWhere((l) => l == lyric);
          if (index >= 0) {
            _lyrics[index] = createdLyric;
            await _storageService.saveLyric(createdLyric);
          }
        } else {
          // Update existing lyric
          await _apiService.updateLyric(lyric.id!, lyric.toJson());
          lyric.isSynced = true;
          lyric.needsSync = false;
          await _storageService.saveLyric(lyric);
        }
      } catch (e) {
        debugPrint('Failed to sync lyric ${lyric.id}: $e');
      }
    }
  }

  // Create new lyric
  Future<bool> createLyric({
    required String title,
    required String content,
    required String categoryId,
    String? poet,
    int? year,
    List<String>? tags,
    String? language,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final lyric = Lyric(
        title: title,
        content: content,
        plainText: content.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
        categoryId: categoryId,
        poet: poet ?? '',
        year: year,
        tags: tags ?? [],
        language: language ?? 'urdu',
        userId: _apiService.authToken, // This should be the user ID
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await _storageService.saveLyric(lyric);
      _lyrics.add(lyric);

      // Try to sync with API
      if (_apiService.isAuthenticated) {
        try {
          final createdLyric = await _apiService.createLyric(
            title: lyric.title,
            content: lyric.content,
            categoryId: lyric.categoryId!,
            poet: lyric.poet.isNotEmpty ? lyric.poet : null,
            year: lyric.year,
            tags: lyric.tags.isNotEmpty ? lyric.tags : null,
            language: lyric.language,
          );

          // Update local lyric with server data
          final index = _lyrics.indexWhere((l) => l == lyric);
          if (index >= 0) {
            _lyrics[index] = createdLyric;
            await _storageService.saveLyric(createdLyric);
          }
        } catch (e) {
          // Keep local copy if sync fails
          debugPrint('Failed to sync new lyric: $e');
        }
      }

      _applyFilters();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update lyric
  Future<bool> updateLyric(String id, Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      final index = _lyrics.indexWhere((lyric) => lyric.id == id);
      if (index < 0) {
        throw Exception('Lyric not found');
      }

          final updatedLyric = _lyrics[index].copyWith(
        id: updates['id'],
        title: updates['title'],
        poet: updates['poet'],
        year: updates['year'],
        content: updates['content'],
        plainText: updates['plainText'],
        userId: updates['userId'],
        categoryId: updates['categoryId'],
        category: updates['category'],
        tags: updates['tags'],
        language: updates['language'],
        attachments: updates['attachments'],
        metadata: updates['metadata'],
        status: updates['status'],
        visibility: updates['visibility'],
        isFavorite: updates['isFavorite'],
        isPinned: updates['isPinned'],
        isLocked: updates['isLocked'],
        viewCount: updates['viewCount'],
        versions: updates['versions'],
        lastViewedAt: updates['lastViewedAt'],
        order: updates['order'],
        createdAt: updates['createdAt'],
        updatedAt: DateTime.now(),
        isSynced: updates['isSynced'],
        lastSyncAt: updates['lastSyncAt'],
        needsSync: updates['needsSync'],
      );

      // Update content and plain text if content changed
      if (updates.containsKey('content')) {
        updatedLyric.plainText =
            updates['content'].replaceAll(RegExp(r'<[^>]*>'), '').trim();
      }

      // Save locally first
      await _storageService.saveLyric(updatedLyric);
      _lyrics[index] = updatedLyric;

      // Try to sync with API
      if (_apiService.isAuthenticated) {
        try {
          final serverLyric = await _apiService.updateLyric(id, updates);
          _lyrics[index] = serverLyric;
          await _storageService.saveLyric(serverLyric);
        } catch (e) {
          // Keep local copy if sync fails
          debugPrint('Failed to sync lyric update: $e');
        }
      }

      _applyFilters();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete lyric
  Future<bool> deleteLyric(String id, {String? pin}) async {
    _setLoading(true);
    _clearError();

    try {
      // Delete from API first if online
      if (_apiService.isAuthenticated) {
        await _apiService.deleteLyric(id, pin: pin);
      }

      // Delete from local storage
      await _storageService.deleteLyric(id);
      _lyrics.removeWhere((lyric) => lyric.id == id);

      _applyFilters();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String id) async {
    try {
      final index = _lyrics.indexWhere((lyric) => lyric.id == id);
      if (index < 0) return false;

      final lyric = _lyrics[index];
      final updatedLyric = lyric.copyWith(
        isFavorite: !lyric.isFavorite,
        updatedAt: DateTime.now(),
      );

      _lyrics[index] = updatedLyric;
      await _storageService.saveLyric(updatedLyric);

      // Try to sync with API
      if (_apiService.isAuthenticated) {
        try {
          await _apiService.toggleFavorite(id);
        } catch (e) {
          debugPrint('Failed to sync favorite toggle: $e');
        }
      }

      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      notifyListeners();
      return false;
    }
  }

  // Toggle pin
  Future<bool> togglePin(String id) async {
    try {
      final index = _lyrics.indexWhere((lyric) => lyric.id == id);
      if (index < 0) return false;

      final lyric = _lyrics[index];
      final updatedLyric = lyric.copyWith(
        isPinned: !lyric.isPinned,
        updatedAt: DateTime.now(),
      );

      _lyrics[index] = updatedLyric;
      await _storageService.saveLyric(updatedLyric);

      // Try to sync with API
      if (_apiService.isAuthenticated) {
        try {
          await _apiService.togglePin(id);
        } catch (e) {
          debugPrint('Failed to sync pin toggle: $e');
        }
      }

      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      notifyListeners();
      return false;
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(String? sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  void setFavoriteFilter(bool? isFavorite) {
    _isFavorite = isFavorite;
    _applyFilters();
    notifyListeners();
  }

  void setPinFilter(bool? isPinned) {
    _isPinned = isPinned;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _sortBy = null;
    _isFavorite = null;
    _isPinned = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters and sorting
  void _applyFilters() {
    _filteredLyrics = List.from(_lyrics);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredLyrics = _filteredLyrics.where((lyric) {
        return lyric.title.toLowerCase().contains(query) ||
            lyric.poet.toLowerCase().contains(query) ||
            lyric.plainText.toLowerCase().contains(query) ||
            lyric.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      _filteredLyrics = _filteredLyrics
          .where((lyric) => lyric.categoryId == _selectedCategoryId)
          .toList();
    }

    // Apply favorite filter
    if (_isFavorite != null) {
      _filteredLyrics = _filteredLyrics
          .where((lyric) => lyric.isFavorite == _isFavorite)
          .toList();
    }

    // Apply pin filter
    if (_isPinned != null) {
      _filteredLyrics = _filteredLyrics
          .where((lyric) => lyric.isPinned == _isPinned)
          .toList();
    }

    // Apply sorting
    _applySorting();
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'title':
        _filteredLyrics.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'poet':
        _filteredLyrics.sort((a, b) => a.poet.compareTo(b.poet));
        break;
      case 'year':
        _filteredLyrics.sort((a, b) {
          if (a.year == null && b.year == null) return 0;
          if (a.year == null) return 1;
          if (b.year == null) return -1;
          return b.year!.compareTo(a.year!);
        });
        break;
      case 'views':
        _filteredLyrics.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'recent':
      default:
        _filteredLyrics.sort((a, b) {
          // Pinned items first
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;

          // Then by updated date
          final aTime = a.updatedAt ?? a.createdAt ?? DateTime(0);
          final bTime = b.updatedAt ?? b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
        break;
    }
  }

  // Get lyrics by category
  List<Lyric> getLyricsByCategory(String categoryId) {
    return _lyrics.where((lyric) => lyric.categoryId == categoryId).toList();
  }

  // Get favorite lyrics
  List<Lyric> getFavoriteLyrics() {
    return _lyrics.where((lyric) => lyric.isFavorite).toList();
  }

  // Get pinned lyrics
  List<Lyric> getPinnedLyrics() {
    return _lyrics.where((lyric) => lyric.isPinned).toList();
  }

  // Get recent lyrics
  List<Lyric> getRecentLyrics({int limit = 10}) {
    final recentLyrics = List.from(_lyrics);
    recentLyrics.sort((a, b) {
      final aTime = a.lastViewedAt ?? a.updatedAt ?? a.createdAt ?? DateTime(0);
      final bTime = b.lastViewedAt ?? b.updatedAt ?? b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    return recentLyrics.take(limit).cast<Lyric>().toList();
  }

  // Get lyric by ID
  Lyric? getLyricById(String id) {
    try {
      return _lyrics.firstWhere((lyric) => lyric.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search lyrics
  List<Lyric> searchLyrics(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _lyrics.where((lyric) {
      return lyric.title.toLowerCase().contains(lowerQuery) ||
          lyric.poet.toLowerCase().contains(lowerQuery) ||
          lyric.plainText.toLowerCase().contains(lowerQuery) ||
          lyric.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _errorMessage = error;
    debugPrint('LyricProvider Error: $error');
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();

      // Common API error patterns
      if (message.contains('Network')) {
        return AppConstants.networkErrorMessage;
      }
      if (message.contains('Timeout')) {
        return 'Request timed out. Please try again';
      }
      if (message.contains('not found')) {
        return 'Lyric not found';
      }
      if (message.contains('Unauthorized')) {
        return 'Please login to continue';
      }

      return message.replaceFirst('Exception: ', '');
    }
    return AppConstants.genericErrorMessage;
  }

  @override
  void dispose() {
    super.dispose();
  }
}