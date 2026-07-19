import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/category.dart';

/// The categories list empty state (`vH7RI`), one message per active
/// [CategoryKind].
///
/// Only shows for the edge case where the user deleted every category of a
/// kind — the onboarding seed set (HU-06) keeps a new user from ever landing
/// here.
///
/// Only the icon and the copy are feature-specific; the layout is the shared
/// `Empty State` component (`jmQO5`).
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
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: LucideIcons.folderPlus,
      message: kind == CategoryKind.expense
          ? l10n.categoriesEmptyExpense
          : l10n.categoriesEmptyIncome,
      ctaLabel: l10n.categoriesAdd,
      onCta: onAddCategory,
    );
  }
}
