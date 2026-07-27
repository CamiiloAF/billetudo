import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

import 'powersync_schema.dart';

PowerSyncDatabase? _powerSyncDatabase;

/// Opens the single [PowerSyncDatabase] for this process, at the same path
/// `openLocalDatabase()` used to open its own `NativeDatabase` (see decision
/// #6, `docs/requirements/05-auth-sync.md`).
///
/// Must be awaited once in `bootstrap()`, **before** `configureDependencies()`
/// builds the DI graph — same pattern as `Supabase.initialize()` there. Only
/// opens the local file and applies the PowerSync schema/triggers; it does
/// NOT connect to the sync service (see `PowerSyncDatabase.connect`, driven by
/// `AuthRepositoryImpl` once a session exists).
///
/// [path] is only for tests (`test/core/di_test.dart`): it lets them point at
/// a temp file directly instead of going through `path_provider`, which has
/// no platform channel implementation under `flutter test`. Production always
/// uses the default.
Future<PowerSyncDatabase> openPowerSyncDatabase({String? path}) async {
  final resolvedPath = path ?? await _defaultDatabasePath();
  final db = PowerSyncDatabase(schema: powerSyncSchema, path: resolvedPath);
  await db.initialize();
  _powerSyncDatabase = db;
  return db;
}

Future<String> _defaultDatabasePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'billetudo.sqlite');
}

/// The already-opened [PowerSyncDatabase] (see [openPowerSyncDatabase]).
///
/// Read synchronously by `register_module.dart`, mirroring how it reads
/// `Supabase.instance.client` — both rely on their respective `bootstrap()`
/// step having completed first.
PowerSyncDatabase get powerSyncDatabase {
  final db = _powerSyncDatabase;
  if (db == null) {
    throw StateError(
      'openPowerSyncDatabase() must complete before anything reads '
      'powerSyncDatabase (see bootstrap.dart).',
    );
  }
  return db;
}

/// A Drift [DatabaseConnection] over the same `sqlite_async` connection
/// [PowerSyncDatabase] manages (decision #6): every write made through Drift
/// is transparently intercepted into PowerSync's upload queue via triggers,
/// with no change needed in `lib/features/*/data/`.
DatabaseConnection driftConnection(PowerSyncDatabase powerSyncDb) =>
    SqliteAsyncDriftConnection(powerSyncDb);
