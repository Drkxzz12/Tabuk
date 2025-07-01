// ===========================================
// lib/services/andriod_web_connectivity_service.dart
// ===========================================
// Provides connectivity check for web and mobile platforms.

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for checking online status on web and mobile.
class WebConnectivityService {
  /// Returns true if the device is online (web: browser, mobile: connectivity_plus).
  static Future<bool> isOnline() async {
    if (kIsWeb) {
      // Web: use browser's online status
      try {
        // ignore: undefined_prefixed_name, avoid_web_libraries_in_flutter
        return ("window" as dynamic).navigator.onLine ?? false;
      } catch (_) {
        return false;
      }
    } else {
      // Android/iOS/other: use connectivity_plus
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    }
  }
}
