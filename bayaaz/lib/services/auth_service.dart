import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final ApiService _apiService = ApiService.instance;
  final StorageService _storageService = StorageService.instance;

  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null && _apiService.isAuthenticated;

  // Initialize auth service
  Future<void> initialize() async {
    try {
      // Try to get stored token and user
      final token = await _storageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);

        final user = await _storageService.getCurrentUser();
        if (user != null) {
          _currentUser = user;

          // Verify token is still valid by fetching current user profile
          try {
            final freshUser = await _apiService.getProfile()
                .timeout(const Duration(seconds: 5));
            _currentUser = freshUser;
            await _storageService.saveCurrentUser(freshUser);
          } catch (e) {
            // Token is invalid or network error, clear storage
            await logout();
            debugPrint('Token validation failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
      await logout();
    }
  }

  // Register new user
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final user = await _apiService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      _currentUser = user;
      await _storageService.saveCurrentUser(user);
      await _storageService.saveToken(_apiService.authToken!);

      debugPrint('User registered successfully: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    }
  }

  // Login user
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _apiService.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      await _storageService.saveCurrentUser(user);
      await _storageService.saveToken(_apiService.authToken!);

      debugPrint('User logged in successfully: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  // Login with social providers (placeholder for future implementation)
  Future<User> loginWithGoogle() async {
    throw UnimplementedError('Google login not implemented yet');
  }

  Future<User> loginWithFacebook() async {
    throw UnimplementedError('Facebook login not implemented yet');
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    } finally {
      _currentUser = null;
      debugPrint('User logged out');
    }
  }

  // Update user profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
  }) async {
    try {
      final user = await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        bio: bio,
      );

      _currentUser = user;
      await _storageService.saveCurrentUser(user);

      debugPrint('Profile updated successfully');
      return user;
    } catch (e) {
      debugPrint('Profile update failed: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      debugPrint('Password changed successfully');
    } catch (e) {
      debugPrint('Password change failed: $e');
      rethrow;
    }
  }

  // Change email
  Future<User> changeEmail({
    required String email,
    required String password,
  }) async {
    try {
      // This would need to be implemented in the API
      throw UnimplementedError('Email change not implemented yet');
    } catch (e) {
      debugPrint('Email change failed: $e');
      rethrow;
    }
  }

  // Update user preferences
  Future<void> updatePreferences({
    String? theme,
    double? fontSize,
    bool? autoSync,
    bool? notifications,
  }) async {
    try {
      final updatedUser = _currentUser?.copyWith(
        profile: _currentUser?.profile,
        preferences: _currentUser?.preferences?.copyWith(
          theme: theme,
          fontSize: fontSize?.toInt(),
          autoSync: autoSync,
          notifications: notifications,
        ),
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
        await _storageService.saveCurrentUser(updatedUser);
      }

      // Also update in storage service for immediate effect
      if (theme != null) {
        await _storageService.setTheme(theme);
      }
      if (fontSize != null) {
        await _storageService.setFontSize(fontSize);
      }

      debugPrint('Preferences updated successfully');
    } catch (e) {
      debugPrint('Preferences update failed: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount({
    required String password,
  }) async {
    try {
      // This would need to be implemented in the API
      throw UnimplementedError('Account deletion not implemented yet');
    } catch (e) {
      debugPrint('Account deletion failed: $e');
      rethrow;
    }
  }

  // Refresh user data
  Future<User> refreshUserData() async {
    try {
      final user = await _apiService.getProfile();
      _currentUser = user;
      await _storageService.saveCurrentUser(user);

      debugPrint('User data refreshed');
      return user;
    } catch (e) {
      debugPrint('User data refresh failed: $e');
      rethrow;
    }
  }

  // Validate token
  Future<bool> validateToken() async {
    try {
      if (_currentUser == null || _apiService.authToken == null) {
        return false;
      }

      await _apiService.getProfile();
      return true;
    } catch (e) {
      debugPrint('Token validation failed: $e');
      return false;
    }
  }

  // Reset password (placeholder for future implementation)
  Future<void> resetPassword(String email) async {
    try {
      throw UnimplementedError('Password reset not implemented yet');
    } catch (e) {
      debugPrint('Password reset failed: $e');
      rethrow;
    }
  }

  // Verify email (placeholder for future implementation)
  Future<void> verifyEmail(String token) async {
    try {
      throw UnimplementedError('Email verification not implemented yet');
    } catch (e) {
      debugPrint('Email verification failed: $e');
      rethrow;
    }
  }

  // Check if user has premium features
  bool get hasPremiumAccess {
    return _currentUser?.subscription?.isPremium ?? false;
  }

  // Check if user subscription is active
  bool get isSubscriptionActive {
    return _currentUser?.subscription?.isActive ?? false;
  }

  // Get user display name
  String get displayName {
    if (_currentUser?.profile?.fullName?.isNotEmpty == true) {
      return _currentUser!.profile!.fullName;
    }
    return _currentUser?.username ?? 'User';
  }

  // Get user avatar
  String get avatarUrl {
    return _currentUser?.profile?.avatar ?? '';
  }

  // Get user email
  String get userEmail {
    return _currentUser?.email ?? '';
  }

  // Get user theme preference
  String get themePreference {
    return _currentUser?.preferences?.theme ?? 'light';
  }

  // Get user font size preference
  double get fontSizePreference {
    return (_currentUser?.preferences?.fontSize ?? 16).toDouble();
  }

  // Get auto sync preference
  bool get autoSyncPreference {
    return _currentUser?.preferences?.autoSync ?? true;
  }

  // Get notifications preference
  bool get notificationsPreference {
    return _currentUser?.preferences?.notifications ?? true;
  }

  // Stream for authentication state changes (can be implemented with ChangeNotifier)
  static final ValueNotifier<bool> _authStateNotifier = ValueNotifier(false);
  static ValueNotifier<bool> get authStateNotifier => _authStateNotifier;

  void _notifyAuthStateChange() {
    _authStateNotifier.value = isAuthenticated;
  }
}