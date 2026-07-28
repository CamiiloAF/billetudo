// Live schema-parity check between `powerSyncSchema` and a real Postgres.
//
// The unit test `test/core/database/schema_parity_test.dart` compares the
// client schema against a versioned snapshot so CI never needs the network.
// This script is the other half: it queries Postgres for real. Run it before a
// release, and every time a migration lands, to make sure the snapshot still
// describes reality.
//
// Usage (from the package root):
//
//   export DATABASE_URL='postgresql://postgres:...@db.<ref>.supabase.co:5432/postgres'
//   dart run tool/check_schema_parity.dart             # check only, exit 1 on drift
//   dart run tool/check_schema_parity.dart --refresh   # rewrite the fixture
//
// Requirements: `psql` on PATH and `DATABASE_URL` pointing at the environment
// you want to verify (the connection string lives in the Supabase dashboard
// under Project settings -> Database). No extra Dart dependency: the query
// runs through `psql` and returns a single JSON document.
//
// Exit codes: 0 = in sync (or fixture refreshed), 1 = drift detected,
// 2 = could not reach Postgres / bad setup.
//
// When it reports drift: write a migration under `supabase/migrations/`, apply
// it to dev AND prod, then re-run with `--refresh` and commit the updated
// fixture next to the migration. Never apply DDL by hand: a Postgres that
// lags the client makes PostgREST answer PGRST204, which stalls the whole
// FIFO upload queue of PowerSync for every table.
import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/database/powersync_schema.dart';

const _fixturePath = 'test/core/database/fixtures/postgres_schema.json';

const _implicitColumn = 'id';

/// Mirrors the allowlists in `test/core/database/schema_parity_test.dart`.
const _postgresOnlyTables = <String>{'category_seeds'};
const _legacyPostgresColumns = <String, Set<String>>{
  'goals': {'saved_minor', 'color'},
};

const _query = '''
select coalesce(jsonb_object_agg(t, cols), '{}'::jsonb)::text
from (
  select table_name as t, jsonb_agg(column_name order by column_name) as cols
  from information_schema.columns
  where table_schema = 'public'
  group by table_name
) s;
''';

Future<Map<String, List<String>>> _fetchPostgresSchema(String url) async {
  final result = await Process.run(
    'psql',
    [url, '--no-align', '--tuples-only', '--command', _query],
  );
  if (result.exitCode != 0) {
    stderr.writeln('psql failed (exit ${result.exitCode}):');
    stderr.writeln(result.stderr);
    exit(2);
  }
  final decoded =
      jsonDecode((result.stdout as String).trim()) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      entry.key: (entry.value as List<dynamic>).cast<String>()..sort(),
  };
}

Map<String, Set<String>> _clientSchema() {
  return {
    for (final table in powerSyncSchema.tables)
      table.name: {
        _implicitColumn,
        ...table.columns.map((column) => column.name),
      },
  };
}

List<String> _findDrift(Map<String, List<String>> postgres) {
  final client = _clientSchema();
  final problems = <String>[];

  for (final entry in client.entries) {
    final postgresColumns = postgres[entry.key];
    if (postgresColumns == null) {
      problems.add('MISSING TABLE in Postgres: ${entry.key}');
      continue;
    }
    for (final column in entry.value.toList()..sort()) {
      if (!postgresColumns.contains(column)) {
        problems.add('MISSING COLUMN in Postgres: ${entry.key}.$column');
      }
    }
  }

  for (final entry in postgres.entries) {
    final clientColumns = client[entry.key];
    if (clientColumns == null) {
      if (!_postgresOnlyTables.contains(entry.key)) {
        problems.add('EXTRA TABLE in Postgres: ${entry.key}');
      }
      continue;
    }
    final allowed = _legacyPostgresColumns[entry.key] ?? const <String>{};
    for (final column in entry.value) {
      if (!clientColumns.contains(column) && !allowed.contains(column)) {
        problems.add('EXTRA COLUMN in Postgres: ${entry.key}.$column');
      }
    }
  }

  return problems;
}

Future<void> _writeFixture(Map<String, List<String>> postgres) async {
  final file = File(_fixturePath);
  final existing = file.existsSync()
      ? jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};

  final sortedTables = postgres.keys.toList()..sort();
  final payload = <String, dynamic>{
    '_readme': existing['_readme'],
    'generatedAt': DateTime.now().toUtc().toIso8601String().split('T').first,
    'source': existing['source'],
    'tables': {for (final table in sortedTables) table: postgres[table]},
  };

  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );
  stdout.writeln('Refreshed $_fixturePath (${sortedTables.length} tables).');
  stdout.writeln(
    'Review `_readme` and `source` in the fixture if a migration changed what '
    'this snapshot represents.',
  );
}

Future<void> main(List<String> args) async {
  final url = Platform.environment['DATABASE_URL'];
  if (url == null || url.isEmpty) {
    stderr.writeln(
      'DATABASE_URL is not set. Export the Supabase connection string of the '
      'environment you want to check and re-run.',
    );
    exit(2);
  }

  final postgres = await _fetchPostgresSchema(url);
  final problems = _findDrift(postgres);

  if (problems.isEmpty) {
    stdout.writeln(
      'Schema parity OK: powerSyncSchema matches Postgres '
      '(${postgres.length} tables).',
    );
  } else {
    stdout.writeln('Schema drift detected (${problems.length}):');
    for (final problem in problems) {
      stdout.writeln('  - $problem');
    }
    stdout.writeln(
      '\nWrite a migration in supabase/migrations/, apply it to dev and prod, '
      'then re-run with --refresh.',
    );
  }

  if (args.contains('--refresh')) {
    await _writeFixture(postgres);
    exit(0);
  }

  exit(problems.isEmpty ? 0 : 1);
}
