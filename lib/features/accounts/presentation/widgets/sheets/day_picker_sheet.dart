import 'package:flutter/material.dart';

import '../../../domain/entities/account_draft.dart';
import '../bottom_sheet_base.dart';
import '../day_cell.dart';

/// Picks a day of the month: the 1-31 grid behind "Día de corte" and "Día de
/// pago".
///
/// The title is whatever the field that opened it passes, so one sheet serves
/// both. There is no note about months without a 31st: the system resolves that
/// on its own and explaining it would only add noise.
class DayPickerSheet extends StatelessWidget {
  const DayPickerSheet({
    required this.title,
    required this.selected,
    super.key,
  });

  /// Already localized by the caller.
  final String title;

  final int? selected;

  /// Resolves to the chosen day, or null if dismissed.
  static Future<int?> show(
    BuildContext context, {
    required String title,
    required int? selected,
  }) =>
      BottomSheetBase.show<int>(
        context,
        builder: (context) => DayPickerSheet(title: title, selected: selected),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var day = AccountDraft.minDayOfMonth;
                day <= AccountDraft.maxDayOfMonth;
                day++)
              DayCell(
                day: day,
                isSelected: day == selected,
                onTap: (value) => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ],
    );
  }
}
