import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';
import '../../../../core/crash/crash_reporter.dart';

/// Bridges PowerSync (HU-04/HU-05) to Supabase: supplies the JWT the sync
/// stream needs, and replicates PowerSync's local write queue against
/// Supabase's REST API so every Drift write that reached PowerSync (see
/// `core/database/database_connection.dart`, decision #6,
/// docs/requirements/05-auth-sync.md) ends up in Postgres too.
///
/// Lives under `features/auth/data/` rather than `core/` because it is a
/// concrete Supabase-backed implementation the same way
/// `google_auth_datasource.dart` is — `core/` only holds the transport-agnostic
/// pieces (the schema, the Drift-over-PowerSync connection).
@lazySingleton
class PowerSyncConnector extends ps.PowerSyncBackendConnector {
  PowerSyncConnector(this._supabase, this._crash);

  final SupabaseClient _supabase;
  final CrashReporter _crash;

  /// Postgres error codes that will never succeed on retry (RLS denial,
  /// invalid input, missing FK target, uniqueness clash...). Matches
  /// PowerSync's own reference Supabase connector: for these, the offending
  /// op is dropped instead of blocking the whole upload queue forever.
  static final _fatalResponseCodes = [
    RegExp(r'^22...$'), // data exception
    RegExp(r'^23...$'), // integrity constraint violation
    RegExp(r'^42501$'), // insufficient privilege (RLS)
  ];

  @override
  Future<ps.PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      // Not signed in: HU-01, local-first, no error — just nothing to sync.
      return null;
    }
    return ps.PowerSyncCredentials(
      endpoint: Env.powerSyncUrl,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    // Rows are born without an owner: the app is local-first, so `user_id` is
    // nullable and nothing stamps it at creation time (`claimUnownedRows` only
    // runs once, during the post-login merge). Stamping it here — the single
    // edge where local data crosses into the cloud — is what makes the row
    // pass the `WITH CHECK (user_id = auth.uid())` policy every synced table
    // carries. Without it every INSERT came back 403/42501 and was dropped as
    // fatal below, silently losing the row on every table.
    final userId = _supabase.auth.currentSession?.user.id;

    try {
      for (final op in transaction.crud) {
        final table = _supabase.from(op.table);
        switch (op.op) {
          case ps.UpdateType.put:
            final data = {'id': op.id, ...?op.opData};
            if (userId != null && data['user_id'] == null) {
              data['user_id'] = userId;
            }
            await table.upsert(data);
          case ps.UpdateType.patch:
            if (op.opData case final data? when data.isNotEmpty) {
              await table.update(data).eq('id', op.id);
            }
          case ps.UpdateType.delete:
            await table.delete().eq('id', op.id);
        }
      }
      await transaction.complete();
    } on PostgrestException catch (e, stackTrace) {
      final code = e.code;
      final isFatal = code != null &&
          _fatalResponseCodes.any((pattern) => pattern.hasMatch(code));
      if (isFatal) {
        // Discard the offending op rather than retrying it forever — see
        // `_fatalResponseCodes`. Reported, never swallowed: dropping a write
        // means losing user data, and doing that without a trace is how the
        // missing `user_id` above went unnoticed while every insert failed.
        await _crash.recordError(
          e,
          stackTrace,
          context: 'PowerSync upload dropped a fatal op (code $code)',
        );
        await transaction.complete();
        return;
      }
      // Transient (network, timeout...): let PowerSync retry the batch.
      rethrow;
    }
  }
}
