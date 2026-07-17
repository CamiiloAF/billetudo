import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// What the detail overflow ("⋮") offers (`G26c4T`).
enum BudgetDetailAction { edit, close, delete }

/// The detail actions sheet: Edit / Close (save to history) / Delete (red).
class BudgetDetailActionsSheet extends StatelessWidget {
  const BudgetDetailActionsSheet({super.key});

  static Future<BudgetDetailAction?> show(BuildContext context) =>
      showModalBottomSheet<BudgetDetailAction>(
        context: context,
        builder: (context) => const BudgetDetailActionsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(LucideIcons.pencil),
            title: Text(l10n.commonEdit),
            onTap: () => Navigator.of(context).pop(BudgetDetailAction.edit),
          ),
          ListTile(
            leading: const Icon(LucideIcons.archive),
            title: Text(l10n.budgetActionClose),
            onTap: () => Navigator.of(context).pop(BudgetDetailAction.close),
          ),
          ListTile(
            leading: Icon(LucideIcons.trash, color: colors.expenseText),
            title: Text(
              l10n.budgetActionDelete,
              style: TextStyle(color: colors.expenseText),
            ),
            onTap: () => Navigator.of(context).pop(BudgetDetailAction.delete),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
