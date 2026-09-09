import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/scheduled_payment_reminder.dart';
import 'scheduled_payment_frequency_unit_chips.dart';

/// HU-08: "¿Cuándo te avisamos?" on the create/edit template form, right
/// after the "Modo" block.
///
/// A row of chips, reusing the exact chip of the frequency picker
/// (`ScheduledPaymentFrequencyUnitChip`) instead of a second chip style —
/// and horizontally scrollable for the same reason it is there: five labels
/// of uneven width must not shrink the type below the design system's
/// minimum on a narrow phone or a large text scale.
///
/// "Sin recordatorio" is a first-class chip and the selected one by default.
/// The default is deliberately not "avisarme": push nobody asked for is how
/// an app loses its notification permission for good.
class ScheduledPaymentReminderField extends StatelessWidget {
  const ScheduledPaymentReminderField({
    required this.reminder,
    required this.onChanged,
    required this.showsPermissionNotice,
    super.key,
  });

  /// The chosen option, or `null` for "sin recordatorio".
  final ScheduledPaymentReminder? reminder;

  final ValueChanged<ScheduledPaymentReminder?> onChanged;

  /// Whether to show the "notifications are off at the system level" note.
  /// Never a blocker: the preference is saved either way (HU-08).
  final bool showsPermissionNotice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    final options = <ScheduledPaymentReminder?, String>{
      null: l10n.remindersOptionNone,
      ScheduledPaymentReminder.onDueDate: l10n.remindersOptionOnDueDate,
      ScheduledPaymentReminder.oneDayBefore: l10n.remindersOptionOneDayBefore,
      ScheduledPaymentReminder.threeDaysBefore:
          l10n.remindersOptionThreeDaysBefore,
      ScheduledPaymentReminder.oneWeekBefore: l10n.remindersOptionOneWeekBefore,
    };
    final entries = options.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.remindersFieldSectionLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                ScheduledPaymentFrequencyUnitChip(
                  label: entries[i].value,
                  selected: entries[i].key == reminder,
                  onTap: () => onChanged(entries[i].key),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          showsPermissionNotice
              ? l10n.remindersPermissionNotice
              : l10n.remindersFieldHint,
          // Same secondary-text treatment for both: the permission note is
          // information, not an error. Nothing failed and nothing is blocked
          // — the preference was saved, it just will not fire yet.
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
