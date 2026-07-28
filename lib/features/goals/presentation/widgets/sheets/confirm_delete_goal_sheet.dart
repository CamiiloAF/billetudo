import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-10: confirms deleting a goal. The delete is a reversible trash
/// (`deletedAt`), so the copy says it can be recovered — no guilt, no
/// finality. The destructive button wears `$expense` (never brand violet).
class ConfirmDeleteGoalSheet extends StatelessWidget {
  const ConfirmDeleteGoalSheet({super.key});

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const ConfirmDeleteGoalSheet(),
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
          title: l10n.goalDeleteSheetTitle,
          message: l10n.goalDeleteSheetMessage,
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
