import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';
import '../error/failure.dart';
import 'crash_reporter.dart';

/// Sentry-backed [CrashReporter]. Only instantiated when `Env.hasSentryDsn` is
/// true. Sentry initialization (which wraps `runApp`) is done by the bootstrap
/// calling [init].
final class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter();

  @override
  Future<void> init() async {
    // The bootstrap already wraps runApp with SentryFlutter.init, so we do not
    // re-initialize here. This hook stays in case scope setup is ever needed.
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      // withScope is synchronous, so the setContexts future cannot be awaited
      // here; Sentry applies it to the scope before the event is sent.
      // setContexts returns FutureOr<void> (not a guaranteed Future), so it
      // is not `unawaited`-able — its synchronous half already ran by the
      // time this closure returns.
      withScope: (scope) {
        scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
        if (context != null) {
          // Neither `await` (withScope is a sync callback) nor `unawaited`
          // (the return type is FutureOr<void>, not a guaranteed Future)
          // applies here; deliberately fire-and-forget.
          // ignore: discarded_futures
          scope.setContexts('origin', {'detail': context});
        }
      },
    );
  }

  @override
  Future<void> recordFailure(Failure failure, {String? context}) async {
    await Sentry.captureException(
      failure.cause ?? failure,
      stackTrace: failure.stackTrace,
      withScope: (scope) {
        // ignore: discarded_futures
        scope.setContexts('failure', {
          'type': failure.runtimeType.toString(),
          'message': failure.message,
          if (context != null) 'origin': context,
        });
      },
    );
  }

  @override
  void log(String message, {String? category}) {
    // A breadcrumb is fire-and-forget: the CrashReporter contract is sync and
    // losing one must never block or fail the caller.
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(message: message, category: category),
      ),
    );
  }

  @override
  Future<void> setUser(String id) async {
    await Sentry.configureScope((scope) => scope.setUser(SentryUser(id: id)));
  }

  @override
  Future<void> clearUser() async {
    await Sentry.configureScope((scope) => scope.setUser(null));
  }
}

/// Shared Sentry configuration used by the bootstrap when wrapping `runApp`
/// with `SentryFlutter.init`.
void applySentryOptions(SentryFlutterOptions options) {
  options
    ..dsn = Env.sentryDsn
    ..environment = Env.environment
    ..debug = Env.isDev
    // Conservative performance sampling; tune once we have real data.
    ..tracesSampleRate = Env.isProduction ? 0.2 : 1.0
    ..enableAutoSessionTracking = true;
}
