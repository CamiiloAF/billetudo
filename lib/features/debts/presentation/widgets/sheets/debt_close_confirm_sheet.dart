import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../domain/entities/debt.dart';
import '../../utils/debt_format.dart';

/// Confirms a manual "Cerrar deuda" (extension, HU-07, `R97gF`): a
/// `Sheet Icon Header` (neutral `flag`), an info card with the pending
/// balance, and Cancelar/Cerrar deuda. Closing with a balance still pending
/// creates **no** `DebtEntry` — a pure status change, never an event.
///
/// Resolves to `true` when the user confirms.
class DebtCloseConfirmSheet extends StatelessWidget {
  const DebtCloseConfirmSheet({
    required this.debt,
    required this.outstandingMinor,
    super.key,
  });

  final Debt debt;
  final int outstandingMinor;

  static Future<bool?> show(
    BuildContext context, {
    required Debt debt,
    required int outstandingMinor,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => DebtCloseConfirmSheet(
          debt: debt,
          outstandingMinor: outstandingMinor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final amount = DebtFormat.amount(outstandingMinor, debt.currency);
    final counterparty = debt.counterparty;

    final message = debt.direction == DebtDirection.iOwe
        ? (counterparty != null
            ? l10n.debtCloseSheetMessageIOwe(amount, counterparty)
            : l10n.debtCloseSheetMessageIOweNoCounterparty(amount))
        : (counterparty != null
            ? l10n.debtCloseSheetMessageOwedToMe(counterparty, amount)
            : l10n.debtCloseSheetMessageOwedToMeNoCounterparty(amount));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(LucideIcons.flag, color: colors.primaryOnSoft, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.debtCloseSheetTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.debtCloseInfoLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.flag, size: 18),
            label: Text(l10n.debtCloseCta),
          ),
        ),
      ],
    );
  }
}
