import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/date_picker_sheet.dart';

/// A date input row that opens [DatePickerSheet], used for the form's
/// `nextDate`/`endDate` fields.
class ScheduledPaymentDateField extends StatelessWidget {
  const ScheduledPaymentDateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.placeholder,
    this.onCleared,
    super.key,
  });

  final String label;
  final DateTime? date;
  final String? placeholder;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final value =
        date == null ? (placeholder ?? '') : DateFormat.yMMMd(locale).format(date!);
    return InkWell(
      onTap: () async {
        final picked = await DatePickerSheet.show(
          context,
          initialDate: date ?? DateTime.now(),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: date != null && onCleared != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onCleared)
              : null,
        ),
        child: Text(value),
      ),
    );
  }
}
