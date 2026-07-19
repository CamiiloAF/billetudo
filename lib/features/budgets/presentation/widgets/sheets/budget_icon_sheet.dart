import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';
import '../../../../categories/presentation/widgets/icon_tile.dart';

/// Budget icon picker (`XsnnD`): the same grid as Cuentas/Categorías but
/// **icon-only, no color** — the budget icon-wrap stays neutral `$muted` by
/// design (HU-01). Reuses the shared [IconTile] and icon catalog.
class BudgetIconSheet extends StatelessWidget {
  const BudgetIconSheet({required this.selected, super.key});

  final String? selected;

  /// Resolves to the picked icon name, or `null` if dismissed.
  static Future<String?> show(BuildContext context, {String? selected}) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => BudgetIconSheet(selected: selected),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.budgetIconSheetTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final iconName in CategoryAppearance.iconNames)
                IconTile(
                  iconName: iconName,
                  selected: iconName == selected,
                  // No color for budgets: keep the selected treatment neutral.
                  selectedColorToken: null,
                  onTap: () => Navigator.of(context).pop(iconName),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
