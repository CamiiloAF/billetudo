import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../widgets/more_row.dart';

/// The "Más" hub (HU-01): the entry point to every other Nivel 0 destination.
/// Cuentas and Categorías are live; the rest are listed with a "Próximamente"
/// badge until their own lote ships, so no Nivel 0 feature is unreachable.
class MorePage extends StatelessWidget {
  const MorePage({
    required this.onOpenAccounts,
    required this.onOpenCategories,
    required this.onOpenScheduledPayments,
    required this.onOpenComingSoon,
    required this.onOpenSettings,
    required this.isSignedIn,
    required this.onSignOut,
    super.key,
  });

  final VoidCallback onOpenAccounts;
  final VoidCallback onOpenCategories;
  final VoidCallback onOpenScheduledPayments;

  /// Opens a stacked "Próximamente" page titled with the destination's name.
  final ValueChanged<String> onOpenComingSoon;

  final VoidCallback onOpenSettings;

  /// Whether the sync session is active (HU-06/HU-01) — "Cerrar sesión" is a
  /// no-op destination, not a feature gate, so it is simply hidden without a
  /// session rather than shown disabled.
  final bool isSignedIn;
  final VoidCallback onSignOut;

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
              icon: LucideIcons.wallet,
              label: l10n.accountsTitle,
              onTap: onOpenAccounts,
            ),
            MoreRow(
              icon: LucideIcons.shapes,
              label: l10n.categoriesTitle,
              onTap: onOpenCategories,
            ),
            MoreRow(
              icon: LucideIcons.handCoins,
              label: l10n.moreDebts,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreDebts),
            ),
            MoreRow(
              icon: LucideIcons.repeat,
              label: l10n.moreScheduledPayments,
              onTap: onOpenScheduledPayments,
            ),
            // Design debt: Pencil frame `gXcHt` only defines 6 rows and
            // omits "Gráficas e informes" — kept here because it's a real
            // roadmap feature (fl_chart, see CLAUDE.md); the `.pen` needs
            // to be updated to reflect it.
            MoreRow(
              icon: LucideIcons.chartLine,
              label: l10n.moreReports,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreReports),
            ),
            MoreRow(
              icon: LucideIcons.arrowUpDown,
              label: l10n.moreImportExport,
              comingSoon: true,
              onTap: () => onOpenComingSoon(l10n.moreImportExport),
            ),
            MoreRow(
              icon: LucideIcons.settings,
              label: l10n.moreSettings,
              onTap: onOpenSettings,
            ),
            if (isSignedIn) ...[
              const SizedBox(height: 16),
              MoreRow(
                icon: LucideIcons.logOut,
                label: l10n.moreSignOut,
                onTap: onSignOut,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
