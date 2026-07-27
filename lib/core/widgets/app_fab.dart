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
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

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
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            child: Semantics(
              button: true,
              label: tooltip,
              child: Icon(icon, size: 24, color: colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
