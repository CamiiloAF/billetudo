import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../domain/entities/account_deletion_impact.dart';

/// HU-08: confirms deleting an account.
///
/// The only genuinely destructive sheet of the feature, so it is the only one
/// wearing `$expense`. It states the impact plainly — how many transactions the
/// account holds — without dressing it as a warning about the user's spending.
class ConfirmDeleteAccountSheet extends StatelessWidget {
  const ConfirmDeleteAccountSheet({required this.impact, super.key});

  final AccountDeletionImpact impact;

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(
    BuildContext context, {
    required AccountDeletionImpact impact,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => ConfirmDeleteAccountSheet(impact: impact),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: Icons.warning_amber_rounded,
          iconColor: colors.expense,
          iconBackground: colors.expenseSoft,
          title: l10n.accountDeleteSheetTitle,
          message: impact.transactionCount > 0
              ? l10n.accountDeleteSheetImpact(impact.transactionCount)
              : l10n.accountDeleteSheetMessage,
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
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}
