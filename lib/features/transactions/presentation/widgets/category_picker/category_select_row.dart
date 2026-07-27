import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';

/// A selection row of the `Category Select Sheet` (`SLfJW`): a root or a
/// subcategory, single-select.
///
/// Two distinct tap zones on an expandable root: the row **body** chooses the
/// category and closes the sheet ([onTap]), while the 44x44 **chevron** only
/// expands/collapses its subcategories ([onToggleExpand]). A root without
/// subcategories has no chevron, so its whole width is the body tap; a
/// subcategory is indented and never has a chevron.
class CategorySelectRow extends StatelessWidget {
  const CategorySelectRow({
    required this.category,
    required this.selected,
    required this.onTap,
    this.isSubcategory = false,
    this.showChevron = false,
    this.expanded = false,
    this.onToggleExpand,
    super.key,
  });

  final Category category;
  final bool selected;

  /// Chooses this category and closes the sheet.
  final VoidCallback onTap;

  final bool isSubcategory;

  /// Whether the trailing 44x44 expand/collapse chevron is shown (only a root
  /// with subcategories).
  final bool showChevron;
  final bool expanded;

  /// Expands/collapses this root's subcategories — the second tap zone,
  /// independent of [onTap].
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final foreground =
        selected ? colors.primaryOnSoftStrong : colors.textPrimary;

    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: EdgeInsets.only(
                  left: isSubcategory ? 24 : 12,
                  top: 10,
                  bottom: 10,
                  right: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: isSubcategory ? 32 : 40,
                      height: isSubcategory ? 32 : 40,
                      decoration: BoxDecoration(
                        color: CategoryAppearance.softColorFor(
                            colors, category.color),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
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
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        LucideIcons.check,
                        size: 18,
                        color: colors.primaryOnSoft,
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
                  duration: const Duration(milliseconds: 200),
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
