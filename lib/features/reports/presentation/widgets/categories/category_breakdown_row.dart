import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';
import '../../../domain/entities/category_breakdown_item.dart';

/// The `Category Row` (`DRc5X`) as used by Categorías' desglose (HU-03):
/// icon, name, `%` and amount, plus a proportional bar. The desglose is a
/// **flat** list of top-level categories (`A3zxf`) — no per-row expand
/// affordance; drilling into subcategories happens through the card's own
/// "Ver subcategorías" link instead.
///
/// **"Sin categoría" is deliberately neutral** (`$text-secondary`, never a
/// palette color) — it names an absence, not a category
/// (`design-system/billetudo/pages/graficas.md`, nota `YGtpe`).
class CategoryBreakdownRow extends StatelessWidget {
  const CategoryBreakdownRow({
    required this.item,
    required this.totalMinor,
    this.currencyCode = 'COP',
    this.onTap,
    super.key,
  });

  final CategoryBreakdownItem item;
  final int totalMinor;
  final String currencyCode;

  /// Navigates to Movimientos filtered by this row's category. `null` for
  /// the "Sin categoría" bucket (`item.categoryId == null`), which has no
  /// category id to filter by.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();

    final pct =
        totalMinor == 0 ? 0 : (item.amountMinor * 100 / totalMinor).round();
    final name = item.isUncategorized
        ? l10n.reportsCategoriesUncategorized
        : (item.name ?? '');
    final tone =
        item.isUncategorized ? colors.textSecondary : _tone(colors, item);
    final softTone = item.isUncategorized
        ? colors.muted
        : CategoryAppearance.softColorFor(colors, item.color);
    final icon = item.isUncategorized
        ? LucideIcons.circleDashed
        : CategoryAppearance.iconFor(item.icon);

    return Semantics(
      label: l10n.reportsCategoriesRowSemantics(
        name,
        pct,
        money.formatSymbol(item.amountMinor, currencyCode: currencyCode),
      ),
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: softTone,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, size: 20, color: tone),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          l10n.reportsCategoriesMovementsCount(
                            item.movementCount,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        money.formatSymbol(item.amountMinor,
                            currencyCode: currencyCode),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.reportsPercentValue(pct),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: colors.muted,
                  valueColor: AlwaysStoppedAnimation(tone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _tone(AppColors colors, CategoryBreakdownItem item) =>
      CategoryAppearance.colorFor(colors, item.color);
}
