import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_action_row.dart';

/// What the list's overflow ("⋮") offers (`TmOGV` / `tFZyK`).
enum BudgetsMenuAction { history, toggleEnvelope, envelopeInfo }

/// The budgets list overflow menu: a bottom sheet (`Bottom Sheet Base`
/// `PqTUt`), never a Material `PopupMenuButton`.
///
/// It always offers the same three options; only the envelope row's wording
/// flips with [envelopeEnabled].
class BudgetsMenuSheet extends StatelessWidget {
  const BudgetsMenuSheet({required this.envelopeEnabled, super.key});

  final bool envelopeEnabled;

  static Future<BudgetsMenuAction?> show(
    BuildContext context, {
    required bool envelopeEnabled,
  }) =>
      BottomSheetBase.show<BudgetsMenuAction>(
        context,
        builder: (context) =>
            BudgetsMenuSheet(envelopeEnabled: envelopeEnabled),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetActionsHead(
          title: l10n.budgetsTitle,
          subtitle: l10n.budgetsMenuOptions,
        ),
        SheetActionRow(
          icon: LucideIcons.history,
          title: l10n.budgetsMenuHistory,
          subtitle: l10n.budgetsMenuHistorySubtitle,
          onTap: () => Navigator.of(context).pop(BudgetsMenuAction.history),
        ),
        SheetActionRow(
          icon: LucideIcons.target,
          title: envelopeEnabled
              ? l10n.budgetsMenuDisableEnvelope
              : l10n.budgetsMenuEnableEnvelope,
          subtitle: envelopeEnabled
              ? l10n.budgetsMenuDisableEnvelopeSubtitle
              : l10n.budgetsMenuEnableEnvelopeSubtitle,
          onTap: () =>
              Navigator.of(context).pop(BudgetsMenuAction.toggleEnvelope),
        ),
        SheetActionRow(
          icon: LucideIcons.info,
          title: l10n.envelopeInfoTitle,
          onTap: () =>
              Navigator.of(context).pop(BudgetsMenuAction.envelopeInfo),
        ),
      ],
    );
  }
}
