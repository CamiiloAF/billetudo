import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/goal_quick_amount.dart';
import '../utils/goal_format.dart';
import 'goal_add_quick_amount_chip.dart';
import 'quick_amount_chip.dart';

/// The "Aporte rápido" row (design-system/billetudo/pages/metas.md), a
/// horizontally-scrolling `Scroll Row` (same pattern as Inicio's
/// `QuickAccessRow`, `clip: true`): the fixed $50.000/$100.000 chips, then the
/// user's custom chips ([customAmounts], oldest first), then the fixed
/// "Otro monto" chip ([onOther]) and the "+ Nueva" chip ([onAddNew]), always
/// last. No limit on custom chips — the row scrolls instead of truncating.
///
/// Every amount chip — fixed or custom — reuses the exact same write path
/// ([onQuickAmount] opens the full Aportar sheet prefilled with that amount,
/// with no visual sign it came from a chip); only custom chips carry the
/// inline "x" ([onRemoveCustom]).
class GoalQuickAmountRow extends StatelessWidget {
  const GoalQuickAmountRow({
    required this.currency,
    required this.customAmounts,
    required this.onQuickAmount,
    required this.onOther,
    required this.onAddNew,
    required this.onRemoveCustom,
    this.amountsMinor = const [5000000, 10000000],
    super.key,
  });

  final String currency;

  /// The user's own chips (`GoalQuickAmounts` rows for this goal), oldest
  /// first — a newly created one appends at the end, right before "Otro
  /// monto"/"+ Nueva".
  final List<GoalQuickAmount> customAmounts;

  final ValueChanged<int> onQuickAmount;
  final VoidCallback onOther;
  final VoidCallback onAddNew;
  final ValueChanged<GoalQuickAmount> onRemoveCustom;

  /// In minor units — defaults to $50.000/$100.000 COP.
  final List<int> amountsMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final amountMinor in amountsMinor) ...[
              QuickAmountChip(
                label: GoalFormat.amount(amountMinor, currency),
                onTap: () => onQuickAmount(amountMinor),
              ),
              const SizedBox(width: 8),
            ],
            for (final custom in customAmounts) ...[
              QuickAmountChip(
                label: GoalFormat.amount(custom.amountMinor, currency),
                onTap: () => onQuickAmount(custom.amountMinor),
                onRemove: () => onRemoveCustom(custom),
              ),
              const SizedBox(width: 8),
            ],
            QuickAmountChip(
              label: l10n.goalQuickAmountOther,
              onTap: onOther,
            ),
            const SizedBox(width: 8),
            GoalAddQuickAmountChip(
              label: l10n.goalQuickAmountAddCta,
              onTap: onAddNew,
            ),
          ],
        ),
      ),
    );
  }
}
