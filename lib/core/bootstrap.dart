import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/categories/domain/usecases/seed_default_categories.dart';
import 'bootstrap/app_bootstrap_gate.dart';
import 'bootstrap/first_launch_offline_gate.dart';
import 'config/env.dart';
import 'crash/crash_reporter.dart';
import 'crash/sentry_crash_reporter.dart';
import 'database/database_connection.dart';
import 'di/injection.dart';
import 'error/result.dart';

/// Shared entry point: mounts [AppBootstrapGate] (which shows the splash
/// screen) immediately, then does the actual setup — bindings, Supabase,
/// PowerSync, dependency injection and global error handling — in the
/// background, swapping in the real app once it is done.
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
///
/// These handlers are installed before dependency injection has finished
/// wiring up (that now happens asynchronously inside [_initApp], behind the
/// splash screen), so they resolve [CrashReporter] lazily and tolerate it not
/// being registered yet — see [_reportBootError].
Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  final gate = AppBootstrapGate(init: () => _initApp(builder));

  if (Env.hasSentryDsn) {
    await SentryFlutter.init(
      applySentryOptions,
      appRunner: () => runApp(gate),
    );
    return;
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      _reportBootError(
        details.exception,
        details.stack,
        context: 'FlutterError',
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(_reportBootError(error, stack, context: 'PlatformDispatcher'));
    return true;
  };

  runApp(gate);
}

/// Reports a fatal error caught by the handlers above through
/// [CrashReporter], if dependency injection has completed registering it by
/// the time the error happens. Errors that occur before then (extremely
/// early in the splash) are swallowed rather than crashing on a missing
/// registration — [FlutterError.presentError] above already surfaced them to
/// the console/IDE.
Future<void> _reportBootError(
  Object error,
  StackTrace? stackTrace, {
  required String context,
}) async {
  if (!getIt.isRegistered<CrashReporter>()) {
    return;
  }
  await getIt<CrashReporter>().recordError(
    error,
    stackTrace,
    context: context,
    fatal: true,
  );
}

/// Does the actual bootstrap work behind the splash screen shown by
/// [AppBootstrapGate], then resolves to the widget-building function the real
/// app should be mounted with.
Future<Widget Function()> _initApp(Widget Function() builder) async {
  // Must run before `configureDependencies()`: the DI graph exposes
  // `Supabase.instance.client` synchronously (see `register_module.dart`),
  // which requires this to have completed already.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  // Also must run before `configureDependencies()`: the DI graph exposes
  // `AppDatabase` synchronously, built on top of this connection (see
  // `register_module.dart` and decision #6, docs/requirements/05-auth-sync.md).
  await openPowerSyncDatabase();

  configureDependencies();

  final crash = getIt<CrashReporter>();
  await crash.init();

  // Stopgap: seed the default categories on every launch until onboarding
  // (HU-06, docs/requirements/13-onboarding.md) owns this — the user decided
  // to load them from main for now. `SeedDefaultCategories` is idempotent
  // (no-op when any category already exists, including the fast path where
  // the `categoriesSeeded` latch is already on — no network call at all), so
  // this is safe and cheap on each normal run.
  //
  // The one case that changes what gets returned below: a `NetworkFailure` on
  // the very first launch (no local categories yet, catalog now lives in
  // Supabase — decisión #12, docs/requirements/05-auth-sync.md). The app
  // cannot use a network-less copy in that case (deliberately not
  // duplicated), so instead of `builder` we return a builder for
  // `FirstLaunchOfflineGate`, which blocks with a retry screen until seeding
  // actually succeeds and only then swaps in the real app. Any other failure
  // (e.g. a local DB error) keeps the previous non-blocking behavior: log it
  // and let the user in — those aren't the network-availability problem this
  // screen exists for.
  final seedResult = await getIt<SeedDefaultCategories>()();
  var effectiveBuilder = builder;
  if (seedResult case Left(value: final failure)) {
    if (failure is NetworkFailure) {
      effectiveBuilder = () => FirstLaunchOfflineGate(builder: builder);
    } else {
      unawaited(
        crash.recordError(
          failure,
          StackTrace.current,
          context: 'seedDefaultCategories',
        ),
      );
    }
  }

  return effectiveBuilder;
}
