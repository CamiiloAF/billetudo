import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

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

  /// `qPSvV/Hbn6k`: the chip is 44 high, not "whatever the label needs". It is
  /// the tap target the component's own context declares, and the loading
  /// placeholder reserves exactly this height — a shorter pill makes the whole
  /// list jump when the counters resolve, which is the glitch the placeholder
  /// exists to prevent.
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: height),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
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
