import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_action_row.dart';

/// What Pagos programados' overflow ("⋮") offers — same pattern as
/// `BudgetsMenuSheet`. This tab root had an empty `Action Spacer` where this
/// menu now sits, needed once the contextual-help minitutorials required a
/// "Ver ayuda" reopen affordance (`docs/requirements/16-minitutoriales.md`
/// criterion 6).
enum ScheduledPaymentsMenuAction { viewHelp }

class ScheduledPaymentsMenuSheet extends StatelessWidget {
  const ScheduledPaymentsMenuSheet({super.key});

  static Future<ScheduledPaymentsMenuAction?> show(BuildContext context) =>
      BottomSheetBase.show<ScheduledPaymentsMenuAction>(
        context,
        builder: (context) => const ScheduledPaymentsMenuSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetActionsHead(
          title: l10n.scheduledPaymentsTitle,
          subtitle: l10n.scheduledPaymentsMenuOptions,
        ),
        SheetActionRow(
          icon: LucideIcons.circleHelp,
          title: l10n.tutorialsMenuViewHelp,
          subtitle: l10n.scheduledPaymentsMenuViewHelpSubtitle,
          onTap: () => Navigator.of(context)
              .pop(ScheduledPaymentsMenuAction.viewHelp),
        ),
      ],
    );
  }
}
