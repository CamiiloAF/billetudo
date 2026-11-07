import 'dart:async';

import 'package:flutter/material.dart';

/// Collapses a piece of scroll-driven chrome (e.g. Movimientos' account chips
/// row and Period Stepper) with the design system's hide/show motion: a 200ms
/// height collapse + fade, driven by [visible].
///
/// Companion of `ScrollAwareFab`: pair it with `ScrollAwareFabVisibility` and
/// feed its [visible] from the same scroll-direction signal that already
/// drives the FAB, so every piece of chrome hides on scroll down and comes
/// back on scroll up together.
///
/// Unlike an `if (visible)` swap, [child] stays in the tree while hidden —
/// preserving its state (e.g. the chip row's own horizontal scroll offset) —
/// while the collapsed layout takes zero height. Hidden chrome also stops
/// receiving pointer events and is excluded from semantics.
///
/// The block is only clipped while hidden or mid-animation: at rest
/// ([visible] `true`, animation idle) it paints unclipped, so descendants
/// whose decoration overflows their own box — e.g. the Period Stepper's drop
/// shadow — keep painting exactly as they would without this wrapper.
class ScrollAwareCollapsible extends StatefulWidget {
  const ScrollAwareCollapsible({
    required this.visible,
    required this.child,
    super.key,
  });

  /// Whether the chrome is currently shown.
  final bool visible;

  /// The chrome to hide/show. Kept alive (never unmounted) across the
  /// animation in both directions.
  final Widget child;

  @override
  State<ScrollAwareCollapsible> createState() => _ScrollAwareCollapsibleState();
}

class _ScrollAwareCollapsibleState extends State<ScrollAwareCollapsible>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 200);
  static const Curve _curve = Curves.easeInOut;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
    value: widget.visible ? 1 : 0,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: _curve,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  /// The animation's last value tick can still report `isAnimating == true`
  /// and no later frame would rebuild this widget, which would leave a
  /// revealed block clipped forever. Rebuilding once on completion recomputes
  /// the clip from the settled (idle) controller state so it relaxes back to
  /// `Clip.none`.
  void _onAnimationStatusChanged(AnimationStatus status) {
    if (mounted && status == AnimationStatus.completed) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ScrollAwareCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) {
      return;
    }
    if (widget.visible) {
      unawaited(_controller.forward());
    } else {
      unawaited(_controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: ExcludeSemantics(
        excluding: !widget.visible,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, child) {
            // Only clip while the block is hidden or moving. A revealed,
            // idle block must not clip its descendants' shadows/overlays.
            final needsClip = _controller.isAnimating || !widget.visible;
            return ClipRect(
              clipBehavior: needsClip ? Clip.hardEdge : Clip.none,
              // Top-left, not top-center: a `Column` child inherits its
              // parent's start alignment, so narrow chrome (e.g. a filter row
              // holding a single chip) must stay left-aligned; centering it
              // would shift the at-rest layout.
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: _progress.value,
                child: Opacity(
                  opacity: _progress.value,
                  child: child,
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
