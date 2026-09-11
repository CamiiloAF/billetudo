import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/forms/keyboard.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../transactions/presentation/widgets/transaction_form_field_button.dart';
import '../../domain/entities/scheduled_payment_reminder.dart';
import 'sheets/scheduled_payment_reminder_sheet.dart';

/// HU-08: the "Recordatorio" field of the create/edit template form
/// (`KXZKA` in `a7x7uy`).
///
/// A `Form Field` (`wOlOA`) — label above, tappable box with an inline icon,
/// the current value and a trailing `chevron-down` — that opens
/// [ScheduledPaymentReminderSheet]. **Not** an inline chip row: the frame's
/// context is explicit that tapping it opens the sheet, and five options of
/// uneven width read as a list, not as a scrollable strip.
///
/// Sits right after the "Al llegar la fecha" block and before "Nota": a
/// reminder only makes sense once it is decided what happens on the date.
///
/// The default is "Sin recordatorio", rendered as a placeholder with the
/// `bell-off` glyph. The app does not start notifying because someone created
/// a scheduled payment.
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

    final value = switch (reminder) {
      null => l10n.remindersOptionNone,
      ScheduledPaymentReminder.onDueDate => l10n.remindersOptionOnDueDate,
      ScheduledPaymentReminder.oneDayBefore => l10n.remindersOptionOneDayBefore,
      ScheduledPaymentReminder.threeDaysBefore =>
        l10n.remindersOptionThreeDaysBefore,
      ScheduledPaymentReminder.oneWeekBefore =>
        l10n.remindersOptionOneWeekBefore,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionFormFieldButton(
          label: l10n.remindersFieldSectionLabel,
          value: value,
          // "Sin recordatorio" is a real, valid choice, but it is the empty
          // pole of the field: the frame renders it in `$text-secondary`
          // with `bell-off`, same as any other placeholder.
          hasValue: reminder != null,
          inlineIcon:
              reminder == null ? LucideIcons.bellOff : LucideIcons.bell,
          onTap: () async {
            // `dismissSystemKeyboard` (not a bare `unfocus()`): on a real
            // device the system keyboard's close animation is not
            // instantaneous, and `ScheduledPaymentReminderSheet` below is a
            // fixed-height, non-scrollable sheet by design (its own doc
            // comment) — opening it before the keyboard's inset has actually
            // settled overflowed its `Column` by the inset still left over.
            await dismissSystemKeyboard(context);
            if (!context.mounted) {
              return;
            }
            final result = await ScheduledPaymentReminderSheet.show(
              context,
              selected: reminder,
            );
            if (result.picked) {
              onChanged(result.reminder);
            }
          },
        ),
        // Only in the state the frame does not cover. With the permission
        // granted the field stands alone, exactly as designed; with it
        // denied, staying silent would let the user pick a reminder that
        // cannot fire and never say so. Secondary text, not an error: nothing
        // failed and nothing is blocked.
        if (showsPermissionNotice) ...[
          const SizedBox(height: 8),
          Text(
            l10n.remindersPermissionNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
