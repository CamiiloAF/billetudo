import 'package:equatable/equatable.dart';

/// Account-level app preferences that sync across devices (a single row in
/// Drift's `AppSettings`, id `'app'`).
///
/// Pure domain entity: it never carries the Drift row type. Today it holds the
/// "Modo sobres" (zero-based) flag (HU-06); more synced preferences (default
/// currency) will land here.
class AppSettings extends Equatable {
  const AppSettings({required this.zeroBasedEnabled});

  /// Sensible default before the singleton row has been read.
  const AppSettings.defaults() : zeroBasedEnabled = false;

  /// Whether "Modo sobres" (zero-based budgeting) is on (HU-06).
  final bool zeroBasedEnabled;

  AppSettings copyWith({bool? zeroBasedEnabled}) => AppSettings(
        zeroBasedEnabled: zeroBasedEnabled ?? this.zeroBasedEnabled,
      );

  @override
  List<Object?> get props => [zeroBasedEnabled];
}
