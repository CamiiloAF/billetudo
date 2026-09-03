import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/sync_operation.dart';
import 'sync_operation_uploader.dart';

/// Supabase/PostgREST implementation of [SyncOperationUploader].
@LazySingleton(as: SyncOperationUploader)
class SupabaseOperationUploader implements SyncOperationUploader {
  const SupabaseOperationUploader(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<void> upload(SyncOperation operation) async {
    if (_supabase.auth.currentSession == null) {
      // No session yet — cold start, or a token mid-refresh. Every synced
      // table's RLS policy requires `user_id = auth.uid()`, so going ahead
      // here would only ever come back `42501` and be quarantined as
      // `invalidData`: a permanent verdict for what is really a timing
      // problem (this is BILLETUDO-D — the app tried to upsert `app_settings`
      // before `currentSession` was ready and the row was quarantined instead
      // of retried). Throwing `AuthException` instead makes
      // `SyncErrorClassifier` read this as a connectivity failure — the same
      // bucket as "device is offline" — so PowerSync keeps the operation in
      // the queue and replays it once sign-in finishes, for any table, not
      // just this one.
      throw AuthException(
        'No active Supabase session: cannot upload '
        '${operation.tableName}/${operation.rowId} yet.',
      );
    }
    final table = _supabase.from(operation.tableName);
    switch (operation.type) {
      case SyncOperationType.put:
        await table.upsert(_ownedPayload(operation));
      case SyncOperationType.patch:
        final payload = operation.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }
        await table.update(payload).eq('id', operation.rowId);
      case SyncOperationType.delete:
        await table.delete().eq('id', operation.rowId);
    }
  }

  /// Rows are born without an owner: the app is local-first, so `user_id` is
  /// nullable and nothing stamps it at creation time (`claimUnownedRows` only
  /// runs once, during the post-login merge). Stamping it here — the single
  /// edge where local data crosses into the cloud — is what makes the row pass
  /// the `WITH CHECK (user_id = auth.uid())` policy every synced table
  /// carries. `upload()` already guarantees a session exists by the time this
  /// runs, so `userId` below is never null in practice; the null-check stays
  /// as a defensive fallback, not the mechanism that prevents 42501 (that is
  /// the guard clause at the top of `upload()`).
  Map<String, dynamic> _ownedPayload(SyncOperation operation) {
    final data = <String, dynamic>{
      'id': operation.rowId,
      ...?operation.payload,
    };
    final userId = _supabase.auth.currentSession?.user.id;
    if (userId != null && data['user_id'] == null) {
      data['user_id'] = userId;
    }
    return data;
  }
}
