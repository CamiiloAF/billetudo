import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// The search empty state of the `Category Select Sheet` (`RculR`): a
/// `search-x` icon and a neutral message, shown while the Search Bar stays in
/// place above it when no category matches the query.
class CategorySelectEmptyState extends StatelessWidget {
  const CategorySelectEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX, size: 40, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            l10n.categorySelectEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
