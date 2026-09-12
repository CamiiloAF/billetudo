import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The design system's floating action button (`H5mzN`): a 56x56 circle
/// filled with `$primary`, a single icon in `$on-primary`, and a soft brand
/// shadow (`$primary` at 40% alpha, blur 16, offset y+6).
///
/// Material's own [FloatingActionButton] themes to `primaryContainer` with a
/// squircle shape, which is not what Pencil draws — this widget owns the
/// geometry so no screen has to restate it.
class AppFab extends StatelessWidget {
  const AppFab({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onLongPress,
    this.longPressHint,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// The secondary gesture (`17-captura-voz.md` HU-02: press and hold to
  /// dictate). `null` on every FAB that has none, which is all of them but
  /// Inicio's.
  final VoidCallback? onLongPress;

  /// Already localized description of [onLongPress], exposed as a semantics
  /// long-press hint. A hidden gesture that a screen reader cannot announce
  /// is not discoverable at all — the minitutorial teaches it visually, this
  /// is its accessible counterpart.
  final String? longPressHint;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: colors.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            // `Tooltip` defaults to showing itself on long-press on mobile
            // (`TooltipTriggerMode.longPress`), which registers its own
            // long-press recognizer in the same gesture arena as the
            // `InkWell` above — two long-press recognizers racing for the
            // same touch, and the tooltip kept winning it, permanently
            // blocking `onLongPress` (voice capture) from ever firing.
            // `manual` removes that gesture recognizer entirely; the visual
            // tooltip is still reachable via mouse hover on desktop/web
            // (unaffected by `triggerMode`) and screen readers get the label
            // straight from `Semantics` below, not from this overlay.
            triggerMode: TooltipTriggerMode.manual,
            child: Semantics(
              button: true,
              label: tooltip,
              onLongPressHint: longPressHint,
              child: Icon(icon, size: 24, color: colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
