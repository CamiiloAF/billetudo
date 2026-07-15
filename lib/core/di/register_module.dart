import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../config/env.dart';
import '../crash/crash_reporter.dart';
import '../crash/noop_crash_reporter.dart';
import '../crash/sentry_crash_reporter.dart';
import '../database/app_database.dart';
import '../database/database_connection.dart';

/// Registers third-party dependencies, and any whose construction logic
/// injectable cannot infer from an annotation on the class itself.
@module
abstract class RegisterModule {
  /// Local source of truth. Singleton: a single SQLite connection per process.
  @lazySingleton
  AppDatabase appDatabase() => AppDatabase(openLocalDatabase());

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
}
