import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/notifications/domain/entities/notification_kind.dart';
import '../../../../core/notifications/domain/usecases/open_notification_system_settings.dart';
import '../../../../core/notifications/domain/usecases/read_notification_permission.dart';
import '../../../../core/notifications/domain/usecases/read_notification_preferences.dart';
import '../../../../core/notifications/domain/usecases/set_notification_kind_enabled.dart';
import '../../../scheduled_payments/domain/usecases/sync_scheduled_payment_reminders.dart';
import 'notification_settings_state.dart';

/// Drives the "Notificaciones" screen reached from Ajustes.
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
    this._readPermission,
    this._openSystemSettings,
  ) : super(const NotificationSettingsState());

  final ReadNotificationPreferences _readPreferences;
  final SetNotificationKindEnabled _setKindEnabled;
  final SyncScheduledPaymentReminders _syncReminders;
  final ReadNotificationPermission _readPermission;
  final OpenNotificationSystemSettings _openSystemSettings;

  Future<void> start() async {
    final preferences = await _readPreferences();
    final permission = await _readPermission();
    if (isClosed) {
      return;
    }
    emit(
      NotificationSettingsState(
        enabledByKind: preferences,
        loaded: true,
        // A failure reading the permission is not a denial: assume granted
        // rather than accuse the phone of something it may not be doing.
        permissionGranted: permission.getOrElse((_) => true),
      ),
    );
  }

  /// Re-reads the permission after coming back from the system settings —
  /// the OS gives no callback, so the screen asks again when it resumes.
  Future<void> refreshPermission() async {
    final permission = await _readPermission();
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(permissionGranted: permission.getOrElse((_) => true)),
    );
  }

  Future<void> openSystemSettings() => _openSystemSettings();

  Future<void> setEnabled(
    NotificationKind kind, {
    required bool enabled,
  }) async {
    await _setKindEnabled(kind, enabled: enabled);
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
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
