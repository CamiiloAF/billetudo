import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/date_picker_sheet.dart';
import 'transaction_form_field_button.dart';

/// The Fecha field of the transaction form. Renders a friendly value
/// ("Hoy, 13 jul") and opens the app's own [DatePickerSheet]; the picked day is
/// handed back through [onChanged] (the cubit's `dateChanged`).
class TransactionDateField extends StatelessWidget {
  const TransactionDateField({
    required this.date,
    required this.onChanged,
    super.key,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TransactionFormFieldButton(
      label: l10n.transactionFormDateLabel,
      value: _label(context, l10n),
      inlineIcon: LucideIcons.calendar,
      onTap: () async {
        final picked = await DatePickerSheet.show(context, initialDate: date);
        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }

  String _label(BuildContext context, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat('d MMM', locale).format(date);
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date);
    final difference = today.difference(day).inDays;
    final prefix = switch (difference) {
      0 => l10n.transactionFormDateToday,
      1 => l10n.transactionFormDateYesterday,
      _ => null,
    };
    return prefix == null
        ? dayLabel
        : l10n.transactionFormDateValue(prefix, dayLabel);
  }
}
