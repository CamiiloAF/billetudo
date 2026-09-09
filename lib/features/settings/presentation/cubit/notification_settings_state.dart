import 'package:equatable/equatable.dart';

import '../../../../core/notifications/domain/entities/notification_kind.dart';

/// State of the "Avisos" section of Ajustes: one switch per
/// [NotificationKind].
class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.enabledByKind = const <NotificationKind, bool>{},
    this.loaded = false,
  });

  final Map<NotificationKind, bool> enabledByKind;

  /// False until the preferences have been read once. The section renders its
  /// switches optimistically as ON meanwhile (the stored default), so it does
  /// not flash from off to on.
  final bool loaded;

  bool isEnabled(NotificationKind kind) => enabledByKind[kind] ?? true;

  @override
  List<Object?> get props => [enabledByKind, loaded];
}
