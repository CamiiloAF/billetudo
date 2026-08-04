import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the sync diagnostics files (quarantine, local log) are kept.
///
/// Behind an interface only so tests can point at a temp directory:
/// `path_provider` has no platform channel implementation under
/// `flutter test` (same reason `openPowerSyncDatabase` takes a `path`).
abstract class SyncStorageDirectory {
  /// The directory, created if it did not exist.
  Future<Directory> resolve();
}

/// Production implementation: `<app documents>/sync/`.
///
/// Deliberately *outside* the PowerSync-managed SQLite file. Three reasons,
/// all learned the hard way:
///  1. Every `_SyncColumns` table is physically a PowerSync **view**, so
///     adding a table there means bumping `schemaVersion` and living with the
///     "Cannot add a column to a view" class of migration failure that already
///     broke a production release on 2026-07-24 (see the `from < 12` note in
///     `app_database.dart`).
///  2. Anything written through that database is intercepted into the very
///     upload queue this quarantine exists to unblock — the record of a failed
///     upload would itself become an upload.
///  3. The quarantine is per-device forensic data. It must never sync.
///
/// A plain JSON file gives durability across restarts with none of that. The
/// volume is bounded (a handful of rejected writes, 200 log lines), so the
/// cost of rewriting the file on each change is irrelevant.
@LazySingleton(as: SyncStorageDirectory)
class AppDocumentsSyncStorageDirectory implements SyncStorageDirectory {
  const AppDocumentsSyncStorageDirectory();

  @override
  Future<Directory> resolve() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'sync'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
