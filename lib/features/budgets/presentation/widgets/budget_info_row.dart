import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Info Row` component (`myfAc`) as used inside the Budgets feature:
/// label above (12/600, `$text-secondary`), value below (15/600,
/// `$text-primary`). A small local copy rather than importing Cuentas'
/// `InfoRow` — same shape, kept per-feature to avoid a cross-feature
/// presentation dependency.
class BudgetInfoRow extends StatelessWidget {
  const BudgetInfoRow({required this.label, required this.value, super.key});

  /// Both already localized/formatted: this widget renders, it does not
  /// translate or format money.
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
