import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The "Más" hub (HU-01): the entry point to every other Nivel 0 destination.
/// Cuentas and Categorías are live; the rest are listed with a "Próximamente"
/// badge until their own lote ships, so no Nivel 0 feature is unreachable.
class MorePage extends StatelessWidget {
  const MorePage({
    required this.onOpenAccounts,
    required this.onOpenCategories,
    required this.onOpenComingSoon,
    super.key,
  });

  final VoidCallback onOpenAccounts;
  final VoidCallback onOpenCategories;

  /// Opens a stacked "Próximamente" page titled with the destination's name.
  final ValueChanged<String> onOpenComingSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            MoreRow(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.accountsTitle,
              onTap: onOpenAccounts,
            ),
            MoreRow(
              icon: Icons.category_outlined,
              label: l10n.categoriesTitle,
              onTap: onOpenCategories,
            ),
            MoreRow(
              icon: Icons.request_quote_outlined,
              label: l10n.moreDebts,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreDebts),
            ),
            MoreRow(
              icon: Icons.autorenew,
              label: l10n.moreRecurring,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreRecurring),
            ),
            MoreRow(
              icon: Icons.insights_outlined,
              label: l10n.moreReports,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreReports),
            ),
            MoreRow(
              icon: Icons.import_export,
              label: l10n.moreImportExport,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreImportExport),
            ),
            MoreRow(
              icon: Icons.settings_outlined,
              label: l10n.moreSettings,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreSettings),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row of the "Más" hub: icon + label, optionally flagged as
/// "Próximamente".
class MoreRow extends StatelessWidget {
  const MoreRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.comingSoon = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(icon, size: 20, color: colors.primaryOnSoft),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: theme.textTheme.titleSmall),
                ),
                if (comingSoon) ...[
                  ComingSoonBadge(label: l10n.comingSoonBadge),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.chevron_right, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The small "Próximamente" pill shown on not-yet-built rows.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
