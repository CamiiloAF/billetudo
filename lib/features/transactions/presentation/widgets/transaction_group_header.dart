import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The header of one date group in the `Movimientos` list (`B3GGa`/`xAk6Y`):
/// "Hoy"/"Ayer"/the date on the left, and on the right either the group's
/// transaction [count] (default) or its already-formatted [totalLabel] —
/// bugfix #11 swaps in the day's signed total when the active filter is
/// exclusively `income` or exclusively `expense` and the group's currency is
/// uniform (see `transaction_group_total.dart`). Exactly one of [count] /
/// [totalLabel] must be provided.
class TransactionGroupHeader extends StatelessWidget {
  const TransactionGroupHeader({
    required this.label,
    this.count,
    this.totalLabel,
    super.key,
  }) : assert(
          (count == null) != (totalLabel == null),
          'Provide exactly one of count or totalLabel',
        );

  /// Already resolved: "Hoy", "Ayer" or the formatted date.
  final String label;

  final int? count;

  /// Already resolved, signed amount (e.g. "+$45.000"), or `null` to fall
  /// back to [count].
  final String? totalLabel;

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
          totalLabel ?? l10n.transactionsGroupCount(count!),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
