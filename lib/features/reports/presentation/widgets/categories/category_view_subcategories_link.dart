import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// The three visual states of [CategoryViewSubcategoriesLink].
enum CategoryDrillDownLinkState {
  /// No section of the donut is selected: the pill is visually inert and
  /// does not react to tap (criterion 4).
  disabled,

  /// A root category with subcategories is selected: tapping drills into
  /// that category's subcategory donut.
  viewSubcategories,

  /// Already showing a subcategory donut: tapping returns to the root level.
  back,
}

/// The "Profundizar"/"Atrás" link (`guwa6`): a compact, right-aligned pill
/// above the donut in `Card Categorías`, following the same visual pattern as
/// `BalancesStripHeader`'s "Ver todas" link. Its label, icon and
/// interactivity follow [state]:
/// - [CategoryDrillDownLinkState.disabled]: no selection yet, inert.
/// - [CategoryDrillDownLinkState.viewSubcategories]: selected category has
///   subcategories, tapping drills in.
/// - [CategoryDrillDownLinkState.back]: already one level in, tapping
///   returns to the root donut.
class CategoryViewSubcategoriesLink extends StatelessWidget {
  const CategoryViewSubcategoriesLink({
    required this.state,
    this.onTap,
    super.key,
  });

  final CategoryDrillDownLinkState state;

  /// Ignored when [state] is [CategoryDrillDownLinkState.disabled].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDisabled = state == CategoryDrillDownLinkState.disabled;
    final label = state == CategoryDrillDownLinkState.back
        ? l10n.reportsCategoriesBack
        : l10n.reportsCategoriesViewSubcategories;
    final icon = state == CategoryDrillDownLinkState.back
        ? LucideIcons.chevronLeft
        : LucideIcons.chevronRight;
    final tone =
        isDisabled ? colors.segmentInactiveText : colors.primaryOnSoft;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == CategoryDrillDownLinkState.back) ...[
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
            if (state != CategoryDrillDownLinkState.back) ...[
              const SizedBox(width: 2),
              Icon(icon, size: 14, color: tone),
            ],
          ],
        ),
      ),
    );
  }
}
