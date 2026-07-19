import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Thin budget progress bar (HU-04). Sober by design: violet `$primary` while
/// healthy, semantic `$expense` only on overspend (>100%) — never a
/// green/amber traffic light near the limit.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.fraction,
    required this.overspent,
    this.height = 8,
    super.key,
  });

  /// Spent / amount. Clamped to `[0, 1]` for the fill; overspend is signalled by
  /// [overspent], not by an overflowing bar.
  final double fraction;
  final bool overspent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = fraction.clamp(0.0, 1.0);
    final fill = overspent ? colors.expense : colors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        // The track is `$border` in every frame that uses it (`FSL69/QrCsr`,
        // `NloPT/Ip7RK`), not `$muted`.
        backgroundColor: colors.border,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }
}
