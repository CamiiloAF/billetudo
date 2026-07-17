import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/transaction.dart';

/// Gasto/Ingreso/Transferencia selector on the transaction form
/// (HU-01/02/03), built as the iOS-style pill `hFu41`: a `muted` track holding
/// three segments, the active one lifted onto a `surface` pill.
class TransactionTypeSegmentedControl extends StatelessWidget {
  const TransactionTypeSegmentedControl({
    required this.type,
    required this.onChanged,
    super.key,
  });

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  /// Color of the active segment's label, per type: expense stays neutral,
  /// income uses the contrast-safe income text token, transfer uses the brand
  /// color that survives dark mode on a soft surface (`primaryOnSoft`).
  static Color activeColor(AppColors colors, TransactionType type) =>
      switch (type) {
        TransactionType.expense => colors.textPrimary,
        TransactionType.income => colors.incomeText,
        TransactionType.transfer => colors.primaryOnSoft,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final labels = <TransactionType, String>{
      TransactionType.expense: l10n.transactionTypeExpense,
      TransactionType.income: l10n.transactionTypeIncome,
      TransactionType.transfer: l10n.transactionTypeTransfer,
    };
    final types = labels.keys.toList();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      child: Row(
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: TransactionTypeSegment(
                label: labels[types[i]]!,
                selected: types[i] == type,
                activeColor: activeColor(colors, types[i]),
                onTap: () => onChanged(types[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single segment of the [TransactionTypeSegmentedControl] pill.
class TransactionTypeSegment extends StatelessWidget {
  const TransactionTypeSegment({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: selected ? colors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? activeColor : colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
