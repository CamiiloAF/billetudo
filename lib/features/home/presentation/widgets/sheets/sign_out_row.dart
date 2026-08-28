import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// `AccountSheet`'s "Cerrar sesión" row.
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          l10n.moreSignOut,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.expenseText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
