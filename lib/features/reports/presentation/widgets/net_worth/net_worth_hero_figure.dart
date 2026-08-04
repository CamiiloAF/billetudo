import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';

/// One figure ("Líquido" or "Total") inside the net worth hero card: a
/// label plus its formatted amount, stacked and left-aligned.
class NetWorthHeroFigure extends StatelessWidget {
  const NetWorthHeroFigure({
    required this.label,
    required this.amountMinor,
    required this.currencyCode,
    super.key,
  });

  final String label;
  final int amountMinor;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    const money = MoneyFormatter();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            money.formatSymbol(amountMinor, currencyCode: currencyCode),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
