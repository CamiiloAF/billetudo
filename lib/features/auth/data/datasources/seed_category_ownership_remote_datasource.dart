import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown by [SeedCategoryOwnershipRemoteDatasource.existingSeedCategoryIds]
/// on any failure reaching Postgres for this check.
class SeedCategoryOwnershipCheckException implements Exception {
  const SeedCategoryOwnershipCheckException(this.cause);

  final Object cause;

  @override
  String toString() => 'SeedCategoryOwnershipCheckException($cause)';
}

/// HU-04's "don't reclaim a seed category the account already has" check
/// (`docs/requirements/05-auth-sync.md`, decision #12): a one-off query
/// straight against Postgres via [SupabaseClient] — not PowerSync, which may
/// not have finished hydrating this account's data yet at this point of the
/// merge — for which of this device's local `seed-*` category ids the
/// just-signed-in account already owns in the cloud.
@lazySingleton
class SeedCategoryOwnershipRemoteDatasource {
  const SeedCategoryOwnershipRemoteDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// Returns the subset of [seedIds] that already exist as rows owned by
  /// [userId] in Postgres's `categories` table. RLS (`user_id = auth.uid()`)
  /// already restricts reads to the signed-in account's own rows; `userId`
  /// is still filtered on explicitly so the query reads correctly on its own
  /// even if RLS were ever loosened.
  Future<List<String>> existingSeedCategoryIds(
    String userId,
    List<String> seedIds,
  ) async {
    if (seedIds.isEmpty) {
      return const [];
    }
    try {
      final rows = await _supabase
          .from('categories')
          .select('id')
          .eq('user_id', userId)
          .inFilter('id', seedIds);
      return rows.map((row) => row['id'] as String).toList();
    } on PostgrestException catch (e) {
      throw SeedCategoryOwnershipCheckException(e);
    } catch (e) {
      throw SeedCategoryOwnershipCheckException(e);
    }
  }
}
