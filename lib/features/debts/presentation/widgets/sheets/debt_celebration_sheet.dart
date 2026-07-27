import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../domain/entities/debt.dart';
import '../../cubit/debt_detail_state.dart';
import '../../utils/debt_format.dart';
import 'debt_celebration_stat.dart';

/// The felicitación sheet (extension, HU-07, `C28Zt`): fires automatically
/// once a debt's balance crosses to settled. A `party-popper` icon header, two
/// stats ("Total pagado/cobrado" + "Duración") and "Ahora no"/"Completar".
///
/// "Completar" closes the debt right there (the same `closedAt` mechanism as
/// the manual "Cerrar deuda", no separate confirmation screen); "Ahora no"
/// just dismisses — the debt stays settled but **not** closed, so it remains
/// in "Activas" until the user closes it, here or later from the ⋮ menu.
///
/// Resolves to `true` when the user taps "Completar".
class DebtCelebrationSheet extends StatelessWidget {
  const DebtCelebrationSheet({required this.celebration, super.key});

  final DebtSettledCelebration celebration;

  static Future<bool?> show(
    BuildContext context, {
    required DebtSettledCelebration celebration,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => DebtCelebrationSheet(celebration: celebration),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final debt = celebration.debt;
    final isIOwe = debt.direction == DebtDirection.iOwe;
    final amount = DebtFormat.amount(celebration.totalPaidMinor, debt.currency);
    final duration = DebtFormat.duration(
      l10n,
      debt.effectiveStartDate,
      celebration.settledAt,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Icon(
            LucideIcons.partyPopper,
            color: colors.primaryOnSoft,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isIOwe
              ? l10n.debtCelebrationTitleIOwe
              : l10n.debtCelebrationTitleOwedToMe,
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
          isIOwe
              ? l10n.debtCelebrationMessageIOwe(debt.name, amount, duration)
              : l10n.debtCelebrationMessageOwedToMe(
                  debt.name,
                  amount,
                  duration,
                ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: DebtCelebrationStat(
                value: amount,
                label: isIOwe
                    ? l10n.debtCelebrationStatTotalPaidIOwe
                    : l10n.debtCelebrationStatTotalPaidOwedToMe,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DebtCelebrationStat(
                value: duration,
                label: l10n.debtCelebrationStatDuration,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.debtCelebrationDismiss),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.debtCelebrationComplete),
          ),
        ),
      ],
    );
  }
}
