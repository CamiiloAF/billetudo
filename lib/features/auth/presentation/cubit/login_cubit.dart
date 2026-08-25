import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/sign_in_outcome.dart';
import '../../domain/usecases/cancel_account_conflict.dart';
import '../../domain/usecases/resolve_account_conflict.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import 'login_state.dart';

/// Drives the loading/error UX of one sign-in attempt on the Login screen
/// (`QD8kh` loading, `JA0KD` error). Separate from `AuthCubit`: this only
/// cares about the attempt in progress on this screen, not the app-wide
/// session.
///
/// A sign-in attempt can also come back as [LoginStatus.accountConflictDetected]
/// (this device already holds local data owned by a different account) —
/// [resolveConflict]/[cancelConflict] are what the blocking confirmation
/// sheet calls to settle it.
@injectable
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(
    this._signInWithGoogle,
    this._signInWithApple,
    this._resolveAccountConflict,
    this._cancelAccountConflict,
  ) : super(const LoginState());

  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final ResolveAccountConflict _resolveAccountConflict;
  final CancelAccountConflict _cancelAccountConflict;

  Future<void> continueWithGoogle() =>
      _attempt(_signInWithGoogle.call, AuthProvider.google);

  Future<void> continueWithApple() =>
      _attempt(_signInWithApple.call, AuthProvider.apple);

  Future<void> _attempt(
    Future<Result<SignInOutcome>> Function() signIn,
    AuthProvider provider,
  ) async {
    emit(state.copyWith(status: LoginStatus.loading, lastProvider: provider));
    try {
      final result = await signIn();
      if (isClosed) {
        return;
      }
      result.fold(
        (failure) {
          if (failure is AuthCancelledFailure) {
            emit(state.copyWith(status: LoginStatus.idle));
          } else {
            emit(state.copyWith(status: LoginStatus.error, failure: failure));
          }
        },
        (outcome) {
          switch (outcome) {
            case SignedIn():
              emit(state.copyWith(status: LoginStatus.signedIn));
            case AccountConflictDetected():
              emit(state.copyWith(status: LoginStatus.accountConflictDetected));
          }
        },
      );
    } catch (e, st) {
      if (isClosed) {
        return;
      }
      // Last-resort net so a provider SDK throwing something unmapped shows
      // as a sign-in error instead of crashing the screen. The cause is kept
      // intact — an earlier version flattened everything into a fixed
      // "auth backend not wired yet" message, which hid real failures once
      // the backend was in fact wired.
      emit(
        state.copyWith(
          status: LoginStatus.error,
          failure: UnexpectedFailure(
            'sign-in failed unexpectedly',
            cause: e,
            stackTrace: st,
          ),
        ),
      );
    }
  }

  /// The confirmation sheet's "borrar y continuar": wipes this device's
  /// local data and completes the sign-in that was held back.
  Future<void> resolveConflict() async {
    try {
      final result = await _resolveAccountConflict();
      if (isClosed) {
        return;
      }
      result.fold(
        (failure) =>
            emit(state.copyWith(status: LoginStatus.error, failure: failure)),
        (_) => emit(
          state.copyWith(
            status: LoginStatus.signedIn,
            signedInAfterConflict: true,
          ),
        ),
      );
    } catch (e, st) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LoginStatus.error,
          failure: UnexpectedFailure(
            'resolving the account conflict failed unexpectedly',
            cause: e,
            stackTrace: st,
          ),
        ),
      );
    }
  }

  /// The confirmation sheet's "cancelar": closes the just-exchanged session
  /// entirely (Supabase + Google/Apple + PowerSync) without touching this
  /// device's existing local data and without ever completing the sign-in.
  Future<void> cancelConflict() async {
    try {
      final result = await _cancelAccountConflict();
      if (isClosed) {
        return;
      }
      result.fold(
        (failure) =>
            emit(state.copyWith(status: LoginStatus.error, failure: failure)),
        (_) => emit(state.copyWith(status: LoginStatus.idle)),
      );
    } catch (e, st) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LoginStatus.error,
          failure: UnexpectedFailure(
            'cancelling the account conflict failed unexpectedly',
            cause: e,
            stackTrace: st,
          ),
        ),
      );
    }
  }

  void dismissError() => emit(state.copyWith(status: LoginStatus.idle));
}
