import 'package:flutter/material.dart';

import 'app_fab.dart';
import 'scroll_aware_fab_visibility.dart';

/// Wraps a FAB (usually [AppFab]) with the design system's scroll-aware
/// hide/show animation (HU-02): a 200ms slide + fade, driven by [visible].
/// Pair with [ScrollAwareFabVisibility] for the scroll-direction logic that
/// feeds [visible].
class ScrollAwareFab extends StatelessWidget {
  const ScrollAwareFab({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  static const Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: _duration,
      offset: visible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: _duration,
        opacity: visible ? 1 : 0,
        child: child,
      ),
    );
  }
}
