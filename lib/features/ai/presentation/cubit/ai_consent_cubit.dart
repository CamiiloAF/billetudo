import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/usecases/get_app_settings.dart';
import '../../../settings/domain/usecases/mark_ai_consent_accepted.dart';
import 'ai_consent_state.dart';

/// Gates the assistant's composer behind `AppSettings.aiConsentAcceptedAt`
/// (Apple 5.1.2(i)): the first message can only be typed after this cubit
/// reports [AiConsentStatus.granted].
///
/// Reactive to [GetAppSettings] rather than a one-shot read, so a consent
/// accepted on another device (it syncs like every other `AppSettings`
/// field) unlocks the composer here too without a relaunch.
@injectable
class AiConsentCubit extends Cubit<AiConsentState> {
  AiConsentCubit(this._getAppSettings, this._markAiConsentAccepted)
      : super(const AiConsentState());

  final GetAppSettings _getAppSettings;
  final MarkAiConsentAccepted _markAiConsentAccepted;

  StreamSubscription<Result<AppSettings>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const AiConsentState());
    _subscription = _getAppSettings().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          // Unreadable settings fail closed: consent is asked again rather
          // than silently assumed.
          (failure) => state.copyWith(status: AiConsentStatus.required),
          (settings) => state.copyWith(
            status: settings.hasAcceptedAiConsent
                ? AiConsentStatus.granted
                : AiConsentStatus.required,
          ),
        ),
      );
    });
  }

  Future<void> accept() async {
    if (state.accepting) {
      return;
    }
    emit(state.copyWith(accepting: true));
    final result = await _markAiConsentAccepted();
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(accepting: false),
        (_) => state.copyWith(
          status: AiConsentStatus.granted,
          accepting: false,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
