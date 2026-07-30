import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// The `Ver subcategorías` link (`guwa6`): a 44pt tappable row with a top
/// border, closing `Card Categorías`' flat desglose (`A3zxf`). Its
/// destination is not designed yet (`design-system/billetudo/pages/
/// graficas.md`, pendiente 3) — [onTap] is deliberately nullable so a caller
/// with nowhere to send the user can render the link inert rather than
/// invent a screen.
class CategoryViewSubcategoriesLink extends StatelessWidget {
  const CategoryViewSubcategoriesLink({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.reportsCategoriesViewSubcategories,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primaryOnSoft,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 15,
              color: colors.primaryOnSoft,
            ),
          ],
        ),
      ),
    );
  }
}
