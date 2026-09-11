import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/capture_shortcut_cubit.dart';
import '../cubit/capture_shortcut_state.dart';
import '../utils/capture_shortcut_destination.dart';

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
        final route = CaptureShortcutDestination.resolve(
          shortcut: shortcut,
          currentLocation: currentLocation(),
        );
        if (route != null) {
          onOpenRoute(route);
        }
        // Consumed either way: a shortcut deliberately ignored (the form is
        // already open, onboarding is in progress) must not be replayed on
        // the next state change.
        context.read<CaptureShortcutCubit>().consumed();
      },
      child: child,
    );
  }
}
