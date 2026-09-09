import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/notifications/domain/entities/notification_kind.dart';
import '../../../../core/notifications/domain/usecases/read_notification_preferences.dart';
import '../../../../core/notifications/domain/usecases/set_notification_kind_enabled.dart';
import '../../../scheduled_payments/domain/usecases/sync_scheduled_payment_reminders.dart';
import 'notification_settings_state.dart';

/// Drives the "Avisos" section of Ajustes.
///
/// Turning a kind off also reconciles the reminder set right away
/// ([SyncScheduledPaymentReminders]) instead of waiting for the next app
/// start: a switch the user just flipped off must stop producing
/// notifications now, or the next one that arrives reads as the app ignoring
/// them.
@injectable
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(
    this._readPreferences,
    this._setKindEnabled,
    this._syncReminders,
  ) : super(const NotificationSettingsState());

  final ReadNotificationPreferences _readPreferences;
  final SetNotificationKindEnabled _setKindEnabled;
  final SyncScheduledPaymentReminders _syncReminders;

  Future<void> start() async {
    final preferences = await _readPreferences();
    if (isClosed) {
      return;
    }
    emit(
      NotificationSettingsState(enabledByKind: preferences, loaded: true),
    );
  }

  Future<void> setEnabled(
    NotificationKind kind, {
    required bool enabled,
  }) async {
    await _setKindEnabled(kind, enabled: enabled);
    if (isClosed) {
      return;
    }
    emit(
      NotificationSettingsState(
        enabledByKind: <NotificationKind, bool>{
          ...state.enabledByKind,
          kind: enabled,
        },
        loaded: true,
      ),
    );
    await _syncReminders();
  }
}
