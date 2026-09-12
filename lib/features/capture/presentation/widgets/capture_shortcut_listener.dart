import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/entities/capture_shortcut.dart';
import '../cubit/capture_shortcut_cubit.dart';
import '../cubit/capture_shortcut_state.dart';
import '../utils/capture_shortcut_destination.dart';
import '../utils/start_voice_capture_flow.dart';

/// Opens the capture surface a home-screen widget shortcut points at
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// Sits above the router's own subtree (it is installed from
/// `MaterialApp.router`'s `builder`), which is why navigation arrives as
/// callbacks instead of `GoRouter.of(context)`: there is no `InheritedGoRouter`
/// that high up, and taking them as parameters also keeps the widget
/// testable without a router.
///
/// It always pushes, never replaces: whatever the user had half-filled stays
/// on the stack (HU-01, "no descarta datos ya escritos sin avisar").
class CaptureShortcutListener extends StatelessWidget {
  const CaptureShortcutListener({
    required this.currentLocation,
    required this.onOpenRoute,
    required this.child,
    super.key,
  });

  /// Where the app is right now, as a location string.
  final String Function() currentLocation;

  /// Pushes a route on top of the current one.
  final void Function(String route) onOpenRoute;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CaptureShortcutCubit, CaptureShortcutState>(
      listenWhen: (previous, current) => current.pending != null,
      listener: (context, state) {
        final shortcut = state.pending;
        if (shortcut == null) {
          return;
        }
        if (shortcut == CaptureShortcut.voice) {
          unawaited(_openVoiceCapture());
        } else {
          final route = CaptureShortcutDestination.resolve(
            shortcut: shortcut,
            currentLocation: currentLocation(),
          );
          if (route != null) {
            onOpenRoute(route);
          }
        }
        // Consumed either way: a shortcut deliberately ignored (the form is
        // already open, onboarding is in progress) must not be replayed on
        // the next state change.
        context.read<CaptureShortcutCubit>().consumed();
      },
      child: child,
    );
  }

  /// Voice never lands on a page route (`CaptureShortcutDestination`'s doc):
  /// it opens `VoiceCaptureSheet` over Home instead, so it cannot reuse
  /// [CaptureShortcutDestination.resolve] — that treats "already on the
  /// destination" as "nothing to do", which is exactly the common case here
  /// (the sheet must still open when the app is already showing Home).
  ///
  /// Navigates to Home first when the app is elsewhere (same "never drop the
  /// user mid-setup" rule as `resolve`: onboarding is left alone), then opens
  /// the sheet via [AppRoutes.rootNavigatorContext] — this widget sits above
  /// the router's own `Navigator`, so it has none of its own to anchor a
  /// modal to.
  Future<void> _openVoiceCapture() async {
    final location = currentLocation();
    if (location.startsWith(AppRoutes.onboarding)) {
      return;
    }
    if (location != AppRoutes.home) {
      onOpenRoute(AppRoutes.home);
    }
    final rootContext = AppRoutes.rootNavigatorContext;
    if (rootContext == null) {
      return;
    }
    await startVoiceCaptureFlow(rootContext);
  }
}
