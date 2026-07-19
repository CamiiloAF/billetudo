import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/budget_usage_notice.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-04 case 1: no dependents (`o9116/qsjbj`).
///
/// Plain destructive pattern: `alert-triangle` on `$expense`/`$expense-soft`,
/// no title — icon + message only.
class ConfirmDeleteSimpleSheet extends StatelessWidget {
  const ConfirmDeleteSimpleSheet({
    this.budgetCount = 0,
    this.isSubcategory = false,
    super.key,
  });

  /// Budgets whose scope references this category (Presupuestos HU-06).
  final int budgetCount;

  /// Whether the category being deleted is a subcategory: changes the
  /// confirm button's label.
  final bool isSubcategory;

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(
    BuildContext context, {
    int budgetCount = 0,
    bool isSubcategory = false,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        useRootNavigator: true,
        builder: (context) => ConfirmDeleteSimpleSheet(
          budgetCount: budgetCount,
          isSubcategory: isSubcategory,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.triangleAlert,
          iconColor: colors.expense,
          iconBackground: colors.expenseSoft,
          message: l10n.categoryDeleteSimpleMessage,
        ),
        BudgetUsageNotice(count: budgetCount),
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
            label: Text(
              isSubcategory
                  ? l10n.categoryDeleteSubcategoryAction
                  : l10n.commonDelete,
            ),
          ),
        ),
      ],
    );
  }
}
