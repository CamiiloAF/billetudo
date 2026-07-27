import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The payoff progress bar: `$primary` fill over a `$muted` track, for both
/// directions (MASTER: progress is never dressed as a problem, so a debt owed
/// to the user fills in the same brand color as one the user owes).
class DebtProgressBar extends StatelessWidget {
  const DebtProgressBar({
    required this.value,
    this.height = 8,
    this.color,
    super.key,
  });

  /// 0..1 fraction paid/collected. Clamped so a rounding overshoot cannot
  /// paint past full.
  final double value;
  final double height;

  /// Fill color, defaults to `$primary`. The closed tab (extension, HU-07)
  /// passes `$text-secondary` for a debt closed with a balance still pending
  /// — atenuada, communicating the residue never got resolved (`vaNHd`).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: colors.muted,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? colors.primary),
      ),
    );
  }
}
