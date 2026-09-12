import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// `AccountSheet`'s "Cerrar sesión" link (`izRyw`,
/// `design-system/billetudo/pages/inicio.md` § "Hoja de cuenta"): a bare
/// `log-out` icon + label, both `$expense-text`, centered, padding vertical
/// 14 — no card or stroke, unlike the `List Card` rows above it.
class SignOutRow extends StatelessWidget {
  const SignOutRow({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.logOut, size: 16, color: colors.expenseText),
            const SizedBox(width: 8),
            Text(
              l10n.moreSignOut,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: colors.expenseText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
