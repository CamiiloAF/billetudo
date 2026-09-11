import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../domain/entities/scheduled_payment_reminder.dart';
import 'reminder_option_row.dart';

/// The `Reminder Select Sheet` component (`HyuO3`, `reusable:true`): the
/// picker behind the template form's "Recordatorio" field (HU-08).
///
/// Reusable on purpose — the same sheet serves creating and editing a
/// template, and the frame's context forbids replicating these rows inline.
///
/// "Sin recordatorio" is the **first** option and the default: the app does
/// not start notifying because someone created a scheduled payment. Push
/// nobody asked for is how an app loses its notification permission for good.
class ScheduledPaymentReminderSheet extends StatelessWidget {
  const ScheduledPaymentReminderSheet({required this.selected, super.key});

  /// The current choice, or `null` for "sin recordatorio".
  final ScheduledPaymentReminder? selected;

  /// Opens the sheet and resolves to the picked option.
  ///
  /// Resolves to `(false, null)` when dismissed without choosing, so the
  /// caller can tell "closed the sheet" apart from "chose sin recordatorio" —
  /// both would otherwise arrive as a bare `null`.
  static Future<({bool picked, ScheduledPaymentReminder? reminder})> show(
    BuildContext context, {
    required ScheduledPaymentReminder? selected,
  }) async {
    final result = await BottomSheetBase.show<
        ({bool picked, ScheduledPaymentReminder? reminder})>(
      context,
      builder: (context) => ScheduledPaymentReminderSheet(selected: selected),
    );
    return result ?? (picked: false, reminder: null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final options = <(ScheduledPaymentReminder?, String)>[
      (null, l10n.remindersOptionNone),
      (ScheduledPaymentReminder.onDueDate, l10n.remindersOptionOnDueDate),
      (
        ScheduledPaymentReminder.oneDayBefore,
        l10n.remindersOptionOneDayBefore,
      ),
      (
        ScheduledPaymentReminder.threeDaysBefore,
        l10n.remindersOptionThreeDaysBefore,
      ),
      (
        ScheduledPaymentReminder.oneWeekBefore,
        l10n.remindersOptionOneWeekBefore,
      ),
    ];

    // Not wrapped in a scroll view: measured on a real 390x844 phone through
    // `BottomSheetBase`, the head plus the five 56px rows end at 816 and the
    // sheet keeps its 28pt bottom padding. The rows have a fixed height, so
    // text scaling does not grow the sheet either. A `SingleChildScrollView`
    // here would only risk eating the drag-to-dismiss gesture.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetHead(
          title: l10n.remindersFieldSectionLabel,
          hint: l10n.remindersSheetCaption,
        ),
        const SizedBox(height: 14),
        for (final option in options)
          ReminderOptionRow(
            // `bell-off` on the "apagado" pole, `bell` on the rest: the state
            // must not hang on the check glyph alone.
            icon: option.$1 == null ? LucideIcons.bellOff : LucideIcons.bell,
            label: option.$2,
            selected: option.$1 == selected,
            onTap: () => Navigator.of(context)
                .pop((picked: true, reminder: option.$1)),
          ),
      ],
    );
  }
}
