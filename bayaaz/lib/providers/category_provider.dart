import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final StorageService _storageService = StorageService.instance;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Statistics
  int get totalCategories => _categories.length;

  // Initialize and load categories
  Future<void> initialize() async {
    await loadCategories();
  }

  // Load categories from storage and/or API
  Future<void> loadCategories({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      // First, load from local storage
      await _loadCategoriesFromStorage();

      // If no local categories or force refresh, sync with API
      if (_categories.isEmpty || forceRefresh) {
        await _syncCategoriesWithApi();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      notifyListeners();
    }
  }

  // Load categories from local storage
  Future<void> _loadCategoriesFromStorage() async {
    final categories = await _storageService.getAllCategories();
    _categories = categories.cast<Category>();

    // If no categories exist, create default ones
    if (_categories.isEmpty) {
      await _createDefaultCategories();
    }
  }

  // Create default categories
  Future<void> _createDefaultCategories() async {
    final defaultCategories = AppConstants.defaultCategories.map((cat) {
      return Category(
        name: cat['name'],
        color: cat['color'],
        icon: cat['icon'],
        isDefault: true,
        order: _categories.length,
        createdAt: DateTime.now(),
      );
    }).toList();

    for (final category in defaultCategories) {
      await _storageService.saveCategory(category);
    }

    _categories = defaultCategories;
  }

  // Sync categories with API
  Future<void> _syncCategoriesWithApi() async {
    if (!_apiService.isAuthenticated) return;

    try {
      final apiCategories = await _apiService.getCategories();

      // Update local storage with server data
      await _mergeServerCategories(apiCategories);
    } catch (e) {
      debugPrint('Category sync failed: $e');
      // Don't throw error, continue with local data
    }
  }

  // Merge server categories with local data
  Future<void> _mergeServerCategories(List<Category> serverCategories) async {
    for (final serverCategory in serverCategories) {
      final localIndex = _categories.indexWhere(
        (category) => category.id == serverCategory.id,
      );

      if (localIndex >= 0) {
        // Update existing category if server version is newer
        final localCategory = _categories[localIndex];
        if (serverCategory.updatedAt!.isAfter(localCategory.updatedAt ?? DateTime(0))) {
          _categories[localIndex] = serverCategory;
          await _storageService.saveCategory(serverCategory);
        }
      } else {
        // Add new category
        _categories.add(serverCategory);
        await _storageService.saveCategory(serverCategory);
      }
    }

    // Upload unsynced local categories
    await _uploadUnsyncedCategories();
  }

  // Upload unsynced categories to server
  Future<void> _uploadUnsyncedCategories() async {
    if (!_apiService.isAuthenticated) return;

    final unsyncedCategories = await _storageService.getUnsyncedCategories();

    for (final category in unsyncedCategories) {
      try {
        if (category.id == null || category.id!.startsWith('local_')) {
          // Create new category
          final createdCategory = await _apiService.createCategory(
            name: category.name,
            description: category.description.isNotEmpty ? category.description : null,
            color: category.color,
            icon: category.icon,
          );

          // Update local category with server ID
          final index = _categories.indexWhere((c) => c == category);
          if (index >= 0) {
            _categories[index] = createdCategory;
            await _storageService.saveCategory(createdCategory);
          }
        } else {
          // Update existing category (not implemented in API yet)
          debugPrint('Category update not implemented in API');
        }
      } catch (e) {
        debugPrint('Failed to sync category ${category.id}: $e');
      }
    }
  }

  // Create new category
  Future<bool> createCategory({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate name uniqueness
      if (_categories.any((cat) => cat.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Category with this name already exists');
      }

      final category = Category(
        name: name,
        description: description ?? '',
        color: color ?? '#6366f1',
        icon: icon ?? 'folder',
        isDefault: false,
        order: _categories.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await _storageService.saveCategory(category);
      _categories.add(category);

      // Try to sync with API
      if (_apiService.isAuthenticated) {
        try {
          final createdCategory = await _apiService.createCategory(
            name: category.name,
            description: category.description.isNotEmpty ? category.description : null,
            color: category.color,
            icon: category.icon,
          );

          // Update local category with server data
          final index = _categories.indexWhere((c) => c == category);
          if (index >= 0) {
            _categories[index] = createdCategory;
            await _storageService.saveCategory(createdCategory);
          }
        } catch (e) {
          // Keep local copy if sync fails
          debugPrint('Failed to sync new category: $e');
        }
      }

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

  // Update category
  Future<bool> updateCategory(String id, {
    String? name,
    String? description,
    String? color,
    String? icon,
    int? order,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final index = _categories.indexWhere((category) => category.id == id);
      if (index < 0) {
        throw Exception('Category not found');
      }

      final category = _categories[index];

      // Check if it's a default category
      if (category.isDefault) {
        throw Exception('Cannot edit default categories');
      }

      // Validate name uniqueness if name is being changed
      if (name != null && name.toLowerCase() != category.name.toLowerCase()) {
        if (_categories.any((cat) =>
            cat.id != id && cat.name.toLowerCase() == name.toLowerCase())) {
          throw Exception('Category with this name already exists');
        }
      }

      final updatedCategory = category.copyWith(
        name: name,
        description: description,
        color: color,
        icon: icon,
        order: order,
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await _storageService.saveCategory(updatedCategory);
      _categories[index] = updatedCategory;

      // Try to sync with API (not implemented yet)
      if (_apiService.isAuthenticated) {
        try {
          await _apiService.updateCategory(id, updatedCategory.toJson());
        } catch (e) {
          // Keep local copy if sync fails
          debugPrint('Failed to sync category update: $e');
        }
      }

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

  // Delete category
  Future<bool> deleteCategory(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final category = _categories.firstWhere((cat) => cat.id == id);

      // Check if it's a default category
      if (category.isDefault) {
        throw Exception('Cannot delete default categories');
      }

      // Check if category has lyrics (this would need to be checked with LyricProvider)
      // For now, we'll assume it can be deleted

      // Delete from API first if online
      if (_apiService.isAuthenticated) {
        await _apiService.deleteCategory(id);
      }

      // Delete from local storage
      await _storageService.deleteCategory(id);
      _categories.removeWhere((cat) => cat.id == id);

      // Reorder remaining categories
      for (int i = 0; i < _categories.length; i++) {
        if (_categories[i].order != i) {
          _categories[i] = _categories[i].copyWith(order: i);
          await _storageService.saveCategory(_categories[i]);
        }
      }

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

  // Reorder categories
  Future<bool> reorderCategories(List<Category> reorderedCategories) async {
    _setLoading(true);
    _clearError();

    try {
      // Update local categories
      for (int i = 0; i < reorderedCategories.length; i++) {
        final category = reorderedCategories[i];
        final index = _categories.indexWhere((cat) => cat.id == category.id);
        if (index >= 0) {
          _categories[index] = _categories[index].copyWith(order: i);
          await _storageService.saveCategory(_categories[index]);
        }
      }

      // Sort categories by order
      _categories.sort((a, b) => a.order.compareTo(b.order));

      // Try to sync with API (not implemented yet)
      if (_apiService.isAuthenticated) {
        try {
          // This would need to be implemented in the API
          debugPrint('Category reordering not implemented in API');
        } catch (e) {
          debugPrint('Failed to sync category reordering: $e');
        }
      }

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

  // Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get default categories
  List<Category> get defaultCategories {
    return _categories.where((category) => category.isDefault).toList();
  }

  // Get custom categories
  List<Category> get customCategories {
    return _categories.where((category) => !category.isDefault).toList();
  }

  // Get categories sorted by order
  List<Category> get sortedCategories {
    final sorted = List<Category>.from(_categories);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  // Search categories
  List<Category> searchCategories(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _categories.where((category) {
      return category.name.toLowerCase().contains(lowerQuery) ||
          (category.description.isNotEmpty &&
           category.description.toLowerCase().contains(lowerQuery));
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
    debugPrint('CategoryProvider Error: $error');
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
        return 'Category not found';
      }
      if (message.contains('already exists')) {
        return 'Category with this name already exists';
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