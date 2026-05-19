import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Handles `bayaaz://i/<token>` invite deep links.
///
/// Two redemption paths:
///   - logged in  → call `redeemInvite` immediately and route to the group
///     (or to the active session for guest invites).
///   - logged out → stash the token in SharedPreferences under
///     `_kPendingTokenKey` and route to /login. After successful login,
///     `consumePendingToken()` is invoked from `_SplashRouter` to redeem.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const _kPendingTokenKey = 'pending_invite_token';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  GlobalKey<NavigatorState>? _navKey;
  bool _loggedInProbe = false;

  /// Initialize once after the app starts. [navigatorKey] is needed so we
  /// can navigate from outside a widget context when a link arrives. The
  /// [isLoggedIn] probe is called each time a link is processed so we can
  /// decide between immediate redeem and stashing.
  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    required bool Function() isLoggedIn,
  }) async {
    _navKey = navigatorKey;
    _loggedInProbe = true;
    _isLoggedIn = isLoggedIn;

    // Cold-launch link.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        // Defer so the first frame builds before we navigate.
        WidgetsBinding.instance.addPostFrameCallback((_) => _handle(initial));
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  late bool Function() _isLoggedIn = () => false;

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Called by `_SplashRouter` after a successful login. Redeems any token
  /// that was stashed while the user was logged out.
  Future<void> consumePendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kPendingTokenKey);
    if (token == null || token.isEmpty) return;
    await prefs.remove(_kPendingTokenKey);
    await _redeem(token);
  }

  Future<void> _handle(Uri uri) async {
    if (!_loggedInProbe) return;
    final token = _extractToken(uri);
    if (token == null) return;

    if (_isLoggedIn()) {
      await _redeem(token);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendingTokenKey, token);
      _navKey?.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  String? _extractToken(Uri uri) {
    // Accept bayaaz://i/<token> or https://bayaaz.app/i/<token>.
    if (uri.scheme != 'bayaaz' && uri.host != 'bayaaz.app') return null;
    final segments = uri.pathSegments;
    if (uri.scheme == 'bayaaz' && uri.host == 'i' && segments.isNotEmpty) {
      return segments.first;
    }
    if (segments.length >= 2 && segments[0] == 'i') {
      return segments[1];
    }
    return null;
  }

  Future<void> _redeem(String token) async {
    final nav = _navKey?.currentState;
    if (nav == null) return;
    // Capture the messenger up front so we don't reach into nav.context
    // after the async gap (lint use_build_context_synchronously).
    final messenger = ScaffoldMessenger.maybeOf(nav.context);
    try {
      final res = await ApiService.redeemInvite(token);
      if (res.type == 'guest' && res.activeSessionId != null) {
        nav.pushNamedAndRemoveUntil(
          '/group-teleprompter',
          (route) => route.settings.name == '/home',
          arguments: {
            'sessionId': res.activeSessionId,
            'groupId': res.groupId,
            'groupName': res.groupName,
            'asGuest': true,
          },
        );
        return;
      }
      // Permanent invite (or guest with no active session) → land on group detail.
      nav.pushNamedAndRemoveUntil(
        '/group',
        (route) => route.settings.name == '/home',
        arguments: {'groupId': res.groupId, 'groupName': res.groupName},
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Invite failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }
}
