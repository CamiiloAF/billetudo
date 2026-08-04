import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_action_row.dart';

/// What the detail's overflow ("⋮") offers (`W5gXNE`): a bottom sheet with
/// the goal's name as its title and up to three wrap-less `SheetActionRow`s,
/// each with a one-line subtitle explaining what it does — never the
/// circular-icon `SheetMenuRow` (that shape has no per-row subtitle and is
/// for a screen's own overflow, not this one), and never a Material
/// `PopupMenuButton`.
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
        SheetActionRow.bare(
          icon: LucideIcons.pencil,
          title: l10n.goalEditTooltip,
          subtitle: l10n.goalActionEditSubtitle,
          onTap: () => Navigator.of(context).pop(GoalActionsSheetAction.edit),
        ),
        SheetActionRow.bare(
          icon: archived ? LucideIcons.archiveRestore : LucideIcons.archive,
          title: archived ? l10n.goalActionUnarchive : l10n.goalActionArchive,
          subtitle: archived
              ? l10n.goalActionUnarchiveSubtitle
              : l10n.goalActionArchiveSubtitle,
          onTap: () => Navigator.of(context).pop(
            archived
                ? GoalActionsSheetAction.unarchive
                : GoalActionsSheetAction.archive,
          ),
        ),
        SheetActionRow.bare(
          icon: LucideIcons.trash2,
          title: l10n.goalActionDeleteLabel,
          subtitle: l10n.goalActionDeleteSubtitle,
          foreground: colors.expenseText,
          onTap: () =>
              Navigator.of(context).pop(GoalActionsSheetAction.delete),
        ),
      ],
    );
  }
}
