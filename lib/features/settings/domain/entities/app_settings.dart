import 'package:equatable/equatable.dart';

/// Account-level app preferences that sync across devices (a single row in
/// Drift's `AppSettings`, id `'app'`).
///
/// Pure domain entity: it never carries the Drift row type. Today it holds the
/// "Modo sobres" (zero-based) flag (HU-06); more synced preferences (default
/// currency) will land here.
class AppSettings extends Equatable {
  const AppSettings({
    required this.zeroBasedEnabled,
    required this.categoriesSeeded,
    required this.onboardingCompleted,
  });

  /// Sensible default before the singleton row has been read.
  const AppSettings.defaults()
      : zeroBasedEnabled = false,
        categoriesSeeded = false,
        onboardingCompleted = false;

  /// Whether "Modo sobres" (zero-based budgeting) is on (HU-06).
  final bool zeroBasedEnabled;

  /// Whether the onboarding default categories have already been seeded for
  /// this installation (HU-06). Once true, never seeded again — even if the
  /// user deletes every category.
  final bool categoriesSeeded;

  /// One-shot latch for the welcome flow (`docs/requirements/13-onboarding.md`).
  /// Turns on once the user reaches the closing screen and acts on it (or logs
  /// in via "Ya tengo cuenta"), or silently if the installation already had an
  /// active account when first evaluated. Never turns off again.
  final bool onboardingCompleted;

  AppSettings copyWith({
    bool? zeroBasedEnabled,
    bool? categoriesSeeded,
    bool? onboardingCompleted,
  }) =>
      AppSettings(
        zeroBasedEnabled: zeroBasedEnabled ?? this.zeroBasedEnabled,
        categoriesSeeded: categoriesSeeded ?? this.categoriesSeeded,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      );

  @override
  List<Object?> get props =>
      [zeroBasedEnabled, categoriesSeeded, onboardingCompleted];
}
