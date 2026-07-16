import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/auth_provider.dart';

enum LoginStatus { idle, loading, signedIn, error }

/// State of the Login screen (`fTetG`/`RSzD1`, HU-02/HU-03).
class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.idle,
    this.failure,
    this.lastProvider,
  });

  final LoginStatus status;
  final Failure? failure;

  /// Which provider the last (or in-flight) attempt used — decides whether
  /// the error snackbar mentions Google or Apple.
  final AuthProvider? lastProvider;

  LoginState copyWith({
    LoginStatus? status,
    Failure? failure,
    AuthProvider? lastProvider,
  }) =>
      LoginState(
        status: status ?? this.status,
        failure: failure,
        lastProvider: lastProvider ?? this.lastProvider,
      );

  @override
  List<Object?> get props => [status, failure, lastProvider];
}
