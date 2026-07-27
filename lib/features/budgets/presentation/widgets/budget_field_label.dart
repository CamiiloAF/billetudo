import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The section label of the budget form (`a3gGPM/AceYL`, 13/600
/// `$text-secondary`).
///
/// Every label sits on the page margin, aligned with the others — never
/// indented to match the input it heads, which would break the column.
class BudgetFieldLabel extends StatelessWidget {
  const BudgetFieldLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
      );
}
