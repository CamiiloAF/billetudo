import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/forms/keyboard.dart';
import '../../../../core/widgets/date_picker_sheet.dart';
import '../../../transactions/presentation/widgets/transaction_form_field_button.dart';

/// The template form's `nextDate`/`endDate` fields, built on top of the
/// shared `Form Field` pattern (`wOlOA`, [TransactionFormFieldButton]) —
/// same box, label and chevron as Transacciones' Cuenta/Fecha fields, only
/// with a different `inlineIcon` and, for `endDate`, an [onCleared] "x" to
/// undo "Sin fecha de fin" instead of the chevron.
///
/// `nextDate` (`IiCkU`, "Primer pago") uses `calendar`; `endDate` (`aLwJo`,
/// "Termina") uses `infinity` — inferred from [onCleared] being set, since
/// only the optional `endDate` field carries a clear action.
class ScheduledPaymentDateField extends StatelessWidget {
  const ScheduledPaymentDateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.placeholder,
    this.onCleared,
    this.minDate,
    super.key,
  });

  final String label;
  final DateTime? date;
  final String? placeholder;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;

  /// The earliest selectable day, when set: a debt cuota's first payment cannot
  /// be dated before the debt was created (HU-03, fix 4a-i).
  final DateTime? minDate;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final value = date == null
        ? (placeholder ?? '')
        : DateFormat.yMMMd(locale).format(date!);
    return TransactionFormFieldButton(
      label: label,
      value: value,
      hasValue: date != null,
      inlineIcon:
          onCleared != null ? LucideIcons.infinity : LucideIcons.calendar,
      onCleared: onCleared,
      onTap: () async {
        // Drop the system keyboard before opening the picker so it does not
        // spring back when the sheet closes (device keyboard-UX fix).
        await dismissSystemKeyboard(context);
        if (!context.mounted) {
          return;
        }
        final minDate = this.minDate;
        final picked = await DatePickerSheet.show(
          context,
          initialDate: date ?? DateTime.now(),
          disabledBefore:
              minDate == null ? null : DateUtils.dateOnly(minDate),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }
}
