import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _onChange = StreamController<bool>.broadcast();
  Stream<bool> get onChange => _onChange.stream;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _apply(initial, notify: false);
    } catch (_) {
      // assume online if probe fails
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results, {bool notify = true}) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) return;
    _isOnline = online;
    if (notify) notifyListeners();
    if (!_onChange.isClosed) _onChange.add(online);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _onChange.close();
    super.dispose();
  }
}
