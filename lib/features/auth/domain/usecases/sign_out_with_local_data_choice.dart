import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../../categories/domain/usecases/seed_default_categories.dart';
import '../entities/local_data_choice.dart';
import '../entities/sign_out_outcome.dart';
import 'sign_out.dart';
import 'wipe_local_data.dart';

/// HU-06: signs out and, if that's what the user picked, wipes this device.
///
/// Order matters: **sign out first, wipe second.** [SignOut] awaits its own
/// PowerSync disconnect, so by the time it returns `Right` nothing can
/// re-download while the wipe runs. The other way around, a `signOut` that
/// failed after the wipe would leave a live session over an empty database and
/// sync would pull everything back — the delete would have achieved nothing.
///
/// Which is also why a `signOut` that fails **aborts the wipe** entirely
/// ([SignOutFailed]): a live session over a wiped database is that same
/// scenario, and confirming a deletion the next launch undoes is worse than
/// not deleting at all.
///
/// If the wipe fails the session is already closed, so the caller gets
/// [SignedOutButWipeFailed] and tells the user their data is still here,
/// instead of handing them a false success.
///
/// Composes the existing [SignOut] and [WipeLocalData] rather than talking to
/// `AuthRepository` directly: those two already are the business operations
/// being sequenced, so the only thing this adds is the ordering rule and the
/// outcome — which is exactly what a test should be able to pin down.
///
/// Re-seeding after a wipe (HU-06): the wipe empties every synced table,
/// including the `app_settings` singleton where the `categoriesSeeded` latch
/// lives, so the latch resets to `false`. We call [SeedDefaultCategories] right
/// after a successful wipe so the defaults come back **in the same session**,
/// instead of only on the next launch (bootstrap seeds there too). This is
/// deliberately here — composing a categories use case from auth is still just
/// composition of use cases — because it keeps the "re-seed after wipe" rule
/// testable at this seam, exactly like the ordering rule above.
///
/// The re-seed is **best-effort and never changes the [SignOutOutcome]**: if it
/// fails (e.g. `NetworkFailure` while offline — the catalog now lives in
/// Supabase, decisión #12 in `docs/requirements/05-auth-sync.md`) the sign-out
/// and wipe still succeeded, and the reset latch means the next launch seeds
/// again anyway. We only log the failure via [CrashReporter], mirroring how
/// `bootstrap.dart` treats a seed failure as non-fatal. Only HU-06's wipe path
/// re-seeds; account deletion (HU-07) is out of scope and doesn't pass here.
@injectable
class SignOutWithLocalDataChoice {
  const SignOutWithLocalDataChoice(
    this._signOut,
    this._wipeLocalData,
    this._seedDefaultCategories,
    this._crashReporter,
  );

  final SignOut _signOut;
  final WipeLocalData _wipeLocalData;
  final SeedDefaultCategories _seedDefaultCategories;
  final CrashReporter _crashReporter;

  Future<SignOutOutcome> call(LocalDataChoice choice) async {
    final signOutResult = await _signOut();
    if (signOutResult case Left(value: final failure)) {
      return SignOutFailed(failure);
    }

    if (choice == LocalDataChoice.keep) {
      return const SignedOutKeepingData();
    }

    final result = await _wipeLocalData();
    return result.fold(
      SignedOutButWipeFailed.new,
      (_) {
        // Best-effort: re-seed the defaults now, but never let a seed failure
        // downgrade a successful wipe — the next launch re-seeds via the reset
        // latch regardless.
        unawaited(_reseedDefaultsBestEffort());
        return const SignedOutAndWiped();
      },
    );
  }

  Future<void> _reseedDefaultsBestEffort() async {
    final seedResult = await _seedDefaultCategories();
    if (seedResult case Left(value: final failure)) {
      await _crashReporter.recordFailure(
        failure,
        context: 'reseedDefaultCategoriesAfterWipe',
      );
    }
  }
}
