import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../features/categories/domain/usecases/seed_default_categories.dart';
import 'config/env.dart';
import 'crash/crash_reporter.dart';
import 'crash/sentry_crash_reporter.dart';
import 'di/injection.dart';
import 'error/result.dart';

/// Shared entry point: sets up bindings, dependency injection and global
/// error handling before running the app.
///
/// - With `SENTRY_DSN`: `SentryFlutter.init` installs its own uncaught error
///   handlers (zone + `FlutterError` + `PlatformDispatcher`) and runs the app
///   from its `appRunner`.
/// - Without a DSN: we install our own [FlutterError.onError] and
///   [PlatformDispatcher.onError] handlers, reporting to the no-op
///   [CrashReporter] (which prints to console in debug). We do NOT wrap
///   `runApp` in a `runZonedGuarded`: `PlatformDispatcher.onError` already
///   catches otherwise-uncaught async errors, and running the app in the same
///   (root) zone as the binding above avoids Flutter's "Zone mismatch"
///   assertion (the binding is initialized here, in the root zone).
Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();

  final crash = getIt<CrashReporter>();
  await crash.init();

  // Stopgap: seed the default categories on every launch until onboarding
  // (HU-06, docs/requirements/13-onboarding.md) owns this — the user decided
  // to load them from main for now. `SeedDefaultCategories` is idempotent
  // (no-op when any category already exists), so this is safe on each run.
  // Placed before the Sentry branch so it runs on both paths (Sentry / no-op).
  final seedResult = await getIt<SeedDefaultCategories>()();
  if (seedResult case Left(value: final failure)) {
    unawaited(
      crash.recordError(
        failure,
        StackTrace.current,
        context: 'seedDefaultCategories',
      ),
    );
  }

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

  runApp(builder());
}
