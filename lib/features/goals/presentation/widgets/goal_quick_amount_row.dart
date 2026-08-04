import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/goal_quick_amount.dart';
import '../utils/goal_format.dart';
import 'goal_add_quick_amount_chip.dart';
import 'quick_amount_chip.dart';

/// The "Aporte rápido" row (design-system/billetudo/pages/metas.md), a
/// horizontally-scrolling `Scroll Row` (same pattern as Inicio's
/// `QuickAccessRow`, `clip: true`): the user's chips ([customAmounts], oldest
/// first — the two default $50.000/$100.000 chips are seeded as real
/// `GoalQuickAmount` rows by `CreateGoal`, so they arrive through this same
/// list), then the "+ Nueva" chip ([onAddNew]), always last. No limit on
/// custom chips — the row scrolls instead of truncating. There is no fixed
/// "Otro monto" chip: the "+ Aportar" CTA above the row already opens the
/// same full sheet with no amount prefilled.
///
/// Every amount chip reuses the exact same write path ([onQuickAmount] opens
/// the full Aportar sheet prefilled with that amount, with no visual sign it
/// came from a chip) and carries the inline "x" ([onRemoveCustom]) — the row
/// is a single uniform list, no chip is hardcoded or undeletable.
class GoalQuickAmountRow extends StatelessWidget {
  const GoalQuickAmountRow({
    required this.currency,
    required this.customAmounts,
    required this.onQuickAmount,
    required this.onAddNew,
    required this.onRemoveCustom,
    super.key,
  });

  final String currency;

  /// The goal's chips (`GoalQuickAmounts` rows for this goal), oldest
  /// first — a newly created one appends at the end, right before "+ Nueva".
  final List<GoalQuickAmount> customAmounts;

  final ValueChanged<int> onQuickAmount;
  final VoidCallback onAddNew;
  final ValueChanged<GoalQuickAmount> onRemoveCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final custom in customAmounts) ...[
              QuickAmountChip(
                label: GoalFormat.amount(custom.amountMinor, currency),
                onTap: () => onQuickAmount(custom.amountMinor),
                onRemove: () => onRemoveCustom(custom),
              ),
              const SizedBox(width: 8),
            ],
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
