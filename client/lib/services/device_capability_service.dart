import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

enum DeviceTier {
  // RAM < 3 GB or SDK < 29 (Android 10)
  low,
  // RAM 3–5 GB
  mid,
  // RAM >= 6 GB and SDK >= 31 (Android 12) / iOS 15+
  high,
}

class DeviceCapabilityService {
  static final DeviceCapabilityService instance = DeviceCapabilityService._();
  DeviceCapabilityService._();

  DeviceTier _tier = DeviceTier.mid;
  bool _detected = false;

  DeviceTier get tier => _tier;

  Future<DeviceTier> detectTier() async {
    if (_detected) return _tier;
    _detected = true;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        final sdkInt = android.version.sdkInt;
        // totalMemory is in bytes on some versions, not always reliable.
        // Use SDK level as the primary signal on Android.
        if (sdkInt < 29) {
          _tier = DeviceTier.low;
        } else if (sdkInt >= 31) {
          _tier = DeviceTier.high;
        } else {
          _tier = DeviceTier.mid;
        }
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        // systemVersion is e.g. "17.4"; compare major version.
        final major =
            int.tryParse(ios.systemVersion.split('.').first) ?? 0;
        if (major >= 15) {
          _tier = DeviceTier.high;
        } else if (major >= 13) {
          _tier = DeviceTier.mid;
        } else {
          _tier = DeviceTier.low;
        }
      }
    } catch (e) {
      debugPrint('[DeviceCap] Detection failed: $e');
      _tier = DeviceTier.mid;
    }
    return _tier;
  }
}
