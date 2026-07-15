import 'package:flutter/foundation.dart';

import '../error/failure.dart';
import 'crash_reporter.dart';

/// No-op [CrashReporter], used when there is no `SENTRY_DSN` (dev without a
/// Sentry project). Prints to console in debug so visibility is not lost; does
/// nothing in release.
final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> init() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[CrashReporter:noop] ${context ?? ''} $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> recordFailure(Failure failure, {String? context}) async {
    if (kDebugMode) {
      debugPrint('[CrashReporter:noop] failure ${context ?? ''} $failure');
    }
  }

  @override
  void log(String message, {String? category}) {
    if (kDebugMode) debugPrint('[CrashReporter:noop] $message');
  }

  @override
  Future<void> setUser(String id) async {}

  @override
  Future<void> clearUser() async {}
}
