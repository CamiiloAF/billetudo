import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

/// Found live, real device + real PowerSync + real Postgres (2026-09-01):
/// `_write`'s previous version ran `UPDATE`, then **unconditionally** ran
/// `INSERT ... insertOrIgnore` afterwards too — trusting its own doc's claim
/// that the insert is a harmless no-op when the row already exists. It is
/// not: every field **absent** from that specific write's companion still
/// gets Drift's typed API to fill in its `clientDefault` before the
/// `INSTEAD OF INSERT` trigger runs, and the trigger applies them — visible
/// on device as `createdAt` changing to "now" on every single settings
/// write. A column with a `clientDefault` (`aiNotesAccessEnabled`) that
/// isn't part of *that particular* write's companion silently reset to its
/// Dart-side default the moment any *other* setting was written — the "the
/// notes toggle doesn't persist" bug was never notes-specific, it hit every
/// `clientDefault` column on every write.
///
/// Runs on real PowerSync, not `NativeDatabase`: this is a view, and the
/// bug lived entirely in how its `INSTEAD OF` triggers handle an `INSERT`
/// against a row that already exists — `NativeDatabase`'s plain-table
/// semantics for `INSERT OR IGNORE` don't reproduce it.
void main() {
  late Directory tempDir;
  late PowerSyncDatabase powerSync;
  late AppDatabase db;
  late AppSettingsLocalDatasource local;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'app_settings_sibling_default',
    );
    powerSync = await openPowerSyncDatabase(
      path: p.join(tempDir.path, 'test.sqlite'),
    );
    db = AppDatabase(driftConnection(powerSync));
    local = AppSettingsLocalDatasource(db);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test(
      'writing an unrelated setting does not reset a sibling '
      'clientDefault column back to its default', () async {
    await local.setAiNotesAccessEnabled(
      enabled: true,
      now: DateTime.fromMillisecondsSinceEpoch(1000),
    );
    expect((await local.readSettings())!.aiNotesAccessEnabled, isTrue);

    // A completely unrelated write — this is the one that used to reset
    // `aiNotesAccessEnabled` back to `false` as a side effect, on device.
    await local.setZeroBasedEnabled(
      zeroBasedEnabled: true,
      now: DateTime.fromMillisecondsSinceEpoch(2000),
    );

    final row = await local.readSettings();
    expect(
      row!.aiNotesAccessEnabled,
      isTrue,
      reason: 'an unrelated settings write must never touch a sibling '
          "column it didn't ask to change",
    );
    expect(row.zeroBasedEnabled, isTrue);
  });

  test(
      "writing an unrelated setting doesn't regenerate createdAt — a "
      'changed createdAt is the direct symptom that an INSERT ran instead '
      'of a plain UPDATE', () async {
    await local.setAiNotesAccessEnabled(
      enabled: true,
      now: DateTime.fromMillisecondsSinceEpoch(1000),
    );
    final createdAtAfterFirstWrite = (await local.readSettings())!.createdAt;

    await local.setZeroBasedEnabled(
      zeroBasedEnabled: true,
      now: DateTime.fromMillisecondsSinceEpoch(2000),
    );

    final createdAtAfterSecondWrite = (await local.readSettings())!.createdAt;
    expect(createdAtAfterSecondWrite, createdAtAfterFirstWrite);
  });
}
