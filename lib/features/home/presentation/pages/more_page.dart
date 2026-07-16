import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../widgets/more_row.dart';

/// The "Más" hub (HU-01): the entry point to every other Nivel 0 destination.
/// Cuentas and Categorías are live; the rest are listed with a "Próximamente"
/// badge until their own lote ships, so no Nivel 0 feature is unreachable.
class MorePage extends StatelessWidget {
  const MorePage({
    required this.onOpenAccounts,
    required this.onOpenCategories,
    required this.onOpenComingSoon,
    required this.onOpenSettings,
    required this.isSignedIn,
    required this.onSignOut,
    super.key,
  });

  final VoidCallback onOpenAccounts;
  final VoidCallback onOpenCategories;

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
              onTap: onOpenSettings,
            ),
            if (isSignedIn) ...[
              const SizedBox(height: 16),
              MoreRow(
                icon: Icons.logout,
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
