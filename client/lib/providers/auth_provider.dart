import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;

  // `serverClientId` MUST be the Google OAuth **Web** client ID (same value as
  // GOOGLE_WEB_CLIENT_ID on the server). Without it, idToken comes back null.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '484047874388-53lrv3vjscls2nfooiq1nb6a6l1a4b6v.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');
    if (token != null && userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.login(email, password);
      await _saveSession(data);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.register(name, email, password);
      await _saveSession(data);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Native Google Sign-In → verified server JWT. Returns false if the user
  /// cancels the Google sheet (not an error).
  Future<bool> googleSignIn() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _loading = false;
        notifyListeners();
        return false; // user dismissed the picker
      }
      final gAuth = await account.authentication;
      final idToken = gAuth.idToken;
      if (idToken == null) {
        throw Exception('No ID token from Google (check serverClientId / SHA-1)');
      }
      final data = await ApiService.googleLogin(idToken);
      await _saveSession(data);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(data['user']));
    _user = UserModel.fromJson(data['user']);
  }

  /// Persists name and/or avatar URL changes. Pass `clearAvatar: true` to
  /// drop the current avatar (the UI then falls back to the initial-letter
  /// circle).
  Future<bool> updateProfile({
    String? name,
    String? avatar,
    bool clearAvatar = false,
  }) async {
    try {
      final data = await ApiService.updateProfile(
        name: name,
        avatar: avatar,
        clearAvatar: clearAvatar,
      );
      final userJson = data['user'] as Map<String, dynamic>;
      _user = UserModel.fromJson(userJson);
      // Refresh the cached session so a cold start keeps the new avatar.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(userJson));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    // Clear the cached Google session too, so re-login shows the picker.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _user = null;
    notifyListeners();
  }
}
