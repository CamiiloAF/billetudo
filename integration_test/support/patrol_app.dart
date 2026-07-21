import 'dart:io';

import 'package:billetudo/app.dart';
import 'package:billetudo/core/config/env.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:flutter/widgets.dart';
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
  await $.pumpWidgetAndSettle(const BilletudoApp());
}
