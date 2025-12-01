import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final StorageService _storageService = StorageService.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasPremiumAccess => _user?.subscription?.isPremium ?? false;
  bool get isSubscriptionActive => _user?.subscription?.isActive ?? false;

  String get displayName => _user?.profile?.fullName?.isNotEmpty == true
      ? _user!.profile!.fullName
      : _user?.username ?? 'User';

  String get avatarUrl => _user?.profile?.avatar ?? '';
  String get userEmail => _user?.email ?? '';

  // Preference getters
  String get themePreference => _user?.preferences?.theme ?? 'system';
  double get fontSizePreference => _user?.preferences?.fontSize?.toDouble() ?? 16.0;
  bool get notificationsPreference => _user?.preferences?.notifications ?? true;
  bool get autoSyncPreference => _user?.preferences?.autoSync ?? true;

  // Initialize auth provider
  Future<void> initialize() async {
    await _authService.initialize();
    _user = _authService.currentUser;
    notifyListeners();
  }

  // Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _validateEmail(email);
      _validatePassword(password);
      _validateUsername(username);

      final user = await _authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      _user = user;
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

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _validateEmail(email);

      final user = await _authService.login(
        email: email,
        password: password,
      );

      _user = user;
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

  // Social login methods (placeholder)
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.loginWithGoogle();
      _user = user;
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

  Future<bool> loginWithFacebook() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.loginWithFacebook();
      _user = user;
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

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
      _user = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        bio: bio,
      );

      _user = user;
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

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _validatePassword(newPassword);

      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

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

  // Update preferences
  Future<bool> updatePreferences({
    String? theme,
    double? fontSize,
    bool? autoSync,
    bool? notifications,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updatePreferences(
        theme: theme,
        fontSize: fontSize,
        autoSync: autoSync,
        notifications: notifications,
      );

      // Refresh user data to get updated preferences
      await refreshUserData();

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

  // Refresh user data
  Future<bool> refreshUserData() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.refreshUserData();
      _user = user;
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

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      _validateEmail(email);

      await _authService.resetPassword(email);
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

  // Delete account
  Future<bool> deleteAccount({
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.deleteAccount(password: password);
      _user = null;
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

  // Check session validity
  Future<bool> checkSessionValidity() async {
    if (_user == null) return false;

    try {
      final isValid = await _authService.validateToken();
      if (!isValid) {
        _user = null;
        notifyListeners();
      }
      return isValid;
    } catch (e) {
      _user = null;
      notifyListeners();
      return false;
    }
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
    debugPrint('AuthProvider Error: $error');
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Validation methods
  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw Exception('Email is required');
    }
    if (!RegExp(AppConstants.emailPattern).hasMatch(email)) {
      throw Exception('Please enter a valid email address');
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw Exception('Password is required');
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw Exception('Password must be at least ${AppConstants.minPasswordLength} characters');
    }
    if (!RegExp(AppConstants.passwordPattern).hasMatch(password)) {
      throw Exception('Password must contain uppercase, lowercase, and number');
    }
  }

  void _validateUsername(String username) {
    if (username.isEmpty) {
      throw Exception('Username is required');
    }
    if (username.length < 3) {
      throw Exception('Username must be at least 3 characters');
    }
    if (username.length > 30) {
      throw Exception('Username cannot exceed 30 characters');
    }
    if (!RegExp(AppConstants.usernamePattern).hasMatch(username)) {
      throw Exception('Username can only contain letters, numbers, and underscores');
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();

      // Common API error patterns
      if (message.contains('Email already exists')) {
        return 'An account with this email already exists';
      }
      if (message.contains('Username already exists')) {
        return 'This username is already taken';
      }
      if (message.contains('Invalid email or password')) {
        return 'Invalid email or password';
      }
      if (message.contains('User not found')) {
        return 'Account not found';
      }
      if (message.contains('Network')) {
        return AppConstants.networkErrorMessage;
      }
      if (message.contains('Timeout')) {
        return 'Request timed out. Please try again';
      }

      return message.replaceFirst('Exception: ', '');
    }
    return AppConstants.genericErrorMessage;
  }

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
}