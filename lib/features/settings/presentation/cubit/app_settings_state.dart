import 'package:equatable/equatable.dart';

import '../../domain/entities/app_settings.dart';

/// State of the account-level app settings (HU-06). Starts with the safe
/// defaults so the toggle renders before the first stream value arrives.
class AppSettingsState extends Equatable {
  const AppSettingsState({this.settings = const AppSettings.defaults()});

  final AppSettings settings;

  bool get zeroBasedEnabled => settings.zeroBasedEnabled;

  AppSettingsState copyWith({AppSettings? settings}) =>
      AppSettingsState(settings: settings ?? this.settings);

  @override
  List<Object?> get props => [settings];
}
