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
  /// carries. Without it every INSERT came back 403/42501 and was dropped as
  /// fatal, silently losing the row on every table.
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
