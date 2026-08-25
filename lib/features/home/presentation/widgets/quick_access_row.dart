import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/quick_access_item.dart';
import 'quick_access_settings_button.dart';

/// HU-05b: chrome row of navigation shortcuts (Pagos programados, Deudas,
/// Gráficas e informes) shown right below the Hero Card in every Home state
/// (loading/ready/empty/failure). Purely a navigation aid to sections
/// otherwise buried in "Más" — no selected/active chip. The order renders
/// [order] as given — the user's persisted pick from Ajustes ▸ "Orden del
/// acceso rápido" (`AppSettings.quickAccessOrder`), never a fixed sequence
/// hardcoded here. Metas is not here anymore: it recovered its own
/// bottom-nav tab. Cuentas is not here either: the "Mis cuentas" strip right
/// below already covers that shortcut. Closing the strip is
/// [QuickAccessSettingsButton], the way back to that Ajustes screen — shaped
/// as a circle, not a fourth pill, because it configures the row instead of
/// navigating anywhere, and pinned outside the scroll view so it stays
/// reachable no matter how wide the chips get.
class QuickAccessRow extends StatelessWidget {
  const QuickAccessRow({
    required this.order,
    required this.onOpenScheduledPayments,
    required this.onOpenDebts,
    required this.onOpenReports,
    required this.onCustomize,
    super.key,
  });

  /// Chips render in this order — always a valid permutation of
  /// [QuickAccessItem.values] (`QuickAccessItem.isValidOrder`), guaranteed
  /// upstream by `AppSettingsRepositoryImpl`.
  final List<QuickAccessItem> order;

  final VoidCallback onOpenScheduledPayments;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenReports;

  /// Opens Ajustes ▸ "Orden del acceso rápido", where [order] is picked. Not a
  /// destination like the chips above — see [QuickAccessSettingsButton].
  final VoidCallback onCustomize;

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
        // The gear sits OUTSIDE the scroll view, pinned to the trailing edge.
        // Inside it, it never showed: the three chips measure ~507pt against a
        // 390pt phone, so the button rendered past the fold and no golden even
        // changed when it was added — an entry point nobody could find.
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in order) ...[
                      QuickAccessChip(
                        icon: _iconFor(item),
                        label: _labelFor(l10n, item),
                        onTap: _onTapFor(item),
                        key: ValueKey(item),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            QuickAccessSettingsButton(onTap: onCustomize),
          ],
        ),
      ],
    );
  }

  IconData _iconFor(QuickAccessItem item) => switch (item) {
        QuickAccessItem.scheduledPayments => LucideIcons.calendarClock,
        QuickAccessItem.debts => LucideIcons.handCoins,
        QuickAccessItem.reports => LucideIcons.chartColumn,
      };

  String _labelFor(AppLocalizations l10n, QuickAccessItem item) =>
      switch (item) {
        QuickAccessItem.scheduledPayments =>
          l10n.homeQuickAccessScheduledPayments,
        QuickAccessItem.debts => l10n.moreDebts,
        QuickAccessItem.reports => l10n.moreReports,
      };

  VoidCallback _onTapFor(QuickAccessItem item) => switch (item) {
        QuickAccessItem.scheduledPayments => onOpenScheduledPayments,
        QuickAccessItem.debts => onOpenDebts,
        QuickAccessItem.reports => onOpenReports,
      };
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
