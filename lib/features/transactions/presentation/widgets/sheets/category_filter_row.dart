import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';

/// A row of the `Filtrar por categoría` sheet (`q0CTl`/`NZbsD`): a root or a
/// subcategory, selected by tapping the whole row body — there is no
/// checkbox, the selected state is only the row's `fill`/`stroke`.
///
/// A root has two independent tap zones: the row body ([onToggleSelected])
/// and, when it has subcategories, the trailing 44x44 chevron
/// ([onToggleExpand]) that only expands/collapses them. A subcategory is
/// indented 56px and has neither counter nor chevron.
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    required this.category,
    required this.selected,
    required this.onToggleSelected,
    this.isSubcategory = false,
    this.subcategoryCount = 0,
    this.expanded = false,
    this.onToggleExpand,
    super.key,
  });

  final Category category;
  final bool selected;

  /// Toggles this row's selection: for a root, its whole subcategory tree
  /// moves with it (`CategoryFilterCubit.toggleRootCategory`'s symmetric
  /// rule); a subcategory toggles alone.
  final VoidCallback onToggleSelected;

  final bool isSubcategory;

  /// Only shown on a root: "N subcategorías".
  final int subcategoryCount;

  final bool expanded;

  /// Expands/collapses this root's subcategories. `null` on a subcategory or
  /// on a root without any.
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final showChevron = !isSubcategory && subcategoryCount > 0;
    final iconWrapSize = isSubcategory ? 32.0 : 40.0;

    return Material(
      color: selected ? colors.primarySoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: selected ? colors.primary : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onToggleSelected,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: EdgeInsets.only(
                  left: isSubcategory ? 56 : 12,
                  top: 10,
                  bottom: 10,
                  right: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: iconWrapSize,
                      height: iconWrapSize,
                      decoration: BoxDecoration(
                        color: CategoryAppearance.softColorFor(
                          colors,
                          category.color,
                        ),
                        borderRadius: BorderRadius.circular(iconWrapSize / 2),
                      ),
                      child: Icon(
                        CategoryAppearance.iconFor(category.icon),
                        size: isSubcategory ? 16 : 20,
                        color:
                            CategoryAppearance.colorFor(colors, category.color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showChevron)
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: onToggleExpand,
                tooltip: expanded
                    ? l10n.categorySelectCollapse
                    : l10n.categorySelectExpand,
                icon: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: AppTheme.motionDuration,
                  child: Icon(
                    LucideIcons.chevronDown,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
