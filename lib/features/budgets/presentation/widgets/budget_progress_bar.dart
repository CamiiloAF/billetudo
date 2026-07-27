import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Thin budget progress bar (HU-04). Sober by design: violet `$primary` while
/// healthy, semantic `$expense` only on overspend (>100%) — never a
/// green/amber traffic light near the limit.
///
/// HU-12 adds a third, contiguous segment for what is "programado" (scheduled
/// payments projected inside the window that have not materialized as a
/// `Transaction` yet): `$primary-light` right after the spent one when the
/// projection is still healthy, or `$amber` when it would push the budget
/// over 100% ([scheduledAtRisk], "riesgo de sobregiro proyectado", HU-12) — a
/// deliberate, documented exception to this bar's sober one-accent rule (see
/// MASTER.md), never a new color for plain proximity to the limit. It only
/// ever eats into the room [fraction] left — see
/// `BudgetProgress.scheduledFraction`, which already clamps that so the two
/// segments never overlap, and the bar never draws past 100% of the track
/// even when the real "programado" amount would mean more.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.fraction,
    required this.overspent,
    this.scheduledFraction = 0,
    this.scheduledAtRisk = false,
    this.height = 8,
    super.key,
  });

  /// Spent / amount. Clamped to `[0, 1]` for the fill; overspend is signalled by
  /// [overspent], not by an overflowing bar.
  final double fraction;
  final bool overspent;

  /// "Programado" / amount (HU-12), already clamped by the domain to the room
  /// [fraction] left. `0` renders no third segment at all.
  final double scheduledFraction;

  /// Whether the "programado" segment renders in `$amber` (projected
  /// overdraw risk, HU-12) instead of the healthy `$primary-light`. Has no
  /// effect when [scheduledFraction] is `0`.
  final bool scheduledAtRisk;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spent = fraction.clamp(0.0, 1.0);
    final scheduled = scheduledFraction <= 0
        ? 0.0
        : scheduledFraction.clamp(0.0, (1.0 - spent).clamp(0.0, 1.0));
    final fill = overspent ? colors.expense : colors.primary;
    final scheduledFill = scheduledAtRisk ? colors.amber : colors.primaryLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                Container(color: colors.border),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: width * spent,
                  child: Container(color: fill),
                ),
                if (scheduled > 0)
                  Positioned(
                    left: width * spent,
                    top: 0,
                    bottom: 0,
                    width: width * scheduled,
                    child: Container(color: scheduledFill),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
