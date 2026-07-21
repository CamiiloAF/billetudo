import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/account_draft.dart';
import '../day_cell.dart';

/// Picks a day of the month: the 1-31 grid behind "Día de corte" and "Día de
/// pago".
///
/// The title is whatever the field that opened it passes, so one sheet serves
/// both. There is no note about months without a 31st: the system resolves that
/// on its own and explaining it would only add noise.
///
/// Tapping a day only stages it — `tYzxA`/`p6SGT` add a `Button/Primary`
/// "Guardar" below the grid, an explicit confirmation step, instead of closing
/// the sheet on the first tap.
class DayPickerSheet extends StatefulWidget {
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
  State<DayPickerSheet> createState() => _DayPickerSheetState();
}

class _DayPickerSheetState extends State<DayPickerSheet> {
  late int? _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
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
                isSelected: day == _selected,
                onTap: (value) => setState(() => _selected = value),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
            icon: const Icon(LucideIcons.check),
            label: Text(l10n.commonSave),
          ),
        ),
      ],
    );
  }
}
