import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../../categories/domain/usecases/seed_default_categories.dart';
import 'wipe_local_data.dart';

/// HU-07 paso 2: wipes local data after the cloud account is already gone,
/// re-seeding the default categories afterwards.
///
/// Same rule as `SignOutWithLocalDataChoice` (HU-06): [WipeLocalData] empties
/// every synced table, including the `app_settings` singleton where the
/// `categoriesSeeded` latch lives, so the latch resets to `false`. We call
/// [SeedDefaultCategories] right after a successful wipe so the defaults come
/// back **in the same session**, instead of only on the next launch
/// (`bootstrap.dart` seeds there too, as a stopgap).
///
/// The re-seed is **best-effort and never changes the wipe [Result]**: if it
/// fails (e.g. `NetworkFailure` while offline — the catalog now lives in
/// Supabase, decisión #12 in `docs/requirements/05-auth-sync.md`) the wipe
/// itself still succeeded, and the reset latch means the next launch seeds
/// again anyway. We only log the failure via [CrashReporter], mirroring how
/// `bootstrap.dart` treats a seed failure as non-fatal.
@injectable
class WipeLocalDataAfterDeletion {
  const WipeLocalDataAfterDeletion(
    this._wipeLocalData,
    this._seedDefaultCategories,
    this._crashReporter,
  );

  final WipeLocalData _wipeLocalData;
  final SeedDefaultCategories _seedDefaultCategories;
  final CrashReporter _crashReporter;

  FutureResult<Unit> call() async {
    final result = await _wipeLocalData();
    return result.fold(Left.new, (value) {
      // Best-effort: re-seed the defaults now, but never let a seed failure
      // downgrade a successful wipe — the next launch re-seeds via the reset
      // latch regardless.
      unawaited(_reseedDefaultsBestEffort());
      return Right(value);
    });
  }

  Future<void> _reseedDefaultsBestEffort() async {
    final seedResult = await _seedDefaultCategories();
    if (seedResult case Left(value: final failure)) {
      await _crashReporter.recordFailure(
        failure,
        context: 'reseedDefaultCategoriesAfterAccountDeletionWipe',
      );
    }
  }
}
