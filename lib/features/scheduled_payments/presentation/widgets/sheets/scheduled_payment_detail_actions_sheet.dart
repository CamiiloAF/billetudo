import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';

/// The detail's ⋮ menu (criterion 12), replaced from a `PopupMenuButton`
/// dropdown into a mobile `Bottom Sheet Base` (MASTER.md forbids anchored
/// dropdowns on mobile). Groups the *occurrence* action (Posponer) above a
/// divider from the *template* actions (Editar, Eliminar) — posponer only
/// applies when the next occurrence is currently pending confirmation.
class ScheduledPaymentDetailActionsSheet extends StatelessWidget {
  const ScheduledPaymentDetailActionsSheet({
    required this.canSnooze,
    required this.templateName,
    required this.onEdit,
    required this.onDelete,
    this.onSnooze,
    super.key,
  });

  final bool canSnooze;

  /// The template's display name, shown as the sheet's title so the user
  /// knows which scheduled payment these actions apply to.
  final String templateName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSnooze;

  static Future<void> show(
    BuildContext context, {
    required bool canSnooze,
    required String templateName,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    VoidCallback? onSnooze,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => ScheduledPaymentDetailActionsSheet(
          canSnooze: canSnooze,
          templateName: templateName,
          onEdit: onEdit,
          onDelete: onDelete,
          onSnooze: onSnooze,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final snooze = onSnooze;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          templateName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.scheduledDetailActionsSheetSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (canSnooze && snooze != null) ...[
          ScheduledPaymentDetailActionTile(
            icon: LucideIcons.alarmClock,
            label: l10n.scheduledDetailActionsSnooze,
            onTap: () {
              Navigator.of(context).pop();
              snooze();
            },
          ),
          Divider(height: 1, color: colors.border),
        ],
        ScheduledPaymentDetailActionTile(
          icon: LucideIcons.pencil,
          label: l10n.commonEdit,
          onTap: () {
            Navigator.of(context).pop();
            onEdit();
          },
        ),
        ScheduledPaymentDetailActionTile(
          icon: LucideIcons.trash2,
          label: l10n.scheduledDetailActionsDelete,
          destructive: true,
          onTap: () {
            Navigator.of(context).pop();
            onDelete();
          },
        ),
      ],
    );
  }
}

/// One row of the detail's actions sheet: an icon, its label, `height: 52`.
class ScheduledPaymentDetailActionTile extends StatelessWidget {
  const ScheduledPaymentDetailActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final color = destructive ? colors.expense : colors.textPrimary;
    return SizedBox(
      height: 52,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
