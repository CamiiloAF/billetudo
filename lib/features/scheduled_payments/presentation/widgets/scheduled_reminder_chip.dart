import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/scheduled_payment_reminder.dart';

/// The "🔔 Te avisamos 3 días antes" chip of a `Scheduled Card` (HU-08,
/// chip `dIIG3` of `tit0W`).
///
/// Only rendered when the template actually carries a reminder, and it names
/// the anticipation the user chose. The chip had been removed precisely
/// because it promised something the app could not do yet; it comes back
/// bound to a real, configured reminder, never to a mode or a default.
class ScheduledReminderChip extends StatelessWidget {
  const ScheduledReminderChip({required this.reminder, super.key});

  final ScheduledPaymentReminder reminder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final label = switch (reminder) {
      ScheduledPaymentReminder.onDueDate => l10n.remindersChipOnDueDate,
      ScheduledPaymentReminder.oneDayBefore => l10n.remindersChipOneDayBefore,
      ScheduledPaymentReminder.oneWeekBefore => l10n.remindersChipOneWeekBefore,
      ScheduledPaymentReminder.threeDaysBefore =>
        l10n.remindersChipDaysBefore(reminder.leadDays),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.bell, size: 12, color: colors.primaryOnSoftStrong),
          const SizedBox(width: 4),
          // Flexible, same as `ScheduledManualModeChip`: these labels are
          // longer than "Te avisamos" ever was, and `overflow: ellipsis`
          // alone does nothing inside a `MainAxisSize.min` Row.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primaryOnSoftStrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
