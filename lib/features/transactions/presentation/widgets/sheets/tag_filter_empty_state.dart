import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// The search empty state of the tag sheet (`FL1gK`).
///
/// The tag sheet's list sits in a fixed viewport, so a query with no matches
/// would otherwise leave an unexplained gap. Mirrors
/// `CategorySelectEmptyState`, the same pattern for the category sheet.
class TagFilterEmptyState extends StatelessWidget {
  const TagFilterEmptyState({super.key});

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
            l10n.tagFilterEmpty,
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
