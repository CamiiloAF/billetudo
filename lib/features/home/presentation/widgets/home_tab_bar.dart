import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// One destination of the bottom tab bar.
class HomeTabItem {
  const HomeTabItem({required this.icon, required this.label});

  final IconData icon;

  /// Already localized.
  final String label;
}

/// The five-destination bottom tab bar (HU-01): Inicio, Movimientos,
/// Presupuestos, Pagos programados, Más. The active destination is highlighted
/// in the brand color; the rest use `text-secondary`. Pagos Programados took
/// Metas' slot (bugfix item 7); Metas now lives in Inicio's quick access and
/// the "Más" hub.
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final items = <HomeTabItem>[
      HomeTabItem(icon: LucideIcons.home, label: l10n.navHome),
      HomeTabItem(
        icon: LucideIcons.arrowLeftRight,
        label: l10n.transactionsTitle,
      ),
      HomeTabItem(icon: LucideIcons.chartPie, label: l10n.navBudgets),
      HomeTabItem(
        icon: LucideIcons.calendarClock,
        label: l10n.navScheduledPayments,
      ),
      HomeTabItem(icon: LucideIcons.ellipsis, label: l10n.navMore),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            // `Tab Inner` (`qmpbo`) has only a soft shadow, no stroke.
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: HomeTabBarItem(
                    item: items[index],
                    isActive: index == currentIndex,
                    onTap: () => onSelect(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single tab slot. The whole slot is the tap target (≥44pt), not just the
/// icon+label (HU-01 / MASTER Tab Bar note).
class HomeTabBarItem extends StatelessWidget {
  const HomeTabBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final HomeTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground = isActive ? colors.primary : colors.textSecondary;

    return Semantics(
      selected: isActive,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? colors.muted : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22, color: foreground),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                // Pencil's `Label` (e.g. `rOzr4`) is 9pt: `labelSmall`'s
                // default (11pt) is what was clipping "Movimientos" and
                // "Presupuestos" to an ellipsis in a 5-column row.
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
