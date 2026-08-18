import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Bug corregido (2026-08-17, docs/requirements/fase-1/05-auth-sync.md): a device
/// that already has a valid Supabase session at launch, but whose local
/// PowerSync store is empty or was reset (fresh install, PowerSync
/// reactivated after being disconnected), used to seed `AppSettings` and the
/// default categories with local defaults *before* PowerSync connected and
/// downloaded the user's real server values. Those seeded defaults then got
/// uploaded via `upsert(...resolution=merge-duplicates)` and silently
/// overwrote the real values on the server for any column present in the
/// seed payload.
///
/// `bootstrap.dart` calls this before `SeedDefaultCategories` (the first use
/// case that touches `AppDatabase`, which is also where Drift's `onCreate`
/// migration — and therefore `_seedAppSettings()` — first runs) so both
/// seeds only ever run once the user's real server state has had a chance to
/// land locally, when there is a server state to race at all.
@injectable
class WaitForFirstSyncBeforeSeeding {
  const WaitForFirstSyncBeforeSeeding(this._repository);

  final AuthRepository _repository;

  /// See `AuthRepository.waitForFirstSync` for the full contract: a no-op
  /// when there is no restorable session, and bounded by [timeout] so a
  /// session with no network at this exact launch cannot hang the app
  /// forever — the caller decides what to do with a `NetworkFailure`.
  FutureResult<Unit> call({Duration timeout = const Duration(seconds: 8)}) =>
      _repository.waitForFirstSync(timeout: timeout);
}
