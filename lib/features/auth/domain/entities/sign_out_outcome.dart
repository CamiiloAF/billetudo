import '../../../../core/error/failure.dart';

/// Result of HU-06's sign out, which may also wipe this device.
///
/// Sealed on purpose: the three endings are not interchangeable and none of
/// them collapses into a `bool` or a generic `Result<Unit>`. In particular
/// [SignedOutButWipeFailed] is *not* a plain failure — the session really is
/// closed, only the local wipe didn't happen — and it must never be reported
/// to the user as a success.
sealed class SignOutOutcome {
  const SignOutOutcome();
}

/// Signed out, and the user chose to keep the data on this device.
class SignedOutKeepingData extends SignOutOutcome {
  const SignedOutKeepingData();
}

/// Signed out and wiped this device, both steps fine.
class SignedOutAndWiped extends SignOutOutcome {
  const SignedOutAndWiped();
}

/// Signed out, but the wipe failed: the data is still on the phone. The UI owes
/// the user that exact message instead of a false success.
class SignedOutButWipeFailed extends SignOutOutcome {
  const SignedOutButWipeFailed(this.failure);

  final Failure failure;
}
