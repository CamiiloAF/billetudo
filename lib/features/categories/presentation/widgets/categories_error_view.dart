import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The categories list error state (`oaBzm`).
///
/// Same neutral treatment as `AccountsErrorView`: the icon is
/// `$muted`/`$text-secondary`, never `$expense` — a failed read is not a
/// financial alarm — and it says the data is still on the device.
class CategoriesErrorView extends StatelessWidget {
  const CategoriesErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  LucideIcons.triangleAlert,
                  color: colors.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.categoriesErrorTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountsErrorLocalFirst,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
