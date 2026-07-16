import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';

/// The categories list empty state (`vH7RI`), one message per active
/// [CategoryKind].
///
/// Only shows for the edge case where the user deleted every category of a
/// kind — the onboarding seed set (HU-06) keeps a new user from ever landing
/// here.
class CategoriesEmptyState extends StatelessWidget {
  const CategoriesEmptyState({
    required this.kind,
    required this.onAddCategory,
    super.key,
  });

  final CategoryKind kind;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final message = kind == CategoryKind.expense
        ? l10n.categoriesEmptyExpense
        : l10n.categoriesEmptyIncome;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(44),
              ),
              child: Icon(
                Icons.create_new_folder_outlined,
                size: 40,
                color: colors.primaryOnSoft,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddCategory,
              icon: const Icon(Icons.add),
              label: Text(l10n.categoriesAdd),
            ),
          ],
        ),
      ),
    );
  }
}
