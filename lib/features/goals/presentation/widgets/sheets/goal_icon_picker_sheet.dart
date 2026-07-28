import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../utils/goal_icon_appearance.dart';
import '../goal_icon_tile.dart';

/// "Elegir ícono" (`cwj6B`/`bqA8H`, HU-01): the 15-icon "set expresivo" grid a
/// goal's icon-and-name row opens. Same shape as `BudgetIconSheet` — a 5-wide
/// grid, tap-to-preview, "Aplicar" commits the pick — but backed by
/// [GoalIconAppearance]'s own icon set instead of `CategoryAppearance`'s,
/// since a goal's icon has no color pairing (HU-01: "sin color por meta").
class GoalIconPickerSheet extends StatefulWidget {
  const GoalIconPickerSheet({required this.selected, super.key});

  final String? selected;

  /// Resolves to the picked icon name, or `null` if dismissed.
  static Future<String?> show(BuildContext context, {String? selected}) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => GoalIconPickerSheet(selected: selected),
      );

  @override
  State<GoalIconPickerSheet> createState() => _GoalIconPickerSheetState();
}

class _GoalIconPickerSheetState extends State<GoalIconPickerSheet> {
  late String? _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHead(
          title: l10n.goalIconSheetTitle,
          hint: l10n.goalIconSheetHint,
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          // Three whole rows of 60pt tiles plus their 12pt gaps: a viewport
          // cut at a row boundary, never mid-tile.
          constraints: const BoxConstraints(maxHeight: 60 * 3 + 12 * 2),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final iconName in GoalIconAppearance.iconNames)
                GoalIconTile(
                  iconName: iconName,
                  selected: iconName == _selected,
                  onTap: () => setState(() => _selected = iconName),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: Text(l10n.commonApply),
        ),
      ],
    );
  }
}
