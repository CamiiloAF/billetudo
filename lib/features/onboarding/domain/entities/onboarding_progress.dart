import 'package:equatable/equatable.dart';

import 'onboarding_step.dart';

/// In-memory state of the welcome flow while it is running.
///
/// This is **not** persisted anywhere: `docs/requirements/13-onboarding.md`
/// ("Interrupción a mitad") is explicit that killing the app mid-flow resets
/// it to the beginning on the next launch — only the `AppSettings.
/// onboardingCompleted` latch (settings feature) and whatever accounts the
/// user already created survive. So this entity is owned and held by the
/// presentation cubit, never written to Drift.
class OnboardingProgress extends Equatable {
  const OnboardingProgress({
    this.step = OnboardingStep.welcome,
    this.accountSkipped = false,
    this.authenticatedViaLogin = false,
  });

  /// The screen currently shown.
  final OnboardingStep step;

  /// Whether the user chose "Omitir" on [OnboardingStep.account] (HU-02).
  /// Drives the closing screen's CTA (HU-04): if `true`, it bridges to
  /// creating an account instead of opening the transaction form.
  final bool accountSkipped;

  /// Whether the user authenticated via "Ya tengo cuenta" (HU-06) — either
  /// from [OnboardingStep.welcome] or from [OnboardingStep.backup]'s "Activar
  /// respaldo" (HU-07). When `true`, [OnboardingStep.backup] is skipped
  /// entirely ("no repetir el mensaje tres veces") and the flow closes as soon
  /// as the merge (`05-auth-sync.md` HU-04) finishes.
  final bool authenticatedViaLogin;

  OnboardingProgress copyWith({
    OnboardingStep? step,
    bool? accountSkipped,
    bool? authenticatedViaLogin,
  }) =>
      OnboardingProgress(
        step: step ?? this.step,
        accountSkipped: accountSkipped ?? this.accountSkipped,
        authenticatedViaLogin:
            authenticatedViaLogin ?? this.authenticatedViaLogin,
      );

  @override
  List<Object?> get props => [step, accountSkipped, authenticatedViaLogin];
}
