import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_action_row.dart';

/// What Metas' overflow ("⋮") offers — same pattern as
/// `BudgetsMenuSheet`/`DebtsMenuSheet`. Metas had no overflow menu until the
/// contextual-help minitutorials needed a "Ver ayuda" reopen affordance
/// (`docs/requirements/16-minitutoriales.md` criterion 6); "Ver archivados"
/// already existed as the list's own bottom `TextButton` and stays there
/// unchanged, so this menu only carries the new option for now.
enum GoalsMenuAction { viewHelp }

class GoalsMenuSheet extends StatelessWidget {
  const GoalsMenuSheet({super.key});

  static Future<GoalsMenuAction?> show(BuildContext context) =>
      BottomSheetBase.show<GoalsMenuAction>(
        context,
        builder: (context) => const GoalsMenuSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetActionsHead(
          title: l10n.goalsTitle,
          subtitle: l10n.goalsMenuOptions,
        ),
        SheetActionRow(
          icon: LucideIcons.circleHelp,
          title: l10n.tutorialsMenuViewHelp,
          subtitle: l10n.goalsMenuViewHelpSubtitle,
          onTap: () => Navigator.of(context).pop(GoalsMenuAction.viewHelp),
        ),
      ],
    );
  }
}
