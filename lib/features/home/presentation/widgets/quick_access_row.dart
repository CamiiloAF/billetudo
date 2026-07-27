import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// HU-05b: fixed chrome row of navigation shortcuts (Pagos programados,
/// Deudas, Gráficas e informes, Metas) shown right below the Hero Card in
/// every Home state (loading/ready/empty/failure). Purely a navigation aid to
/// sections otherwise buried in "Más" — no selected/active chip, and the
/// order is fixed for now (configurable reordering is a future feature, see
/// `docs/requirements/04-inicio.md` § Pendiente). Metas is last: it lost its
/// bottom-nav tab to Pagos Programados (bugfix item 7). Cuentas is not here:
/// the "Mis cuentas" strip right below already covers that shortcut.
class QuickAccessRow extends StatelessWidget {
  const QuickAccessRow({
    required this.onOpenScheduledPayments,
    required this.onOpenDebts,
    required this.onOpenReports,
    required this.onOpenGoals,
    super.key,
  });

  final VoidCallback onOpenScheduledPayments;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeQuickAccessTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              QuickAccessChip(
                icon: LucideIcons.calendarClock,
                label: l10n.homeQuickAccessScheduledPayments,
                onTap: onOpenScheduledPayments,
              ),
              const SizedBox(width: 8),
              QuickAccessChip(
                icon: LucideIcons.handCoins,
                label: l10n.moreDebts,
                onTap: onOpenDebts,
              ),
              const SizedBox(width: 8),
              QuickAccessChip(
                icon: LucideIcons.chartColumn,
                label: l10n.moreReports,
                onTap: onOpenReports,
              ),
              const SizedBox(width: 8),
              QuickAccessChip(
                icon: LucideIcons.target,
                label: l10n.navGoals,
                onTap: onOpenGoals,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One pill of [QuickAccessRow]: icon + label, purely navigational (no
/// selected/active state — it is not a tab).
class QuickAccessChip extends StatelessWidget {
  const QuickAccessChip({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
