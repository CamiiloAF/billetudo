import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/category_node.dart';
import '../utils/category_appearance.dart';
import 'category_subrow.dart';

/// A root row of the accordion (`bA51N`): icon+color, name, subcategory
/// count, chevron. Expanding reveals its subcategories indented plus
/// "Agregar subcategoría" — collapsing keeps only the count.
///
/// The expand animation is `AnimatedSize`, same criterion as the account
/// type pill/grid swap.
class CategoryAccordionRow extends StatelessWidget {
  const CategoryAccordionRow({
    required this.node,
    required this.expanded,
    required this.onToggle,
    required this.onAddSubcategory,
    this.onTapSubcategory,
    this.onEditRoot,
    super.key,
  });

  final CategoryNode node;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAddSubcategory;
  final ValueChanged<String>? onTapSubcategory;

  /// Opens the root category for editing. The row itself toggles the
  /// accordion, so editing gets its own explicit affordance next to the
  /// chevron (`categorias.md` leaves the exact trigger to implementation).
  final VoidCallback? onEditRoot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final root = node.root;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CategoryAppearance.softColorFor(colors, root.color),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      CategoryAppearance.iconFor(root.icon),
                      color: CategoryAppearance.colorFor(colors, root.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      root.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (node.hasSubcategories)
                    Text(
                      l10n.categorySubcategoryCount(node.subcategoryCount),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  if (onEditRoot != null)
                    IconButton(
                      onPressed: onEditRoot,
                      tooltip: l10n.commonEdit,
                      icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
                      visualDensity: VisualDensity.compact,
                    ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        for (final sub in node.subcategories)
                          CategorySubrow(
                            category: sub,
                            onTap: onTapSubcategory == null
                                ? null
                                : () => onTapSubcategory!(sub.id),
                          ),
                        InkWell(
                          onTap: onAddSubcategory,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 44,
                              top: 8,
                              bottom: 8,
                              right: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 18,
                                  color: colors.primaryDeep,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.categoryAddSubcategory,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.primaryDeep,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
