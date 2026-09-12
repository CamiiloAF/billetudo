import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/quick_access_item.dart';
import 'quick_access_chip_with_badge.dart';
import 'quick_access_row_chip.dart';
import 'quick_access_settings_button.dart';

/// HU-05b: chrome row of navigation shortcuts (Pagos programados, Cuentas,
/// Deudas, Gráficas, Metas) shown right below the Hero Card in every Home
/// state (loading/ready/empty/failure). Purely a navigation aid to sections
/// otherwise buried in "Más" — no selected/active chip. The order renders
/// [order] as given — the user's persisted pick from Ajustes ▸ "Orden del
/// acceso rápido" (`AppSettings.quickAccessOrder`), never a fixed sequence
/// hardcoded here.
///
/// Cuentas and Metas joined the row in the Home hero redesign
/// (`design-system/billetudo/pages/inicio.md`): the "Mis cuentas" strip that
/// used to cover the Cuentas shortcut is gone from Home (its atajo is now the
/// header's wallet button → "Tu dinero" sheet), so Cuentas needed a seat
/// here; Metas joined at the same time to round the row out to 5. Pagos
/// programados renders with a pending-occurrences badge
/// ([QuickAccessChipWithBadge]) whenever [pendingScheduledCount] is
/// positive — never a badge showing zero.
class QuickAccessRow extends StatelessWidget {
  const QuickAccessRow({
    required this.order,
    required this.pendingScheduledCount,
    required this.onOpenScheduledPayments,
    required this.onOpenAccounts,
    required this.onOpenDebts,
    required this.onOpenReports,
    required this.onOpenGoals,
    required this.onCustomize,
    super.key,
  });

  /// Chips render in this order — always a valid permutation of
  /// [QuickAccessItem.values] (`QuickAccessItem.isValidOrder`), guaranteed
  /// upstream by `AppSettingsRepositoryImpl`.
  final List<QuickAccessItem> order;

  /// Scheduled-payment occurrences pending confirmation — the "Pagos
  /// programados" chip's badge count. `0` renders the plain chip instead.
  final int pendingScheduledCount;

  final VoidCallback onOpenScheduledPayments;
  final VoidCallback onOpenAccounts;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenGoals;

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
        // The gear is the 6th item of the scroll, after the 5 category
        // chips — Pencil node `u4f7l` ("Quick Access Chip A · Ajustes"):
        // same chrome ($surface fill, $border stroke, 44pt tap target) but
        // circular and without a visible label, since it configures the row
        // instead of navigating into a section.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in order) ...[
                QuickAccessRowChip(
                  key: ValueKey(item),
                  item: item,
                  pendingScheduledCount: pendingScheduledCount,
                  onOpenScheduledPayments: onOpenScheduledPayments,
                  onOpenAccounts: onOpenAccounts,
                  onOpenDebts: onOpenDebts,
                  onOpenReports: onOpenReports,
                  onOpenGoals: onOpenGoals,
                ),
                const SizedBox(width: 8),
              ],
              QuickAccessSettingsButton(onTap: onCustomize),
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
