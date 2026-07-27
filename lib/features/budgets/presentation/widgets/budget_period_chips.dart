import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/budget.dart';
import '../utils/budget_format.dart';

/// The periodicity picker of the budget form (`a3gGPM/Aj6Ly`): free-width
/// pills, not a segmented control — the four options do not share the row
/// evenly on the frame, and "Personalizado" is not one of them (the `custom`
/// period IS the "Una única vez" branch of Repetir).
///
/// Like Pagos programados' frequency strip, the row scrolls instead of
/// shrinking so a large text scale never pushes the labels below the minimum
/// size of `MASTER.md`.
class BudgetPeriodChips extends StatelessWidget {
  const BudgetPeriodChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  static const List<BudgetPeriod> options = [
    BudgetPeriod.weekly,
    BudgetPeriod.biweekly,
    BudgetPeriod.monthly,
    BudgetPeriod.yearly,
  ];

  final BudgetPeriod selected;
  final ValueChanged<BudgetPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            BudgetPeriodChip(
              label: BudgetFormat.periodLabel(l10n, options[i]),
              selected: options[i] == selected,
              onTap: () => onChanged(options[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// One pill of [BudgetPeriodChips]: `$muted` at rest, `$primary-soft` ringed
/// in `$primary` when picked (`qKktu`).
class BudgetPeriodChip extends StatelessWidget {
  const BudgetPeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: selected ? colors.primarySoft : colors.muted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color:
                  selected ? colors.primaryOnSoftStrong : colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
