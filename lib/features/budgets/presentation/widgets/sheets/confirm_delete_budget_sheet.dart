import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-11 delete confirmation. Neutral, reversible tone: the budget goes to
/// the trash, not gone forever — `trash-2` on `$primary-soft`/
/// `$primary-on-soft` (violet, not red: this is a recoverable, logical
/// delete, never a destructive one).
class ConfirmDeleteBudgetSheet extends StatelessWidget {
  const ConfirmDeleteBudgetSheet({super.key});

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const ConfirmDeleteBudgetSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.trash2,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          message: l10n.budgetDeleteConfirmMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.trash2),
            label: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}
