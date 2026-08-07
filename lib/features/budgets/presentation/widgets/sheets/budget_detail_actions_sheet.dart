import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_action_row.dart';
import '../../../../settings/presentation/cubit/app_settings_cubit.dart';
import '../../../../settings/presentation/cubit/app_settings_state.dart';
import '../../../domain/services/budget_hero_selector.dart';

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
///
/// "Destacar en Inicio" is derived **reactively** from [AppSettingsCubit],
/// never captured as a static `bool` at the moment the sheet is opened: the
/// caller's `AppSettingsCubit` is a fresh instance per navigation to the
/// detail route (`app_router.dart`), and its active-budgets stream does not
/// necessarily emit in the same synchronous tick the `⋮` button is tapped —
/// a static snapshot could freeze the sheet on "Usar como destacado" for a
/// budget that is, in fact, already featured. Rebuilding against the cubit's
/// stream self-corrects the moment the real value arrives, whether that is
/// before or after the sheet is visible.
class BudgetDetailActionsSheet extends StatelessWidget {
  const BudgetDetailActionsSheet({
    required this.budgetName,
    required this.budgetId,
    super.key,
  });

  /// Shown as the sheet's head title, so the menu says which budget it acts on.
  final String budgetName;

  /// The budget this sheet acts on — resolved against
  /// `AppSettingsCubit.state` (via [BudgetHeroSelector.pick]) to pick between
  /// "Usar como destacado en Inicio" (`gFBcD`) and "Quitar de Inicio"
  /// (`yaRtv`).
  final String budgetId;

  /// [settingsCubit] is the caller's already-provided `AppSettingsCubit`
  /// instance, threaded in explicitly: this sheet opens on the root
  /// navigator (`BottomSheetBase.show`'s `useRootNavigator: true`), so its
  /// own `BuildContext` is a sibling of the detail page's provider subtree,
  /// not a descendant of it, and cannot `context.read`/`watch` it directly.
  static Future<BudgetDetailAction?> show(
    BuildContext context, {
    required String budgetName,
    required String budgetId,
    required AppSettingsCubit settingsCubit,
  }) =>
      BottomSheetBase.show<BudgetDetailAction>(
        context,
        builder: (context) => BlocProvider<AppSettingsCubit>.value(
          value: settingsCubit,
          child: BudgetDetailActionsSheet(
            budgetName: budgetName,
            budgetId: budgetId,
          ),
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
        BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, settingsState) {
            final resolved = BudgetHeroSelector.pick(
              settingsState.activeBudgets,
              mode: settingsState.settings.featuredBudgetMode,
              featuredBudgetId: settingsState.featuredBudgetId,
            );
            final isFeatured = resolved?.budget.id == budgetId;
            return isFeatured
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
                  );
          },
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
