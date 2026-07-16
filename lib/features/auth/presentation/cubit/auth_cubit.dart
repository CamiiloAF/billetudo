import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/watch_auth_session.dart';

/// The app-wide backup/sync session (HU-01, HU-06): a single shared instance
/// (`@singleton`) so Ajustes, "Más" and Login all agree on whether the user
/// is signed in, without any of them owning the source of truth.
///
/// Never gates navigation — every screen that reads this only changes what it
/// *shows* (session card vs. "Respaldar en la nube"), never whether a Nivel 0
/// feature is reachable.
@singleton
class AuthCubit extends Cubit<AuthSession> {
  AuthCubit(this._watchAuthSession, this._signOut)
      : super(_watchAuthSession.current);

  final WatchAuthSession _watchAuthSession;
  final SignOut _signOut;

  StreamSubscription<AuthSession>? _subscription;

  void start() {
    _subscription ??= _watchAuthSession().listen(emit);
  }

  Future<void> signOut() => _signOut();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
