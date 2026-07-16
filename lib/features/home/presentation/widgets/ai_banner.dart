import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The one-line AI "próximamente" banner (HU-06), shown right below the recent
/// feed. Tapping it opens a "coming soon" sheet — it never runs AI nor calls a
/// backend, so Nivel 0 stays intact.
class AiBanner extends StatelessWidget {
  const AiBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 20, color: colors.primaryOnSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.homeAiBanner,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward,
                  size: 18, color: colors.primaryOnSoft),
            ],
          ),
        ),
      ),
    );
  }
}
