import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../utils/goal_format.dart';
import 'quick_amount_chip.dart';

/// HU-14's one-tap quick amounts on the detail ("$50.000"/"$100.000"/"Otro"):
/// picking a fixed chip reuses the exact same write path as the full sheet
/// ([onQuickAmount]); "Otro" opens the sheet instead ([onOther]).
class GoalQuickAmountRow extends StatelessWidget {
  const GoalQuickAmountRow({
    required this.currency,
    required this.onQuickAmount,
    required this.onOther,
    this.amountsMinor = const [5000000, 10000000],
    super.key,
  });

  final String currency;
  final ValueChanged<int> onQuickAmount;
  final VoidCallback onOther;

  /// In minor units — defaults to $50.000/$100.000 COP.
  final List<int> amountsMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        for (final amountMinor in amountsMinor) ...[
          Expanded(
            child: QuickAmountChip(
              label: GoalFormat.amount(amountMinor, currency),
              onTap: () => onQuickAmount(amountMinor),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: QuickAmountChip(label: l10n.goalQuickAmountOther, onTap: onOther),
        ),
      ],
    );
  }
}
