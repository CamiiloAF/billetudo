import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';
import '../../../../categories/presentation/widgets/icon_tile.dart';

/// Budget icon picker (`XsnnD` / `Al6tQ`): the same grid as Cuentas/Categorías
/// but **icon-only, no color** — the budget icon-wrap stays neutral `$muted` by
/// design (HU-01), so the picked tile wears the brand family instead of a
/// category color. Reuses the shared [IconTile] and icon catalog.
///
/// Tapping a tile only moves the selection; the value is returned by the
/// "Aplicar" `Button/Primary` at the foot of the sheet.
class BudgetIconSheet extends StatefulWidget {
  const BudgetIconSheet({required this.selected, super.key});

  final String? selected;

  /// Resolves to the picked icon name, or `null` if dismissed.
  static Future<String?> show(BuildContext context, {String? selected}) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => BudgetIconSheet(selected: selected),
      );

  @override
  State<BudgetIconSheet> createState() => _BudgetIconSheetState();
}

class _BudgetIconSheetState extends State<BudgetIconSheet> {
  late String? _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHead(
          title: l10n.budgetIconSheetTitle,
          hint: l10n.budgetIconSheetHint,
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          // Four whole rows of 60pt tiles plus their 12pt gaps: a viewport cut
          // at a row boundary, never mid-tile.
          constraints: const BoxConstraints(maxHeight: 60 * 4 + 12 * 3),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final iconName in CategoryAppearance.iconNames)
                IconTile(
                  iconName: iconName,
                  selected: iconName == _selected,
                  // No color for budgets: the picked tile takes the brand
                  // family, never a category color.
                  selectedColorToken: null,
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
