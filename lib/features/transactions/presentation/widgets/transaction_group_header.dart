import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The header of one date group in the `Movimientos` list (`B3GGa`/`xAk6Y`):
/// "Hoy"/"Ayer"/the date on the left, the group's transaction count on the
/// right.
class TransactionGroupHeader extends StatelessWidget {
  const TransactionGroupHeader({
    required this.label,
    required this.count,
    super.key,
  });

  /// Already resolved: "Hoy", "Ayer" or the formatted date.
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        Text(
          l10n.transactionsGroupCount(count),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
