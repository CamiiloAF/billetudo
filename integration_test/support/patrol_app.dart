import 'dart:io';

import 'package:billetudo/app.dart';
import 'package:billetudo/core/config/env.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The [PowerSyncDatabase] opened by the previous [startApp] call, if any.
///
/// Every `patrolTest` scenario in a suite runs in the same Dart process, so
/// nothing closes the connection opened by the previous scenario on its own.
/// [startApp] closes it here, before [resetLocalDatabase] deletes the
/// underlying SQLite file — otherwise the delete would race a still-open
/// connection from the prior scenario.
PowerSyncDatabase? _previousPowerSyncDatabase;

/// Deletes the on-device Drift database (`AppDatabase`'s only backing store,
/// see `core/database/database_connection.dart`) before the app boots.
///
/// Every scenario starts against a fresh, real SQLite file on the
/// device/simulator — not a mock — so each `patrolTest` gets its own "clean
/// install" without needing a separate app reinstall per test.
Future<void> resetLocalDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'billetudo.sqlite'));
  if (file.existsSync()) {
    file.deleteSync();
  }
}

/// Boots billetudo for a Patrol scenario: fresh local database, a clean
/// `getIt` graph, and the real widget tree pumped through `$` (never
/// `runApp`, per Patrol's own setup docs — the test binding needs to own the
/// pump so it can drive it after startup).
///
/// Deliberately does not reuse `core/bootstrap.dart`: that file installs
/// `FlutterError.onError` handlers, which Patrol's docs explicitly say a test
/// must not touch, since the test engine relies on the default handler to
/// notice a failing scenario.
///
/// It does, however, reproduce `bootstrap()`'s pre-DI setup steps
/// (`Supabase.initialize` then `openPowerSyncDatabase`, same order as
/// `bootstrap.dart`): `configureDependencies()` builds `AppDatabase` and
/// `SupabaseClient` synchronously off of them (see `register_module.dart`),
/// so both must complete first or the DI graph throws.
Future<void> startApp(PatrolIntegrationTester $) async {
  await _prepareCleanBoot($);
  await $.pumpWidgetAndSettle(const BilletudoApp());
}

/// Same clean-install boot as [startApp], but mounts [BilletudoApp] with
/// `initialLocation: AppRoutes.onboarding` instead of relying on its default
/// (`AppRoutes.home`).
///
/// `startApp` cannot exercise the welcome flow at all: unlike a real launch
/// (`bootstrap.dart`'s `_initApp`, which calls `ShouldShowOnboarding` and
/// feeds its result into `BilletudoApp.initialLocation` before the widget
/// tree exists), this harness pumps `BilletudoApp` directly and skips
/// `bootstrap.dart` entirely (see this file's own `startApp` doc comment —
/// Patrol's docs say a test must not install `bootstrap.dart`'s
/// `FlutterError.onError` handlers). `BilletudoApp()`'s default parameter
/// then always lands on Home, regardless of `AppSettings.onboardingCompleted`
/// — every existing Patrol scenario in this repo, including this file's own
/// `startApp`, has therefore never actually rendered `WelcomePage`. A fresh
/// install's `onboardingCompleted` really is `false` (a plain
/// `clientDefault`), so pinning the location here reproduces exactly the
/// route `bootstrap.dart` would have chosen for this same clean database
/// state, without needing to reimplement its `ShouldShowOnboarding` call in
/// the test harness too.
Future<void> startOnboardingApp(PatrolIntegrationTester $) async {
  await _prepareCleanBoot($);
  await $.pumpWidgetAndSettle(
    const BilletudoApp(initialLocation: AppRoutes.onboarding),
  );
}

Future<void> _prepareCleanBoot(PatrolIntegrationTester $) async {
  await _previousPowerSyncDatabase?.close();
  await resetLocalDatabase();
  await getIt.reset();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
  _previousPowerSyncDatabase = await openPowerSyncDatabase();

  configureDependencies();
  // The app follows the device locale (app.dart no longer pins es-CO), but
  // these scenarios assert Spanish copy and es-CO money formatting. Pin the
  // locale so the suite is deterministic regardless of the device/emulator
  // language (Android emulators default to en-US).
  $.tester.platformDispatcher.localesTestValue = const [Locale('es', 'CO')];
}

/// Dismisses the HU-01 minitutorial sheet if it auto-showed
/// (`docs/requirements/fase-1/16-minitutoriales.md` criterion 1) right after
/// arriving at Presupuestos/Metas/Deudas/Pagos programados for the first
/// time in a scenario.
///
/// [startApp] always boots against a fresh database: `TutorialViews` is
/// empty and `AppSettings.showHelpOnSectionEntry` defaults to `true`, so the
/// very first visit to any of those 4 screens in *every* scenario
/// auto-shows its tutorial sheet — the sheet is a full-screen modal that
/// would otherwise swallow the next `tap`/`enterText` this suite issues.
/// Call this once right after navigating to one of those screens, before
/// interacting with it.
///
/// A bounded poll, not a plain `pumpAndSettle`: `TutorialGateCubit.evaluate`
/// awaits a real on-device Drift query (`HasSeenTutorial`) before opening
/// the sheet, so the modal route can still be a few frames away from
/// `showModalBottomSheet` actually pushing — same reasoning as this file's
/// sibling suites' own `_pumpUntilFound` helpers. No-ops (and costs at most
/// this poll's budget) on a screen's *second* visit in the same scenario,
/// where the tutorial was already marked seen and never shows again.
Future<void> dismissAutoTutorialIfShown(
  PatrolIntegrationTester $, {
  int maxFrames = 20,
}) async {
  final gotIt = find.text('Entendido');
  for (var i = 0; i < maxFrames && gotIt.evaluate().isEmpty; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
  }
  if (gotIt.evaluate().isNotEmpty) {
    await $.tester.tap(gotIt.first);
    await $.tester.pumpAndSettle();
  }
}
