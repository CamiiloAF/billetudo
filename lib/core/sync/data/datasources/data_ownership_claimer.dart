import '../../../error/result.dart';

/// Stamps `userId` on local rows that were created before any account
/// signed in on this device — the "claim" step behind HU-04's post-login
/// merge, and (since the JSON restore ownership fix) behind restoring a
/// `.billetudo.json` backup while a session is already active.
///
/// Implemented in
/// `features/auth/data/datasources/local_data_ownership_datasource.dart`
/// (that is where the seed-category ownership check against Postgres
/// lives, decision #12 in `docs/requirements/fase-1/05-auth-sync.md`);
/// exposed here so other features (ej. `import_export`) never import
/// `auth/data` directly — only this core-level abstraction.
abstract class DataOwnershipClaimer {
  /// Claims every row with `user_id IS NULL`, across every synced table,
  /// for [userId]. Once `user_id` is set, PowerSync's write interception
  /// treats each row as changed and queues it for upload on its own — there
  /// is no separate upload step to trigger.
  FutureResult<Unit> claimUnownedRows(String userId);
}
