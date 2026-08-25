import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/auth_provider.dart';

enum LoginStatus { idle, loading, signedIn, accountConflictDetected, error }

/// State of the Login screen (`fTetG`/`RSzD1`, HU-02/HU-03).
class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.idle,
    this.failure,
    this.lastProvider,
    this.signedInAfterConflict = false,
  });

  final LoginStatus status;
  final Failure? failure;

  /// Which provider the last (or in-flight) attempt used — decides whether
  /// the error snackbar mentions Google or Apple.
  final AuthProvider? lastProvider;

  /// True only when [status] is [LoginStatus.signedIn] because the user
  /// resolved a blocking [LoginStatus.accountConflictDetected] (this
  /// device's local data was wiped and the held-back sign-in was then
  /// completed), not a plain sign-in. Callers (the router) use this to skip
  /// `MergeConfirmationPage` — there is nothing left on this device to fold
  /// in after a wipe.
  final bool signedInAfterConflict;

  LoginState copyWith({
    LoginStatus? status,
    Failure? failure,
    AuthProvider? lastProvider,
    bool signedInAfterConflict = false,
  }) =>
      LoginState(
        status: status ?? this.status,
        failure: failure,
        lastProvider: lastProvider ?? this.lastProvider,
        signedInAfterConflict: signedInAfterConflict,
      );

  @override
  List<Object?> get props =>
      [status, failure, lastProvider, signedInAfterConflict];
}
