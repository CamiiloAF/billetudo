import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config/env.dart';
import 'crash/crash_reporter.dart';
import 'crash/sentry_crash_reporter.dart';
import 'di/injection.dart';

/// Shared entry point: sets up bindings, dependency injection and global
/// error handling before running the app.
///
/// - With `SENTRY_DSN`: `SentryFlutter.init` installs its own uncaught error
///   handlers (zone + `FlutterError` + `PlatformDispatcher`) and runs the app
///   from its `appRunner`.
/// - Without a DSN: we install our own handlers, reporting to the no-op
///   [CrashReporter] (which prints to console in debug), inside a
///   `runZonedGuarded`.
Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();

  final crash = getIt<CrashReporter>();
  await crash.init();

  if (Env.hasSentryDsn) {
    await SentryFlutter.init(
      applySentryOptions,
      appRunner: () => runApp(builder()),
    );
    return;
  }

  // Both handlers have synchronous signatures, so reporting is fire-and-forget:
  // the app is already crashing and must not wait on the network.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      crash.recordError(
        details.exception,
        details.stack,
        context: 'FlutterError',
        fatal: true,
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      crash.recordError(
        error,
        stack,
        context: 'PlatformDispatcher',
        fatal: true,
      ),
    );
    return true;
  };

  runZonedGuarded(
    () => runApp(builder()),
    (error, stack) =>
        crash.recordError(error, stack, context: 'zone', fatal: true),
  );
}
