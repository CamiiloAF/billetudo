import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/local_data_ownership_datasource.dart';
import '../config/env.dart';
import '../crash/crash_reporter.dart';
import '../crash/noop_crash_reporter.dart';
import '../crash/sentry_crash_reporter.dart';
import '../database/app_database.dart';
import '../database/database_connection.dart' as db_connection;
import '../sync/data/datasources/data_ownership_claimer.dart';
import '../sync/domain/repositories/backup_id_collision_resolver.dart';

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
  /// #6, docs/requirements/fase-1/05-auth-sync.md) so every write it makes is
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

  /// Backs `ThemePreferenceDatasource` (Ajustes → "Apariencia", local-only,
  /// per-device). The constructor itself is synchronous — only individual
  /// reads/writes are async — so this needs no `@preResolve`, keeping
  /// `configureDependencies()` synchronous like the rest of the graph.
  @lazySingleton
  SharedPreferencesAsync sharedPreferencesAsync() => SharedPreferencesAsync();

  /// `LocalDataOwnershipDatasource` implements two domain interfaces —
  /// `DataOwnershipClaimer` (HU-04's post-login claim) and
  /// `BackupIdCollisionResolver` (restoring a backup across two Supabase
  /// accounts) — but injectable's `@LazySingleton(as: X)` binds only one
  /// abstract type per class annotation, so it is registered as itself
  /// there and exposed under each interface here instead. Both getters
  /// receive the exact same singleton instance (`@lazySingleton` on the
  /// class itself caches it in `GetIt`), never two separate ones.
  @lazySingleton
  DataOwnershipClaimer dataOwnershipClaimer(
    LocalDataOwnershipDatasource datasource,
  ) =>
      datasource;

  @lazySingleton
  BackupIdCollisionResolver backupIdCollisionResolver(
    LocalDataOwnershipDatasource datasource,
  ) =>
      datasource;

  /// Bridge with the native home-screen widgets
  /// (`docs/requirements/fase-2/20-widget-captura-rapida.md`). Named so tests
  /// can swap it for a channel backed by a fake handler; the name string must
  /// stay in sync with `QuickCaptureWidgetBridge.kt` and `AppDelegate.swift`.
  @Named('captureShortcutChannel')
  @lazySingleton
  MethodChannel captureShortcutChannel() =>
      const MethodChannel('com.billetudo.app/capture_shortcuts');
}
