import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import 'app_router.dart';

/// Startup placeholder. It is replaced by the real shell + Tab Bar once the
/// features land (see `design-system/billetudo/pages/`).
class BootstrapHomePage extends StatelessWidget {
  const BootstrapHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: colors.primaryOnSoft,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bootstrapReady,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              // Temporary way into Cuentas (design note P0eUE): it belongs in
              // the Hero of Inicio / the "Más" menu, neither of which exists
              // yet. It goes away with the real shell.
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.accounts),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text(l10n.accountsOpenAction),
              ),
              const SizedBox(height: 12),
              // Temporary way into Categorías, same reasoning as Cuentas
              // above: it goes away with the real shell/menu "Más".
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.categories),
                icon: const Icon(Icons.category_outlined),
                label: Text(l10n.categoriesOpenAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
