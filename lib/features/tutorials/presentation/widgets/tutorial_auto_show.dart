import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/tutorial_sheet.dart';
import '../../domain/entities/tutorial_key.dart';
import '../../domain/usecases/has_seen_tutorial.dart';
import '../../domain/usecases/mark_tutorial_seen.dart';
import '../cubit/tutorial_gate_cubit.dart';
import '../utils/tutorial_content_catalog.dart';

/// Evaluates [key] (via [TutorialGateCubit]) and, if it qualifies, shows its
/// sheet and marks it seen — the exact "evaluate, then show, then mark seen,
/// then optionally navigate" sequence every one of the 12 trigger points
/// needs, whether it fires on mount ([TutorialAutoShow]) or on a specific
/// user action (e.g. flipping "Modo sobres" on).
///
/// [skipIfSeen], when given, is checked *before* evaluating [key] at all: if
/// that other tutorial has already been seen, [key] is skipped outright
/// without consuming the `TutorialNavigationGuard` slot. This is the
/// "Modo sobres" rule (`docs/requirements/16-minitutoriales.md`): its own
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
Future<void> maybeShowTutorial(
  BuildContext context,
  TutorialKey key, {
  bool accountGateShown = false,
  TutorialKey? skipIfSeen,
  FutureOr<void> Function(BuildContext context)? onCta,
}) async {
  if (!getIt.isRegistered<TutorialGateCubit>()) {
    return;
  }
  if (skipIfSeen != null) {
    final skipSeenResult = await getIt<HasSeenTutorial>()(skipIfSeen);
    final skipSeen = skipSeenResult.fold((_) => false, (v) => v);
    if (skipSeen || !context.mounted) {
      return;
    }
  }

  final gate = getIt<TutorialGateCubit>();
  final content = TutorialContentCatalog.of(context, key);
  final shouldShow = await gate.evaluate(
    content: content,
    accountGateShown: accountGateShown,
  );
  if (!shouldShow || !context.mounted) {
    return;
  }

  final result = await TutorialSheet.show(context, content);
  await getIt<MarkTutorialSeen>()(key);
  if (result == TutorialSheetResult.cta && onCta != null && context.mounted) {
    await onCta(context);
  }
}

/// Wraps [child] and, once mounted, calls [maybeShowTutorial] for
/// [tutorialKey] — the shape every HU-01 screen and most HU-02 sub-flows use
/// (the ones triggered by *opening* a screen/control, not by a specific
/// in-place action like flipping a switch on).
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => unawaited(_maybeShow()));
  }

  Future<void> _maybeShow() async {
    if (_handled || !mounted) {
      return;
    }
    _handled = true;
    await maybeShowTutorial(
      context,
      widget.tutorialKey,
      accountGateShown: widget.accountGateShown,
      skipIfSeen: widget.skipIfSeen,
      onCta: widget.onCta,
    );
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
