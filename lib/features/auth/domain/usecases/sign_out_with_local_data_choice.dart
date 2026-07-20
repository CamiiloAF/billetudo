import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
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
@injectable
class SignOutWithLocalDataChoice {
  const SignOutWithLocalDataChoice(this._signOut, this._wipeLocalData);

  final SignOut _signOut;
  final WipeLocalData _wipeLocalData;

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
      (_) => const SignedOutAndWiped(),
    );
  }
}
