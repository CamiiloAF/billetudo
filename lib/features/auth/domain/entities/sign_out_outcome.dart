import '../../../../core/error/failure.dart';

/// Result of HU-06's sign out, which may also wipe this device.
///
/// Sealed on purpose: the endings are not interchangeable and none of them
/// collapses into a `bool` or a generic `Result<Unit>`. In particular
/// [SignedOutButWipeFailed] is *not* a plain failure — the session really is
/// closed, only the local wipe didn't happen — and it must never be reported
/// to the user as a success. And [SignOutFailed] is its mirror image: nothing
/// at all happened, including the wipe.
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

/// The sign out itself failed, so **nothing** was done: the session is still
/// open and, whatever the user picked, this device was not wiped.
///
/// Wiping here would be worse than not wiping: the session surviving on disk
/// means the next launch restores it, PowerSync reconnects and downloads
/// everything back — the user would have been told their data was deleted and
/// then watch it reappear. The UI must say the sign out didn't go through and
/// that nothing was deleted, so retrying is the obvious next step.
class SignOutFailed extends SignOutOutcome {
  const SignOutFailed(this.failure);

  final Failure failure;
}
