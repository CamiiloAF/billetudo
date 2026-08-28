import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../budgets/domain/entities/budget_progress.dart';

/// The hero's progress bar (`Bar Track`, `Jh0yS`, `design-system/billetudo/
/// pages/inicio.md` § "Hero compacto"): track + one or two contiguous
/// segments — real spend, and (only in the projected-overspend-risk state) a
/// second segment for projected scheduled-payment spend.
///
/// Purely a drawing surface: which color the spent segment takes (`$on-primary`
/// for every state except real overspend, which tints `$on-primary-alert`) is
/// resolved by the caller (`HomeHeroCard`) from `HomeHeroState`, never here.
class HomeHeroBudgetProgress extends StatelessWidget {
  const HomeHeroBudgetProgress({
    required this.progress,
    required this.spentColor,
    super.key,
  });

  final BudgetProgress progress;

  /// `$on-primary` in every state but real overspend (`$on-primary-alert`).
  final Color spentColor;

  /// Track/bar height and corner radius (`Jh0yS`/`YoDHh`).
  static const double _height = 10;
  static const double _radius = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spentFraction = progress.fraction.clamp(0.0, 1.0);
    final scheduledFraction = progress.scheduledFraction;
    final hasScheduled = scheduledFraction > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final spentWidth = trackWidth * spentFraction;
        final scheduledWidth = trackWidth * scheduledFraction;
        // Threshold rule (criterion 8): a single segment's remaining track to
        // its right below 2× the radius (<10px) collapses that segment's
        // right corners to square — otherwise the fill's rounded cap and the
        // track's own rounded cap overlap and the gap reads as antialiasing,
        // not as "a sliver of budget left".
        final remainder = trackWidth - spentWidth - scheduledWidth;
        final singleSegmentFlat = !hasScheduled && remainder < _radius * 2;

        return Container(
          width: trackWidth,
          height: _height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.trackOverlay,
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: spentWidth,
                  height: _height,
                  decoration: BoxDecoration(
                    color: spentColor,
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(_radius),
                      right: hasScheduled || singleSegmentFlat
                          ? Radius.zero
                          : const Radius.circular(_radius),
                    ),
                  ),
                ),
              ),
              if (hasScheduled)
                Positioned(
                  left: spentWidth,
                  child: Container(
                    width: scheduledWidth,
                    height: _height,
                    decoration: BoxDecoration(
                      color: colors.onPrimaryWarn,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(_radius),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
