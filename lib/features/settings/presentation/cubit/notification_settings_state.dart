import 'package:equatable/equatable.dart';

import '../../../../core/notifications/domain/entities/notification_kind.dart';

/// State of the "Notificaciones" screen: one switch per [NotificationKind],
/// plus whether the OS is letting anything through at all.
class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.enabledByKind = const <NotificationKind, bool>{},
    this.loaded = false,
    this.permissionGranted = true,
  });

  final Map<NotificationKind, bool> enabledByKind;

  /// False until the preferences have been read once. The section renders its
  /// switches optimistically as ON meanwhile (the stored default), so it does
  /// not flash from off to on.
  final bool loaded;

  /// Whether the OS notification permission is currently granted.
  ///
  /// Optimistically `true` before the first read, for the same reason as
  /// [loaded]: flashing the "permiso denegado" strip on every open of the
  /// screen would be a lie most of the time.
  ///
  /// When `false`, the stored per-kind values are **kept untouched** — the
  /// screen renders them inert and restores them as they were the moment the
  /// permission comes back.
  final bool permissionGranted;

  bool isEnabled(NotificationKind kind) => enabledByKind[kind] ?? true;

  NotificationSettingsState copyWith({
    Map<NotificationKind, bool>? enabledByKind,
    bool? loaded,
    bool? permissionGranted,
  }) =>
      NotificationSettingsState(
        enabledByKind: enabledByKind ?? this.enabledByKind,
        loaded: loaded ?? this.loaded,
        permissionGranted: permissionGranted ?? this.permissionGranted,
      );

  @override
  List<Object?> get props => [enabledByKind, loaded, permissionGranted];
}
