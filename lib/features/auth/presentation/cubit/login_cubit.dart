import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import 'login_state.dart';

/// Drives the loading/error UX of one sign-in attempt on the Login screen
/// (`QD8kh` loading, `JA0KD` error). Separate from `AuthCubit`: this only
/// cares about the attempt in progress on this screen, not the app-wide
/// session.
@injectable
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._signInWithGoogle, this._signInWithApple)
      : super(const LoginState());

  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;

  Future<void> continueWithGoogle() =>
      _attempt(_signInWithGoogle.call, AuthProvider.google);

  Future<void> continueWithApple() =>
      _attempt(_signInWithApple.call, AuthProvider.apple);

  Future<void> _attempt(
    Future<Result<AuthUser>> Function() signIn,
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
        (_) => emit(state.copyWith(status: LoginStatus.signedIn)),
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

  void dismissError() => emit(state.copyWith(status: LoginStatus.idle));
}
