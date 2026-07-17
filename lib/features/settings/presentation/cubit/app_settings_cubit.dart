import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_app_settings.dart';
import '../../domain/usecases/set_zero_based_enabled.dart';
import 'app_settings_state.dart';

/// Drives the account-level settings shown in Ajustes (HU-06). Talks only to
/// use cases. The toggle is optimistic against the settings stream, which is the
/// source of truth and re-emits the persisted value.
@injectable
class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._getAppSettings, this._setZeroBasedEnabled)
      : super(const AppSettingsState());

  final GetAppSettings _getAppSettings;
  final SetZeroBasedEnabled _setZeroBasedEnabled;

  StreamSubscription<Result<AppSettings>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _getAppSettings().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (_) {},
        (settings) => emit(state.copyWith(settings: settings)),
      );
    });
  }

  /// Persists the "Modo sobres" flag (HU-06). The stream re-emits the stored
  /// value, so no manual state juggling is needed.
  Future<void> setZeroBasedEnabled(bool enabled) =>
      _setZeroBasedEnabled(enabled);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
