import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// Fix B: confirms deleting a single solo-deuda movement (an abono,
/// desembolso, interest accrual, or manual adjustment) from
/// `DebtMovementDetailSheet`. Same destructive pattern as
/// `ConfirmDeleteDebtSheet` — `$expense`, never brand violet — scoped to one
/// movement instead of a whole debt.
class ConfirmDeleteDebtEntrySheet extends StatelessWidget {
  const ConfirmDeleteDebtEntrySheet({super.key});

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const ConfirmDeleteDebtEntrySheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.trash2,
          iconColor: colors.expense,
          iconBackground: colors.expenseSoft,
          title: l10n.debtEntryDeleteSheetTitle,
          message: l10n.debtEntryDeleteSheetMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colors.expense),
            icon: const Icon(LucideIcons.trash2),
            label: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}
