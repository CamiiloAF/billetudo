import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_menu_row.dart';

/// What the detail's overflow ("⋮") offers (`W5gXNE`/`tKk1Y`/`uGtaB`): a
/// bottom sheet with the goal's name as its title and up to three `Menu Row`s
/// — never a Material `PopupMenuButton`.
enum GoalActionsSheetAction { edit, archive, unarchive, delete }

class GoalActionsSheet extends StatelessWidget {
  const GoalActionsSheet({
    required this.goalName,
    required this.archived,
    super.key,
  });

  final String goalName;

  /// Whether the goal is already archived — swaps "Archivar" for
  /// "Desarchivar".
  final bool archived;

  static Future<GoalActionsSheetAction?> show(
    BuildContext context, {
    required String goalName,
    required bool archived,
  }) =>
      BottomSheetBase.show<GoalActionsSheetAction>(
        context,
        builder: (context) =>
            GoalActionsSheet(goalName: goalName, archived: archived),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            goalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        SheetMenuRow(
          icon: LucideIcons.pencil,
          label: l10n.goalEditTooltip,
          onTap: () => Navigator.of(context).pop(GoalActionsSheetAction.edit),
        ),
        SheetMenuRow(
          icon: archived ? LucideIcons.archiveRestore : LucideIcons.archive,
          label: archived ? l10n.goalActionUnarchive : l10n.goalActionArchive,
          showChevron: false,
          onTap: () => Navigator.of(context).pop(
            archived
                ? GoalActionsSheetAction.unarchive
                : GoalActionsSheetAction.archive,
          ),
        ),
        SheetMenuRow(
          icon: LucideIcons.trash2,
          label: l10n.commonDelete,
          foreground: colors.expenseText,
          showChevron: false,
          onTap: () =>
              Navigator.of(context).pop(GoalActionsSheetAction.delete),
        ),
      ],
    );
  }
}
