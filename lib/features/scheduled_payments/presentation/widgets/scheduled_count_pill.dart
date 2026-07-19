import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Activos · N" / "Terminados · N": a rounded pill counter.
class ScheduledCountPill extends StatelessWidget {
  const ScheduledCountPill({
    required this.label,
    required this.emphasized,
    super.key,
  });

  final String label;

  /// True for the selected pill (`$primarySoft` + border), false for the
  /// inactive one (neutral `$muted`, no border).
  ///
  /// The border is not decoration: `$primarySoft` and `$muted` hold the same
  /// value in both themes, so without it the two boxes are identical and the
  /// selected state would be encoded in the label colour alone (WCAG 1.4.1).
  /// It uses `$primaryOnSoftStrong` — plain `$primary` over `$muted` in dark
  /// is 2.75:1, under the 3:1 of WCAG 1.4.11 — and is aligned inside so it
  /// does not inflate the 44px tap target.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? colors.primarySoft : colors.muted,
        border: emphasized
            ? Border.all(
                // `strokeAlign` is left at its default, which is already
                // `strokeAlignInside`.
                color: colors.primaryOnSoftStrong,
                width: 1.5,
              )
            : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: emphasized
                  ? colors.primaryOnSoftStrong
                  : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
