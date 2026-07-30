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

/// The `Ver subcategorías`/`Atrás` pill (`guwa6`): a 44pt tappable row with a
/// top border, closing `Card Categorías`' flat desglose (`A3zxf`). Its
/// label, icon and interactivity follow [state]:
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
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state == CategoryDrillDownLinkState.back) ...[
              Icon(icon, size: 15, color: tone),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
            if (state != CategoryDrillDownLinkState.back) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 15, color: tone),
            ],
          ],
        ),
      ),
    );
  }
}
