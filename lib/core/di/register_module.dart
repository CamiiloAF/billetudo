import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../crash/crash_reporter.dart';
import '../crash/noop_crash_reporter.dart';
import '../crash/sentry_crash_reporter.dart';
import '../database/app_database.dart';
import '../database/database_connection.dart' as db_connection;

/// Registers third-party dependencies, and any whose construction logic
/// injectable cannot infer from an annotation on the class itself.
@module
abstract class RegisterModule {
  /// The PowerSync-managed local database (HU-04/HU-05 sync). Already opened
  /// by `bootstrap()` before `configureDependencies()` runs (see
  /// `database_connection.dart`) — this just exposes it for injection.
  @lazySingleton
  PowerSyncDatabase powerSyncDatabase() => db_connection.powerSyncDatabase;

  /// Local source of truth. Singleton: a single SQLite connection per process.
  /// Drift opens on top of the same PowerSync-managed connection (decision
  /// #6, docs/requirements/05-auth-sync.md) so every write it makes is
  /// intercepted into PowerSync's upload queue automatically.
  @lazySingleton
  AppDatabase appDatabase() => AppDatabase(
        db_connection.driftConnection(db_connection.powerSyncDatabase),
      );

  /// Secure storage backed by Keystore/Keychain. `first_unlock_this_device`
  /// accessibility: never backed up to iCloud (Cuentas HU-03).
  @lazySingleton
  FlutterSecureStorage secureStorage() => const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  /// Single place where the crash reporter is chosen: Sentry when a DSN is
  /// present, a no-op otherwise. See `core/config/env.dart`.
  @lazySingleton
  CrashReporter crashReporter() =>
      Env.hasSentryDsn ? SentryCrashReporter() : const NoopCrashReporter();

  /// Sync/auth backend client. `Supabase.initialize` is async and must run
  /// once, before `configureDependencies()` builds this graph (see
  /// `bootstrap.dart`) — by the time this provider runs, `Supabase.instance`
  /// is already set up, so this is just exposing it for injection.
  @lazySingleton
  SupabaseClient supabaseClient() => Supabase.instance.client;
}
