import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_action_row.dart';

/// What the detail overflow ("⋮") offers (`G26c4T`).
enum BudgetDetailAction { edit, toggleFeatured, adjustAmount, close, delete }

/// The detail actions sheet: a head with the budget's own name, then Editar /
/// Usar como destacado (o Quitar de Inicio) / Ajustar monto / Cerrar (guardar
/// en histórico) / Eliminar presupuesto (in `$expense-text`).
///
/// Rows use the wrap-less [SheetActionRow.bare] shape, which is what `G26c4T`
/// draws here — unlike the list menu (`TmOGV`), whose rows do carry the
/// `$muted` icon-wrap. The "Destacar en Inicio" row (`gFBcD`/`yaRtv`) follows
/// the same bare shape — the `.md` calls out a `$muted` wrap for it, but the
/// `.pen` node itself has none, and the `.pen` wins.
class BudgetDetailActionsSheet extends StatelessWidget {
  const BudgetDetailActionsSheet({
    required this.budgetName,
    required this.isFeatured,
    super.key,
  });

  /// Shown as the sheet's head title, so the menu says which budget it acts on.
  final String budgetName;

  /// Whether this budget is currently `AppSettings.featuredBudgetId` — picks
  /// between "Usar como destacado en Inicio" (`gFBcD`) and "Quitar de
  /// Inicio" (`yaRtv`).
  final bool isFeatured;

  static Future<BudgetDetailAction?> show(
    BuildContext context, {
    required String budgetName,
    required bool isFeatured,
  }) =>
      BottomSheetBase.show<BudgetDetailAction>(
        context,
        builder: (context) => BudgetDetailActionsSheet(
          budgetName: budgetName,
          isFeatured: isFeatured,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetActionsHead(
          title: budgetName,
          subtitle: l10n.budgetDetailActionsSubtitle,
        ),
        SheetActionRow.bare(
          icon: LucideIcons.pencil,
          title: l10n.commonEdit,
          onTap: () => Navigator.of(context).pop(BudgetDetailAction.edit),
        ),
        isFeatured
            ? SheetActionRow.bare(
                icon: LucideIcons.starOff,
                title: l10n.budgetActionRemoveFeatured,
                foreground: colors.primaryOnSoft,
                onTap: () => Navigator.of(context)
                    .pop(BudgetDetailAction.toggleFeatured),
              )
            : SheetActionRow.bare(
                icon: LucideIcons.star,
                title: l10n.budgetActionUseAsFeatured,
                subtitle: l10n.budgetActionUseAsFeaturedSubtitle,
                onTap: () => Navigator.of(context)
                    .pop(BudgetDetailAction.toggleFeatured),
              ),
        SheetActionRow.bare(
          icon: LucideIcons.repeat1,
          title: l10n.budgetActionAdjustAmount,
          onTap: () =>
              Navigator.of(context).pop(BudgetDetailAction.adjustAmount),
        ),
        SheetActionRow.bare(
          icon: LucideIcons.archive,
          title: l10n.budgetActionClose,
          onTap: () => Navigator.of(context).pop(BudgetDetailAction.close),
        ),
        SheetActionRow.bare(
          icon: LucideIcons.trash2,
          title: l10n.budgetActionDeleteBudget,
          foreground: colors.expenseText,
          onTap: () => Navigator.of(context).pop(BudgetDetailAction.delete),
        ),
      ],
    );
  }
}
