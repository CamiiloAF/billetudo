// Guards the client schema against the real Postgres schema.
//
// Why this test exists: the Supabase schema used to be applied by hand and
// prod fell behind the client. A single missing column (`debts.closed_at`)
// made PostgREST answer PGRST204, which the PowerSync connector retried
// forever — and because the upload queue is FIFO, no write from any table ever
// reached the server again. That failure is invisible to every other test in
// this repo, so it gets its own.
//
// Design: this test must never need the network in CI. It compares
// `powerSyncSchema` (the client's source of truth) against a versioned
// snapshot of Postgres in `fixtures/postgres_schema.json`. Refresh that
// snapshot with `dart run tool/check_schema_parity.dart --refresh` (see the
// README block at the top of that script) whenever a migration lands.
import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/database/powersync_schema.dart';
import 'package:flutter_test/flutter_test.dart';

/// Path of the Postgres snapshot, relative to the package root (where
/// `flutter test` runs).
const _fixturePath = 'test/core/database/fixtures/postgres_schema.json';

const _refreshHint =
    'Refresh it with `dart run tool/check_schema_parity.dart --refresh`.';

const _migrationHint =
    'Add a migration under supabase/migrations/ (never apply DDL by hand over '
    'MCP: an out-of-date Postgres blocks the whole PowerSync upload queue), '
    'apply it to dev and prod, then $_refreshHint';

/// `id` is never declared in `powerSyncSchema` — PowerSync manages it
/// implicitly for every table — but it does exist in Postgres.
const _implicitColumn = 'id';

/// Tables that exist in Postgres on purpose without being synced, so they are
/// absent from `powerSyncSchema`.
const _postgresOnlyTables = <String>{
  // Global read-only catalog of suggested categories. Fetched over REST, never
  // synced, and it has no `user_id` nor sync columns.
  'category_seeds',
};

/// Columns kept in Postgres for backwards compatibility with older clients
/// that still write them, and deliberately dropped from the client schema.
/// Anything not listed here is unexpected drift and fails the test.
const _legacyPostgresColumns = <String, Set<String>>{
  // schemaVersion 19 moved a goal's progress to the `goal_contributions`
  // ledger. Both columns stay in Postgres so an old build keeps working.
  'goals': {'saved_minor', 'color'},
};

Map<String, Set<String>> _readPostgresSnapshot() {
  final file = File(_fixturePath);
  if (!file.existsSync()) {
    fail('Missing Postgres schema snapshot at $_fixturePath. $_refreshHint');
  }
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final tables = decoded['tables'] as Map<String, dynamic>;
  return {
    for (final entry in tables.entries)
      entry.key: (entry.value as List<dynamic>).cast<String>().toSet(),
  };
}

Map<String, Set<String>> _readClientSchema() {
  return {
    for (final table in powerSyncSchema.tables)
      table.name: {
        _implicitColumn,
        ...table.columns.map((column) => column.name),
      },
  };
}

void main() {
  late Map<String, Set<String>> postgres;
  late Map<String, Set<String>> client;

  setUp(() {
    postgres = _readPostgresSnapshot();
    client = _readClientSchema();
  });

  test('every table in powerSyncSchema exists in Postgres', () {
    final missing = client.keys.where((t) => !postgres.containsKey(t)).toList()
      ..sort();

    expect(
      missing,
      isEmpty,
      reason: 'These tables are declared in '
          'lib/core/database/powersync_schema.dart but do NOT exist in '
          'Postgres: ${missing.join(', ')}.\n'
          'PowerSync will fail every upload that touches them, and the FIFO '
          'queue will stall for every other table too.\n'
          '$_migrationHint',
    );
  });

  test('every column in powerSyncSchema exists in Postgres', () {
    final missing = <String>[];
    for (final entry in client.entries) {
      final postgresColumns = postgres[entry.key];
      if (postgresColumns == null) {
        // Reported by the table-level test above.
        continue;
      }
      for (final column in entry.value.toList()..sort()) {
        if (!postgresColumns.contains(column)) {
          missing.add('${entry.key}.$column');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'These columns are declared in '
          'lib/core/database/powersync_schema.dart but do NOT exist in '
          'Postgres: ${missing.join(', ')}.\n'
          'PostgREST answers PGRST204 for each of them and the PowerSync '
          'upload queue stalls forever (this is exactly the `debts.closed_at` '
          'outage).\n'
          '$_migrationHint',
    );
  });

  test('Postgres has no unexpected extra table', () {
    final extra = postgres.keys
        .where(
            (t) => !client.containsKey(t) && !_postgresOnlyTables.contains(t))
        .toList()
      ..sort();

    expect(
      extra,
      isEmpty,
      reason: 'These tables exist in Postgres but are not declared in '
          'lib/core/database/powersync_schema.dart: ${extra.join(', ')}.\n'
          'Either mirror them in the client schema (and in '
          'lib/core/database/app_database.dart), or add them to '
          '`_postgresOnlyTables` in this test with a comment saying why they '
          'are not synced.',
    );
  });

  test('Postgres has no unexpected extra column', () {
    final extra = <String>[];
    for (final entry in postgres.entries) {
      final clientColumns = client[entry.key];
      if (clientColumns == null) {
        // Reported by the extra-table test above, or allowlisted.
        continue;
      }
      final allowed = _legacyPostgresColumns[entry.key] ?? const <String>{};
      for (final column in entry.value.toList()..sort()) {
        if (!clientColumns.contains(column) && !allowed.contains(column)) {
          extra.add('${entry.key}.$column');
        }
      }
    }

    expect(
      extra,
      isEmpty,
      reason: 'These columns exist in Postgres but are not declared in '
          'lib/core/database/powersync_schema.dart: ${extra.join(', ')}.\n'
          'A server-only column never reaches the device: the client cannot '
          'read it and never writes it. Either mirror it in the client schema '
          '(and in lib/core/database/app_database.dart), or add it to '
          '`_legacyPostgresColumns` in this test with a comment saying why it '
          'is intentionally server-only.',
    );
  });

  test('the snapshot covers the sync columns of every synced table', () {
    // Cheap sanity check on the fixture itself: a truncated or half-refreshed
    // snapshot would silently make the tests above pass.
    const syncColumns = {
      'id',
      'created_at',
      'updated_at',
      'deleted_at',
      'tombstoned_at',
      'user_id',
    };

    for (final entry in postgres.entries) {
      if (_postgresOnlyTables.contains(entry.key)) {
        continue;
      }
      expect(
        entry.value,
        containsAll(syncColumns),
        reason: 'Table `${entry.key}` in $_fixturePath is missing sync '
            'columns. The snapshot looks stale or truncated. $_refreshHint',
      );
    }
  });
}
