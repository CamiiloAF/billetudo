import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/transaction.dart';

/// The `Detail Amount Hero` (ref `npfLO`): the icon circle + big colored
/// amount + subtitle at the top of HU-08's detail screen.
///
/// Unlike the list row or the category picker, the icon circle always uses
/// the fixed `$primary-soft`/`$primary-on-soft` pair — never the category's
/// own palette token — because this is the hero, not a category chip.
class DetailAmountHero extends StatelessWidget {
  const DetailAmountHero({
    required this.type,
    required this.amountLabel,
    required this.subtitle,
    this.categoryIcon,
    super.key,
  });

  final TransactionType type;

  /// Already formatted (`MoneyFormatter`), no sign prefix.
  final String amountLabel;

  /// Category name for income/expense, or the "Transferencia" literal.
  final String subtitle;

  /// Ignored for [TransactionType.transfer], which always shows
  /// `arrow-left-right`.
  final String? categoryIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final isTransfer = type == TransactionType.transfer;
    final icon = isTransfer
        ? LucideIcons.arrowLeftRight
        : CategoryAppearance.iconFor(categoryIcon);

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(icon, size: 28, color: colors.primaryOnSoft),
        ),
        const SizedBox(height: 8),
        Text(
          amountLabel,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: _amountColor(colors),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Deliberately not the `$expense`/red token — only the delete link uses
  /// that — per the spec correction to HU-08's palette.
  Color _amountColor(AppColors colors) => switch (type) {
        TransactionType.expense => colors.textPrimary,
        TransactionType.income => colors.incomeText,
        TransactionType.transfer => colors.primaryOnSoft,
      };
}
