import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../budgets/domain/entities/budget_progress.dart';

/// The hero's "con presupuesto" progress bar (HU-03, frame `aOhoY`/`ls7Ed`):
/// a track + solid fill, plus a caption row with the percent/amount on the
/// left and the days left on the right.
///
/// Unlike `budgets/presentation`'s `BudgetProgressBar`, this one has **no**
/// conditional sano/riesgo/excedido color and **no** "programado" segment —
/// it is purely informative on top of the hero's violet gradient, so the fill
/// always reads solid white. Do not reuse the detail-screen bar here.
class HomeHeroBudgetProgress extends StatelessWidget {
  const HomeHeroBudgetProgress({
    required this.progress,
    required this.currency,
    super.key,
  });

  final BudgetProgress progress;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    final fraction = progress.fraction.clamp(0.0, 1.0);
    final onPrimary = colors.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Container(
            width: constraints.maxWidth,
            height: 8,
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: onPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.homeHeroBudgetProgress(
                  progress.percent,
                  money.formatSymbol(
                    progress.amountMinor,
                    currencyCode: currency,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.homeHeroBudgetDaysLeft(progress.daysLeft),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
