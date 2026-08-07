import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_action_row.dart';

/// What Deudas' overflow ("⋮") offers — same pattern as `BudgetsMenuSheet`.
/// Deudas had no overflow menu until the contextual-help minitutorials needed
/// a "Ver ayuda" reopen affordance (`docs/requirements/16-minitutoriales.md`
/// criterion 6), so this menu only ever carries that one option today.
enum DebtsMenuAction { viewHelp }

class DebtsMenuSheet extends StatelessWidget {
  const DebtsMenuSheet({super.key});

  static Future<DebtsMenuAction?> show(BuildContext context) =>
      BottomSheetBase.show<DebtsMenuAction>(
        context,
        builder: (context) => const DebtsMenuSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetActionsHead(
          title: l10n.debtsTitle,
          subtitle: l10n.debtsMenuOptions,
        ),
        SheetActionRow(
          icon: LucideIcons.circleHelp,
          title: l10n.tutorialsMenuViewHelp,
          subtitle: l10n.debtsMenuViewHelpSubtitle,
          onTap: () => Navigator.of(context).pop(DebtsMenuAction.viewHelp),
        ),
      ],
    );
  }
}
