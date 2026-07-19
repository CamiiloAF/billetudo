import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';

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
  PowerSyncConnector(this._supabase);

  final SupabaseClient _supabase;

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

    try {
      for (final op in transaction.crud) {
        final table = _supabase.from(op.table);
        switch (op.op) {
          case ps.UpdateType.put:
            await table.upsert({'id': op.id, ...?op.opData});
          case ps.UpdateType.patch:
            if (op.opData case final data? when data.isNotEmpty) {
              await table.update(data).eq('id', op.id);
            }
          case ps.UpdateType.delete:
            await table.delete().eq('id', op.id);
        }
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      final code = e.code;
      final isFatal = code != null &&
          _fatalResponseCodes.any((pattern) => pattern.hasMatch(code));
      if (isFatal) {
        // Discard the offending op rather than retrying it forever — see
        // `_fatalResponseCodes`.
        await transaction.complete();
        return;
      }
      // Transient (network, timeout...): let PowerSync retry the batch.
      rethrow;
    }
  }
}
