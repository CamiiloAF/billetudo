import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../../domain/entities/onboarding_step.dart';
import '../../domain/usecases/complete_onboarding.dart';

/// Orchestrates the welcome flow's shared state across its four screens
/// (`13-onboarding.md`, "Secuencia real del flujo").
///
/// This does **not** own account creation or login: those stay the real
/// `AccountFormCubit` (Cuentas) and `LoginCubit`/`MergeCubit` (Auth)
/// instances the router wires up per step — this cubit only remembers the
/// two facts the closing screen (HU-04) and "no repetir el mensaje tres
/// veces" (HU-07) need afterward: whether the account step was skipped, and
/// whether the user already authenticated via "Ya tengo cuenta"/"Activar
/// respaldo".
///
/// Registered `@lazySingleton` (not `@injectable`) so the same instance
/// survives across the `go_router` pushes between onboarding screens — each
/// step is a separate route/page, not a page inside one `PageView`, so a
/// factory-scoped cubit would lose this state the moment the user moved to
/// the next screen.
///
/// Deliberately does **not** call `ShouldShowOnboarding` itself: that latch
/// is evaluated exactly once, in `bootstrap.dart`, to decide the router's
/// `initialLocation` before the widget tree exists at all
/// (`13-onboarding.md`, "El gate se evalúa una sola vez por arranque, tras el
/// bootstrap"). Calling it again here would either be a redundant read (the
/// common case) or, worse, a second place that could disagree with the
/// router about whether the flow should be showing — the single evaluation
/// point is what the requirements document asks for.
@lazySingleton
class OnboardingFlowCubit extends Cubit<OnboardingProgress> {
  OnboardingFlowCubit(this._completeOnboarding)
      : super(const OnboardingProgress());

  final CompleteOnboarding _completeOnboarding;

  /// Marks the screen currently shown — purely informational bookkeeping for
  /// [OnboardingProgress.step]; navigation itself is `go_router`'s job.
  void stepped(OnboardingStep step) => emit(state.copyWith(step: step));

  /// The user tapped "Crear cuenta" and it saved (HU-02).
  void accountCreated() => emit(state.copyWith(accountSkipped: false));

  /// The user tapped "Omitir por ahora" (HU-02) — the closing screen must
  /// bridge to account creation instead of opening the transaction form.
  void accountSkipped() => emit(state.copyWith(accountSkipped: true));

  /// "Ya tengo cuenta" (HU-06) or "Activar respaldo" (HU-07) finished
  /// authenticating — the backup screen must not show again.
  void authenticated() => emit(state.copyWith(authenticatedViaLogin: true));

  /// Turns the `onboardingCompleted` latch on for good (HU-04/HU-06/HU-07).
  FutureResult<Unit> finish() => _completeOnboarding();
}
