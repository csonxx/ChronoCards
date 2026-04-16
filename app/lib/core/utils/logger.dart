import 'package:flutter/foundation.dart';

/// Simple logger for ChronoCards
class GameLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[ChronoCards DEBUG] $message');
    }
  }

  static void info(String message) {
    debugPrint('[ChronoCards INFO] $message');
  }

  static void warning(String message) {
    debugPrint('[ChronoCards WARN] $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[ChronoCards ERROR] $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
