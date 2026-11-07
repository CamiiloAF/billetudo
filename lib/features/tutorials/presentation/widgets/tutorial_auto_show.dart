import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_route_observer.dart';
import '../../../../core/widgets/tutorial_sheet.dart';
import '../../domain/entities/tutorial_key.dart';
import '../../domain/usecases/has_seen_tutorial.dart';
import '../../domain/usecases/mark_tutorial_seen.dart';
import '../cubit/tutorial_gate_cubit.dart';
import '../utils/tutorial_content_catalog.dart';

/// Result of one [maybeShowTutorial] attempt.
enum TutorialShowOutcome {
  /// The sheet was shown and the tutorial recorded as seen.
  shown,

  /// The gate said no (already seen, help off, account gate has precedence,
  /// another tutorial just showed) or the DI graph is not available. Nothing
  /// to retry: the answer will not change on the next navigation.
  skipped,

  /// The screen that owns the trigger was not the one the user was looking
  /// at, so nothing was evaluated or marked. The caller may retry when
  /// navigation changes (that is what [TutorialAutoShow] does).
  notVisible,
}

/// Whether the screen that owns [context] is the one the user is actually
/// looking at.
///
/// `ModalRoute.isCurrent` alone is not enough: the app's tab shell is a
/// `StatefulShellRoute`, so a branch's route stays `isCurrent` inside its own
/// navigator even while a root-level page covers the whole shell (the
/// onboarding → "crear cuenta" flow does exactly that: `go(inicio)` mounts
/// Inicio and immediately pushes the account form on the root navigator). In
/// that state a tutorial evaluated from Inicio would pop over the account
/// form, which is the reported bug. Hence the second check: a nested route is
/// only visible while nothing is pushed above the shell on the root navigator.
bool isTutorialSurfaceVisible(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route == null) {
    // No route (bare widget test harness): nothing can be covering it.
    return true;
  }
  if (!route.isCurrent) {
    return false;
  }
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final routeNavigator = route.navigator;
  if (routeNavigator == null || routeNavigator == rootNavigator) {
    return true;
  }
  return !rootNavigator.canPop();
}

/// Evaluates [key] (via [TutorialGateCubit]) and, if it qualifies, shows its
/// sheet and marks it seen — the exact "evaluate, then show, then mark seen,
/// then optionally navigate" sequence every one of the 12 trigger points
/// needs, whether it fires on mount ([TutorialAutoShow]) or on a specific
/// user action (e.g. flipping "Modo sobres" on).
///
/// Never shows over a screen the user is not looking at: if
/// [isTutorialSurfaceVisible] is false, it returns
/// [TutorialShowOutcome.notVisible] **without evaluating the gate**, so
/// nothing is claimed or marked and the caller can retry later. That check
/// runs both before evaluating and again right before showing, because the
/// gate reads storage asynchronously and navigation can land in between.
///
/// [skipIfSeen], when given, is checked *before* evaluating [key] at all: if
/// that other tutorial has already been seen, [key] is skipped outright
/// without consuming the `TutorialNavigationGuard` slot. This is the
/// "Modo sobres" rule (`docs/requirements/fase-1/16-minitutoriales.md`): its own
/// sub-flow tutorial never shows once the Presupuestos screen tutorial
/// ([TutorialKey.budgetsScreen]) has been seen — the concept is already
/// covered there.
///
/// Not on the original change map: added because 11 trigger sites sharing
/// this exact sequence should not each hand-roll it — one call site
/// forgetting to mark seen after a gesture-dismiss is exactly the kind of
/// drift this file exists to prevent.
///
/// No-ops silently (never throws) when the tutorials feature's DI graph is
/// not registered — true in production (bootstrapped once at app start) but
/// not in most existing widget tests for the 12 screens/sub-flows this wires
/// into, which build their widget under test directly without
/// `configureDependencies()`. Those tests were never about minitutorials, so
/// their pages/sheets should keep working exactly as before rather than
/// crash on an unrelated, decorative side-feature.
Future<TutorialShowOutcome> maybeShowTutorial(
  BuildContext context,
  TutorialKey key, {
  bool accountGateShown = false,
  TutorialKey? skipIfSeen,
  FutureOr<void> Function(BuildContext context)? onCta,
}) async {
  if (!getIt.isRegistered<TutorialGateCubit>()) {
    return TutorialShowOutcome.skipped;
  }
  if (!isTutorialSurfaceVisible(context)) {
    return TutorialShowOutcome.notVisible;
  }
  if (skipIfSeen != null) {
    final skipSeenResult = await getIt<HasSeenTutorial>()(skipIfSeen);
    final skipSeen = skipSeenResult.fold((_) => false, (v) => v);
    if (skipSeen || !context.mounted) {
      return TutorialShowOutcome.skipped;
    }
  }

  final gate = getIt<TutorialGateCubit>();
  final content = TutorialContentCatalog.of(context, key);
  final shouldShow = await gate.evaluate(
    content: content,
    accountGateShown: accountGateShown,
  );
  if (!shouldShow || !context.mounted) {
    return TutorialShowOutcome.skipped;
  }
  if (!isTutorialSurfaceVisible(context)) {
    // Navigation landed while the gate was reading storage. The navigation
    // guard slot is already claimed for this entry, so the next navigation is
    // the caller's cue to try again.
    return TutorialShowOutcome.notVisible;
  }

  final result = await TutorialSheet.show(context, content);
  await getIt<MarkTutorialSeen>()(key);
  if (result == TutorialSheetResult.cta && onCta != null && context.mounted) {
    await onCta(context);
  }
  return TutorialShowOutcome.shown;
}

/// Wraps [child] and, once mounted, calls [maybeShowTutorial] for
/// [tutorialKey] — the shape every HU-01 screen and most HU-02 sub-flows use
/// (the ones triggered by *opening* a screen/control, not by a specific
/// in-place action like flipping a switch on).
///
/// When the attempt comes back [TutorialShowOutcome.notVisible] the tutorial
/// stays pending and is retried on the next navigation change, so covering the
/// screen for a moment (onboarding pushes the account form over Inicio right
/// after mounting it) delays the tutorial instead of losing it — and never
/// shows it over the screen that covered it.
class TutorialAutoShow extends StatefulWidget {
  const TutorialAutoShow({
    required this.tutorialKey,
    required this.child,
    this.onCta,
    this.accountGateShown = false,
    this.skipIfSeen,
    super.key,
  });

  final TutorialKey tutorialKey;
  final Widget child;

  /// Called after the sheet closes via its CTA (HU-01 only — [tutorialKey]
  /// must be one of [TutorialKey.screenTutorials] for this to ever fire).
  final FutureOr<void> Function(BuildContext context)? onCta;

  /// See [TutorialGateCubit.evaluate]'s docs on the same parameter.
  final bool accountGateShown;

  /// See [maybeShowTutorial]'s docs on the same parameter.
  final TutorialKey? skipIfSeen;

  @override
  State<TutorialAutoShow> createState() => _TutorialAutoShowState();
}

class _TutorialAutoShowState extends State<TutorialAutoShow> {
  bool _handled = false;
  bool _attemptInFlight = false;

  @override
  void initState() {
    super.initState();
    appRouteObserver.navigationChanges.addListener(_onNavigation);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => unawaited(_maybeShow()));
  }

  @override
  void dispose() {
    appRouteObserver.navigationChanges.removeListener(_onNavigation);
    super.dispose();
  }

  /// Navigation changed: the screen may have just become visible (or may have
  /// just been covered). Re-run the attempt only if the tutorial is still
  /// pending; never synchronously, since navigators are mid-transition.
  void _onNavigation() {
    if (_handled) {
      return;
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => unawaited(_maybeShow()));
  }

  Future<void> _maybeShow() async {
    if (_handled || _attemptInFlight || !mounted) {
      return;
    }
    _attemptInFlight = true;
    try {
      final outcome = await maybeShowTutorial(
        context,
        widget.tutorialKey,
        accountGateShown: widget.accountGateShown,
        skipIfSeen: widget.skipIfSeen,
        onCta: widget.onCta,
      );
      if (!mounted) {
        return;
      }
      _handled = outcome != TutorialShowOutcome.notVisible;
    } finally {
      _attemptInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Reopens [key]'s sheet exactly as HU-01's "Ver ayuda" menu row requires:
/// no gate evaluation, no "seen" registry write (HU-03: reopening never
/// alters anything). [onCta] behaves the same as [TutorialAutoShow.onCta].
Future<void> reopenTutorial(
  BuildContext context,
  TutorialKey key, {
  FutureOr<void> Function(BuildContext context)? onCta,
}) async {
  final content = TutorialContentCatalog.of(context, key);
  final result = await TutorialSheet.show(context, content);
  if (result == TutorialSheetResult.cta && onCta != null && context.mounted) {
    await onCta(context);
  }
}
